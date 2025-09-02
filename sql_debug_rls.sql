-- Script para diagnosticar problemas com a tabela app_users
-- Execute no SQL Editor do Supabase para debug

-- 1. Verificar se a tabela existe e suas permissões
SELECT 
    schemaname, 
    tablename, 
    tableowner,
    hasindexes,
    hasrules,
    hastriggers,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'app_users';

-- 2. Verificar se RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    forcerowsecurity
FROM pg_tables 
WHERE tablename = 'app_users';

-- 3. Listar todas as políticas RLS da tabela
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'app_users';

-- 4. Verificar permissões da tabela para o usuário atual
SELECT 
    table_schema,
    table_name,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_name = 'app_users'
AND grantee = current_user;

-- 5. Tentar uma operação SELECT simples para testar acesso
SELECT COUNT(*) as total_users FROM app_users;

-- 6. Verificar se há dados na tabela
SELECT 
    id,
    email,
    full_name,
    user_type,
    status,
    created_at
FROM app_users 
LIMIT 5;

-- 7. Testar UPDATE na tabela (substitua pelos valores reais)
-- UPDATE app_users 
-- SET full_name = 'Teste UPDATE'
-- WHERE id = 'seu-user-id-aqui';

-- 8. Verificar logs de erro recentes (se disponível)
-- SELECT * FROM pg_stat_activity WHERE datname = current_database();