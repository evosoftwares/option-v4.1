-- =============================================
-- TESTE DAS CORREÇÕES DAS FUNÇÕES DE MOTORISTA
-- Execute este script após aplicar as correções
-- =============================================

-- PASSO 1: Verificar se as funções existem
SELECT 
    'VERIFICAÇÃO DE FUNÇÕES CORRIGIDAS' as categoria,
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name = 'get_nearby_drivers' THEN 'Função para buscar motoristas próximos'
        WHEN routine_name = 'get_emergency_nearby_drivers' THEN 'Função para emergências'
        ELSE 'Outra função'
    END as descricao
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('get_nearby_drivers', 'get_emergency_nearby_drivers')
ORDER BY routine_name;

-- PASSO 2: Verificar estrutura das tabelas necessárias
SELECT 
    'VERIFICAÇÃO DE TABELAS' as categoria,
    table_name,
    CASE 
        WHEN table_name = 'drivers' THEN 'Tabela principal de motoristas'
        WHEN table_name = 'app_users' THEN 'Tabela de usuários (contém full_name)'
        ELSE 'Outra tabela'
    END as descricao
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('drivers', 'app_users')
ORDER BY table_name;

-- PASSO 3: Verificar se existem motoristas para teste
SELECT 
    'DADOS PARA TESTE' as categoria,
    COUNT(*) as total_drivers,
    COUNT(CASE WHEN d.is_online = true THEN 1 END) as drivers_online,
    COUNT(CASE WHEN d.approval_status = 'approved' THEN 1 END) as drivers_approved,
    COUNT(CASE WHEN d.current_latitude IS NOT NULL AND d.current_longitude IS NOT NULL THEN 1 END) as drivers_with_location
FROM drivers d
INNER JOIN app_users au ON d.user_id = au.id
WHERE au.status = 'active';

-- PASSO 4: Teste básico da função get_nearby_drivers
-- (usando coordenadas de São Paulo como exemplo)
SELECT 'TESTE get_nearby_drivers' as teste;

-- Teste com parâmetros válidos
SELECT 
    driver_id,
    user_id,
    driver_name,
    is_online,
    vehicle_category,
    distance_km
FROM get_nearby_drivers(-23.5505, -46.6333, 10.0) 
LIMIT 5;

-- PASSO 5: Teste básico da função get_emergency_nearby_drivers
SELECT 'TESTE get_emergency_nearby_drivers' as teste;

-- Teste com parâmetros válidos
SELECT 
    driver_id,
    user_id,
    driver_name,
    phone,
    distance_km
FROM get_emergency_nearby_drivers(-23.5505, -46.6333, 5.0) 
LIMIT 3;

-- PASSO 6: Teste de performance (verificar se não há erros)
SELECT 'TESTE DE PERFORMANCE' as teste;

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM get_nearby_drivers(-23.5505, -46.6333, 5.0) LIMIT 10;

-- PASSO 7: Verificar permissões das funções
SELECT 
    'VERIFICAÇÃO DE PERMISSÕES' as categoria,
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_schema = 'public' 
    AND routine_name IN ('get_nearby_drivers', 'get_emergency_nearby_drivers')
ORDER BY routine_name, grantee;

-- PASSO 8: Teste de erro (verificar se não retorna erro 42P01)
SELECT 'TESTE DE ROBUSTEZ' as teste;

-- Teste com coordenadas extremas
SELECT COUNT(*) as resultado_coordenadas_extremas
FROM get_nearby_drivers(90.0, 180.0, 1.0);

-- Teste com raio zero
SELECT COUNT(*) as resultado_raio_zero
FROM get_nearby_drivers(-23.5505, -46.6333, 0.0);

-- PASSO 9: Verificar se o JOIN está funcionando corretamente
SELECT 'VERIFICAÇÃO DO JOIN' as teste;

SELECT 
    d.id as driver_id,
    d.user_id,
    au.full_name,
    au.email,
    d.vehicle_brand,
    d.vehicle_model
FROM drivers d
INNER JOIN app_users au ON d.user_id = au.id
WHERE d.is_online = true
    AND d.approval_status = 'approved'
    AND au.status = 'active'
LIMIT 3;

-- PASSO 10: Resumo dos testes
SELECT 
    'RESUMO DOS TESTES' as categoria,
    'Se todos os testes acima executaram sem erro 42P01, as correções foram aplicadas com sucesso!' as resultado;

-- INSTRUÇÕES PARA EXECUÇÃO:
-- 1. Execute este script completo no SQL Editor do Supabase
-- 2. Verifique se não há erros do tipo "relation does not exist"
-- 3. Confirme que as funções retornam dados válidos
-- 4. Teste o aplicativo Flutter após as correções