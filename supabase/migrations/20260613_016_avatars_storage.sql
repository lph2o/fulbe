-- ────────────────────────────────────────────────────────────────
-- 016 : Storage bucket pour les avatars des membres
-- Crée le bucket `avatars` avec les policies RLS associées.
-- Même pattern que `post-images` (013) et `event-images` (014).
-- ────────────────────────────────────────────────────────────────

-- 1. Créer le bucket public
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy : tout le monde (y compris non connecté) peut voir les avatars
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Public can view avatars'
  ) THEN
    CREATE POLICY "Public can view avatars"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'avatars');
  END IF;
END $$;

-- 3. Policy : les utilisateurs authentifiés peuvent uploader leur avatar
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload avatars'
  ) THEN
    CREATE POLICY "Authenticated users can upload avatars"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'avatars');
  END IF;
END $$;

-- 4. Policy : les utilisateurs peuvent supprimer leurs propres avatars
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Users can delete own avatars'
  ) THEN
    CREATE POLICY "Users can delete own avatars"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'avatars' AND owner = auth.uid());
  END IF;
END $$;
