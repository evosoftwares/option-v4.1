-- TESTE DIRETO DE CADA FUNÇÃO - Execute uma por vez para identificar o problema

-- 1. TESTE get_nearby_drivers (SUSPEITA PRINCIPAL)
SELECT 'TESTANDO get_nearby_drivers' as teste;
SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 5.0) LIMIT 3;

-- 2. TESTE get_emergency_nearby_drivers  
SELECT 'TESTANDO get_emergency_nearby_drivers' as teste;
SELECT * FROM get_emergency_nearby_drivers(-23.5505, -46.6333, 2.0) LIMIT 3;

-- 3. TESTE find_available_drivers (NOVA SUSPEITA)
SELECT 'TESTANDO find_available_drivers' as teste;
SELECT * FROM find_available_drivers(
    -23.5505,  -- p_origin_lat
    -46.6333,  -- p_origin_lng
    -23.5500,  -- p_dest_lat
    -46.6330,  -- p_dest_lng
    'standard', -- p_category
    'Centro',   -- p_origin_neighborhood
    'Vila Madalena', -- p_dest_neighborhood
    false,      -- p_needs_pet
    false,      -- p_needs_grocery
    false,      -- p_needs_ac
    false,      -- p_is_condo_origin
    false,      -- p_is_condo_dest
    0           -- p_stops
) LIMIT 3;

-- 4. TESTE available_drivers_view
SELECT 'TESTANDO available_drivers_view' as teste;
SELECT * FROM available_drivers_view LIMIT 3;

-- 5. TESTE CRÍTICO: Verificar se a view tem definição problemática
SELECT 
    table_name,
    view_definition
FROM information_schema.views 
WHERE table_name = 'available_drivers_view';

-- 6. TESTE: Simular erro proposital para confirmar
-- SELECT drivers.name FROM drivers LIMIT 1;  -- Esta linha DEVE dar erro