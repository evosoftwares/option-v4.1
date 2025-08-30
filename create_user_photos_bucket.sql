-- Script simplificado para criar bucket e políticas básicas
-- Execute no SQL Editor do Supabase Dashboard

-- 1. Primeiro, vamos verificar se o bucket já existe
SELECT * FROM storage.buckets WHERE id = 'user-photos';

-- 2. Se não existir, criar o bucket (execute via interface do Supabase Storage)
-- Vá em Storage > Create bucket > nome: "user-photos" > public: true

-- 3. Políticas básicas para o bucket user-photos
-- IMPORTANTE: Execute cada comando separadamente

-- Política de INSERT (upload)
CREATE POLICY "Authenticated users can upload profile photos" 
ON storage.objects 
FOR INSERT 
TO authenticated
WITH CHECK (bucket_id = 'user-photos');

-- Política de SELECT (visualização) - Público
CREATE POLICY "Anyone can view profile photos" 
ON storage.objects 
FOR SELECT 
TO public 
USING (bucket_id = 'user-photos');

-- Política de UPDATE (atualização)
CREATE POLICY "Users can update their profile photos" 
ON storage.objects 
FOR UPDATE 
TO authenticated
USING (bucket_id = 'user-photos');

-- Política de DELETE (exclusão)
CREATE POLICY "Users can delete their profile photos" 
ON storage.objects 
FOR DELETE 
TO authenticated
USING (bucket_id = 'user-photos');

-- Verificar se RLS está habilitado
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';