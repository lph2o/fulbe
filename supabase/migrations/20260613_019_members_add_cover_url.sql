-- ────────────────────────────────────────────────────────────────
-- 019 : Ajouter la colonne cover_url à la table members
--
-- Supporte la photo de couverture personnalisable (style LinkedIn).
-- Crée aussi le bucket storage `covers` avec les policies RLS.
-- ────────────────────────────────────────────────────────────────

-- 1. Ajouter la colonne cover_url
ALTER TABLE public.members
ADD COLUMN IF NOT EXISTS cover_url text;

-- 2. Mettre à jour le trigger pour peupler cover_url à l'inscription
CREATE OR REPLACE FUNCTION public.tg_handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.members (user_id, full_name, profession, city, country, avatar_url, cover_url, bio)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'profession', 'Membre Connecté'),
    COALESCE(NEW.raw_user_meta_data ->> 'city', ''),
    COALESCE(NEW.raw_user_meta_data ->> 'country', ''),
    NEW.raw_user_meta_data ->> 'avatar_url',
    NEW.raw_user_meta_data ->> 'cover_url',
    NEW.raw_user_meta_data ->> 'bio'
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 3. Recréer la vue v_member_profiles pour inclure cover_url
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
  m.cover_url,
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
  'Member profiles flattened with skills, bio, cover_url, chapter_id, and organization_id.';

GRANT SELECT ON public.v_member_profiles TO anon, authenticated;

-- 4. Créer le bucket storage pour les covers
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true)
ON CONFLICT (id) DO NOTHING;

-- 5. Policy : tout le monde peut voir les covers
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Public can view covers'
  ) THEN
    CREATE POLICY "Public can view covers"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'covers');
  END IF;
END $$;

-- 6. Policy : les utilisateurs authentifiés peuvent uploader leur cover
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload covers'
  ) THEN
    CREATE POLICY "Authenticated users can upload covers"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'covers');
  END IF;
END $$;

-- 7. Policy : les utilisateurs peuvent supprimer leurs propres covers
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Users can delete own covers'
  ) THEN
    CREATE POLICY "Users can delete own covers"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'covers' AND owner = auth.uid());
  END IF;
END $$;
