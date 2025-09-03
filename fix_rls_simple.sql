-- ===================================================
-- CORREÇÃO SIMPLES DE RLS PARA BUCKET USER-PHOTOS
-- Execute este script no Supabase SQL Editor
-- ===================================================

-- 1. Remover políticas existentes que podem estar causando conflito
DROP POLICY IF EXISTS "user_photos_insert" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_select" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_update" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_delete" ON storage.objects;
DROP POLICY IF EXISTS "user_photos_public_select" ON storage.objects;
DROP POLICY IF EXISTS "Motoristas podem fazer upload de documentos (caminho drivers)" ON storage.objects;
DROP POLICY IF EXISTS "Motoristas podem fazer upload de documentos (novo caminho)" ON storage.objects;

-- 2. Habilitar RLS na tabela storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Criar política INSERT mais permissiva (sem verificação de auth.uid)
CREATE POLICY "user_photos_insert" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'user-photos'
);

-- 4. Criar política SELECT para usuários autenticados
CREATE POLICY "user_photos_select" ON storage.objects
FOR SELECT 
TO authenticated
USING (
  bucket_id = 'user-photos'
);

-- 5. Criar política UPDATE
CREATE POLICY "user_photos_update" ON storage.objects
FOR UPDATE 
TO authenticated
USING (
  bucket_id = 'user-photos'
)
WITH CHECK (
  bucket_id = 'user-photos'
);

-- 6. Criar política DELETE
CREATE POLICY "user_photos_delete" ON storage.objects
FOR DELETE 
TO authenticated
USING (
  bucket_id = 'user-photos'
);

-- 7. Criar política SELECT pública (bucket é público)
CREATE POLICY "user_photos_public_select" ON storage.objects
FOR SELECT 
TO public
USING (
  bucket_id = 'user-photos'
);

-- 8. Conceder permissões necessárias
GRANT ALL ON storage.objects TO authenticated;
GRANT SELECT ON storage.objects TO anon;

-- 9. Garantir que o bucket user-photos existe e está configurado corretamente
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-photos',
  'user-photos', 
  true,
  52428800, -- 50MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) 
DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 10. Verificar se as políticas foram criadas
SELECT 
  'POLÍTICAS CRIADAS' as status,
  policyname, 
  cmd, 
  roles 
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage' 
AND policyname LIKE 'user_photos%';

-- 11. Verificar configuração do bucket
SELECT 
  'CONFIGURAÇÃO DO BUCKET' as status,
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'user-photos';

-- ===================================================
-- INSTRUÇÕES:
-- 1. Copie todo este script
-- 2. Vá para o Supabase Dashboard > SQL Editor
-- 3. Cole o script e execute
-- 4. Verifique se as consultas de verificação retornam dados
-- 5. Teste o upload na aplicação
-- ===================================================