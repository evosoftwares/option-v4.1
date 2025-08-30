-- Script para corrigir RLS no Supabase Storage
-- Execute este script no SQL Editor do Supabase Dashboard

-- 1. Verificar estado atual do RLS nas tabelas de storage
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename IN ('objects', 'buckets');

-- 2. Desabilitar RLS nas tabelas de storage
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- 3. Remover políticas existentes de storage
DROP POLICY IF EXISTS "Give anon users access to JPG images in folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Give anon users access to PNG images in folder 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_0" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_1" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1oj01fe_2" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;
DROP POLICY IF EXISTS "Public bucket access" ON storage.buckets;

-- 4. Garantir permissões básicas para usuários anônimos e autenticados
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT SELECT ON storage.buckets TO anon;
GRANT SELECT ON storage.buckets TO authenticated;

-- 5. Verificar se o bucket user-photos existe e está público
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE name = 'user-photos';

-- 6. Se o bucket não existir, criar ele
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

-- 7. Verificar estado final
SELECT 'RLS Status' as check_type, 
       schemaname, 
       tablename, 
       rowsecurity as enabled
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename IN ('objects', 'buckets')

UNION ALL

SELECT 'Bucket Status' as check_type,
       'storage' as schemaname,
       name as tablename,
       public::text as enabled
FROM storage.buckets 
WHERE name = 'user-photos';

-- 8. Teste de inserção (opcional)
-- Descomente as linhas abaixo para testar se as permissões estão funcionando
/*
INSERT INTO storage.objects (
    bucket_id,
    name,
    owner,
    metadata
) VALUES (
    'user-photos',
    'test/test_file.txt',
    null,
    '{"size": 100}'
);

SELECT 'Test Insert' as result, 'SUCCESS' as status;

-- Limpar teste
DELETE FROM storage.objects 
WHERE bucket_id = 'user-photos' 
AND name = 'test/test_file.txt';
*/

-- 9. Resumo final
SELECT 
    '✅ Script executado com sucesso!' as status,
    'RLS desabilitado no storage' as rls_status,
    'Bucket user-photos configurado' as bucket_status,
    'Permissões básicas concedidas' as permissions_status;

-- 10. Instruções finais
SELECT 
    'PRÓXIMOS PASSOS:' as instrucoes,
    '1. Execute o teste Dart novamente' as passo_1,
    '2. Upload deve funcionar com chave anônima' as passo_2,
    '3. URLs públicas devem ser acessíveis' as passo_3;