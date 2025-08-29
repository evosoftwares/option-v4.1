-- ===============================================
-- SCRIPT PARA DESABILITAR COMPLETAMENTE RLS
-- ===============================================
-- Este script remove todas as políticas RLS e triggers problemáticos
-- Execute no SQL Editor do Supabase

-- PASSO 1: Desabilitar RLS em todas as tabelas
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS auth_sync_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS sync_control DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS drivers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS passengers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_excluded_zones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_operation_zones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS trips DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS trip_requests DISABLE ROW LEVEL SECURITY;

-- PASSO 2: Remover todas as políticas existentes
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Loop através de todas as políticas no schema public
    FOR r IN (SELECT schemaname, tablename, policyname 
              FROM pg_policies 
              WHERE schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
        RAISE NOTICE 'Dropped policy % on table %', r.policyname, r.tablename;
    END LOOP;
END $$;

-- PASSO 3: Remover triggers problemáticos
DROP TRIGGER IF EXISTS auth_user_sync_trigger ON auth.users;
DROP TRIGGER IF EXISTS app_user_sync_trigger ON app_users;
DROP TRIGGER IF EXISTS sync_control_trigger ON sync_control;

-- PASSO 4: Remover funções de sincronização problemáticas
DROP FUNCTION IF EXISTS sync_auth_to_app_users() CASCADE;
DROP FUNCTION IF EXISTS sync_app_to_auth_users() CASCADE;
DROP FUNCTION IF EXISTS handle_auth_user_changes() CASCADE;
DROP FUNCTION IF EXISTS handle_app_user_changes() CASCADE;

-- PASSO 5: Limpar tabelas de controle
DROP TABLE IF EXISTS auth_sync_logs CASCADE;
DROP TABLE IF EXISTS sync_control CASCADE;

-- PASSO 6: Garantir permissões básicas para auth
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon;

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- PASSO 7: Limpar qualquer configuração de auth problemática
DELETE FROM auth.config WHERE key LIKE '%SIGNUP%' OR key LIKE '%DISABLE%';

-- PASSO 8: Resetar configurações de auth para padrão
INSERT INTO auth.config (key, value) VALUES 
('DISABLE_SIGNUP', 'false'),
('SITE_URL', 'http://localhost:3000'),
('EXTERNAL_EMAIL_ENABLED', 'true')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- PASSO 9: Verificar se não há processos presos
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state IN ('idle in transaction', 'active')
  AND query_start < NOW() - INTERVAL '2 minutes'
  AND application_name LIKE '%supabase%';

-- PASSO 10: Função de diagnóstico simples
CREATE OR REPLACE FUNCTION simple_auth_check()
RETURNS json AS $$
BEGIN
    RETURN json_build_object(
        'timestamp', NOW(),
        'rls_disabled', (
            SELECT COUNT(*) = 0 
            FROM pg_tables 
            WHERE schemaname = 'public' 
            AND rowsecurity = true
        ),
        'policies_count', (
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE schemaname = 'public'
        ),
        'app_users_accessible', (
            SELECT COUNT(*) 
            FROM app_users 
            LIMIT 1
        ) IS NOT NULL,
        'auth_config', (
            SELECT json_object_agg(key, value)
            FROM auth.config
            WHERE key IN ('DISABLE_SIGNUP', 'SITE_URL', 'EXTERNAL_EMAIL_ENABLED')
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 11: Executar diagnóstico
SELECT simple_auth_check();

-- PASSO 12: Teste básico de inserção
DO $$
DECLARE
    test_id uuid := gen_random_uuid();
BEGIN
    -- Testar se conseguimos inserir em app_users sem problemas
    INSERT INTO app_users (id, email, full_name, phone, user_type, status)
    VALUES (test_id, 'test@example.com', 'Test User', '+1234567890', 'passenger', 'active');
    
    -- Limpar teste
    DELETE FROM app_users WHERE id = test_id;
    
    RAISE NOTICE 'SUCCESS: app_users table is accessible and working';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ERROR: %', SQLERRM;
END $$;

RAISE NOTICE '=== RLS COMPLETELY DISABLED ===';
RAISE NOTICE 'Auth should now work with native Supabase auth only';
RAISE NOTICE 'Test signup in your app now!';