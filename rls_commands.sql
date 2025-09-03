-- Comandos RLS individuais para aplicar no Dashboard do Supabase

-- 1. Verificar políticas existentes
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

-- 2. Remover políticas existentes (execute se existirem)
DROP POLICY IF EXISTS "user_photos_insert" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_select" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_update" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_delete" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_public_select" ON storage.objects;

-- 3. Habilitar RLS na tabela storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 4. Criar política INSERT (permite usuários autenticados inserir no bucket user-photos)
CREATE POLICY "user_photos_insert" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);

-- 5. Criar política SELECT para usuários autenticados
CREATE POLICY "user_photos_select" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'user-photos');

-- 6. Criar política UPDATE (necessária para upsert)
CREATE POLICY "user_photos_update" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL)
WITH CHECK (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);

-- 7. Criar política DELETE
CREATE POLICY "user_photos_delete" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'user-photos' AND auth.uid()::text IS NOT NULL);

-- 8. Criar política SELECT pública (bucket é público)
CREATE POLICY "user_photos_public_select" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'user-photos');

-- 9. Conceder permissões para usuários autenticados
GRANT ALL ON storage.objects TO authenticated;

-- 10. Verificar se bucket existe
SELECT id, name, public, file_size_limit FROM storage.buckets WHERE id = 'user-photos';

-- 11. Criar/atualizar bucket user-photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('user-photos', 'user-photos', true, 52428800, ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 12. Verificar políticas criadas
SELECT policyname, cmd, roles FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname LIKE 'user_photos%';