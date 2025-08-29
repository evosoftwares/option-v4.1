-- ===============================================
-- ESTRATÉGIA ALTERNATIVA: CRIAR PRÓPRIO SISTEMA DE AUTH
-- ===============================================
-- Se o Supabase Auth continuar falhando, criamos nosso próprio sistema

-- PASSO 1: Criar tabela de autenticação própria
CREATE TABLE IF NOT EXISTS custom_auth (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    password_hash text NOT NULL,
    full_name text NOT NULL,
    phone text,
    user_type text NOT NULL CHECK (user_type IN ('passenger', 'driver')),
    email_verified boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_login timestamp with time zone,
    login_attempts integer DEFAULT 0,
    locked_until timestamp with time zone
);

-- PASSO 2: Função para hash de senha
CREATE OR REPLACE FUNCTION hash_password(password text)
RETURNS text AS $$
BEGIN
    RETURN crypt(password, gen_salt('bf', 10));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 3: Função para verificar senha
CREATE OR REPLACE FUNCTION verify_password(password text, hash text)
RETURNS boolean AS $$
BEGIN
    RETURN hash = crypt(password, hash);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 4: Função de registro personalizada
CREATE OR REPLACE FUNCTION custom_signup(
    p_email text,
    p_password text,
    p_full_name text,
    p_phone text DEFAULT NULL,
    p_user_type text DEFAULT 'passenger'
)
RETURNS json AS $$
DECLARE
    new_user_id uuid;
    password_hash text;
BEGIN
    -- Validações básicas
    IF length(p_password) < 6 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Password must be at least 6 characters'
        );
    END IF;
    
    IF p_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid email format'
        );
    END IF;
    
    -- Verificar se email já existe
    IF EXISTS (SELECT 1 FROM custom_auth WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email already registered'
        );
    END IF;
    
    -- Hash da senha
    password_hash := hash_password(p_password);
    
    -- Inserir novo usuário
    INSERT INTO custom_auth (
        email, 
        password_hash, 
        full_name, 
        phone, 
        user_type,
        email_verified
    ) VALUES (
        lower(trim(p_email)),
        password_hash,
        trim(p_full_name),
        trim(p_phone),
        p_user_type,
        true  -- Para simplificar, consideramos verificado
    ) RETURNING id INTO new_user_id;
    
    -- Criar registro correspondente em app_users
    INSERT INTO app_users (
        id,
        email,
        full_name,
        phone,
        user_type,
        status
    ) VALUES (
        new_user_id,
        lower(trim(p_email)),
        trim(p_full_name),
        COALESCE(trim(p_phone), ''),
        p_user_type,
        'active'
    );
    
    -- Criar registro específico por tipo
    IF p_user_type = 'passenger' THEN
        INSERT INTO passengers (id, user_id) VALUES (gen_random_uuid(), new_user_id);
    ELSE
        INSERT INTO drivers (id, user_id, approval_status, is_online) 
        VALUES (gen_random_uuid(), new_user_id, 'pending', false);
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'user_id', new_user_id,
        'email', lower(trim(p_email)),
        'full_name', trim(p_full_name),
        'user_type', p_user_type,
        'message', 'Account created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 5: Função de login personalizada
CREATE OR REPLACE FUNCTION custom_login(
    p_email text,
    p_password text
)
RETURNS json AS $$
DECLARE
    user_record custom_auth%ROWTYPE;
    app_user_record app_users%ROWTYPE;
BEGIN
    -- Buscar usuário
    SELECT * INTO user_record
    FROM custom_auth 
    WHERE email = lower(trim(p_email));
    
    -- Verificar se usuário existe
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid email or password'
        );
    END IF;
    
    -- Verificar se conta não está bloqueada
    IF user_record.locked_until IS NOT NULL AND user_record.locked_until > now() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Account temporarily locked. Try again later.'
        );
    END IF;
    
    -- Verificar senha
    IF NOT verify_password(p_password, user_record.password_hash) THEN
        -- Incrementar tentativas de login
        UPDATE custom_auth 
        SET login_attempts = login_attempts + 1,
            locked_until = CASE 
                WHEN login_attempts >= 4 THEN now() + interval '15 minutes'
                ELSE NULL
            END
        WHERE id = user_record.id;
        
        RETURN json_build_object(
            'success', false,
            'error', 'Invalid email or password'
        );
    END IF;
    
    -- Login bem-sucedido - resetar tentativas e atualizar último login
    UPDATE custom_auth 
    SET login_attempts = 0,
        locked_until = NULL,
        last_login = now()
    WHERE id = user_record.id;
    
    -- Buscar dados completos do app_users
    SELECT * INTO app_user_record
    FROM app_users
    WHERE id = user_record.id;
    
    RETURN json_build_object(
        'success', true,
        'user_id', user_record.id,
        'email', user_record.email,
        'full_name', user_record.full_name,
        'phone', user_record.phone,
        'user_type', user_record.user_type,
        'email_verified', user_record.email_verified,
        'last_login', user_record.last_login,
        'app_user', row_to_json(app_user_record),
        'message', 'Login successful'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 6: Dar permissões
GRANT EXECUTE ON FUNCTION custom_signup TO anon, authenticated;
GRANT EXECUTE ON FUNCTION custom_login TO anon, authenticated;

-- PASSO 7: Teste das funções
SELECT 'Testing custom_signup' as test;
SELECT custom_signup(
    'test_custom@example.com',
    'password123',
    'Usuário Teste Custom',
    '+5511999887766',
    'passenger'
);

SELECT 'Testing custom_login' as test;
SELECT custom_login('test_custom@example.com', 'password123');

-- PASSO 8: Limpeza do teste
DELETE FROM passengers WHERE user_id IN (SELECT id FROM custom_auth WHERE email = 'test_custom@example.com');
DELETE FROM app_users WHERE email = 'test_custom@example.com';
DELETE FROM custom_auth WHERE email = 'test_custom@example.com';

RAISE NOTICE '=== CUSTOM AUTH SYSTEM READY ===';
RAISE NOTICE 'Functions available:';
RAISE NOTICE '- custom_signup(email, password, full_name, phone, user_type)';
RAISE NOTICE '- custom_login(email, password)';
RAISE NOTICE 'Use these via supabase.rpc() in your Flutter app';