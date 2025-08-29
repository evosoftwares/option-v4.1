-- ===================================================
-- CONFIGURAÇÃO DOS BUCKETS DO SUPABASE STORAGE
-- Execute este script no Supabase SQL Editor
-- ===================================================
--
-- Este script cria os buckets necessários para o funcionamento
-- da aplicação, incluindo upload de fotos de perfil e documentos.

-- 1. Criar bucket para fotos de perfil dos usuários
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-photos',
    'user-photos', 
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Criar bucket para documentos dos motoristas
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'driver-documents',
    'driver-documents',
    false, -- Privado para documentos sensíveis
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- 3. Criar políticas de segurança para bucket user-photos
-- Permitir que usuários autenticados façam upload de suas próprias fotos
CREATE POLICY "Users can upload own photos" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'user-photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir que usuários autenticados vejam suas próprias fotos
CREATE POLICY "Users can view own photos" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'user-photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir que usuários autenticados deletem suas próprias fotos
CREATE POLICY "Users can delete own photos" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'user-photos' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- 4. Criar políticas de segurança para bucket driver-documents
-- Permitir que motoristas façam upload de seus próprios documentos
CREATE POLICY "Drivers can upload own documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'driver-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir que motoristas vejam seus próprios documentos
CREATE POLICY "Drivers can view own documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'driver-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir que motoristas deletem seus próprios documentos
CREATE POLICY "Drivers can delete own documents" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'driver-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir que administradores vejam todos os documentos
CREATE POLICY "Admins can view all documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'driver-documents' AND
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

-- 5. Verificar se os buckets foram criados corretamente
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id IN ('user-photos', 'driver-documents')
ORDER BY id;

-- 6. Verificar políticas criadas
SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%photos%' OR policyname LIKE '%documents%'
ORDER BY policyname;

-- ===================================================
-- INSTRUÇÕES:
-- ===================================================
-- 1. Vá para seu dashboard do Supabase
-- 2. Clique em "SQL Editor" no menu lateral
-- 3. Cole este código completo
-- 4. Clique em "Run" para executar
-- 5. Verifique se as últimas queries retornam os buckets criados
-- 6. Teste o upload de fotos no app
-- ===================================================

-- NOTA: Se você receber erro "Bucket not found", significa que
-- este script ainda não foi executado ou houve algum problema
-- na criação dos buckets.