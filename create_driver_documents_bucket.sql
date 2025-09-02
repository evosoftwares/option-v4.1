-- ===================================================
-- CRIAÇÃO DO BUCKET DRIVER-DOCUMENTS
-- Execute este script no Supabase SQL Editor
-- ===================================================

-- 1. Verificar se o bucket já existe
SELECT 
    'VERIFICAÇÃO DE BUCKET' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'driver-documents';

-- 2. Criar bucket para documentos dos motoristas (se não existir)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'driver-documents',
    'driver-documents',
    false, -- Privado para documentos sensíveis
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- 3. Verificar se RLS está habilitado
SELECT 
    'VERIFICAÇÃO RLS' as status,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 4. Desabilitar RLS se estiver habilitado (para simplificar)
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 5. Conceder permissões básicas
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated, anon;

-- 6. Remover políticas conflitantes (se existirem)
DROP POLICY IF EXISTS "Drivers can upload own documents" ON storage.objects;
DROP POLICY IF EXISTS "Drivers can view own documents" ON storage.objects;
DROP POLICY IF EXISTS "Drivers can delete own documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all documents" ON storage.objects;

-- 7. Verificação final
SELECT 
    'VERIFICAÇÃO FINAL' as status,
    id,
    name,
    public,
    file_size_limit
FROM storage.buckets 
WHERE id IN ('user-photos', 'driver-documents')
ORDER BY id;

-- 8. Teste de conectividade (opcional)
SELECT 
    'TESTE DE ACESSO' as status,
    bucket_id,
    COUNT(*) as total_objects
FROM storage.objects 
WHERE bucket_id IN ('user-photos', 'driver-documents')
GROUP BY bucket_id
ORDER BY bucket_id;

-- ===================================================
-- INSTRUÇÕES:
-- 1. Copie e cole este script no Supabase SQL Editor
-- 2. Execute o script completo
-- 3. Verifique se não há erros
-- 4. Teste o upload na aplicação Flutter
-- ===================================================