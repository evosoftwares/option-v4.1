-- =============================================
-- DIAGNÓSTICO DE ASSOCIAÇÃO DE PERFIL DE MOTORISTA
-- Execute este script no Supabase SQL Editor
-- =============================================

-- PASSO 1: Verificar usuários com user_type='driver' que NÃO têm registro na tabela drivers
SELECT 
    'USUÁRIOS SEM PERFIL DE MOTORISTA' as diagnostico,
    COUNT(*) as total_problematicos
FROM app_users au
WHERE au.user_type = 'driver'
    AND NOT EXISTS (
        SELECT 1 FROM drivers d 
        WHERE d.user_id = au.id
    );

-- PASSO 2: Listar detalhes dos usuários problemáticos
SELECT 
    au.id as user_id,
    au.email,
    au.full_name,
    au.user_type,
    au.status,
    au.created_at,
    'SEM_PERFIL_MOTORISTA' as problema
FROM app_users au
WHERE au.user_type = 'driver'
    AND NOT EXISTS (
        SELECT 1 FROM drivers d 
        WHERE d.user_id = au.id
    )
ORDER BY au.created_at DESC;

-- PASSO 3: Verificar motoristas que têm perfil mas usuário não é 'driver'
SELECT 
    'MOTORISTAS COM USER_TYPE INCORRETO' as diagnostico,
    COUNT(*) as total_problematicos
FROM drivers d
JOIN app_users au ON au.id = d.user_id
WHERE au.user_type != 'driver';

-- PASSO 4: Listar detalhes dos motoristas com user_type incorreto
SELECT 
    d.id as driver_id,
    d.user_id,
    au.email,
    au.full_name,
    au.user_type as user_type_atual,
    au.status,
    d.created_at as driver_created_at,
    'USER_TYPE_INCORRETO' as problema
FROM drivers d
JOIN app_users au ON au.id = d.user_id
WHERE au.user_type != 'driver'
ORDER BY d.created_at DESC;

-- PASSO 5: Verificar estatísticas gerais
SELECT 
    'ESTATÍSTICAS GERAIS' as categoria,
    (
        SELECT COUNT(*) FROM app_users 
        WHERE user_type = 'driver'
    ) as total_users_driver,
    (
        SELECT COUNT(*) FROM drivers
    ) as total_registros_drivers,
    (
        SELECT COUNT(*) FROM app_users au
        JOIN drivers d ON d.user_id = au.id
        WHERE au.user_type = 'driver'
    ) as associacoes_corretas;

-- PASSO 6: Verificar se há registros órfãos na tabela drivers
SELECT 
    'REGISTROS ÓRFÃOS EM DRIVERS' as diagnostico,
    COUNT(*) as total_orfaos
FROM drivers d
WHERE NOT EXISTS (
    SELECT 1 FROM app_users au 
    WHERE au.id = d.user_id
);

-- PASSO 7: Listar registros órfãos em drivers
SELECT 
    d.id as driver_id,
    d.user_id,
    d.created_at,
    'REGISTRO_ÓRFÃO' as problema
FROM drivers d
WHERE NOT EXISTS (
    SELECT 1 FROM app_users au 
    WHERE au.id = d.user_id
)
ORDER BY d.created_at DESC;

-- PASSO 8: Verificar estrutura das tabelas para confirmar campos necessários
SELECT 
    'ESTRUTURA APP_USERS' as tabela,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'app_users' 
    AND table_schema = 'public'
    AND column_name IN ('id', 'user_type', 'email', 'full_name', 'status')
ORDER BY ordinal_position;

-- PASSO 9: Verificar estrutura da tabela drivers
SELECT 
    'ESTRUTURA DRIVERS' as tabela,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'drivers' 
    AND table_schema = 'public'
    AND column_name IN ('id', 'user_id', 'created_at', 'updated_at')
ORDER BY ordinal_position;

-- PASSO 10: Teste de função getDriverIdForUser simulado
-- Simular o que a função getDriverIdForUser faz
SELECT 
    'TESTE GETDRIVERIDFUSER' as teste,
    au.id as user_id,
    au.email,
    d.id as driver_id_encontrado,
    CASE 
        WHEN d.id IS NULL THEN 'DRIVER_ID_NULL'
        ELSE 'DRIVER_ID_ENCONTRADO'
    END as resultado
FROM app_users au
LEFT JOIN drivers d ON d.user_id = au.id
WHERE au.user_type = 'driver'
ORDER BY au.created_at DESC
LIMIT 10;