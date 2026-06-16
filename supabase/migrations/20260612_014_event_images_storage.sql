-- ────────────────────────────────────────────────────────────────
-- 014 : Storage bucket pour les images d'événements
-- Crée le bucket `event-images` avec les policies RLS associées.
-- Même pattern que `post-images` (migration 013).
-- ────────────────────────────────────────────────────────────────

-- 1. Créer le bucket public
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-images', 'event-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy : tout le monde peut voir les images d'événements
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Public can view event images'
  ) THEN
    CREATE POLICY "Public can view event images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'event-images');
  END IF;
END $$;

-- 3. Policy : les utilisateurs authentifiés peuvent uploader
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload event images'
  ) THEN
    CREATE POLICY "Authenticated users can upload event images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'event-images');
  END IF;
END $$;

-- 4. Policy : les utilisateurs peuvent supprimer leurs propres uploads
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Users can delete own event images'
  ) THEN
    CREATE POLICY "Users can delete own event images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'event-images' AND owner = auth.uid());
  END IF;
END $$;
