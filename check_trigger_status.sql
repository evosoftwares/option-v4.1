-- Verificar se o trigger auto_create_driver_record_trigger existe
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'auto_create_driver_record_trigger';

-- Verificar se a função auto_create_driver_record existe
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'auto_create_driver_record';

-- Verificar usuários drivers sem registro na tabela drivers
SELECT 
    u.id as user_id,
    u.email,
    u.user_type,
    CASE WHEN d.id IS NULL THEN 'SEM REGISTRO' ELSE 'COM REGISTRO' END as status_driver
FROM auth.users u
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.email_confirmed_at IS NOT NULL
ORDER BY u.created_at DESC
LIMIT 10;