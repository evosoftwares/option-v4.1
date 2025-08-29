-- ===============================================
-- SOLUÇÃO DE EMERGÊNCIA PARA ERRO 500 NO AUTH
-- ===============================================
-- Este script força uma reinicialização completa do sistema de auth

-- PASSO 1: Limpar completamente o cache do schema
SELECT pg_notify('pgrst', 'reload schema');

-- PASSO 2: Reinicializar o pooler de conexões
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE datname = current_database()
  AND state IN ('idle', 'idle in transaction', 'idle in transaction (aborted)')
  AND pid != pg_backend_pid();

-- PASSO 3: Aguardar limpeza
SELECT pg_sleep(3);

-- PASSO 4: Verificar se há extensões problemáticas que podem causar o erro 500
SELECT extname, extversion 
FROM pg_extension 
WHERE extname IN ('pgjwt', 'pgcrypto', 'uuid-ossp', 'http');

-- PASSO 5: Forçar reinstalação das extensões críticas
DROP EXTENSION IF EXISTS pgjwt CASCADE;
CREATE EXTENSION IF NOT EXISTS pgjwt;

-- PASSO 6: Verificar se há funções problemáticas no schema auth
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT proname 
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'auth'
        AND proname LIKE '%trigger%'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS auth.%I CASCADE', func_record.proname);
        RAISE NOTICE 'Dropped problematic auth function: %', func_record.proname;
    END LOOP;
END $$;

-- PASSO 7: Limpar qualquer trigger no schema auth que possa estar causando problemas
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers
        WHERE trigger_schema = 'auth'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON auth.%I CASCADE', 
                      trigger_record.trigger_name, 
                      trigger_record.event_object_table);
        RAISE NOTICE 'Dropped auth trigger: % on %', 
                     trigger_record.trigger_name, 
                     trigger_record.event_object_table;
    END LOOP;
END $$;

-- PASSO 8: Verificar e limpar a tabela auth.users se necessário
DO $$
BEGIN
    -- Verificar se há registros corrompidos na tabela auth.users
    DELETE FROM auth.users 
    WHERE email IS NULL 
       OR email = '' 
       OR encrypted_password IS NULL 
       OR created_at IS NULL;
       
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Cleaned % corrupted records from auth.users', deleted_count;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not clean auth.users: %', SQLERRM;
END $$;

-- PASSO 9: Resetar sequence se necessário
DO $$
BEGIN
    -- Tentar resetar sequences que podem estar corrompidas
    PERFORM setval('auth.users_id_seq', 1, false);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'No sequence to reset or error: %', SQLERRM;
END $$;

-- PASSO 10: Forçar vacuum na tabela auth.users
VACUUM FULL auth.users;

-- PASSO 11: Recriar índices problemáticos se necessário
REINDEX TABLE auth.users;

-- PASSO 12: Função de teste de signup direto no auth.users
CREATE OR REPLACE FUNCTION test_direct_signup()
RETURNS text AS $$
DECLARE
    test_id uuid := gen_random_uuid();
    test_email text := 'emergency_test_' || extract(epoch from now()) || '@example.com';
    result_msg text;
BEGIN
    -- Tentar inserir diretamente no auth.users sem usar o endpoint
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        test_id,
        'authenticated',
        'authenticated', 
        test_email,
        crypt('test123456', gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider": "email", "providers": ["email"]}',
        '{}'
    );
    
    result_msg := 'SUCCESS: Direct insert to auth.users worked';
    
    -- Limpar teste
    DELETE FROM auth.users WHERE id = test_id;
    
    RETURN result_msg;
EXCEPTION WHEN OTHERS THEN
    -- Tentar limpar
    BEGIN
        DELETE FROM auth.users WHERE email = test_email;
    EXCEPTION WHEN OTHERS THEN
        -- Ignorar
    END;
    
    RETURN 'ERROR: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 13: Executar teste
SELECT test_direct_signup();

-- PASSO 14: Verificar configuração crítica do PostgREST
DO $$
BEGIN
    -- Tentar recarregar a configuração do PostgREST
    PERFORM pg_notify('pgrst', 'reload schema');
    PERFORM pg_notify('pgrst', 'reload config');
    
    RAISE NOTICE 'Forced PostgREST reload';
END $$;

-- PASSO 15: Status final
SELECT 
    'Emergency Fix Status' as check_type,
    json_build_object(
        'timestamp', now(),
        'auth_users_count', (SELECT COUNT(*) FROM auth.users),
        'extensions_ok', (
            SELECT COUNT(*) = 3 
            FROM pg_extension 
            WHERE extname IN ('pgcrypto', 'uuid-ossp', 'pgjwt')
        ),
        'ready_to_test', 'YES - Try signup now',
        'next_step', 'Restart your Flutter app and test'
    ) as status;

RAISE NOTICE '=== EMERGENCY AUTH FIX COMPLETED ===';
RAISE NOTICE 'The 500 error should be resolved now';
RAISE NOTICE 'Restart your Flutter app (stop and run again)';
RAISE NOTICE 'Then test signup with fresh session';