-- =============================================
-- CORREÇÃO DO ERRO 409 - EXECUTAR NO SUPABASE SQL EDITOR
-- =============================================
-- Este script deve ser executado no Supabase SQL Editor
-- para resolver o conflito de dados duplicados

-- PASSO 1: Verificar registros conflitantes
SELECT 
    'VERIFICAÇÃO DE CONFLITOS' as status,
    COUNT(*) as total_conflitos,
    array_agg(DISTINCT id::text) as ids_conflitantes,
    array_agg(DISTINCT email) as emails_conflitantes,
    array_agg(DISTINCT phone) as phones_conflitantes
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 2: Mostrar detalhes dos registros conflitantes
SELECT 
    'DETALHES DOS CONFLITOS' as info,
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

-- PASSO 3: Verificar registros relacionados que precisam ser removidos
SELECT 
    'REGISTROS RELACIONADOS - PASSENGERS' as tabela,
    COUNT(*) as total
FROM passengers p
WHERE p.user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

SELECT 
    'REGISTROS RELACIONADOS - DRIVERS' as tabela,
    COUNT(*) as total
FROM drivers d
WHERE d.user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

SELECT 
    'REGISTROS RELACIONADOS - SAVED_PLACES' as tabela,
    COUNT(*) as total
FROM saved_places sp
WHERE sp.user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- PASSO 4: Criar backup dos registros que serão removidos
CREATE TABLE IF NOT EXISTS backup_conflict_409_removal AS
SELECT 
    'app_users' as source_table,
    now() as backup_timestamp,
    id,
    email,
    full_name,
    phone,
    photo_url,
    user_type,
    status,
    created_at,
    updated_at
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 5: Remover registros relacionados primeiro (para evitar violação de FK)
-- Remover passengers
DELETE FROM passengers 
WHERE user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- Remover drivers
DELETE FROM drivers 
WHERE user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- Remover saved_places
DELETE FROM saved_places 
WHERE user_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- Remover trips relacionados
DELETE FROM trips 
WHERE passenger_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
)
OR driver_id IN (
    SELECT id FROM app_users 
    WHERE 
        id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        OR email = 'asdfadsf@gmail.com'
        OR phone = '(11) 9 9999-9999'
);

-- PASSO 6: Remover os registros conflitantes da tabela app_users
DELETE FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 7: Verificar se a remoção foi bem-sucedida
SELECT 
    'VERIFICAÇÃO PÓS-REMOÇÃO' as status,
    COUNT(*) as registros_restantes,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Conflito resolvido - dados removidos com sucesso'
        ELSE '❌ Ainda existem ' || COUNT(*) || ' registros conflitantes'
    END as resultado
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 8: Testar inserção dos dados após limpeza
INSERT INTO app_users (
    id,
    email,
    full_name,
    phone,
    photo_url,
    user_type,
    status,
    created_at,
    updated_at
) VALUES (
    'e202bc55-61fa-4f18-9003-27dcfb8a12fa',
    'asdfadsf@gmail.com',
    'asdfadsf',
    '(11) 9 9999-9999',
    null,
    'passenger',
    'active',
    now(),
    now()
);

-- PASSO 9: Criar registro passenger correspondente
INSERT INTO passengers (
    id,
    user_id,
    consecutive_cancellations,
    total_trips,
    average_rating,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'e202bc55-61fa-4f18-9003-27dcfb8a12fa',
    0,
    0,
    0.0,
    now(),
    now()
);

-- PASSO 10: Verificar se tudo foi criado corretamente
SELECT 
    'VERIFICAÇÃO FINAL' as status,
    u.id as user_id,
    u.email,
    u.full_name,
    u.phone,
    u.user_type,
    u.status,
    p.id as passenger_id,
    CASE 
        WHEN p.id IS NOT NULL THEN '✅ Usuário e passenger criados com sucesso'
        ELSE '❌ Passenger não foi criado'
    END as resultado
FROM app_users u
LEFT JOIN passengers p ON u.id = p.user_id
WHERE u.id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';

-- PASSO 11: Verificar backup criado
SELECT 
    'BACKUP CRIADO' as info,
    COUNT(*) as registros_no_backup,
    backup_timestamp
FROM backup_conflict_409_removal
GROUP BY backup_timestamp
ORDER BY backup_timestamp DESC;

-- PASSO 12: Resumo da operação
SELECT 
    json_build_object(
        'timestamp', NOW(),
        'operation', 'conflict_409_resolution',
        'status', 'completed',
        'user_created', EXISTS(
            SELECT 1 FROM app_users 
            WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        ),
        'passenger_created', EXISTS(
            SELECT 1 FROM passengers 
            WHERE user_id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        ),
        'backup_available', EXISTS(
            SELECT 1 FROM backup_conflict_409_removal
        ),
        'next_steps', array[
            'Teste o cadastro no app Flutter',
            'Monitore logs para confirmar funcionamento',
            'Backup disponível em backup_conflict_409_removal'
        ]
    ) as operation_summary;

-- =============================================
-- INSTRUÇÕES DE USO:
-- =============================================
-- 1. Vá para o Supabase Dashboard
-- 2. Clique em "SQL Editor" no menu lateral
-- 3. Cole este script completo
-- 4. Clique em "Run" para executar
-- 5. Verifique se todos os passos retornam sucesso
-- 6. Teste o cadastro no app Flutter
-- =============================================

-- COMANDOS DE LIMPEZA (se necessário):
-- DROP TABLE IF EXISTS backup_conflict_409_removal;