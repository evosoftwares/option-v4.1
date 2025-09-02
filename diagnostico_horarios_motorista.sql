-- ===================================================
-- DIAGNÓSTICO DE HORÁRIOS DE TRABALHO DOS MOTORISTAS
-- Identificar problemas no salvamento de horários
-- ===================================================

-- 1. Verificar estrutura da tabela driver_schedules
SELECT 
    'ESTRUTURA DRIVER_SCHEDULES' as status,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'driver_schedules' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Verificar se existem motoristas na base
SELECT 
    'MOTORISTAS DISPONÍVEIS' as status,
    COUNT(*) as total_motoristas,
    COUNT(CASE WHEN approval_status = 'approved' THEN 1 END) as motoristas_aprovados
FROM drivers;

-- 3. Verificar horários existentes
SELECT 
    'HORÁRIOS EXISTENTES' as status,
    ds.id,
    ds.driver_id,
    au.email as driver_email,
    ds.day_of_week,
    ds.start_time,
    ds.end_time,
    ds.is_active,
    ds.created_at
FROM driver_schedules ds
JOIN drivers d ON ds.driver_id = d.id
JOIN auth.users au ON d.user_id = au.id
ORDER BY ds.created_at DESC
LIMIT 10;

-- 4. Verificar políticas RLS na tabela driver_schedules
SELECT 
    'POLÍTICAS RLS SCHEDULES' as status,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'driver_schedules' 
  AND schemaname = 'public';

-- 5. Verificar status RLS da tabela
SELECT 
    'STATUS RLS SCHEDULES' as status,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'driver_schedules';

-- 6. Verificar constraints da tabela
SELECT 
    'CONSTRAINTS SCHEDULES' as status,
    conname as constraint_name,
    contype as constraint_type,
    consrc as constraint_definition
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'driver_schedules' 
  AND n.nspname = 'public';

-- 7. Verificar índices
SELECT 
    'ÍNDICES SCHEDULES' as status,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'driver_schedules' 
  AND schemaname = 'public';

-- 8. Teste de inserção simples (comentado por segurança)
/*
-- DESCOMENTAR APENAS PARA TESTE, SUBSTITUIR driver_id por um válido
INSERT INTO driver_schedules (driver_id, day_of_week, start_time, end_time, is_active)
VALUES (
    (SELECT id FROM drivers LIMIT 1), -- Pega o primeiro motorista
    1, -- Segunda-feira
    '08:00:00',
    '17:00:00',
    true
);
*/

-- 9. Verificar permissões da tabela
SELECT 
    'PERMISSÕES SCHEDULES' as status,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'driver_schedules' 
  AND table_schema = 'public';

-- ===================================================
-- POSSÍVEIS PROBLEMAS E SOLUÇÕES:
-- 
-- 1. RLS muito restritivo:
--    - Verificar se as políticas RLS permitem inserção
--    - Temporariamente desabilitar RLS para teste
-- 
-- 2. Constraint violada:
--    - Verificar se day_of_week está no range 0-6
--    - Verificar formato do time (HH:MM:SS)
-- 
-- 3. Driver não existe:
--    - Verificar se driver_id é válido
--    - Confirmar que o motorista está na tabela drivers
-- 
-- 4. Permissões insuficientes:
--    - Verificar se o usuário authenticated tem INSERT
-- ===================================================