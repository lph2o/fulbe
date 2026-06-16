-- ────────────────────────────────────────────────────────────────
-- 013 : Storage buckets
-- Crée le bucket `post-images` pour les images des posts du fil
-- d'actualité, ainsi que les policies RLS associées.
-- ────────────────────────────────────────────────────────────────

-- 1. Créer le bucket public
INSERT INTO storage.buckets (id, name, public)
VALUES ('post-images', 'post-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy : tout le monde (y compris non connecté) peut voir les images
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Public can view post images'
  ) THEN
    CREATE POLICY "Public can view post images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'post-images');
  END IF;
END $$;

-- 3. Policy : les utilisateurs authentifiés peuvent uploader
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload post images'
  ) THEN
    CREATE POLICY "Authenticated users can upload post images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'post-images');
  END IF;
END $$;

-- 4. Policy : les utilisateurs peuvent supprimer leurs propres uploads
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Users can delete own post images'
  ) THEN
    CREATE POLICY "Users can delete own post images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'post-images' AND owner = auth.uid());
  END IF;
END $$;
