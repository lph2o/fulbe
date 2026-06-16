-- ────────────────────────────────────────────────────────────────
-- 017 : Ajouter chapter_id et organization_id à v_member_profiles
-- 
-- Permet aux requêtes par chapitre (ChapterDetailScreen) de
-- faire un seul appel au lieu de deux (N+1 évité).
-- ────────────────────────────────────────────────────────────────

-- Recréer la vue avec les colonnes ajoutées
-- DROP + CREATE (pas CREATE OR REPLACE) car les colonnes
-- changent de position avec l'ajout de chapter_id et organization_id.
DROP VIEW IF EXISTS public.v_member_profiles;
CREATE VIEW public.v_member_profiles
WITH (security_invoker = true) AS
SELECT
  m.id,
  m.user_id,
  m.full_name,
  m.profession,
  m.city,
  m.country,
  m.avatar_url,
  m.initials,
  m.is_verified,
  m.linkedin,
  m.created_at,
  m.updated_at,
  m.chapter_id,
  m.organization_id,
  coalesce(
    (
      SELECT array_agg(s.skill ORDER BY s.skill)
      FROM public.member_skills s
      WHERE s.member_id = m.id
    ),
    '{}'::text[]
  ) as skills
FROM public.members m;

COMMENT ON VIEW public.v_member_profiles IS
  'Member profiles flattened with their skills, chapter_id, and organization_id. Use this for the directory screen and chapter detail.';

GRANT SELECT ON public.v_member_profiles TO anon, authenticated;
