-- ===============================================
-- SCRIPT PARA DIAGNOSTICAR ERRO 500 NO AUTH
-- ===============================================
-- Execute no SQL Editor para identificar a causa do erro 500

-- PASSO 1: Verificar configuração do auth
SELECT 
    'Auth Configuration' as check_type,
    key,
    value,
    created_at,
    updated_at
FROM auth.config
ORDER BY key;

-- PASSO 2: Verificar se há triggers no auth.users
SELECT 
    'Auth Users Triggers' as check_type,
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'auth' 
  AND event_object_table = 'users';

-- PASSO 3: Verificar permissões do schema auth
SELECT 
    'Auth Schema Permissions' as check_type,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.schema_privileges
WHERE schema_name = 'auth';

-- PASSO 4: Verificar logs de erro recentes
SELECT 
    'Recent Error Logs' as check_type,
    extract(epoch from now() - created_at) as seconds_ago,
    level,
    msg,
    metadata
FROM auth.audit_log_entries
WHERE level = 'ERROR'
ORDER BY created_at DESC
LIMIT 10;

-- PASSO 5: Verificar se há bloqueios de sessão
SELECT 
    'Active Sessions' as check_type,
    pid,
    state,
    query,
    query_start,
    application_name
FROM pg_stat_activity
WHERE datname = current_database()
  AND state != 'idle'
  AND application_name LIKE '%supabase%'
ORDER BY query_start;

-- PASSO 6: Testar função de signup manualmente
DO $$
DECLARE
    test_email text := 'test_' || extract(epoch from now()) || '@example.com';
    result_msg text;
BEGIN
    -- Simular o que o endpoint /auth/v1/signup faz
    BEGIN
        -- Tentar inserir um usuário de teste no auth.users
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            confirmation_sent_at,
            confirmation_token,
            recovery_token,
            email_change_token_new,
            email_change,
            created_at,
            updated_at,
            raw_app_meta_data,
            raw_user_meta_data
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            test_email,
            crypt('test123456', gen_salt('bf')),
            now(),
            now(),
            '',
            '',
            '',
            '',
            now(),
            now(),
            '{"provider": "email", "providers": ["email"]}',
            '{}'
        );
        
        result_msg := 'SUCCESS: Test user created in auth.users';
        
        -- Limpar o usuário de teste
        DELETE FROM auth.users WHERE email = test_email;
        
    EXCEPTION WHEN OTHERS THEN
        result_msg := 'ERROR: ' || SQLERRM;
        
        -- Tentar limpar mesmo com erro
        BEGIN
            DELETE FROM auth.users WHERE email = test_email;
        EXCEPTION WHEN OTHERS THEN
            -- Ignorar
        END;
    END;
    
    RAISE NOTICE '%', result_msg;
END $$;

-- PASSO 7: Verificar se função de hash de senha funciona
DO $$
BEGIN
    PERFORM crypt('test', gen_salt('bf'));
    RAISE NOTICE 'Password hashing works correctly';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR with password hashing: %', SQLERRM;
END $$;

-- PASSO 8: Verificar extensões necessárias
SELECT 
    'Extensions' as check_type,
    extname,
    extversion,
    extrelocatable
FROM pg_extension
WHERE extname IN ('pgcrypto', 'uuid-ossp', 'pgjwt');

-- PASSO 9: Verificar configuração JWT
SELECT 
    'JWT Settings' as check_type,
    name,
    setting,
    context
FROM pg_settings
WHERE name LIKE '%jwt%' OR name LIKE '%auth%';

-- PASSO 10: Verificar se há rate limiting ativo
SELECT 
    'Rate Limiting Check' as check_type,
    bucket,
    tokens,
    last_refill
FROM auth.flow_state
WHERE bucket = 'signup'
ORDER BY last_refill DESC
LIMIT 5;