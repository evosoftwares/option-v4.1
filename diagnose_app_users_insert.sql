-- =============================================
-- DIAGNÓSTICO ESPECÍFICO PARA INSERÇÃO EM APP_USERS
-- Execute este script no Supabase SQL Editor
-- =============================================

-- PASSO 1: Verificar estrutura da tabela app_users
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'app_users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- PASSO 2: Verificar constraints da tabela
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'app_users' 
AND tc.table_schema = 'public';

-- PASSO 3: Verificar políticas RLS ativas
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
AND schemaname = 'public'
ORDER BY policyname;

-- PASSO 4: Verificar se RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'app_users'
AND schemaname = 'public';

-- PASSO 5: Verificar triggers ativos
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    action_condition
FROM information_schema.triggers 
WHERE event_object_table = 'app_users'
AND event_object_schema = 'public';

-- PASSO 6: Testar inserção simulada (sem executar)
-- Esta query mostra o que seria necessário para uma inserção válida
SELECT 
    'Campos obrigatórios para INSERT:' as info,
    string_agg(
        column_name || ' (' || data_type || ')', 
        ', ' ORDER BY ordinal_position
    ) as required_fields
FROM information_schema.columns 
WHERE table_name = 'app_users' 
AND table_schema = 'public'
AND is_nullable = 'NO'
AND column_default IS NULL;

-- PASSO 7: Verificar se há dados corrompidos que podem causar conflitos
SELECT 
    'Verificação de dados corrompidos' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN email IS NULL OR email = '' THEN 1 END) as invalid_emails,
    COUNT(CASE WHEN full_name IS NULL OR full_name = '' THEN 1 END) as invalid_names,
    COUNT(CASE WHEN phone IS NULL OR phone = '' THEN 1 END) as invalid_phones,
    COUNT(CASE WHEN user_type NOT IN ('passenger', 'driver', 'admin') THEN 1 END) as invalid_user_types
FROM app_users;

-- PASSO 8: Verificar últimos erros de inserção (se houver logs)
SELECT 
    'Últimos logs de erro' as info,
    event_type,
    error_details,
    created_at
FROM auth_sync_logs 
WHERE event_type LIKE '%error%' 
OR error_details IS NOT NULL
ORDER BY created_at DESC 
LIMIT 5;

-- PASSO 9: Função de teste de inserção segura
CREATE OR REPLACE FUNCTION test_app_users_insert_safe()
RETURNS json AS $$
DECLARE
    test_id uuid := gen_random_uuid();
    result json;
    error_msg text;
BEGIN
    -- Tentar inserção de teste
    BEGIN
        INSERT INTO app_users (
            id,
            user_id,
            email,
            full_name,
            phone,
            user_type,
            status
        ) VALUES (
            test_id,
            test_id,
            'test@example.com',
            'Test User',
            '+5511999999999',
            'passenger',
            'active'
        );
        
        -- Se chegou aqui, a inserção funcionou
        result := json_build_object(
            'success', true,
            'message', 'Inserção de teste bem-sucedida',
            'test_id', test_id
        );
        
        -- Limpar o registro de teste
        DELETE FROM app_users WHERE id = test_id;
        
    EXCEPTION WHEN OTHERS THEN
        error_msg := SQLERRM;
        result := json_build_object(
            'success', false,
            'error', error_msg,
            'sqlstate', SQLSTATE
        );
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 10: Executar teste de inserção
SELECT test_app_users_insert_safe() as test_result;

-- PASSO 11: Verificar permissões do role authenticated
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'app_users'
AND table_schema = 'public'
AND grantee = 'authenticated';

-- PASSO 12: Resumo do diagnóstico
SELECT 
    json_build_object(
        'timestamp', NOW(),
        'table_exists', EXISTS(
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'app_users' AND table_schema = 'public'
        ),
        'rls_enabled', (
            SELECT rowsecurity 
            FROM pg_tables 
            WHERE tablename = 'app_users' AND schemaname = 'public'
        ),
        'policies_count', (
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE tablename = 'app_users' AND schemaname = 'public'
        ),
        'triggers_count', (
            SELECT COUNT(*) 
            FROM information_schema.triggers 
            WHERE event_object_table = 'app_users' AND event_object_schema = 'public'
        ),
        'constraints_count', (
            SELECT COUNT(*) 
            FROM information_schema.table_constraints 
            WHERE table_name = 'app_users' AND table_schema = 'public'
        )
    ) as diagnostic_summary;

-- INSTRUÇÕES:
-- 1. Execute este script completo no Supabase SQL Editor
-- 2. Analise os resultados de cada seção
-- 3. Preste atenção especial ao resultado de test_app_users_insert_safe()
-- 4. Se houver erro na função de teste, isso indicará o problema exato
-- 5. Compartilhe os resultados para análise detalhada