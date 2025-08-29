-- PRÓXIMOS PASSOS: Execute estas consultas no Supabase para encontrar o problema

-- 1. PRIMEIRA PRIORIDADE: Encontrar funções que referenciam drivers + name
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_type = 'FUNCTION'
    AND routine_schema = 'public'
    AND (
        routine_definition ILIKE '%drivers%name%' 
        OR routine_definition ILIKE '%drivers.name%'
        OR routine_name ILIKE '%driver%'
    )
ORDER BY routine_name;

-- 2. SEGUNDA PRIORIDADE: Verificar views problemáticas
SELECT 
    table_name,
    view_definition
FROM information_schema.views 
WHERE table_schema = 'public'
    AND (
        view_definition ILIKE '%drivers%name%'
        OR view_definition ILIKE '%drivers.name%'
        OR table_name ILIKE '%driver%'
    )
ORDER BY table_name;

-- 3. TERCEIRA PRIORIDADE: Verificar triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
    AND (
        action_statement ILIKE '%drivers%name%'
        OR action_statement ILIKE '%drivers.name%'
        OR event_object_table = 'drivers'
    )
ORDER BY trigger_name;

-- 4. TESTE ESPECÍFICO: Verificar se get_nearby_drivers existe e tem problema
SELECT routine_name, routine_definition 
FROM information_schema.routines 
WHERE routine_name = 'get_nearby_drivers';

-- 5. BUSCA AMPLA: Qualquer coisa que mencione 'name' em funções relacionadas a drivers
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_type = 'FUNCTION'
    AND routine_schema = 'public'
    AND routine_definition ILIKE '%name%'
    AND routine_definition ILIKE '%driver%'
ORDER BY routine_name;