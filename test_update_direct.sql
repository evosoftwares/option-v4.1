-- Teste direto de UPDATE para verificar se o problema é RLS
-- Execute no SQL Editor do Supabase

-- 1. Primeiro, vamos ver o usuário atual logado
SELECT 
    id,
    email,
    full_name,
    phone,
    user_type,
    status
FROM app_users 
WHERE email = 'ijnioni@gmail.com'  -- Email que vimos nos logs
LIMIT 1;

-- 2. Tentar um UPDATE simples na mesma linha
UPDATE app_users 
SET 
    full_name = 'jhvygdj TESTE',
    phone = '1198238489',
    updated_at = NOW()
WHERE email = 'ijnioni@gmail.com';

-- 3. Verificar se o UPDATE funcionou
SELECT 
    id,
    email,
    full_name,
    phone,
    user_type,
    status,
    updated_at
FROM app_users 
WHERE email = 'ijnioni@gmail.com';