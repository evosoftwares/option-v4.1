-- Script para desabilitar RLS das tabelas relacionadas ao stepper e cadastro
-- Execute este script no painel SQL do Supabase

-- ===== DESABILITAR RLS =====

-- 1. Tabela principal de usuários (app_users) - essencial para cadastro
SELECT 'Desabilitando RLS para app_users...' as status;
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;

-- 2. Tabela de passageiros - criada durante o cadastro
SELECT 'Desabilitando RLS para passengers...' as status;
ALTER TABLE IF EXISTS passengers DISABLE ROW LEVEL SECURITY;

-- 3. Tabela de motoristas - criada durante o cadastro  
SELECT 'Desabilitando RLS para drivers...' as status;
ALTER TABLE IF EXISTS drivers DISABLE ROW LEVEL SECURITY;

-- 4. Tabela de locais salvos - usada no stepper
SELECT 'Desabilitando RLS para saved_places...' as status;
ALTER TABLE IF EXISTS saved_places DISABLE ROW LEVEL SECURITY;

-- 5. View de compatibilidade profiles - usada pelo código legacy
SELECT 'Desabilitando RLS para profiles (se existir)...' as status;
-- Views não têm RLS, mas vamos garantir que as tabelas subjacentes estão OK

-- 6. Outras tabelas relacionadas ao cadastro
SELECT 'Desabilitando RLS para payment_methods...' as status;
ALTER TABLE IF EXISTS payment_methods DISABLE ROW LEVEL SECURITY;

SELECT 'Desabilitando RLS para favorite_locations...' as status;
ALTER TABLE IF EXISTS favorite_locations DISABLE ROW LEVEL SECURITY;

SELECT 'Desabilitando RLS para emergency_contacts...' as status;
ALTER TABLE IF EXISTS emergency_contacts DISABLE ROW LEVEL SECURITY;

-- ===== REMOVER POLÍTICAS EXISTENTES =====

SELECT 'Removendo políticas RLS existentes...' as status;

-- app_users policies
DROP POLICY IF EXISTS "Users can view own data" ON app_users;
DROP POLICY IF EXISTS "Users can update own data" ON app_users;
DROP POLICY IF EXISTS "Allow signup to create app_users" ON app_users;
DROP POLICY IF EXISTS "Enable read access for all users" ON app_users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON app_users;

-- passengers policies
DROP POLICY IF EXISTS "Users can view own passenger data" ON passengers;
DROP POLICY IF EXISTS "Users can update own passenger data" ON passengers;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON passengers;

-- drivers policies
DROP POLICY IF EXISTS "Users can view own driver data" ON drivers;
DROP POLICY IF EXISTS "Users can update own driver data" ON drivers;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON drivers;

-- saved_places policies
DROP POLICY IF EXISTS "Users can manage their own saved places" ON saved_places;
DROP POLICY IF EXISTS "Enable read access for users on their own saved places" ON saved_places;
DROP POLICY IF EXISTS "Enable insert access for users on their own saved places" ON saved_places;
DROP POLICY IF EXISTS "Enable update access for users on their own saved places" ON saved_places;
DROP POLICY IF EXISTS "Enable delete access for users on their own saved places" ON saved_places;

-- payment_methods policies (se existir)
DROP POLICY IF EXISTS "Users can manage their own payment methods" ON payment_methods;

-- favorite_locations policies (se existir)
DROP POLICY IF EXISTS "Users can manage their own favorite locations" ON favorite_locations;

-- emergency_contacts policies (se existir)  
DROP POLICY IF EXISTS "Users can manage their own emergency contacts" ON emergency_contacts;

-- ===== VERIFICAR STATUS =====

SELECT 'Verificando status do RLS após desabilitação...' as status;

SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'app_users', 
    'passengers', 
    'drivers', 
    'saved_places', 
    'payment_methods', 
    'favorite_locations',
    'emergency_contacts'
  )
ORDER BY tablename;

-- ===== TESTE DE FUNCIONALIDADE =====

SELECT 'Executando testes de funcionalidade...' as status;

DO $$
DECLARE
    test_user_id UUID := gen_random_uuid();
    test_email TEXT := 'test_stepper@example.com';
    test_success BOOLEAN := TRUE;
BEGIN
    BEGIN
        -- Teste 1: Inserir em app_users
        INSERT INTO app_users (
            id, 
            email, 
            full_name, 
            phone, 
            user_type, 
            status
        ) VALUES (
            test_user_id,
            test_email,
            'Teste Stepper',
            '11999999999',
            'passenger',
            'active'
        );
        
        RAISE NOTICE 'SUCCESS: app_users insertion working';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR in app_users test: %', SQLERRM;
        test_success := FALSE;
    END;
    
    BEGIN
        -- Teste 2: Inserir em passengers
        INSERT INTO passengers (
            id,
            user_id
        ) VALUES (
            gen_random_uuid(),
            test_user_id
        );
        
        RAISE NOTICE 'SUCCESS: passengers insertion working';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'ERROR in passengers test: %', SQLERRM;
        test_success := FALSE;
    END;
    
    BEGIN
        -- Teste 3: Inserir em saved_places (se existir)
        INSERT INTO saved_places (
            id,
            user_id,
            label,
            address,
            latitude,
            longitude,
            category
        ) VALUES (
            gen_random_uuid(),
            test_user_id,
            'Casa Teste',
            'Rua Teste, 123',
            -23.5505,
            -46.6333,
            'home'
        );
        
        RAISE NOTICE 'SUCCESS: saved_places insertion working';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'INFO: saved_places test failed (table may not exist): %', SQLERRM;
    END;
    
    -- Limpar dados de teste
    DELETE FROM saved_places WHERE user_id = test_user_id;
    DELETE FROM passengers WHERE user_id = test_user_id;  
    DELETE FROM app_users WHERE id = test_user_id;
    
    IF test_success THEN
        RAISE NOTICE '✅ STEPPER/CADASTRO: RLS desabilitado com sucesso para as tabelas principais!';
    ELSE
        RAISE NOTICE '⚠️  STEPPER/CADASTRO: RLS desabilitado, mas alguns testes falharam';
    END IF;
END $$;

-- ===== RESULTADO FINAL =====

SELECT 
    '🎯 RLS Status Final' as info,
    json_build_object(
        'app_users_rls', (
            SELECT rowsecurity 
            FROM pg_tables 
            WHERE schemaname = 'public' AND tablename = 'app_users'
        ),
        'passengers_rls', (
            SELECT rowsecurity 
            FROM pg_tables 
            WHERE schemaname = 'public' AND tablename = 'passengers'
        ),
        'drivers_rls', (
            SELECT rowsecurity 
            FROM pg_tables 
            WHERE schemaname = 'public' AND tablename = 'drivers'
        ),
        'saved_places_rls', (
            SELECT rowsecurity 
            FROM pg_tables 
            WHERE schemaname = 'public' AND tablename = 'saved_places'
        )
    ) as status_final;

SELECT '🚀 Execute este script no Supabase SQL Editor para desabilitar RLS do stepper e cadastro' as instrucoes;