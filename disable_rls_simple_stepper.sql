-- SCRIPT SIMPLES: Desabilitar RLS para Stepper e Cadastro
-- Execute no Supabase SQL Editor

-- Desabilitar RLS das tabelas essenciais
ALTER TABLE app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE passengers DISABLE ROW LEVEL SECURITY;  
ALTER TABLE drivers DISABLE ROW LEVEL SECURITY;
ALTER TABLE saved_places DISABLE ROW LEVEL SECURITY;

-- Verificar status
SELECT 
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('app_users', 'passengers', 'drivers', 'saved_places')
ORDER BY tablename;

SELECT '✅ RLS desabilitado para stepper e cadastro' as resultado;