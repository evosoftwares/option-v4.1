-- Script para corrigir políticas RLS do Supabase Storage
-- Execute este script no SQL Editor do Supabase Dashboard

-- 1. Habilitar RLS na tabela storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas existentes
DROP POLICY IF EXISTS "Allow authenticated users to select files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to insert files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete files" ON storage.objects;

-- 3. Criar política SELECT (necessária para upsert)
CREATE POLICY "Allow authenticated users to select files"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'user-photos');

-- 4. Criar política INSERT (necessária para upsert)
CREATE POLICY "Allow authenticated users to insert files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'user-photos');

-- 5. Criar política UPDATE (ESSENCIAL para upsert)
CREATE POLICY "Allow authenticated users to update files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'user-photos')
WITH CHECK (bucket_id = 'user-photos');

-- 6. Criar política DELETE
CREATE POLICY "Allow authenticated users to delete files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'user-photos');

-- 7. Verificar políticas criadas
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects';}}}