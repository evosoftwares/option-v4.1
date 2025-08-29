-- BUSCAR O PROBLEMA REAL: Execute estas consultas uma por uma

-- 1. Verificar se há views problemáticas
SELECT 
    table_name,
    view_definition
FROM information_schema.views 
WHERE table_schema = 'public'
    AND view_definition ILIKE '%drivers%'
ORDER BY table_name;

-- 2. Verificar se alguma view está tentando acessar drivers.name
SELECT 
    table_name,
    view_definition
FROM information_schema.views 
WHERE table_schema = 'public'
    AND view_definition ILIKE '%drivers.name%'
ORDER BY table_name;

-- 3. Testar diretamente as funções RPC que estavam dando erro
SELECT 'Testando get_nearby_drivers' as teste;
SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 5.0) LIMIT 3;

SELECT 'Testando get_emergency_nearby_drivers' as teste;
SELECT * FROM get_emergency_nearby_drivers(-23.5505, -46.6333, 2.0) LIMIT 3;

-- 4. Verificar se available_drivers_view existe e está correta
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'available_drivers_view' 
ORDER BY ordinal_position;

-- 5. Testar a view available_drivers_view
SELECT * FROM available_drivers_view LIMIT 3;