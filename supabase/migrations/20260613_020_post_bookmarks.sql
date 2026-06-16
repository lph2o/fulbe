-- ────────────────────────────────────────────────────────────────
-- 020 : Table post_bookmarks — posts mis en favoris par les membres
-- Chaque membre peut bookmarker un post une seule fois
-- (contrainte UNIQUE sur member_id + post_id).
-- ────────────────────────────────────────────────────────────────

-- 1. Créer la table
CREATE TABLE IF NOT EXISTS public.post_bookmarks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id uuid NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  post_id uuid NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now() NOT NULL,
  UNIQUE (member_id, post_id)
);

-- 2. Index pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_post_bookmarks_member
  ON public.post_bookmarks (member_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_post_bookmarks_post
  ON public.post_bookmarks (post_id);

-- 3. Activer RLS
ALTER TABLE public.post_bookmarks ENABLE ROW LEVEL SECURITY;

-- 4. Policies RLS
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'post_bookmarks'
      AND policyname = 'Members can view their own bookmarks'
  ) THEN
    CREATE POLICY "Members can view their own bookmarks"
    ON public.post_bookmarks FOR SELECT
    TO authenticated
    USING (member_id IN (
      SELECT id FROM public.members WHERE user_id = auth.uid()
    ));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'post_bookmarks'
      AND policyname = 'Members can insert their own bookmarks'
  ) THEN
    CREATE POLICY "Members can insert their own bookmarks"
    ON public.post_bookmarks FOR INSERT
    TO authenticated
    WITH CHECK (member_id IN (
      SELECT id FROM public.members WHERE user_id = auth.uid()
    ));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'post_bookmarks'
      AND policyname = 'Members can delete their own bookmarks'
  ) THEN
    CREATE POLICY "Members can delete their own bookmarks"
    ON public.post_bookmarks FOR DELETE
    TO authenticated
    USING (member_id IN (
      SELECT id FROM public.members WHERE user_id = auth.uid()
    ));
  END IF;
END $$;
