-- Corrigir permissões da view available_drivers_view
-- Execute este SQL no Supabase Dashboard
-- ATUALIZADO: Alinhado com a nova arquitetura baseada em documentos

-- Garantir que a view existe com a lógica correta
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
    d.consecutive_cancellations,
    ds.online_intent
FROM drivers d
LEFT JOIN driver_status ds ON ds.driver_id = d.id
WHERE 
    -- NOVA LÓGICA: Status online depende de online_intent + documentos aprovados
    ds.online_intent = true
    -- Motorista deve estar aprovado
    AND d.approval_status = 'approved'
    -- Motorista deve ter documentos aprovados (nova validação baseada em documentos)
    AND EXISTS (
        SELECT 1 FROM driver_documents dd 
        WHERE dd.driver_id = d.id 
        AND dd.status = 'approved'
        AND dd.is_current = true
        AND dd.document_type IN ('CNH_FRONT', 'CNH_BACK', 'CRLV')
        GROUP BY dd.driver_id
        HAVING COUNT(DISTINCT dd.document_type) >= 3
    )
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

-- Conceder permissões para o role anon (usado pelo app)
GRANT SELECT ON available_drivers_view TO anon;
GRANT SELECT ON available_drivers_view TO authenticated;

-- Conceder permissões para o role service_role (usado pelo backend)
GRANT SELECT ON available_drivers_view TO service_role;

-- Verificar se as permissões foram aplicadas
SELECT 
    schemaname,
    viewname,
    viewowner,
    definition
FROM pg_views 
WHERE viewname = 'available_drivers_view';

-- Testar a view
SELECT COUNT(*) as total_available_drivers FROM available_drivers_view;

-- Comentário para documentação
COMMENT ON VIEW available_drivers_view IS 'View otimizada que retorna apenas motoristas realmente disponíveis para aceitar corridas. Usa a nova lógica baseada em documentos: online_intent + documentos aprovados. Inclui permissões para anon, authenticated e service_role.';

-- Consulta de diagnóstico para verificar a nova lógica
SELECT 
    'Motoristas com online_intent = true' as categoria,
    COUNT(*) as total
FROM drivers d
LEFT JOIN driver_status ds ON ds.driver_id = d.id
WHERE ds.online_intent = true

UNION ALL

SELECT 
    'Motoristas aprovados' as categoria,
    COUNT(*) as total
FROM drivers d
WHERE d.approval_status = 'approved'

UNION ALL

SELECT 
    'Motoristas com documentos completos' as categoria,
    COUNT(DISTINCT dd.driver_id) as total
FROM driver_documents dd 
WHERE dd.status = 'approved'
AND dd.is_current = true
AND dd.document_type IN ('CNH_FRONT', 'CNH_BACK', 'CRLV')
GROUP BY dd.driver_id
HAVING COUNT(DISTINCT dd.document_type) >= 3;