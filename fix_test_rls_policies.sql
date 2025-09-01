-- Script para corrigir políticas RLS que estão bloqueando os testes
-- Baseado na análise dos erros "permission denied for table app_users"

-- 1. Configurar políticas RLS para app_users
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- Política para permitir inserção durante testes e signup
DROP POLICY IF EXISTS "Allow test and signup operations" ON app_users;
CREATE POLICY "Allow test and signup operations" ON app_users
    FOR INSERT WITH CHECK (
        -- Permite inserção se:
        -- 1. O usuário está autenticado e o ID corresponde
        auth.uid() = id OR 
        -- 2. É uma operação de service role (testes)
        auth.role() = 'service_role' OR
        -- 3. É uma operação anônima durante signup
        auth.role() = 'anon'
    );

-- Política para permitir leitura
DROP POLICY IF EXISTS "Allow read own data" ON app_users;
CREATE POLICY "Allow read own data" ON app_users
    FOR SELECT USING (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

-- Política para permitir atualização
DROP POLICY IF EXISTS "Allow update own data" ON app_users;
CREATE POLICY "Allow update own data" ON app_users
    FOR UPDATE USING (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

-- 2. Configurar políticas RLS para passengers
ALTER TABLE passengers ENABLE ROW LEVEL SECURITY;

-- Política para permitir inserção
DROP POLICY IF EXISTS "Allow passenger operations" ON passengers;
CREATE POLICY "Allow passenger operations" ON passengers
    FOR ALL USING (
        -- Permite se o user_id corresponde ao usuário autenticado
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE app_users.id = passengers.user_id 
            AND (app_users.id = auth.uid() OR auth.role() = 'service_role')
        ) OR
        -- Ou se é service role (testes)
        auth.role() = 'service_role'
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE app_users.id = passengers.user_id 
            AND (app_users.id = auth.uid() OR auth.role() = 'service_role')
        ) OR
        auth.role() = 'service_role'
    );

-- 3. Configurar políticas RLS para drivers
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Política para permitir operações de driver
DROP POLICY IF EXISTS "Allow driver operations" ON drivers;
CREATE POLICY "Allow driver operations" ON drivers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE app_users.id = drivers.user_id 
            AND (app_users.id = auth.uid() OR auth.role() = 'service_role')
        ) OR
        auth.role() = 'service_role'
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM app_users 
            WHERE app_users.id = drivers.user_id 
            AND (app_users.id = auth.uid() OR auth.role() = 'service_role')
        ) OR
        auth.role() = 'service_role'
    );

-- 4. Configurar políticas RLS para trip_requests
ALTER TABLE trip_requests ENABLE ROW LEVEL SECURITY;

-- Política para trip_requests
DROP POLICY IF EXISTS "Allow trip request operations" ON trip_requests;
CREATE POLICY "Allow trip request operations" ON trip_requests
    FOR ALL USING (
        -- Permite se é o passageiro que criou a solicitação
        EXISTS (
            SELECT 1 FROM passengers p
            JOIN app_users au ON au.id = p.user_id
            WHERE p.id = trip_requests.passenger_id 
            AND (au.id = auth.uid() OR auth.role() = 'service_role')
        ) OR
        -- Ou se é service role (testes)
        auth.role() = 'service_role'
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM passengers p
            JOIN app_users au ON au.id = p.user_id
            WHERE p.id = trip_requests.passenger_id 
            AND (au.id = auth.uid() OR auth.role() = 'service_role')
        ) OR
        auth.role() = 'service_role'
    );

-- 5. Configurar políticas RLS para trips
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

-- Política para trips
DROP POLICY IF EXISTS "Allow trip operations" ON trips;
CREATE POLICY "Allow trip operations" ON trips
    FOR ALL USING (
        -- Permite se é o passageiro ou motorista da viagem
        EXISTS (
            SELECT 1 FROM passengers p
            JOIN app_users au ON au.id = p.user_id
            WHERE p.id = trips.passenger_id 
            AND au.id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM drivers d
            JOIN app_users au ON au.id = d.user_id
            WHERE d.id = trips.driver_id 
            AND au.id = auth.uid()
        ) OR
        -- Ou se é service role (testes)
        auth.role() = 'service_role'
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM passengers p
            JOIN app_users au ON au.id = p.user_id
            WHERE p.id = trips.passenger_id 
            AND au.id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM drivers d
            JOIN app_users au ON au.id = d.user_id
            WHERE d.id = trips.driver_id 
            AND au.id = auth.uid()
        ) OR
        auth.role() = 'service_role'
    );

-- 6. Configurar políticas RLS para driver_offers
ALTER TABLE driver_offers ENABLE ROW LEVEL SECURITY;

-- Política para driver_offers
DROP POLICY IF EXISTS "Allow driver offer operations" ON driver_offers;
CREATE POLICY "Allow driver offer operations" ON driver_offers
    FOR ALL USING (
        -- Permite se é o motorista que fez a oferta
        EXISTS (
            SELECT 1 FROM drivers d
            JOIN app_users au ON au.id = d.user_id
            WHERE d.id = driver_offers.driver_id 
            AND au.id = auth.uid()
        ) OR
        -- Ou se é o passageiro da solicitação
        EXISTS (
            SELECT 1 FROM trip_requests tr
            JOIN passengers p ON p.id = tr.passenger_id
            JOIN app_users au ON au.id = p.user_id
            WHERE tr.id = driver_offers.trip_request_id 
            AND au.id = auth.uid()
        ) OR
        -- Ou se é service role (testes)
        auth.role() = 'service_role'
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM drivers d
            JOIN app_users au ON au.id = d.user_id
            WHERE d.id = driver_offers.driver_id 
            AND au.id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM trip_requests tr
            JOIN passengers p ON p.id = tr.passenger_id
            JOIN app_users au ON au.id = p.user_id
            WHERE tr.id = driver_offers.trip_request_id 
            AND au.id = auth.uid()
        ) OR
        auth.role() = 'service_role'
    );

-- 7. Configurar políticas para tabelas de log e sincronização
ALTER TABLE auth_sync_logs ENABLE ROW LEVEL SECURITY;

-- Política permissiva para logs (necessário para triggers)
DROP POLICY IF EXISTS "Allow system sync operations" ON auth_sync_logs;
CREATE POLICY "Allow system sync operations" ON auth_sync_logs
    FOR ALL USING (true)
    WITH CHECK (true);

-- Verificar se sync_control existe e configurar
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sync_control') THEN
        ALTER TABLE sync_control ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "Allow system sync control" ON sync_control;
        CREATE POLICY "Allow system sync control" ON sync_control
            FOR ALL USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- 8. Função para diagnóstico das políticas
CREATE OR REPLACE FUNCTION diagnose_rls_policies()
RETURNS TABLE(
    table_name text,
    rls_enabled boolean,
    policy_count bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::text,
        t.rowsecurity,
        COUNT(p.policyname)
    FROM pg_tables t
    LEFT JOIN pg_policies p ON p.tablename = t.tablename
    WHERE t.schemaname = 'public'
    AND t.tablename IN ('app_users', 'passengers', 'drivers', 'trip_requests', 'trips', 'driver_offers', 'auth_sync_logs', 'sync_control')
    GROUP BY t.tablename, t.rowsecurity
    ORDER BY t.tablename;
END;
$$ LANGUAGE plpgsql;

-- Executar diagnóstico
SELECT * FROM diagnose_rls_policies();

SELECT 'RLS policies configured successfully for testing' as status;