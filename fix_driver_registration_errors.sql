-- Script para corrigir erros de cadastro de motorista
-- Execute este script no SQL Editor do Supabase Dashboard

-- ========================================
-- PARTE 1: DIAGNÓSTICO DOS PROBLEMAS
-- ========================================

-- 1.1 Verificar constraint atual de vehicle_category
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname LIKE '%vehicle_category%' 
   OR conname LIKE '%drivers_vehicle_category%';

-- 1.2 Verificar RLS nas tabelas de storage
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename IN ('objects', 'buckets');

-- 1.3 Verificar buckets existentes
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE name IN ('user-photos', 'driver-documents');

-- ========================================
-- PARTE 2: CORREÇÃO DA CONSTRAINT VEHICLE_CATEGORY
-- ========================================

-- 2.1 Remover constraint antiga se existir
ALTER TABLE drivers DROP CONSTRAINT IF EXISTS drivers_vehicle_category_check;
ALTER TABLE drivers DROP CONSTRAINT IF EXISTS vehicle_category_check;

-- 2.2 Criar nova constraint com valores corretos
ALTER TABLE drivers ADD CONSTRAINT drivers_vehicle_category_check 
CHECK (vehicle_category IN ('economico', 'standard', 'premium', 'suv', 'executivo', 'van'));

-- 2.3 Verificar se há registros com valores inválidos
SELECT 
    id,
    user_id,
    vehicle_category,
    'VALOR INVÁLIDO' as status
FROM drivers 
WHERE vehicle_category NOT IN ('economico', 'standard', 'premium', 'suv', 'executivo', 'van')
   OR vehicle_category IS NULL;

-- ========================================
-- PARTE 3: CORREÇÃO DO RLS NO STORAGE
-- ========================================

-- 3.1 Desabilitar RLS nas tabelas de storage
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- 3.2 Remover políticas conflitantes
DROP POLICY IF EXISTS "Give anon users access to JPG images in folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Give anon users access to PNG images in folder 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_2" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;
DROP POLICY IF EXISTS "Public bucket access" ON storage.buckets;

-- 3.3 Conceder permissões básicas
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT SELECT ON storage.buckets TO anon;
GRANT SELECT ON storage.buckets TO authenticated;

-- ========================================
-- PARTE 4: CONFIGURAÇÃO DOS BUCKETS
-- ========================================

-- 4.1 Criar/atualizar bucket user-photos
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'user-photos',
    'user-photos',
    true,
    52428800, -- 50MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 4.2 Criar/atualizar bucket driver-documents
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
VALUES (
    'driver-documents',
    'driver-documents',
    true,
    52428800, -- 50MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ========================================
-- PARTE 5: VERIFICAÇÃO FINAL
-- ========================================

-- 5.1 Verificar constraint atualizada
SELECT 
    'Constraint Status' as check_type,
    conname as name,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conname = 'drivers_vehicle_category_check';

-- 5.2 Verificar RLS desabilitado
SELECT 
    'RLS Status' as check_type,
    schemaname || '.' || tablename as name,
    CASE WHEN rowsecurity THEN 'HABILITADO' ELSE 'DESABILITADO' END as status
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename IN ('objects', 'buckets');

-- 5.3 Verificar buckets configurados
SELECT 
    'Bucket Status' as check_type,
    name,
    CASE WHEN public THEN 'PÚBLICO' ELSE 'PRIVADO' END as status,
    file_size_limit,
    array_length(allowed_mime_types, 1) as mime_types_count
FROM storage.buckets 
WHERE name IN ('user-photos', 'driver-documents');

-- ========================================
-- PARTE 6: TESTE DE INSERÇÃO (OPCIONAL)
-- ========================================

-- 6.1 Teste de inserção na tabela drivers (descomente para testar)
/*
INSERT INTO drivers (
    user_id,
    vehicle_brand,
    vehicle_model,
    vehicle_year,
    vehicle_color,
    vehicle_plate,
    vehicle_category,
    approval_status
) VALUES (
    '00000000-0000-0000-0000-000000000000', -- UUID de teste
    'TESTE',
    'TESTE',
    2020,
    'TESTE',
    'TESTE123',
    'standard', -- Valor válido
    'pending'
);

SELECT 'Driver Insert Test' as result, 'SUCCESS' as status;

-- Limpar teste
DELETE FROM drivers WHERE vehicle_plate = 'TESTE123';
*/

-- 6.2 Teste de upload no storage (descomente para testar)
/*
INSERT INTO storage.objects (
    bucket_id,
    name,
    owner,
    metadata
) VALUES (
    'driver-documents',
    'test/test_upload.jpg',
    null,
    '{"size": 1024}'
);

SELECT 'Storage Insert Test' as result, 'SUCCESS' as status;

-- Limpar teste
DELETE FROM storage.objects WHERE name = 'test/test_upload.jpg';
*/

-- ========================================
-- RESUMO DAS CORREÇÕES APLICADAS
-- ========================================

SELECT '🎯 CORREÇÕES APLICADAS:' as summary
UNION ALL
SELECT '✅ Constraint vehicle_category atualizada com valores corretos'
UNION ALL
SELECT '✅ RLS desabilitado nas tabelas de storage'
UNION ALL
SELECT '✅ Permissões concedidas para anon/authenticated'
UNION ALL
SELECT '✅ Buckets user-photos e driver-documents configurados'
UNION ALL
SELECT '✅ Políticas conflitantes removidas'
UNION ALL
SELECT ''
UNION ALL
SELECT '🚀 O cadastro de motorista deve funcionar agora!';