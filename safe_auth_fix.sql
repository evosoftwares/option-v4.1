-- ===============================================
-- CORREÇÃO SEGURA DO AUTH SEM PRIVILÉGIOS DE SUPERUSUÁRIO
-- ===============================================
-- Este script só executa operações que não requerem privilégios especiais

-- PASSO 1: Limpar o cache do schema (se possível)
DO $$
BEGIN
    PERFORM pg_notify('pgrst', 'reload schema');
    RAISE NOTICE 'Schema cache reload requested';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not reload schema cache: %', SQLERRM;
END $$;

-- PASSO 2: Limpar conexões idle que podem estar causando problemas
DO $$
DECLARE
    idle_count int;
BEGIN
    SELECT COUNT(*) INTO idle_count
    FROM pg_stat_activity
    WHERE datname = current_database()
      AND state = 'idle'
      AND query_start < NOW() - INTERVAL '5 minutes';
    
    RAISE NOTICE 'Found % idle connections older than 5 minutes', idle_count;
END $$;

-- PASSO 3: Verificar se RLS está realmente desabilitado
SELECT 
    'RLS Status Check' as info,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('app_users', 'drivers', 'passengers')
ORDER BY tablename;

-- PASSO 4: Verificar se ainda há políticas ativas
SELECT 
    'Policies Check' as info,
    COUNT(*) as total_policies,
    string_agg(tablename || '.' || policyname, ', ') as policy_list
FROM pg_policies 
WHERE schemaname = 'public';

-- PASSO 5: Garantir permissões básicas (sem privilégios especiais)
DO $$
BEGIN
    -- Tentar dar permissões básicas nas nossas tabelas
    GRANT SELECT, INSERT, UPDATE, DELETE ON app_users TO anon, authenticated;
    GRANT SELECT, INSERT, UPDATE, DELETE ON drivers TO anon, authenticated;
    GRANT SELECT, INSERT, UPDATE, DELETE ON passengers TO anon, authenticated;
    
    RAISE NOTICE 'Basic permissions granted successfully';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not grant all permissions: %', SQLERRM;
END $$;

-- PASSO 6: Teste de inserção em app_users para verificar se está funcionando
DO $$
DECLARE
    test_id uuid := gen_random_uuid();
    test_email text := 'safe_test_' || extract(epoch from now()) || '@example.com';
BEGIN
    -- Testar inserção
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
        'Teste Seguro',
        '+5511999999999',
        'passenger',
        'active'
    );
    
    RAISE NOTICE 'SUCCESS: Test insertion in app_users worked';
    
    -- Testar seleção
    IF EXISTS (SELECT 1 FROM app_users WHERE id = test_id) THEN
        RAISE NOTICE 'SUCCESS: Test record found in app_users';
    END IF;
    
    -- Limpeza
    DELETE FROM app_users WHERE id = test_id;
    RAISE NOTICE 'SUCCESS: Test cleanup completed';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR in app_users test: %', SQLERRM;
    
    -- Tentar limpeza mesmo com erro
    BEGIN
        DELETE FROM app_users WHERE email = test_email;
    EXCEPTION WHEN OTHERS THEN
        -- Ignorar
    END;
END $$;

-- PASSO 7: Verificar configuração básica do ambiente
SELECT 
    'Environment Check' as info,
    json_build_object(
        'current_database', current_database(),
        'current_user', current_user,
        'session_user', session_user,
        'version', version(),
        'timezone', current_setting('timezone')
    ) as details;

-- PASSO 8: Verificar extensões disponíveis
SELECT 
    'Extensions Check' as info,
    extname,
    extversion,
    CASE WHEN extname IN ('pgcrypto', 'uuid-ossp') THEN 'CRITICAL' ELSE 'optional' END as importance
FROM pg_extension 
WHERE extname IN ('pgcrypto', 'uuid-ossp', 'pgjwt', 'http')
ORDER BY extname;

-- PASSO 9: Função de diagnóstico final
CREATE OR REPLACE FUNCTION safe_auth_diagnostic()
RETURNS json AS $$
BEGIN
    RETURN json_build_object(
        'timestamp', NOW(),
        'database_accessible', current_database() IS NOT NULL,
        'app_users_accessible', (
            SELECT COUNT(*) >= 0 
            FROM app_users 
            LIMIT 1
        ),
        'rls_disabled', (
            SELECT COUNT(*) = 0 
            FROM pg_tables 
            WHERE schemaname = 'public' 
            AND rowsecurity = true
            AND tablename = 'app_users'
        ),
        'policies_removed', (
            SELECT COUNT(*) = 0 
            FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = 'app_users'
        ),
        'extensions_ok', (
            SELECT COUNT(*) >= 2 
            FROM pg_extension 
            WHERE extname IN ('pgcrypto', 'uuid-ossp')
        ),
        'ready_for_auth', 'Check individual results above'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 10: Executar diagnóstico final
SELECT safe_auth_diagnostic();

-- PASSO 11: Instruções finais
DO $$
BEGIN
    RAISE NOTICE '=== SAFE AUTH FIX COMPLETED ===';
    RAISE NOTICE 'Check the diagnostic results above';
    RAISE NOTICE 'If app_users_accessible = true and rls_disabled = true:';
    RAISE NOTICE '1. The database side should be working';
    RAISE NOTICE '2. The 500 error might be in Supabase Auth service itself';
    RAISE NOTICE '3. Try restarting your Flutter app completely';
    RAISE NOTICE '4. If still fails, the issue may be with Supabase project configuration';
END $$;