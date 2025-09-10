-- Criar view available_drivers_view para otimizar busca de motoristas disponíveis
-- Esta view consolida dados de motoristas que estão online, aprovados e disponíveis

CREATE OR REPLACE VIEW available_drivers_view AS
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
    d.total_trips,
    d.average_rating,
    d.current_latitude,
    d.current_longitude,
    d.last_location_update,
    d.consecutive_cancellations
FROM drivers d
WHERE 
    -- Motorista deve estar online
    d.is_online = true
    -- Motorista deve estar aprovado
    AND d.approval_status = 'approved'
    -- Motorista deve ter localização atual
    AND d.current_latitude IS NOT NULL 
    AND d.current_longitude IS NOT NULL
    -- Localização deve ser recente (últimas 2 horas)
    AND d.last_location_update IS NOT NULL
    AND d.last_location_update > NOW() - INTERVAL '2 hours'
    -- Motorista não deve ter muitos cancelamentos consecutivos
    AND d.consecutive_cancellations < 5
    -- Motorista não deve estar em viagem ativa
    AND NOT EXISTS (
        SELECT 1 FROM trips t 
        WHERE t.driver_id = d.id 
        AND t.status IN ('ongoing', 'arrived', 'picked_up')
    )
    -- Motorista não deve ter solicitação pendente
    AND NOT EXISTS (
        SELECT 1 FROM trip_requests tr 
        WHERE tr.target_driver_id = d.id 
        AND tr.status = 'pending'
    );

-- Criar índices para otimizar a performance da view
CREATE INDEX IF NOT EXISTS idx_drivers_online_approved 
ON drivers (is_online, approval_status) 
WHERE is_online = true AND approval_status = 'approved';

CREATE INDEX IF NOT EXISTS idx_drivers_location_recent 
ON drivers (current_latitude, current_longitude, last_location_update) 
WHERE current_latitude IS NOT NULL AND current_longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_trips_driver_active_status 
ON trips (driver_id, status) 
WHERE status IN ('ongoing', 'arrived', 'picked_up');

CREATE INDEX IF NOT EXISTS idx_trip_requests_driver_pending 
ON trip_requests (target_driver_id, status) 
WHERE status = 'pending';

-- Comentários para documentação
COMMENT ON VIEW available_drivers_view IS 'View otimizada que retorna apenas motoristas realmente disponíveis para aceitar corridas';