-- Primeiro, desabilitar RLS temporariamente para testar
ALTER TABLE app_users DISABLE ROW LEVEL SECURITY;

-- Testar UPDATE sem RLS
UPDATE app_users 
SET full_name = 'jhvygdj TESTE'
WHERE email = 'ijnioni@gmail.com';

-- Ver se funcionou
SELECT id, email, full_name, updated_at
FROM app_users 
WHERE email = 'ijnioni@gmail.com';