-- =============================================
-- INVESTIGAÇÃO DO CONFLITO 409 NO CADASTRO
-- Dados problemáticos: {id: e202bc55-61fa-4f18-9003-27dcfb8a12fa, email: asdfadsf@gmail.com, phone: (11) 9 9999-9999}
-- =============================================

-- PASSO 1: Verificar se já existe registro com o mesmo ID
SELECT 
    'Verificação por ID' as check_type,
    id,
    email,
    full_name,
    phone,
    user_type,
    status,
    created_at
FROM app_users 
WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';

-- PASSO 2: Verificar se já existe registro com o mesmo EMAIL
SELECT 
    'Verificação por EMAIL' as check_type,
    id,
    email,
    full_name,
    phone,
    user_type,
    status,
    created_at
FROM app_users 
WHERE email = 'asdfadsf@gmail.com';

-- PASSO 3: Verificar se já existe registro com o mesmo TELEFONE
SELECT 
    'Verificação por TELEFONE' as check_type,
    id,
    email,
    full_name,
    phone,
    user_type,
    status,
    created_at
FROM app_users 
WHERE phone = '(11) 9 9999-9999';

-- PASSO 4: Verificar todas as constraints únicas da tabela app_users
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    tc.table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'app_users' 
    AND tc.table_schema = 'public'
    AND tc.constraint_type = 'UNIQUE'
ORDER BY tc.constraint_name;

-- PASSO 5: Verificar índices únicos
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'app_users' 
    AND schemaname = 'public'
    AND indexdef LIKE '%UNIQUE%';

-- PASSO 6: Função para testar inserção com os dados exatos do erro
CREATE OR REPLACE FUNCTION test_problematic_insert()
RETURNS json AS $$
DECLARE
    result json;
    error_msg text;
    error_detail text;
    error_hint text;
BEGIN
    -- Tentar inserção com os dados exatos que estão falhando
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
            'message', 'Inserção bem-sucedida - não deveria haver conflito'
        );
        
        -- Limpar o registro de teste
        DELETE FROM app_users WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';
        
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS 
            error_msg = MESSAGE_TEXT,
            error_detail = PG_EXCEPTION_DETAIL,
            error_hint = PG_EXCEPTION_HINT;
            
        result := json_build_object(
            'success', false,
            'error', error_msg,
            'detail', error_detail,
            'hint', error_hint,
            'sqlstate', SQLSTATE,
            'constraint_violated', CASE 
                WHEN SQLSTATE = '23505' THEN 'UNIQUE_VIOLATION'
                WHEN SQLSTATE = '23503' THEN 'FOREIGN_KEY_VIOLATION'
                WHEN SQLSTATE = '23514' THEN 'CHECK_VIOLATION'
                ELSE 'OTHER'
            END
        );
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 7: Executar teste com dados problemáticos
SELECT test_problematic_insert() as test_result;

-- PASSO 8: Verificar se há registros órfãos ou corrompidos
SELECT 
    'Registros com problemas' as check_type,
    COUNT(*) as total,
    COUNT(CASE WHEN email IS NULL OR email = '' THEN 1 END) as emails_vazios,
    COUNT(CASE WHEN full_name IS NULL OR full_name = '' THEN 1 END) as nomes_vazios,
    COUNT(CASE WHEN user_type NOT IN ('passenger', 'driver', 'admin') THEN 1 END) as tipos_invalidos
FROM app_users;

-- PASSO 9: Buscar registros duplicados por email
SELECT 
    email,
    COUNT(*) as count,
    array_agg(id) as ids
FROM app_users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- PASSO 10: Buscar registros duplicados por telefone
SELECT 
    phone,
    COUNT(*) as count,
    array_agg(id) as ids
FROM app_users 
WHERE phone IS NOT NULL AND phone != ''
GROUP BY phone 
HAVING COUNT(*) > 1;

-- PASSO 11: Verificar se RLS está interferindo
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN 'RLS pode estar bloqueando a inserção'
        ELSE 'RLS não está interferindo'
    END as rls_status
FROM pg_tables 
WHERE tablename = 'app_users' AND schemaname = 'public';

-- PASSO 12: Listar todas as políticas RLS ativas
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'app_users' AND schemaname = 'public';

-- INSTRUÇÕES DE USO:
-- 1. Execute este script no Supabase SQL Editor
-- 2. Analise cada resultado para identificar o problema
-- 3. O PASSO 7 mostrará exatamente qual constraint está sendo violado
-- 4. Use os resultados para aplicar a correção apropriada

-- POSSÍVEIS SOLUÇÕES:
-- Se for violação de UNIQUE em email: DELETE FROM app_users WHERE email = 'asdfadsf@gmail.com';
-- Se for violação de UNIQUE em phone: DELETE FROM app_users WHERE phone = '(11) 9 9999-9999';
-- Se for violação de UNIQUE em id: DELETE FROM app_users WHERE id = 'e202bc55-61fa-4f18-9003-27dcfb8a12fa';
-- Se for RLS: Execute disable_rls_simple.sql