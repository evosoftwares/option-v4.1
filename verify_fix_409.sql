-- =============================================
-- VERIFICAÇÃO FINAL APÓS CORREÇÃO DO CONFLITO 409
-- Confirma que o problema foi resolvido
-- =============================================

-- PASSO 1: Verificar se não há mais registros conflitantes
SELECT 
    'Status dos dados conflitantes' as check_type,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ Nenhum registro conflitante encontrado'
        ELSE '❌ Ainda existem ' || COUNT(*) || ' registros conflitantes'
    END as status,
    COUNT(*) as count
FROM app_users 
WHERE 
    id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
    OR email = 'asdfadsf@gmail.com'
    OR phone = '(11) 9 9999-9999';

-- PASSO 2: Testar inserção completa com todos os campos
CREATE OR REPLACE FUNCTION test_complete_user_insert()
RETURNS json AS $$
DECLARE
    result json;
    error_msg text;
    test_id uuid := 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';
BEGIN
    BEGIN
        -- Inserir com todos os campos necessários
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
            test_id,
            'asdfadsf@gmail.com',
            'asdfadsf',
            '(11) 9 9999-9999',
            null,
            'passenger',
            'active',
            now(),
            now()
        );
        
        -- Verificar se foi inserido corretamente
        IF EXISTS (SELECT 1 FROM app_users WHERE id = test_id) THEN
            result := json_build_object(
                'success', true,
                'message', 'Usuário inserido com sucesso!',
                'user_id', test_id,
                'next_step', 'Criar registro passenger correspondente'
            );
        ELSE
            result := json_build_object(
                'success', false,
                'message', 'Usuário não foi encontrado após inserção',
                'error', 'INSERT_NOT_REFLECTED'
            );
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        result := json_build_object(
            'success', false,
            'error', error_msg,
            'sqlstate', SQLSTATE,
            'constraint_type', CASE 
                WHEN SQLSTATE = '23505' THEN 'UNIQUE_VIOLATION'
                WHEN SQLSTATE = '23503' THEN 'FOREIGN_KEY_VIOLATION'
                WHEN SQLSTATE = '23514' THEN 'CHECK_VIOLATION'
                WHEN SQLSTATE = '42501' THEN 'PERMISSION_DENIED'
                ELSE 'OTHER_ERROR'
            END
        );
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 3: Executar teste de inserção
SELECT test_complete_user_insert() as insert_test;

-- PASSO 4: Testar criação do registro passenger correspondente
CREATE OR REPLACE FUNCTION test_passenger_creation()
RETURNS json AS $$
DECLARE
    result json;
    error_msg text;
    user_exists boolean;
    passenger_id uuid := gen_random_uuid();
BEGIN
    -- Verificar se o usuário existe
    SELECT EXISTS(SELECT 1 FROM app_users WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa') INTO user_exists;
    
    IF NOT user_exists THEN
        result := json_build_object(
            'success', false,
            'error', 'Usuário não existe na tabela app_users',
            'step', 'passenger_creation'
        );
        RETURN result;
    END IF;
    
    BEGIN
        -- Tentar criar registro passenger
        INSERT INTO passengers (
            id,
            user_id,
            consecutive_cancellations,
            total_trips,
            average_rating,
            created_at,
            updated_at
        ) VALUES (
            passenger_id,
            'e202bc55-61fa-4f18-9003-27dcfb8a12fa',
            0,
            0,
            0.0,
            now(),
            now()
        );
        
        result := json_build_object(
            'success', true,
            'message', 'Registro passenger criado com sucesso!',
            'passenger_id', passenger_id,
            'user_id', 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
        );
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        result := json_build_object(
            'success', false,
            'error', error_msg,
            'sqlstate', SQLSTATE,
            'step', 'passenger_creation'
        );
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 5: Executar teste de criação passenger
SELECT test_passenger_creation() as passenger_test;

-- PASSO 6: Verificar integridade dos dados criados
SELECT 
    'Verificação de integridade' as check_type,
    u.id as user_id,
    u.email,
    u.full_name,
    u.phone,
    u.user_type,
    u.status,
    p.id as passenger_id,
    p.consecutive_cancellations,
    p.total_trips,
    CASE 
        WHEN p.id IS NOT NULL THEN '✅ Passenger criado'
        ELSE '❌ Passenger não encontrado'
    END as passenger_status
FROM app_users u
LEFT JOIN passengers p ON u.id = p.user_id
WHERE u.id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';

-- PASSO 7: Verificar se RLS está interferindo
SELECT 
    'Status RLS' as check_type,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '⚠️ RLS ativo - pode causar problemas'
        ELSE '✅ RLS desabilitado'
    END as rls_status
FROM pg_tables 
WHERE tablename IN ('app_users', 'passengers') 
    AND schemaname = 'public'
ORDER BY tablename;

-- PASSO 8: Verificar políticas ativas
SELECT 
    'Políticas RLS ativas' as check_type,
    tablename,
    policyname,
    cmd,
    permissive,
    roles
FROM pg_policies 
WHERE tablename IN ('app_users', 'passengers') 
    AND schemaname = 'public'
ORDER BY tablename, policyname;

-- PASSO 9: Teste final de limpeza (opcional)
CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS json AS $$
DECLARE
    result json;
BEGIN
    -- Remover dados de teste
    DELETE FROM passengers WHERE user_id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';
    DELETE FROM app_users WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';
    
    result := json_build_object(
        'success', true,
        'message', 'Dados de teste removidos com sucesso',
        'note', 'O app agora deve conseguir criar o usuário normalmente'
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 10: Resumo final
SELECT 
    json_build_object(
        'timestamp', NOW(),
        'verification', 'conflict_409_fix',
        'database_ready', NOT EXISTS(
            SELECT 1 FROM app_users 
            WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa'
               OR email = 'asdfadsf@gmail.com'
               OR phone = '(11) 9 9999-9999'
        ),
        'rls_status', (
            SELECT COUNT(*) = 0 
            FROM pg_tables 
            WHERE tablename = 'app_users' 
                AND schemaname = 'public' 
                AND rowsecurity = true
        ),
        'next_steps', array[
            'Teste o cadastro no app Flutter',
            'Se ainda falhar, execute: SELECT cleanup_test_data();',
            'Monitore os logs do app para confirmar'
        ]
    ) as final_summary;

-- INSTRUÇÕES FINAIS:
-- 1. Execute este script após fix_conflict_409.sql
-- 2. Verifique se todos os testes retornam success: true
-- 3. Se algum teste falhar, analise o erro específico
-- 4. Execute cleanup_test_data() se quiser limpar os dados de teste
-- 5. Teste o cadastro no app Flutter

-- COMANDOS DE LIMPEZA (se necessário):
-- SELECT cleanup_test_data(); -- Remove dados de teste
-- DROP FUNCTION IF EXISTS test_complete_user_insert();
-- DROP FUNCTION IF EXISTS test_passenger_creation();
-- DROP FUNCTION IF EXISTS cleanup_test_data();