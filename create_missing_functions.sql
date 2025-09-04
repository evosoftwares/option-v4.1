-- Script para criar as funções get_nearby_drivers e get_emergency_nearby_drivers
-- Estas funções estão sendo chamadas pelo código mas não existem no banco, causando erro 42P01

-- Função para buscar motoristas próximos
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
        -- Calcular distância usando fórmula de Haversine
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) as distance_km,
        au.fcm_token as onesignal_player_id, -- Compatibilidade com código antigo
        au.fcm_token as player_id, -- Compatibilidade com código antigo
        au.fcm_token
    FROM drivers d
    INNER JOIN app_users au ON d.user_id = au.id
    WHERE 
        d.is_online = true
        AND (d.approval_status = 'approved' OR d.approval_status IS NULL)
        AND d.current_latitude IS NOT NULL
        AND d.current_longitude IS NOT NULL
        -- Filtro de bounding box para performance
        AND d.current_latitude BETWEEN (lat - (radius_km / 111.0)) AND (lat + (radius_km / 111.0))
        AND d.current_longitude BETWEEN (lng - (radius_km / (111.0 * cos(radians(lat))))) AND (lng + (radius_km / (111.0 * cos(radians(lat)))))
    HAVING 
        -- Filtro de distância real usando Haversine
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

-- Função para buscar motoristas próximos em emergências
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
        -- Calcular distância usando fórmula de Haversine
        (
            6371 * acos(
                cos(radians(lat)) * 
                cos(radians(d.current_latitude)) * 
                cos(radians(d.current_longitude) - radians(lng)) + 
                sin(radians(lat)) * 
                sin(radians(d.current_latitude))
            )
        ) as distance_km,
        au.fcm_token as onesignal_player_id, -- Compatibilidade com código antigo
        au.fcm_token as player_id, -- Compatibilidade com código antigo
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
        -- Filtro de bounding box para performance
        AND d.current_latitude BETWEEN (lat - (radius_km / 111.0)) AND (lat + (radius_km / 111.0))
        AND d.current_longitude BETWEEN (lng - (radius_km / (111.0 * cos(radians(lat))))) AND (lng + (radius_km / (111.0 * cos(radians(lat)))))
    HAVING 
        -- Filtro de distância real usando Haversine
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
    LIMIT 100; -- Mais motoristas para emergências
END;
$$ LANGUAGE plpgsql;

-- Comentários sobre as funções criadas:
-- 1. get_nearby_drivers: Busca motoristas próximos para solicitações normais
-- 2. get_emergency_nearby_drivers: Busca motoristas próximos para emergências (raio maior)
-- 3. Ambas usam a fórmula de Haversine para calcular distâncias precisas
-- 4. Incluem filtros de bounding box para melhor performance
-- 5. Retornam dados compatíveis com o código existente
-- 6. Incluem campos de FCM token para notificações

-- Para executar este script:
-- 1. Acesse o Supabase Dashboard
-- 2. Vá para SQL Editor
-- 3. Cole este script e execute
-- 4. Verifique se as funções foram criadas sem erros