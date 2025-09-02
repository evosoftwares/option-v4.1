-- Script simples para verificar app_users (sem comentários que possam causar problemas)

-- Verificar se a tabela existe
SELECT tablename, tableowner, rowsecurity
FROM pg_tables 
WHERE tablename = 'app_users';

-- Verificar políticas RLS
SELECT tablename, policyname, cmd, roles
FROM pg_policies 
WHERE tablename = 'app_users';

-- Testar acesso básico
SELECT COUNT(*) as total_users FROM app_users;

-- Ver dados do usuário atual
SELECT id, email, full_name, user_type, status
FROM app_users 
WHERE email = 'ijnioni@gmail.com';