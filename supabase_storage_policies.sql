-- Configuração do Supabase Storage para upload de fotos de perfil
-- Execute este script no SQL Editor do Supabase

-- 1. Criar o bucket user-photos se não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-photos', 'user-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Política para permitir que usuários autenticados façam upload de suas próprias fotos
CREATE POLICY "Users can upload their own profile photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'user-photos' 
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = 'users'
  AND (storage.foldername(name))[2] = auth.uid()::text
  AND (storage.foldername(name))[3] = 'profile'
);

-- 3. Política para permitir que usuários autenticados atualizem suas próprias fotos
CREATE POLICY "Users can update their own profile photos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'user-photos'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = 'users'
  AND (storage.foldername(name))[2] = auth.uid()::text
  AND (storage.foldername(name))[3] = 'profile'
);

-- 4. Política para permitir que usuários autenticados deletem suas próprias fotos
CREATE POLICY "Users can delete their own profile photos" ON storage.objects
FOR DELETE USING (
  bucket_id = 'user-photos'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = 'users'
  AND (storage.foldername(name))[2] = auth.uid()::text
  AND (storage.foldername(name))[3] = 'profile'
);

-- 5. Política para permitir leitura pública das fotos (para exibição nos perfis)
CREATE POLICY "Public can view profile photos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'user-photos'
  AND (storage.foldername(name))[1] = 'users'
  AND (storage.foldername(name))[3] = 'profile'
);

-- 6. Habilitar RLS no bucket storage.objects (se não estiver habilitado)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Verificar as políticas criadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%profile photos%';