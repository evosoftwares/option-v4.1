-- Teste muito simples para ver se conseguimos acessar a tabela
SELECT current_schema();
SELECT current_user;

-- Ver todas as tabelas no schema atual
SELECT table_name, table_schema 
FROM information_schema.tables 
WHERE table_type = 'BASE TABLE'
AND table_name LIKE '%user%'
ORDER BY table_name;

-- Tentar acessar a tabela diretamente
SELECT * FROM public.app_users LIMIT 1;