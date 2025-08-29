-- ===============================================
-- SCRIPT DE DEPURAÇÃO AVANÇADA DO SIGNUP
-- ===============================================
-- Execute este script no SQL Editor do Supabase para diagnosticar o problema

-- PASSO 1: Verificar logs de erro recentes do PostgreSQL
SELECT 
    'PostgreSQL Error Logs' as check_type,
    message,
    detail,
    hint,
    context,
    query,
    query_pos,
    location,
    application_name,
    timestamp
FROM pg_stat_statements_info
WHERE lower(query) LIKE '%signup%' 
   OR lower(query) LIKE '%auth%'
   OR lower(query) LIKE '%app_users%'
ORDER BY timestamp DESC 
LIMIT 10;

-- PASSO 2: Verificar processos ativos problemáticos
SELECT 
    'Active Processes' as check_type,
    pid,
    state,
    query,
    query_start,
    state_change,
    waiting,
    backend_type,
    application_name
FROM pg_stat_activity 
WHERE state != 'idle' 
   AND (query LIKE '%auth%' OR query LIKE '%app_users%' OR query LIKE '%signup%')
ORDER BY query_start;

-- PASSO 3: Verificar configurações de autenticação do Supabase
SELECT 
    'Auth Config Check' as check_type,
    key,
    value,
    created_at,
    updated_at
FROM auth.config 
WHERE key IN (
    'SITE_URL',
    'URI_ALLOW_LIST', 
    'DISABLE_SIGNUP',
    'EXTERNAL_EMAIL_ENABLED',
    'MAILER_SECURE_EMAIL_CHANGE_ENABLED'
)
ORDER BY key;

-- PASSO 4: Verificar se há triggers falhando
SELECT 
    'Trigger Status' as check_type,
    schemaname,
    tablename,
    triggername,
    triggerdef
FROM pg_triggers 
WHERE schemaname IN ('auth', 'public') 
  AND tablename IN ('users', 'app_users', 'auth_sync_logs');

-- PASSO 5: Verificar constraints que podem estar falhando
SELECT 
    'Constraint Violations' as check_type,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    tc.constraint_type,
    rc.match_option,
    rc.update_rule,
    rc.delete_rule,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON rc.unique_constraint_name = ccu.constraint_name
    AND rc.unique_constraint_schema = ccu.constraint_schema
WHERE tc.table_name IN ('app_users', 'users') 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type;

-- PASSO 6: Testar criação manual de usuário
DO $$ 
DECLARE
    test_user_id uuid;
    test_email text := 'test_debug_' || extract(epoch from now()) || '@example.com';
    error_msg text;
BEGIN
    -- Tentar criar um usuário de teste
    BEGIN
        -- Simular o que o auth.users faria
        test_user_id := gen_random_uuid();
        
        -- Tentar inserir diretamente no app_users
        INSERT INTO app_users (
            id,
            email,
            full_name,
            phone,
            user_type,
            status
        ) VALUES (
            test_user_id,
            test_email,
            'Teste Depuração',
            '+5511999999999',
            'passenger',
            'active'
        );
        
        RAISE NOTICE 'SUCCESS: Test user created with ID: %', test_user_id;
        
        -- Limpar o usuário de teste
        DELETE FROM app_users WHERE id = test_user_id;
        RAISE NOTICE 'Test user cleaned up successfully';
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        RAISE NOTICE 'ERROR during test user creation: %', error_msg;
        
        -- Tentar limpar mesmo em caso de erro
        BEGIN
            DELETE FROM app_users WHERE email = test_email;
        EXCEPTION WHEN OTHERS THEN
            -- Ignorar erros de limpeza
        END;
    END;
END $$;

-- PASSO 7: Verificar permissões da role anon
SELECT 
    'Anonymous Permissions' as check_type,
    schemaname,
    tablename,
    grantor,
    grantee,
    privilege_type,
    is_grantable,
    with_hierarchy
FROM information_schema.table_privileges 
WHERE grantee = 'anon' 
  AND tablename IN ('app_users', 'users')
ORDER BY tablename, privilege_type;

-- PASSO 8: Verificar RLS policies detalhadamente
SELECT 
    'RLS Policies Detail' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('app_users', 'auth_sync_logs', 'sync_control')
ORDER BY tablename, policyname;

-- PASSO 9: Função para testar signup completo
CREATE OR REPLACE FUNCTION test_signup_flow(
    p_email text DEFAULT 'debug_test@example.com',
    p_password text DEFAULT 'test123456',
    p_full_name text DEFAULT 'Debug User',
    p_phone text DEFAULT '+5511999888777'
)
RETURNS json AS $$
DECLARE
    result json;
    test_user_id uuid;
    step_info text;
BEGIN
    step_info := 'Starting signup flow test';
    
    -- Step 1: Generate user ID
    test_user_id := gen_random_uuid();
    step_info := 'Generated user ID: ' || test_user_id;
    
    -- Step 2: Try to create app_users record
    BEGIN
        INSERT INTO app_users (
            id, email, full_name, phone, user_type, status
        ) VALUES (
            test_user_id, p_email, p_full_name, p_phone, 'passenger', 'active'
        );
        step_info := step_info || ' | app_users created successfully';
    EXCEPTION WHEN OTHERS THEN
        step_info := step_info || ' | ERROR in app_users: ' || SQLERRM;
        
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'step', 'app_users_insert',
            'details', step_info
        );
    END;
    
    -- Cleanup
    DELETE FROM app_users WHERE id = test_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Signup flow test completed successfully',
        'details', step_info,
        'user_id_tested', test_user_id
    );
    
EXCEPTION WHEN OTHERS THEN
    -- Emergency cleanup
    BEGIN
        DELETE FROM app_users WHERE email = p_email OR id = test_user_id;
    EXCEPTION WHEN OTHERS THEN
        -- Ignore cleanup errors
    END;
    
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'step', 'general_error',
        'details', step_info
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 10: Executar teste completo
SELECT test_signup_flow();

-- PASSO 11: Verificar configuração do auth schema
SELECT 
    'Auth Schema Info' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users'
ORDER BY table_name, ordinal_position;