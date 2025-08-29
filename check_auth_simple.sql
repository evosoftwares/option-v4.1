-- ===============================================
-- DIAGNÓSTICO SIMPLES DO AUTH
-- ===============================================
-- Script que funciona sem depender de tabelas específicas

-- PASSO 1: Verificar se RLS está desabilitado
SELECT 
    'RLS Status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('app_users', 'drivers', 'passengers')
ORDER BY tablename;

-- PASSO 2: Contar políticas restantes
SELECT 
    'Policies Count' as check_type,
    COUNT(*) as total_policies
FROM pg_policies 
WHERE schemaname = 'public';

-- PASSO 3: Listar políticas restantes (se houver)
SELECT 
    'Remaining Policies' as check_type,
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- PASSO 4: Verificar permissões
SELECT 
    'Table Permissions' as check_type,
    schemaname,
    tablename,
    grantor,
    grantee,
    privilege_type
FROM information_schema.table_privileges 
WHERE schemaname = 'public' 
  AND tablename = 'app_users'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee, privilege_type;

-- PASSO 5: Verificar se há processos ativos problemáticos
SELECT 
    'Active Processes' as check_type,
    pid,
    state,
    application_name,
    query_start,
    left(query, 100) as query_preview
FROM pg_stat_activity 
WHERE state != 'idle' 
  AND datname = current_database()
ORDER BY query_start;

-- PASSO 6: Verificar estrutura da tabela app_users
SELECT 
    'App Users Structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'app_users'
ORDER BY ordinal_position;

-- PASSO 7: Teste de inserção manual
DO $$
DECLARE
    test_id uuid := gen_random_uuid();
    test_email text := 'test_' || extract(epoch from now()) || '@example.com';
BEGIN
    -- Tentar inserir um usuário de teste
    INSERT INTO app_users (
        id, 
        email, 
        full_name, 
        phone, 
        user_type, 
        status
    ) VALUES (
        test_id,
        test_email,
        'Usuário Teste',
        '+5511999999999',
        'passenger',
        'active'
    );
    
    RAISE NOTICE 'SUCCESS: Test user inserted successfully';
    
    -- Verificar se foi inserido
    IF EXISTS (SELECT 1 FROM app_users WHERE id = test_id) THEN
        RAISE NOTICE 'SUCCESS: Test user found in database';
    ELSE
        RAISE NOTICE 'ERROR: Test user not found after insert';
    END IF;
    
    -- Limpar
    DELETE FROM app_users WHERE id = test_id;
    RAISE NOTICE 'SUCCESS: Test user cleaned up';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR during test: %', SQLERRM;
    
    -- Tentar limpar mesmo com erro
    BEGIN
        DELETE FROM app_users WHERE email = test_email;
    EXCEPTION WHEN OTHERS THEN
        -- Ignorar erro de limpeza
    END;
END $$;

-- PASSO 8: Verificar extensões importantes
SELECT 
    'Extensions' as check_type,
    extname,
    extversion
FROM pg_extension 
WHERE extname IN ('pgcrypto', 'uuid-ossp')
ORDER BY extname;

-- PASSO 9: Status final
SELECT 
    'Final Status' as check_type,
    json_build_object(
        'timestamp', now(),
        'rls_tables_count', (
            SELECT COUNT(*) 
            FROM pg_tables 
            WHERE schemaname = 'public' AND rowsecurity = true
        ),
        'total_policies', (
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE schemaname = 'public'
        ),
        'app_users_accessible', (
            SELECT COUNT(*) >= 0
            FROM app_users 
            LIMIT 1
        ),
        'ready_for_auth', CASE 
            WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) = 0 
            THEN 'YES' 
            ELSE 'NO - RLS still active'
        END
    ) as status;