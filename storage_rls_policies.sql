-- Script para criar políticas RLS corretas para Supabase Storage
-- Baseado na documentação oficial do Supabase

-- 1. Primeiro, verificar se RLS está habilitado na tabela storage.objects
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 2. Habilitar RLS se não estiver habilitado
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Remover todas as políticas existentes (se houver)
DROP POLICY IF EXISTS "Allow authenticated users to select files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to insert files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete files" ON storage.objects;

-- 4. Criar política SELECT para permitir leitura de arquivos no bucket user-photos
CREATE POLICY "Allow authenticated users to select files"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-photos'
);

-- 5. Criar política INSERT para permitir upload de arquivos no bucket user-photos
CREATE POLICY "Allow authenticated users to insert files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-photos'
);

-- 6. Criar política UPDATE para permitir atualização de arquivos no bucket user-photos
-- Esta política é ESSENCIAL para o upsert funcionar
CREATE POLICY "Allow authenticated users to update files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-photos'
)
WITH CHECK (
  bucket_id = 'user-photos'
);

-- 7. Criar política DELETE para permitir remoção de arquivos no bucket user-photos
CREATE POLICY "Allow authenticated users to delete files"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-photos'
);

-- 8. Verificar se as políticas foram criadas corretamente
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- 9. Verificar se o bucket user-photos existe e está configurado corretamente
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets 
WHERE id = 'user-photos';

-- IMPORTANTE: 
-- O upsert no Supabase Storage requer que as políticas SELECT, INSERT e UPDATE estejam todas presentes
-- porque o upsert pode fazer uma operação SELECT para verificar se o arquivo existe,
-- seguida de INSERT (se não existir) ou UPDATE (se existir)
-- 
-- Sem a política UPDATE, o upsert falhará com erro RLS mesmo que o usuário esteja autenticado