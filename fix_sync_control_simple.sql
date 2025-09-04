-- Script simples para corrigir o erro sync_control
-- Execute este script no Supabase Dashboard > SQL Editor

-- 1. Verificar se o trigger problemático existe
SELECT 
    trigger_name, 
    event_object_table, 
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_app_to_auth' 
AND event_object_table = 'app_users';

-- 2. Remover o trigger problemático que está causando o erro
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;

-- 3. Verificar se o trigger foi removido com sucesso
SELECT COUNT(*) as triggers_restantes
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_app_to_auth' 
AND event_object_table = 'app_users';

-- 4. Verificar se a função problemática existe
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'controlled_sync_app_to_auth'
AND routine_schema = 'public';

-- 5. Remover a função problemática se existir
DROP FUNCTION IF EXISTS controlled_sync_app_to_auth() CASCADE;

-- 6. Verificação final - deve retornar 0 triggers
SELECT 
    'Correção aplicada com sucesso!' as status,
    COUNT(*) as triggers_sync_restantes
FROM information_schema.triggers 
WHERE trigger_name LIKE '%sync%' 
AND event_object_table = 'app_users';

-- RESULTADO ESPERADO:
-- triggers_sync_restantes deve ser 0
-- Isso significa que o erro sync_control foi corrigido