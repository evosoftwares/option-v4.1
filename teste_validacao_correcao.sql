-- =============================================
-- SCRIPT DE TESTE E VALIDAÇÃO DA CORREÇÃO
-- Execute este script no Supabase SQL Editor para testar a correção
-- =============================================

-- PASSO 1: Verificar estado atual antes da correção
SELECT 
    'ESTADO ANTES DA CORREÇÃO' as status,
    (
        SELECT COUNT(*) FROM app_users 
        WHERE user_type = 'driver'
    ) as total_users_driver,
    (
        SELECT COUNT(*) FROM drivers
    ) as total_registros_drivers,
    (
        SELECT COUNT(*) FROM app_users au
        WHERE au.user_type = 'driver'
            AND NOT EXISTS (
                SELECT 1 FROM drivers d 
                WHERE d.user_id = au.id
            )
    ) as users_sem_perfil_driver;

-- PASSO 2: Listar usuários problemáticos (se houver)
SELECT 
    'USUÁRIOS PROBLEMÁTICOS' as categoria,
    au.id,
    au.email,
    au.full_name,
    au.user_type,
    au.created_at
FROM app_users au
WHERE au.user_type = 'driver'
    AND NOT EXISTS (
        SELECT 1 FROM drivers d 
        WHERE d.user_id = au.id
    )
ORDER BY au.created_at
LIMIT 10;

-- PASSO 3: Simular teste da função getDriverIdForUser
SELECT 
    'TESTE FUNÇÃO getDriverIdForUser' as categoria,
    au.id as user_id,
    au.email,
    au.user_type,
    d.id as driver_id,
    CASE 
        WHEN d.id IS NOT NULL THEN 'SUCESSO - Driver ID encontrado'
        WHEN au.user_type = 'driver' THEN 'ERRO - User é driver mas não tem driver_id'
        ELSE 'OK - User não é driver'
    END as resultado_teste
FROM app_users au
LEFT JOIN drivers d ON d.user_id = au.id
WHERE au.user_type = 'driver'
ORDER BY au.created_at
LIMIT 10;

-- PASSO 4: Verificar se as funções de correção existem
SELECT 
    'VERIFICAÇÃO DE FUNÇÕES' as categoria,
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name = 'fix_driver_associations' THEN 'Função de correção automática'
        WHEN routine_name = 'auto_create_driver_record' THEN 'Função trigger para criação automática'
        ELSE 'Outra função'
    END as descricao
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('fix_driver_associations', 'auto_create_driver_record')
ORDER BY routine_name;

-- PASSO 5: Verificar se o trigger existe
SELECT 
    'VERIFICAÇÃO DE TRIGGER' as categoria,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    CASE 
        WHEN trigger_name = 'auto_create_driver_record_trigger' THEN 'Trigger para criação automática de driver'
        ELSE 'Outro trigger'
    END as descricao
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
    AND trigger_name = 'auto_create_driver_record_trigger';

-- PASSO 6: Teste de criação de usuário driver (simulação)
-- Este é um teste conceitual - NÃO EXECUTE em produção sem cuidado
/*
INSERT INTO app_users (
    id, email, full_name, user_type, created_at, updated_at
) VALUES (
    gen_random_uuid(), 
    'teste_driver_' || extract(epoch from now()) || '@teste.com',
    'Motorista Teste',
    'driver',
    NOW(),
    NOW()
) RETURNING id, email, user_type;
*/

-- PASSO 7: Verificar estrutura da tabela drivers
SELECT 
    'ESTRUTURA TABELA DRIVERS' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'user_id' THEN 'Chave estrangeira para app_users'
        WHEN column_name = 'approval_status' THEN 'Status de aprovação do motorista'
        WHEN column_name IN ('cnh_number', 'vehicle_plate') THEN 'Campo obrigatório para motorista'
        ELSE 'Campo adicional'
    END as importancia
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'drivers'
    AND column_name IN ('user_id', 'cnh_number', 'vehicle_plate', 'approval_status', 'created_at')
ORDER BY ordinal_position;

-- PASSO 8: Verificar constraints e foreign keys
SELECT 
    'CONSTRAINTS E FOREIGN KEYS' as categoria,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'drivers' 
    AND tc.table_schema = 'public'
    AND tc.constraint_type = 'FOREIGN KEY';

-- PASSO 9: Relatório final de validação
SELECT 
    'RELATÓRIO FINAL DE VALIDAÇÃO' as categoria,
    'Total de usuários driver: ' || (
        SELECT COUNT(*) FROM app_users WHERE user_type = 'driver'
    ) as estatistica_1,
    'Total de registros drivers: ' || (
        SELECT COUNT(*) FROM drivers
    ) as estatistica_2,
    'Usuários driver sem perfil: ' || (
        SELECT COUNT(*) FROM app_users au
        WHERE au.user_type = 'driver'
            AND NOT EXISTS (SELECT 1 FROM drivers d WHERE d.user_id = au.id)
    ) as estatistica_3,
    'Drivers órfãos (sem user): ' || (
        SELECT COUNT(*) FROM drivers d
        WHERE NOT EXISTS (SELECT 1 FROM app_users au WHERE au.id = d.user_id)
    ) as estatistica_4;

-- PASSO 10: Instruções para execução da correção
SELECT 
    'INSTRUÇÕES PARA CORREÇÃO' as categoria,
    'Para executar a correção automática, execute o script: correcao_associacao_motorista.sql' as instrucao_1,
    'Após a correção, execute novamente este script para validar os resultados' as instrucao_2,
    'Verifique se todos os usuários driver agora possuem registros na tabela drivers' as instrucao_3;

-- COMENTÁRIOS FINAIS
/*
Este script de validação verifica:
1. Estado atual da associação entre usuários e perfis de motorista
2. Existência das funções de correção
3. Presença do trigger automático
4. Estrutura das tabelas envolvidas
5. Constraints e relacionamentos
6. Estatísticas finais

Para uma validação completa:
1. Execute este script ANTES da correção
2. Execute o script de correção (correcao_associacao_motorista.sql)
3. Execute este script DEPOIS da correção
4. Compare os resultados para confirmar que a correção funcionou
*/