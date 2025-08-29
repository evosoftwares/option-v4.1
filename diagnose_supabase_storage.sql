-- ===================================================
-- DIAGNÓSTICO DO SUPABASE STORAGE
-- Execute este script no Supabase SQL Editor
-- ===================================================
--
-- Este script verifica se os buckets necessários existem
-- e diagnostica possíveis problemas de configuração.

-- 1. Verificar se os buckets existem
SELECT 
    'VERIFICAÇÃO DE BUCKETS' as diagnostico,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id IN ('user-photos', 'driver-documents')
ORDER BY id;

-- 2. Listar todos os buckets existentes
SELECT 
    'TODOS OS BUCKETS EXISTENTES' as diagnostico,
    id,
    name,
    public,
    created_at
FROM storage.buckets 
ORDER BY created_at;

-- 3. Verificar políticas de segurança para storage.objects
SELECT 
    'POLÍTICAS DE STORAGE' as diagnostico,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;

-- 4. Verificar se RLS está habilitado na tabela storage.objects
SELECT 
    'RLS STATUS' as diagnostico,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'objects'
AND schemaname = 'storage';

-- 5. Verificar se há objetos nos buckets (se existirem)
SELECT 
    'OBJETOS NOS BUCKETS' as diagnostico,
    bucket_id,
    COUNT(*) as total_objects,
    MIN(created_at) as primeiro_upload,
    MAX(created_at) as ultimo_upload
FROM storage.objects 
WHERE bucket_id IN ('user-photos', 'driver-documents')
GROUP BY bucket_id
ORDER BY bucket_id;

-- 6. Verificar permissões do usuário atual
SELECT 
    'USUÁRIO ATUAL' as diagnostico,
    auth.uid() as user_id,
    auth.role() as user_role;

-- 7. Verificar se há erros recentes relacionados a storage
-- (Esta query pode não funcionar se não houver logs de erro)
SELECT 
    'VERIFICAÇÃO DE SCHEMA STORAGE' as diagnostico,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'storage'
AND table_name IN ('buckets', 'objects')
ORDER BY table_name, ordinal_position;

-- 8. Testar criação de bucket (se não existir)
-- ATENÇÃO: Descomente apenas se quiser criar os buckets
/*
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('user-photos', 'user-photos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']),
    ('driver-documents', 'driver-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;
*/

-- 9. Verificar se há conflitos de nomes ou IDs
SELECT 
    'VERIFICAÇÃO DE CONFLITOS' as diagnostico,
    id,
    name,
    CASE 
        WHEN id = name THEN 'OK'
        ELSE 'CONFLITO: ID != NAME'
    END as status
FROM storage.buckets;

-- ===================================================
-- INTERPRETAÇÃO DOS RESULTADOS:
-- ===================================================
-- 
-- 1. Se "VERIFICAÇÃO DE BUCKETS" retornar 0 linhas:
--    - Os buckets não existem, execute setup_supabase_storage_buckets.sql
--
-- 2. Se "POLÍTICAS DE STORAGE" retornar 0 linhas:
--    - Não há políticas configuradas, pode causar erros de permissão
--
-- 3. Se "RLS STATUS" mostrar rls_enabled = false:
--    - RLS não está habilitado, pode causar problemas de segurança
--
-- 4. Se "USUÁRIO ATUAL" retornar user_id = null:
--    - Usuário não está autenticado, faça login primeiro
--
-- 5. Erros comuns:
--    - "Bucket not found": Execute setup_supabase_storage_buckets.sql
--    - "Permission denied": Verifique políticas de segurança
--    - "File too large": Verifique file_size_limit do bucket
-- ===================================================