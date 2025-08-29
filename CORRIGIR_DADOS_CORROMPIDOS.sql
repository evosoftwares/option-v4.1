-- ===================================================
-- SCRIPT PARA CORRIGIR DADOS CORROMPIDOS DE USUÁRIOS
-- ===================================================
-- 
-- Execute este script no Supabase SQL Editor para limpar
-- dados JSON que foram salvos incorretamente no campo full_name

-- 1. Primeiro, vamos ver os dados corrompidos
SELECT 
    'Usuários com dados corrompidos' as info,
    id,
    email,
    full_name,
    user_type
FROM app_users 
WHERE full_name LIKE '%missing_passenger_records%' 
   OR full_name LIKE '%{%}%'
   OR full_name LIKE '%issue%';

-- 2. Limpar os dados corrompidos - ATENÇÃO: BACKUP ANTES!
-- Primeiro, vamos criar um backup dos dados corrompidos
CREATE TABLE IF NOT EXISTS backup_corrupted_users AS
SELECT * FROM app_users 
WHERE full_name LIKE '%missing_passenger_records%' 
   OR full_name LIKE '%{%}%'
   OR full_name LIKE '%issue%';

-- 3. Mostrar backup criado
SELECT 'Backup criado com sucesso' as status, COUNT(*) as registros_backup
FROM backup_corrupted_users;

-- 4. Atualizar os dados corrompidos
-- ATENÇÃO: Substitua 'Nome Corrigido' pelo nome real do usuário
-- Você pode executar este UPDATE para cada usuário individualmente

-- Exemplo - DESCOMENTE e ajuste antes de executar:
/*
UPDATE app_users 
SET 
    full_name = 'Nome Real Do Usuario',  -- SUBSTITUA pelo nome correto
    updated_at = now()
WHERE id = 'UUID_DO_USUARIO_AQUI';      -- SUBSTITUA pelo ID do usuário
*/

-- 5. Verificação após correção
SELECT 
    'Usuários após correção' as info,
    id,
    email,
    full_name,
    user_type,
    updated_at
FROM app_users 
ORDER BY updated_at DESC 
LIMIT 10;

-- 6. Verificar se ainda há dados corrompidos
SELECT 
    'Dados ainda corrompidos' as warning,
    COUNT(*) as total
FROM app_users 
WHERE full_name LIKE '%missing_passenger_records%' 
   OR full_name LIKE '%{%}%'
   OR full_name LIKE '%issue%';

-- ===================================================
-- INSTRUÇÕES PARA CORREÇÃO:
-- ===================================================
-- 1. Execute as consultas 1, 2 e 3 para ver e fazer backup
-- 2. Para cada usuário corrompido encontrado:
--    a) Descomente e edite a query UPDATE na seção 4
--    b) Substitua 'Nome Real Do Usuario' pelo nome correto
--    c) Substitua 'UUID_DO_USUARIO_AQUI' pelo ID do usuário
--    d) Execute o UPDATE
-- 3. Execute as verificações 5 e 6 para confirmar
-- 4. Teste o login no app para ver se o nome aparece corretamente
-- ===================================================