-- 021 : Table post_shares + compteur de partages
-- Permet de tracker qui a partage quel post, et met a jour
-- automatiquement posts.shares_count via un trigger.

-- 1. Ajouter la colonne shares_count a la table posts
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS shares_count integer NOT NULL DEFAULT 0;

-- 2. Creer la table post_shares
CREATE TABLE IF NOT EXISTS public.post_shares (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id uuid NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  post_id uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE (member_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_post_shares_post
  ON public.post_shares (post_id);

-- 3. Activer RLS
ALTER TABLE public.post_shares ENABLE ROW LEVEL SECURITY;

-- 4. Trigger pour mettre a jour posts.shares_count
CREATE OR REPLACE FUNCTION public.tg_post_share_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET shares_count = shares_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET shares_count = GREATEST(shares_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_post_share_count ON public.post_shares;
CREATE TRIGGER trg_post_share_count
AFTER INSERT OR DELETE ON public.post_shares
FOR EACH ROW EXECUTE FUNCTION public.tg_post_share_count();

-- 5. Policies RLS
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'post_shares'
      AND policyname = 'Members can insert their own shares'
  ) THEN
    CREATE POLICY "Members can insert their own shares"
    ON public.post_shares FOR INSERT
    TO authenticated
    WITH CHECK (member_id IN (
      SELECT id FROM public.members WHERE user_id = auth.uid()
    ));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'post_shares'
      AND policyname = 'Members can view their own shares'
  ) THEN
    CREATE POLICY "Members can view their own shares"
    ON public.post_shares FOR SELECT
    TO authenticated
    USING (member_id IN (
      SELECT id FROM public.members WHERE user_id = auth.uid()
    ));
  END IF;
END $$;

-- 6. Recréer la vue v_home_feed pour inclure shares_count
DROP VIEW IF EXISTS public.v_home_feed;
CREATE VIEW public.v_home_feed
WITH (security_invoker = true) AS
SELECT
  p.id,
  p.author_id,
  p.content,
  p.image_url,
  p.likes_count,
  p.comments_count,
  p.shares_count,
  p.time_ago,
  p.created_at,
  p.updated_at,
  p.event_id,
  m.full_name        AS author_name,
  m.city             AS author_city,
  m.country          AS author_country,
  m.avatar_url       AS author_avatar_url,
  m.initials         AS author_initials,
  m.is_verified      AS author_is_verified
FROM public.posts p
LEFT JOIN public.members m ON m.id = p.author_id
ORDER BY p.created_at desc;

COMMENT ON VIEW public.v_home_feed IS
  'Home feed posts with author info denormalized, event link, and share count.';

GRANT SELECT ON public.v_home_feed TO anon, authenticated;
