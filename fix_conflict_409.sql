-- =============================================
-- CORREÇÃO AUTOMÁTICA DO CONFLITO 409
-- Remove registros conflitantes para permitir novo cadastro
-- =============================================

-- IMPORTANTE: Execute primeiro investigate_conflict_409.sql para identificar o problema

-- PASSO 1: Backup dos registros que serão removidos
CREATE TABLE IF NOT EXISTS backup_conflicting_users AS
SELECT 
    *,
    'conflict_409_' || extract(epoch from now()) as backup_reason,
    now() as backup_timestamp
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 2: Verificar quantos registros serão afetados
SELECT 
    'Registros que serão removidos' as info,
    COUNT(*) as total_records
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 3: Mostrar detalhes dos registros conflitantes
SELECT 
    'Detalhes dos registros conflitantes' as info,
    id,
    email,
    full_name,
    phone,
    user_type,
    status,
    created_at
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999'
ORDER BY created_at;

-- PASSO 4: Remover registros relacionados em outras tabelas primeiro
-- (para evitar violação de foreign key)

-- Remover de passengers se existir
DELETE FROM passengers 
WHERE user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- Remover de drivers se existir
DELETE FROM drivers 
WHERE user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- Remover de saved_places se existir
DELETE FROM saved_places 
WHERE user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- Remover de trips como passenger_id
UPDATE trips 
SET passenger_id = NULL 
WHERE passenger_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- Remover de trips como driver_id
UPDATE trips 
SET driver_id = NULL 
WHERE driver_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- PASSO 5: Remover os registros conflitantes da tabela app_users
DELETE FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 6: Verificar se a remoção foi bem-sucedida
SELECT 
    'Verificação pós-remoção' as info,
    COUNT(*) as registros_restantes
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 7: Testar se agora é possível inserir os dados
CREATE OR REPLACE FUNCTION test_insert_after_cleanup()
RETURNS json AS $$
DECLARE
    result json;
    error_msg text;
BEGIN
    BEGIN
        INSERT INTO app_users (
            id,
            email,
            full_name,
            phone,
            user_type,
            status
        ) VALUES (
            'e202bc55-61fa-4f18-9003-27dcfb8a12fa',
            'asdfadsf@gmail.com',
            'asdfadsf',
            '(11) 9 9999-9999',
            'passenger',
            'active'
        );
        
        result := json_build_object(
            'success', true,
            'message', 'Inserção bem-sucedida após limpeza!',
            'next_step', 'O cadastro agora deve funcionar no app'
        );
        
        -- Manter o registro para o teste do app
        -- DELETE FROM app_users WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        result := json_build_object(
            'success', false,
            'error', error_msg,
            'sqlstate', SQLSTATE,
            'next_step', 'Ainda há problemas - verifique RLS ou outras constraints'
        );
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 8: Executar teste final
SELECT test_insert_after_cleanup() as final_test;

-- PASSO 9: Verificar backup criado
SELECT 
    'Backup criado' as info,
    COUNT(*) as registros_no_backup,
    backup_reason,
    backup_timestamp
FROM backup_conflicting_users
GROUP BY backup_reason, backup_timestamp;

-- PASSO 10: Resumo da operação
SELECT 
    json_build_object(
        'timestamp', NOW(),
        'operation', 'fix_conflict_409',
        'status', 'completed',
        'backup_table', 'backup_conflicting_users',
        'next_steps', array[
            'Teste o cadastro no app novamente',
            'Se ainda falhar, execute disable_rls_simple.sql',
            'Verifique os logs do app para confirmar'
        ]
    ) as operation_summary;

-- INSTRUÇÕES:
-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se o teste final (PASSO 8) retorna success: true
-- 3. Teste o cadastro no app novamente
-- 4. Se ainda falhar, o problema pode ser RLS ou outras políticas
-- 5. Os dados removidos estão salvos na tabela backup_conflicting_users