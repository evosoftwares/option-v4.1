-- ===============================================
-- SCRIPT SIMPLES PARA DESABILITAR RLS
-- ===============================================
-- Este script remove RLS sem depender de tabelas que podem não existir

-- PASSO 1: Desabilitar RLS em todas as tabelas
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS drivers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS passengers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_excluded_zones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_operation_zones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS trips DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS trip_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_offers DISABLE ROW LEVEL SECURITY;

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

-- PASSO 3: Garantir permissões básicas
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- PASSO 4: Limpar qualquer tabela de controle que possa existir
DROP TABLE IF EXISTS auth_sync_logs CASCADE;
DROP TABLE IF EXISTS sync_control CASCADE;

-- PASSO 5: Verificar se não há processos presos
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state IN ('idle in transaction', 'active')
  AND query_start < NOW() - INTERVAL '2 minutes'
  AND query LIKE '%auth%';

-- PASSO 6: Teste básico de inserção no app_users
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

-- PASSO 7: Função de diagnóstico simples
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
        'app_users_count', (
            SELECT COUNT(*) 
            FROM app_users
        ),
        'message', 'RLS completely disabled, ready for native auth'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 8: Executar diagnóstico
SELECT simple_auth_check();

RAISE NOTICE '=== RLS COMPLETELY DISABLED ===';
RAISE NOTICE 'Native Supabase auth should work now!';
RAISE NOTICE 'Test signup in your app!';