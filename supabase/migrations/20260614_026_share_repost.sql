-- 026 : Ajout share_type (post_shares), repost_of (posts), metadata (messages)
-- Supporte le double mode de partage : DM (message privé) et Repost (fil d'actualité)

-- 1. Ajouter share_type à post_shares (valeurs: 'native', 'dm', 'repost')
ALTER TABLE public.post_shares
  ADD COLUMN IF NOT EXISTS share_type text NOT NULL DEFAULT 'native';

COMMENT ON COLUMN public.post_shares.share_type IS
  'Type de partage : native (OS share), dm (message privé), repost (fil)';

-- 2. Ajouter repost_of à posts (référence au post original pour les reposts)
ALTER TABLE public.posts
  ADD COLUMN IF NOT EXISTS repost_of uuid REFERENCES public.posts(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.posts.repost_of IS
  'ID du post original si ce post est un repost (NULL sinon). SET NULL si le post original est supprimé.';

CREATE INDEX IF NOT EXISTS idx_posts_repost_of ON public.posts(repost_of);

-- 3. Ajouter metadata aux messages (stocke msg_type: 'post_share' et post_id pour les partages)
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.messages.metadata IS
  'Métadonnées du message. Pour un partage de post : {"msg_type": "post_share", "post_id": "<uuid>"}';

-- 4. Mettre à jour la vue v_home_feed pour inclure repost_of
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
  p.repost_of,
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
  'Home feed posts with author info denormalized, event link, share count, and repost reference.';

GRANT SELECT ON public.v_home_feed TO anon, authenticated;
