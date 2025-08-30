-- Desabilitar RLS em todas as tabelas principais
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS drivers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS passengers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS trips DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS trip_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS saved_places DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS payment_methods DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS favorite_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS emergency_contacts DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_excluded_zones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS driver_operation_zones DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS passenger_wallets DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS passenger_wallet_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS passenger_promo_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS passenger_promo_code_usage DISABLE ROW LEVEL SECURITY;

-- Remover todas as políticas existentes
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname 
              FROM pg_policies 
              WHERE schemaname = 'public')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
        RAISE NOTICE 'Dropped policy % on table %', r.policyname, r.tablename;
    END LOOP;
END $$;

-- Verificar resultado
SELECT 'RLS Status' as info, 
       schemaname, 
       tablename, 
       rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true;

SELECT 'Policies Count' as info, COUNT(*) as remaining_policies
FROM pg_policies 
WHERE schemaname = 'public';