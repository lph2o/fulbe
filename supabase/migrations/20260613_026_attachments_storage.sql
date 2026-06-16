-- ────────────────────────────────────────────────────────────────
-- 026 : Storage bucket pour les pièces jointes des messages
-- Crée le bucket `attachments` avec les policies RLS associées.
-- Même pattern que `post-images` et `event-images`.
-- ────────────────────────────────────────────────────────────────

-- 1. Créer le bucket public
INSERT INTO storage.buckets (id, name, public)
VALUES ('attachments', 'attachments', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy : tout le monde peut voir les pièces jointes
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Public can view attachments'
  ) THEN
    CREATE POLICY "Public can view attachments"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'attachments');
  END IF;
END $$;

-- 3. Policy : les utilisateurs authentifiés peuvent uploader
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Authenticated users can upload attachments'
  ) THEN
    CREATE POLICY "Authenticated users can upload attachments"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'attachments');
  END IF;
END $$;

-- 4. Policy : les utilisateurs peuvent supprimer leurs propres uploads
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Users can delete own attachments'
  ) THEN
    CREATE POLICY "Users can delete own attachments"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'attachments' AND owner = auth.uid());
  END IF;
END $$;
