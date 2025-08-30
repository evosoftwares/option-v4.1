-- =============================================
-- CONFIGURAÇÃO DA TABELA app_users SEM RLS
-- =============================================
-- Este script configura a tabela app_users para permitir updates
-- sem Row Level Security (RLS), especialmente para photo_url
--
-- EXECUTE NO SUPABASE SQL EDITOR
-- =============================================

-- Informações iniciais
SELECT 'Configurando tabela app_users sem RLS...' as status;

-- =============================================
-- 1. VERIFICAR ESTADO ATUAL
-- =============================================

SELECT 'DIAGNÓSTICO INICIAL' as step;

-- Verificar se a tabela existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_users')
        THEN '✅ Tabela app_users existe'
        ELSE '❌ Tabela app_users NÃO existe'
    END as table_status;

-- Verificar estado do RLS
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '❌ RLS HABILITADO (precisa desabilitar)'
        ELSE '✅ RLS DESABILITADO (correto)'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'app_users';

-- Verificar se coluna photo_url existe
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'app_users' AND column_name = 'photo_url'
        )
        THEN '✅ Coluna photo_url existe'
        ELSE '❌ Coluna photo_url NÃO existe'
    END as column_status;

-- =============================================
-- 2. DESABILITAR RLS
-- =============================================

SELECT 'DESABILITANDO RLS' as step;

-- Desabilitar RLS na tabela app_users
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;

SELECT '✅ RLS desabilitado na tabela app_users' as result;

-- =============================================
-- 3. REMOVER POLÍTICAS EXISTENTES
-- =============================================

SELECT 'REMOVENDO POLÍTICAS RLS' as step;

-- Remover todas as políticas RLS da tabela app_users
DROP POLICY IF EXISTS "Users can view own data" ON app_users;
DROP POLICY IF EXISTS "Users can update own data" ON app_users;
DROP POLICY IF EXISTS "Allow signup to create app_users" ON app_users;
DROP POLICY IF EXISTS "Enable read access for all users" ON app_users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON app_users;
DROP POLICY IF EXISTS "Enable update for authenticated users only" ON app_users;
DROP POLICY IF EXISTS "Users can manage their own data" ON app_users;
DROP POLICY IF EXISTS "Public read access" ON app_users;
DROP POLICY IF EXISTS "Authenticated users can insert" ON app_users;
DROP POLICY IF EXISTS "Authenticated users can update" ON app_users;

SELECT '✅ Políticas RLS removidas' as result;

-- =============================================
-- 4. GARANTIR COLUNA photo_url
-- =============================================

SELECT 'VERIFICANDO COLUNA photo_url' as step;

-- Adicionar coluna photo_url se não existir
ALTER TABLE app_users 
ADD COLUMN IF NOT EXISTS photo_url TEXT;

SELECT '✅ Coluna photo_url garantida' as result;

-- =============================================
-- 5. CONCEDER PERMISSÕES BÁSICAS
-- =============================================

SELECT 'CONCEDENDO PERMISSÕES' as step;

-- Conceder permissões básicas para usuários anônimos e autenticados
GRANT SELECT, INSERT, UPDATE, DELETE ON app_users TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_users TO authenticated;

SELECT '✅ Permissões concedidas para anon e authenticated' as result;

-- =============================================
-- 6. VERIFICAÇÃO FINAL
-- =============================================

SELECT 'VERIFICAÇÃO FINAL' as step;

-- Verificar estado final do RLS
SELECT 
    'RLS Status' as check_type,
    tablename,
    CASE 
        WHEN rowsecurity = false THEN '✅ RLS DESABILITADO (correto)'
        ELSE '❌ RLS ainda habilitado'
    END as status
FROM pg_tables 
WHERE tablename = 'app_users';

-- Verificar políticas ativas (deve retornar 0)
SELECT 
    'Políticas Ativas' as check_type,
    COUNT(*) as total_policies,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Nenhuma política ativa (correto)'
        ELSE '❌ Ainda existem ' || COUNT(*) || ' políticas ativas'
    END as status
FROM pg_policies 
WHERE tablename = 'app_users';

-- Verificar permissões concedidas
SELECT 
    'Permissões' as check_type,
    grantee,
    string_agg(privilege_type, ', ') as privileges
FROM information_schema.role_table_grants 
WHERE table_name = 'app_users'
AND grantee IN ('anon', 'authenticated')
GROUP BY grantee;

-- Verificar estrutura da coluna photo_url
SELECT 
    'Coluna photo_url' as check_type,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'photo_url' THEN '✅ Coluna photo_url configurada'
        ELSE '❌ Problema na coluna'
    END as status
FROM information_schema.columns 
WHERE table_name = 'app_users' 
AND column_name = 'photo_url';

-- =============================================
-- 7. TESTE DE UPDATE (OPCIONAL)
-- =============================================

SELECT 'TESTE OPCIONAL' as step;

-- Comentário: Para testar, descomente e ajuste o ID do usuário
/*
DO $$
DECLARE
    test_user_id uuid;
    test_result record;
BEGIN
    -- Buscar um usuário existente para teste
    SELECT id INTO test_user_id 
    FROM app_users 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- Tentar fazer update de teste
        UPDATE app_users 
        SET 
            photo_url = 'https://example.com/test-photo.jpg',
            updated_at = NOW()
        WHERE id = test_user_id;
        
        -- Verificar se o update funcionou
        SELECT photo_url INTO test_result 
        FROM app_users 
        WHERE id = test_user_id;
        
        RAISE NOTICE '✅ TESTE DE UPDATE: Sucesso! photo_url = %', test_result;
        
        -- Reverter o teste
        UPDATE app_users 
        SET photo_url = NULL 
        WHERE id = test_user_id;
        
    ELSE
        RAISE NOTICE 'ℹ️ TESTE DE UPDATE: Nenhum usuário encontrado para teste';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ TESTE DE UPDATE: Falhou - %', SQLERRM;
END $$;
*/

-- =============================================
-- 8. RESUMO FINAL
-- =============================================

SELECT 'CONFIGURAÇÃO CONCLUÍDA' as final_status;

SELECT '
✅ RESUMO DA CONFIGURAÇÃO:

1. RLS desabilitado na tabela app_users
2. Todas as políticas RLS removidas
3. Coluna photo_url garantida (TEXT, nullable)
4. Permissões concedidas para anon e authenticated
5. Tabela pronta para updates sem RLS

📝 PRÓXIMOS PASSOS:

1. Execute o script validate_app_users_setup.py para validar
2. Teste o update de photo_url na aplicação Flutter
3. Use o método UserService.updateUser() recomendado

🔧 EXEMPLO DE USO NO FLUTTER:

final success = await UserService.updateUser(
  userId: user.id,
  photoUrl: "https://your-bucket.supabase.co/photo.jpg",
);

' as instructions;

-- =============================================
-- FIM DO SCRIPT
-- =============================================