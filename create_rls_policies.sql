-- Script para criar políticas RLS necessárias para a tabela app_users
-- Execute no SQL Editor do Supabase caso as políticas estejam faltando

-- 1. Habilitar RLS na tabela (se não estiver habilitado)
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- 2. Política para permitir que usuários vejam seus próprios dados
CREATE POLICY "Users can view own profile" ON app_users
    FOR SELECT USING (auth.uid() = id);

-- 3. Política para permitir que usuários atualizem seus próprios dados  
CREATE POLICY "Users can update own profile" ON app_users
    FOR UPDATE USING (auth.uid() = id);

-- 4. Política para inserção de novos usuários (durante cadastro)
CREATE POLICY "Enable insert for authenticated users only" ON app_users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 5. Verificar se as políticas foram criadas corretamente
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
WHERE tablename = 'app_users'
ORDER BY policyname;

-- 6. Testar se agora conseguimos fazer SELECT e UPDATE
SELECT COUNT(*) as total_users FROM app_users;

-- Teste UPDATE (substitua pelo ID do usuário logado)
-- UPDATE app_users 
-- SET full_name = 'Teste UPDATE RLS'
-- WHERE id = auth.uid();

COMMENT ON POLICY "Users can view own profile" ON app_users IS 'Permite que usuários vejam apenas seus próprios dados de perfil';
COMMENT ON POLICY "Users can update own profile" ON app_users IS 'Permite que usuários atualizem apenas seus próprios dados de perfil';
COMMENT ON POLICY "Enable insert for authenticated users only" ON app_users IS 'Permite inserção apenas para usuários autenticados com seu próprio ID';