-- Script para debugar e configurar Storage no Supabase
-- Execute no SQL Editor do Supabase

-- 1. Verificar buckets existentes
SELECT id, name, public, created_at 
FROM storage.buckets 
ORDER BY created_at DESC;

-- 2. Verificar políticas existentes para storage.objects
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- 3. Verificar se RLS está habilitado
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 4. Se não houver buckets, criar um bucket básico para avatares
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars', 
  'avatars', 
  true, 
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 5. Política muito permissiva para teste (CUIDADO: só para desenvolvimento)
CREATE POLICY IF NOT EXISTS "Allow all operations for authenticated users" 
ON storage.objects 
FOR ALL 
TO authenticated
USING (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

-- 6. Política para visualização pública
CREATE POLICY IF NOT EXISTS "Allow public read access to avatars" 
ON storage.objects 
FOR SELECT 
TO public 
USING (bucket_id = 'avatars');