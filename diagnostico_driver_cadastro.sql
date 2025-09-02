-- ===================================================
-- DIAGNÓSTICO CADASTRO DE MOTORISTA
-- Verificar problemas no fluxo de cadastro
-- ===================================================

-- 1. Verificar usuários autenticados
SELECT 
    'USUÁRIOS AUTENTICADOS' as status,
    id,
    email,
    created_at,
    email_confirmed_at
FROM auth.users
WHERE email_confirmed_at IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 2. Verificar se motoristas estão sendo criados corretamente
SELECT 
    'MOTORISTAS NA BASE' as status,
    d.id as driver_id,
    d.user_id,
    u.email,
    d.approval_status,
    d.vehicle_brand,
    d.vehicle_model,
    d.created_at
FROM drivers d
JOIN auth.users u ON d.user_id = u.id
ORDER BY d.created_at DESC
LIMIT 10;

-- 3. Verificar usuários SEM motorista associado
SELECT 
    'USUÁRIOS SEM MOTORISTA' as status,
    u.id as user_id,
    u.email,
    u.created_at
FROM auth.users u
LEFT JOIN drivers d ON u.id = d.user_id
WHERE d.id IS NULL 
  AND u.email_confirmed_at IS NOT NULL
ORDER BY u.created_at DESC;

-- 4. Verificar políticas RLS na tabela drivers
SELECT 
    'POLÍTICAS RLS DRIVERS' as status,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'drivers' 
  AND schemaname = 'public';

-- 5. Verificar se RLS está habilitado
SELECT 
    'STATUS RLS' as status,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('drivers', 'users');

-- 6. Verificar buckets de storage
SELECT 
    'BUCKETS STORAGE' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
ORDER BY name;

-- ===================================================
-- SOLUÇÕES POSSÍVEIS:
-- 
-- Se não há motorista para um usuário:
-- 1. Verificar se o trigger de criação automática está funcionando
-- 2. Criar manualmente o motorista se necessário
-- 
-- Se há problemas de permissão:
-- 1. Verificar políticas RLS
-- 2. Desabilitar RLS temporariamente para testes
-- ===================================================