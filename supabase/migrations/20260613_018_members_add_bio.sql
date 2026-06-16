-- ────────────────────────────────────────────────────────────────
-- 018 : Ajouter la colonne bio à la table members
--
-- La bio était stockée uniquement dans auth.users.raw_user_meta_data.
-- On l'ajoute à members pour la synchroniser et l'exposer dans la vue.
-- ────────────────────────────────────────────────────────────────

-- 1. Ajouter la colonne
ALTER TABLE public.members
ADD COLUMN IF NOT EXISTS bio text;

-- 2. Mettre à jour le trigger pour inclure bio lors de la création du membre
CREATE OR REPLACE FUNCTION public.tg_handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.members (user_id, full_name, profession, city, country, avatar_url, bio)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'profession', 'Membre Connecté'),
    COALESCE(NEW.raw_user_meta_data ->> 'city', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'country', ''),
    NEW.raw_user_meta_data ->> 'avatar_url',
    NEW.raw_user_meta_data ->> 'bio'
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 3. Recréer la vue v_member_profiles pour inclure bio
--    DROP + CREATE car la position des colonnes change.
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
  m.bio,
  m.created_at,
  m.updated_at,
  m.chapter_id,
  m.organization_id,
  COALESCE(
    (
      SELECT array_agg(s.skill ORDER BY s.skill)
      FROM public.member_skills s
      WHERE s.member_id = m.id
    ),
    '{}'::text[]
  ) AS skills
FROM public.members m;

COMMENT ON VIEW public.v_member_profiles IS
  'Member profiles flattened with their skills, bio, chapter_id, and organization_id. Use for directory and chapter detail.';

GRANT SELECT ON public.v_member_profiles TO anon, authenticated;
