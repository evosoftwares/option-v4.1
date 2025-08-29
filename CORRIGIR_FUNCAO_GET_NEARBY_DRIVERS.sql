-- Script para corrigir a função get_nearby_drivers que está causando o erro "drivers.name does not exist"
-- Execute este script no painel SQL do Supabase

-- 1. Primeiro, vamos ver se a função existe e drop ela
DROP FUNCTION IF EXISTS get_nearby_drivers(lat double precision, lng double precision, radius_km double precision);

-- 2. Criar a função corrigida usando JOIN com app_users para obter o nome
CREATE OR REPLACE FUNCTION get_nearby_drivers(
    lat double precision, 
    lng double precision, 
    radius_km double precision DEFAULT 5.0
)
RETURNS TABLE(
    driver_id uuid,
    user_id uuid,
    driver_name text,
    fcm_token text,
    device_platform text,
    is_online boolean,
    current_latitude numeric,
    current_longitude numeric,
    vehicle_category text,
    distance_km double precision
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        au.full_name as driver_name,
        d.fcm_token,
        d.device_platform,
        d.is_online,
        d.current_latitude,
        d.current_longitude,
        d.vehicle_category,
        -- Calcular distância usando fórmula haversine aproximada
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude::double precision)) * 
                cos(radians(d.current_longitude::double precision) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude::double precision))
            )
        ) as distance_km
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id
    WHERE 
        d.is_online = true
        AND d.approval_status = 'approved'
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND au.status = 'active'
        -- Filtro de bounding box para performance (aproximado)
        AND d.current_latitude BETWEEN (lat - radius_km / 111.0) AND (lat + radius_km / 111.0)
        AND d.current_longitude BETWEEN (lng - radius_km / (111.0 * cos(radians(lat)))) AND (lng + radius_km / (111.0 * cos(radians(lat))))
    ORDER BY distance_km ASC
    LIMIT 50;
END;
$$;

-- 3. Dar permissões necessárias
GRANT EXECUTE ON FUNCTION get_nearby_drivers(double precision, double precision, double precision) TO authenticated;
GRANT EXECUTE ON FUNCTION get_nearby_drivers(double precision, double precision, double precision) TO anon;

-- 4. Comentário da função
COMMENT ON FUNCTION get_nearby_drivers IS 'Retorna motoristas próximos dentro de um raio específico, incluindo nome completo via JOIN com app_users';

-- 5. Teste da função (opcional - descomente para testar)
-- SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 10.0) LIMIT 5;

-- 6. Se existir uma versão similar para emergency_service, vamos corrigir também
DROP FUNCTION IF EXISTS get_emergency_nearby_drivers(lat double precision, lng double precision, radius_km double precision);

CREATE OR REPLACE FUNCTION get_emergency_nearby_drivers(
    lat double precision, 
    lng double precision, 
    radius_km double precision DEFAULT 2.0
)
RETURNS TABLE(
    driver_id uuid,
    user_id uuid,
    driver_name text,
    phone text,
    fcm_token text,
    current_latitude numeric,
    current_longitude numeric,
    distance_km double precision
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id as driver_id,
        d.user_id,
        au.full_name as driver_name,
        au.phone,
        d.fcm_token,
        d.current_latitude,
        d.current_longitude,
        -- Calcular distância usando fórmula haversine aproximada
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude::double precision)) * 
                cos(radians(d.current_longitude::double precision) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude::double precision))
            )
        ) as distance_km
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id
    WHERE 
        d.is_online = true
        AND d.approval_status = 'approved'
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        AND au.status = 'active'
        -- Raio menor para emergências
        AND (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude::double precision)) * 
                cos(radians(d.current_longitude::double precision) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude::double precision))
            )
        ) <= radius_km
    ORDER BY distance_km ASC
    LIMIT 10;
END;
$$;

GRANT EXECUTE ON FUNCTION get_emergency_nearby_drivers(double precision, double precision, double precision) TO authenticated;