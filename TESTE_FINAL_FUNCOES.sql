-- TESTE FINAL: Execute estas consultas para identificar o problema real

-- 1. Testar as funções RPC diretamente (MAIS IMPORTANTE)
SELECT 'Testando get_nearby_drivers...' as status;
SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 5.0) LIMIT 3;

SELECT 'Testando get_emergency_nearby_drivers...' as status;
SELECT * FROM get_emergency_nearby_drivers(-23.5505, -46.6333, 2.0) LIMIT 3;

-- 2. Testar a view available_drivers_view
SELECT 'Testando available_drivers_view...' as status;
SELECT * FROM available_drivers_view LIMIT 3;

-- 3. Verificar se há outras views com problema
SELECT 
    table_name,
    view_definition
FROM information_schema.views 
WHERE table_schema = 'public'
    AND view_definition ILIKE '%drivers%'
ORDER BY table_name;

-- 4. Verificar se há triggers problemáticos na tabela drivers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
    AND event_object_table = 'drivers'
ORDER BY trigger_name;

-- 5. TESTE CRÍTICO: Simular exatamente o erro que apareceu no app
-- Tentar acessar diretamente drivers.name (deve dar erro)
-- SELECT drivers.name FROM drivers LIMIT 1;  -- Esta linha VAI dar erro propositalmente

-- 6. Verificar se existe alguma função que ainda não vimos
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
    AND routine_definition ILIKE '%name%'
    AND routine_name NOT IN ('get_nearby_drivers', 'get_emergency_nearby_drivers', 'find_available_drivers')
ORDER BY routine_name;