-- ────────────────────────────────────────────────────────────────
-- 015 : Ajout event_id aux posts
-- Permet de lier un post à un événement, pour afficher une
-- carte de prévisualisation enrichie dans le feed.
-- ────────────────────────────────────────────────────────────────

-- 1. Ajouter la colonne event_id (FK optionnelle vers events)
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES public.events(id) ON DELETE SET NULL;

-- 2. Recréer la vue v_home_feed pour inclure event_id
--    DROP + CREATE (pas CREATE OR REPLACE) car les colonnes
--    changent de position avec l'ajout de updated_at et event_id.
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
  'Home feed posts with author info denormalized and event link. Use for the home screen.';

GRANT SELECT ON public.v_home_feed TO anon, authenticated;
