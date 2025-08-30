-- ===================================================
-- CONFIGURAÇÃO DO BUCKET USER-PHOTOS SEM RLS
-- Execute este script no Supabase SQL Editor
-- ===================================================
--
-- IMPORTANTE: Este script NÃO usa RLS conforme restrições do projeto
-- A segurança será gerenciada pela aplicação

-- 1. Verificar se o bucket já existe
SELECT 
    'VERIFICAÇÃO INICIAL' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'user-photos';

-- 2. Criar bucket user-photos se não existir
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
    true,  -- Público para permitir acesso direto
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 3. DESABILITAR RLS na tabela storage.objects (se estiver habilitado)
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 4. Remover todas as políticas existentes para storage.objects
-- (para evitar conflitos)
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON storage.objects';
        RAISE NOTICE 'Política removida: %', policy_record.policyname;
    END LOOP;
END $$;

-- 5. Garantir permissões básicas para usuários autenticados
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO anon;

-- 6. Verificar configuração final
SELECT 
    'CONFIGURAÇÃO FINAL' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'user-photos';

-- 7. Verificar se RLS está desabilitado
SELECT 
    'STATUS RLS' as status,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'objects'
AND schemaname = 'storage';

-- 8. Verificar se não há políticas ativas
SELECT 
    'POLÍTICAS ATIVAS' as status,
    COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- ===================================================
-- INSTRUÇÕES DE USO:
-- ===================================================
-- 1. Vá para o Supabase Dashboard
-- 2. Acesse SQL Editor
-- 3. Cole e execute este script completo
-- 4. Verifique se todas as queries retornam resultados esperados:
--    - Bucket 'user-photos' criado
--    - RLS desabilitado (rls_enabled = false)
--    - Nenhuma política ativa (total_policies = 0)
-- 5. Teste o upload na aplicação
--
-- NOTA: A segurança será gerenciada pela aplicação Flutter
-- através do FileUploadService que valida:
-- - Autenticação do usuário
-- - Tamanho do arquivo (máx 5MB)
-- - Tipos MIME permitidos
-- - Estrutura de pastas por usuário
-- ===================================================

-- 9. Teste de conectividade (opcional)
-- Descomente para testar se o bucket está acessível
/*
SELECT 
    'TESTE DE ACESSO' as status,
    bucket_id,
    COUNT(*) as total_objects
FROM storage.objects 
WHERE bucket_id = 'user-photos'
GROUP BY bucket_id;
*/