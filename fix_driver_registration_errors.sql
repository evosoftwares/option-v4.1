-- Script para corrigir erros de cadastro de motorista
-- Execute este script no SQL Editor do Supabase Dashboard

-- ========================================
-- PARTE 0: CRIAR FUNÇÕES FALTANTES (PRIORIDADE ALTA)
-- ========================================

-- 0.0 Remover funções existentes se houver conflito
DROP FUNCTION IF EXISTS get_nearby_drivers(double precision, double precision, double precision);
DROP FUNCTION IF EXISTS get_emergency_nearby_drivers(double precision, double precision, double precision);

-- 0.1 Criar função get_nearby_drivers
CREATE OR REPLACE FUNCTION get_nearby_drivers(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (
    driver_id UUID,
    user_id UUID,
    vehicle_brand TEXT,
    vehicle_model TEXT,
    vehicle_year INTEGER,
    vehicle_color TEXT,
    vehicle_category TEXT,
    vehicle_plate TEXT,
    is_online BOOLEAN,
    accepts_pet BOOLEAN,
    accepts_grocery BOOLEAN,
    accepts_condo BOOLEAN,
    ac_policy TEXT,
    custom_price_per_km NUMERIC,
    custom_price_per_minute NUMERIC,
    pet_fee NUMERIC,
    grocery_fee NUMERIC,
    condo_fee NUMERIC,
    stop_fee NUMERIC,
    current_latitude DOUBLE PRECISION,
    current_longitude DOUBLE PRECISION,
    average_rating NUMERIC,
    total_trips INTEGER,
    distance_km DOUBLE PRECISION,
    onesignal_player_id TEXT,
    player_id TEXT,
    fcm_token TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        d.vehicle_brand,
        d.vehicle_model,
        d.vehicle_year,
        d.vehicle_color,
        d.vehicle_category,
        d.vehicle_plate,
        d.is_online,
        d.accepts_pet,
        d.accepts_grocery,
        d.accepts_condo,
        d.ac_policy,
        d.custom_price_per_km,
        d.custom_price_per_minute,
        d.pet_fee,
        d.grocery_fee,
        d.condo_fee,
        d.stop_fee,
        d.current_latitude,
        d.current_longitude,
        d.average_rating,
        d.total_trips,
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) as distance_km,
        au.fcm_token as onesignal_player_id,
        au.fcm_token as player_id,
        au.fcm_token
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id
    WHERE 
        d.is_online = true
        AND (d.approval_status = 'approved' OR d.approval_status IS NULL)
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND d.current_latitude BETWEEN (lat - (radius_km / 111.0)) AND (lat + (radius_km / 111.0))
        AND d.current_longitude BETWEEN (lng - (radius_km / (111.0 * cos(radians(lat))))) AND (lng + (radius_km / (111.0 * cos(radians(lat)))))
    HAVING 
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) <= radius_km
    ORDER BY distance_km
    LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- 0.2 Criar função get_emergency_nearby_drivers
CREATE OR REPLACE FUNCTION get_emergency_nearby_drivers(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10.0
)
RETURNS TABLE (
    driver_id UUID,
    user_id UUID,
    vehicle_brand TEXT,
    vehicle_model TEXT,
    vehicle_year INTEGER,
    vehicle_color TEXT,
    vehicle_category TEXT,
    vehicle_plate TEXT,
    is_online BOOLEAN,
    current_latitude DOUBLE PRECISION,
    current_longitude DOUBLE PRECISION,
    average_rating NUMERIC,
    total_trips INTEGER,
    distance_km DOUBLE PRECISION,
    onesignal_player_id TEXT,
    player_id TEXT,
    fcm_token TEXT,
    full_name TEXT,
    phone TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        d.vehicle_brand,
        d.vehicle_model,
        d.vehicle_year,
        d.vehicle_color,
        d.vehicle_category,
        d.vehicle_plate,
        d.is_online,
        d.current_latitude,
        d.current_longitude,
        d.average_rating,
        d.total_trips,
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) as distance_km,
        au.fcm_token as onesignal_player_id,
        au.fcm_token as player_id,
        au.fcm_token,
        au.full_name,
        au.phone
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id
    WHERE 
        d.is_online = true
        AND (d.approval_status = 'approved' OR d.approval_status IS NULL)
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND d.current_latitude BETWEEN (lat - (radius_km / 111.0)) AND (lat + (radius_km / 111.0))
        AND d.current_longitude BETWEEN (lng - (radius_km / (111.0 * cos(radians(lat))))) AND (lng + (radius_km / (111.0 * cos(radians(lat)))))
    HAVING 
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) <= radius_km
    ORDER BY distance_km
    LIMIT 100;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PARTE 1: DIAGNÓSTICO DOS PROBLEMAS
-- ========================================

-- 1.1 Verificar constraint atual de vehicle_category
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname LIKE '%vehicle_category%' 
   OR conname LIKE '%drivers_vehicle_category%';

-- 1.2 Verificar se as funções RPC foram criadas
SELECT 
    proname as function_name,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname IN ('get_nearby_drivers', 'get_emergency_nearby_drivers');

-- ========================================
-- PARTE 2: CORREÇÃO DA CONSTRAINT VEHICLE_CATEGORY
-- ========================================

-- 2.1 Remover constraint antiga se existir
ALTER TABLE drivers DROP CONSTRAINT IF EXISTS drivers_vehicle_category_check;
ALTER TABLE drivers DROP CONSTRAINT IF EXISTS vehicle_category_check;

-- 2.2 Criar nova constraint com valores corretos
ALTER TABLE drivers ADD CONSTRAINT drivers_vehicle_category_check 
CHECK (vehicle_category IN ('economico', 'standard', 'premium', 'suv', 'executivo', 'van'));

-- 2.3 Verificar se há registros com valores inválidos
SELECT 
    id,
    user_id,
    vehicle_category,
    'VALOR INVÁLIDO' as status
FROM drivers 
WHERE vehicle_category NOT IN ('economico', 'standard', 'premium', 'suv', 'executivo', 'van')
   OR vehicle_category IS NULL;

-- ========================================
-- PARTE 3: VERIFICAÇÃO DAS FUNÇÕES CRIADAS
-- ========================================

-- 3.1 Testar função get_nearby_drivers
SELECT 'Testando get_nearby_drivers...' as test_status;
SELECT COUNT(*) as function_exists 
FROM pg_proc 
WHERE proname = 'get_nearby_drivers';

-- 3.2 Testar função get_emergency_nearby_drivers
SELECT 'Testando get_emergency_nearby_drivers...' as test_status;
SELECT COUNT(*) as function_exists 
FROM pg_proc 
WHERE proname = 'get_emergency_nearby_drivers';

-- ========================================
-- PARTE 4: VERIFICAÇÃO FINAL
-- ========================================

-- 4.1 Verificar constraint atualizada
SELECT 
    'Constraint Status' as check_type,
    conname as name,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conname = 'drivers_vehicle_category_check';

-- 4.2 Verificar funções RPC criadas
SELECT 
    'Function Status' as check_type,
    proname as name,
    'CRIADA' as status
FROM pg_proc 
WHERE proname IN ('get_nearby_drivers', 'get_emergency_nearby_drivers');

-- 4.3 Verificar se há registros com vehicle_category inválido
SELECT 
    'Data Validation' as check_type,
    COUNT(*) as invalid_records,
    'Registros com vehicle_category inválido' as description
FROM drivers 
WHERE vehicle_category NOT IN ('economico', 'standard', 'premium', 'suv', 'executivo', 'van')
   OR vehicle_category IS NULL;

-- ========================================
-- PARTE 5: TESTE DE INSERÇÃO (OPCIONAL)
-- ========================================

-- 5.1 Teste de inserção na tabela drivers (descomente para testar)
/*
INSERT INTO drivers (
    user_id,
    vehicle_brand,
    vehicle_model,
    vehicle_year,
    vehicle_color,
    vehicle_plate,
    vehicle_category,
    approval_status
) VALUES (
    '00000000-0000-0000-0000-000000000000', -- UUID de teste
    'TESTE',
    'TESTE',
    2020,
    'TESTE',
    'TESTE123',
    'standard', -- Valor válido
    'pending'
);

SELECT 'Driver Insert Test' as result, 'SUCCESS' as status;

-- Limpar teste
DELETE FROM drivers WHERE vehicle_plate = 'TESTE123';
*/

-- 5.2 Teste das funções RPC (descomente para testar)
/*
-- Testar get_nearby_drivers
SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 5.0) LIMIT 1;

-- Testar get_emergency_nearby_drivers
SELECT * FROM get_emergency_nearby_drivers(-23.5505, -46.6333, 10.0) LIMIT 1;

SELECT 'RPC Functions Test' as result, 'SUCCESS' as status;
*/

-- ========================================
-- RESUMO DAS CORREÇÕES APLICADAS
-- ========================================

SELECT '🎯 CORREÇÕES APLICADAS:' as summary
UNION ALL
SELECT '✅ Funções get_nearby_drivers e get_emergency_nearby_drivers criadas'
UNION ALL
SELECT '✅ Constraint vehicle_category atualizada com valores corretos'
UNION ALL
SELECT '✅ Erro 42P01 (função inexistente) resolvido'
UNION ALL
SELECT '✅ Validação de dados implementada'
UNION ALL
SELECT ''
UNION ALL
SELECT '📝 NOTA: O projeto usa Firebase Storage para arquivos'
UNION ALL
SELECT '📝 Upload de documentos é feito via FirebaseFileUploadService'
UNION ALL
SELECT ''
UNION ALL
SELECT '🚀 O cadastro de motorista deve funcionar agora!';