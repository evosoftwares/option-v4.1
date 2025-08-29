-- Script para verificar e listar todas as funções que podem ter referências problemáticas
-- Execute este script no painel SQL do Supabase para diagnosticar

-- 1. Listar todas as funções que mencionam 'drivers' ou 'name'
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

-- 2. Verificar se as views estão corretas
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

-- 3. Verificar triggers que podem ter referências problemáticas
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

-- 4. Testar se as funções RPC agora funcionam
SELECT 'Testando get_nearby_drivers...' as teste;
-- SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 5.0) LIMIT 3;

SELECT 'Testando get_emergency_nearby_drivers...' as teste;  
-- SELECT * FROM get_emergency_nearby_drivers(-23.5505, -46.6333, 2.0) LIMIT 3;

-- 5. Verificar a estrutura da tabela drivers para confirmar campos
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'drivers' AND table_schema = 'public'
ORDER BY ordinal_position;