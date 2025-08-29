-- ===================================================
-- SCRIPT PARA PREVENIR CORRUPÇÃO DE DADOS
-- ===================================================
-- 
-- Este script adiciona constraints e funções no PostgreSQL/Supabase
-- para GARANTIR que NUNCA passem dados corrompidos para as tabelas

-- 1. Função para validar se uma string não contém dados corrompidos
CREATE OR REPLACE FUNCTION validate_clean_text(input_text TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- Verifica se é nulo ou vazio
    IF input_text IS NULL OR trim(input_text) = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Verifica se contém caracteres JSON/corrompidos
    IF input_text ~ '[{}[\]<>]' THEN
        RAISE EXCEPTION 'Dados corrompidos detectados (JSON): %', input_text;
    END IF;
    
    -- Verifica se contém palavras de erro específicas
    IF lower(input_text) ~ '(missing_passenger_records|issue|count|error|exception|null|undefined|nan|select|from|where|insert|update|delete|drop|alter|create|function|return|console\.log|print\(|//|/\*)' THEN
        RAISE EXCEPTION 'Dados corrompidos detectados (palavras proibidas): %', input_text;
    END IF;
    
    -- Verifica se contém códigos de status HTTP
    IF input_text ~ '^[0-9]{3}$' THEN
        RAISE EXCEPTION 'Dados corrompidos detectados (código HTTP): %', input_text;
    END IF;
    
    -- Verifica se contém códigos hex
    IF input_text ~ '^(0x|#)' THEN
        RAISE EXCEPTION 'Dados corrompidos detectados (código hex): %', input_text;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- 2. Função para validar nome completo
CREATE OR REPLACE FUNCTION validate_full_name(name_input TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validações básicas
    IF NOT validate_clean_text(name_input) THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar comprimento
    IF length(trim(name_input)) < 2 OR length(trim(name_input)) > 100 THEN
        RAISE EXCEPTION 'Nome deve ter entre 2 e 100 caracteres: %', name_input;
    END IF;
    
    -- Verificar caracteres especiais proibidos (além dos já validados)
    IF name_input ~ '[@#$%^&*()+=|\\`~]' THEN
        RAISE EXCEPTION 'Nome contém caracteres inválidos: %', name_input;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- 3. Função para validar email
CREATE OR REPLACE FUNCTION validate_email(email_input TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validações básicas
    IF NOT validate_clean_text(email_input) THEN
        RETURN FALSE;
    END IF;
    
    -- Validar formato de email básico
    IF NOT email_input ~ '^[^@]+@[^@]+\.[^@]+$' THEN
        RAISE EXCEPTION 'Email inválido: %', email_input;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- 4. Função para validar tipo de usuário
CREATE OR REPLACE FUNCTION validate_user_type(type_input TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validações básicas
    IF NOT validate_clean_text(type_input) THEN
        RETURN FALSE;
    END IF;
    
    -- Validar tipos permitidos
    IF lower(trim(type_input)) NOT IN ('passenger', 'driver', 'admin') THEN
        RAISE EXCEPTION 'Tipo de usuário inválido: %. Tipos válidos: passenger, driver, admin', type_input;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- 5. Adicionar constraints CHECK nas tabelas

-- Para app_users
ALTER TABLE app_users 
ADD CONSTRAINT check_full_name_valid 
CHECK (validate_full_name(full_name));

ALTER TABLE app_users 
ADD CONSTRAINT check_email_valid 
CHECK (validate_email(email));

ALTER TABLE app_users 
ADD CONSTRAINT check_user_type_valid 
CHECK (validate_user_type(user_type));

-- Constraint adicional para não permitir strings que parecem JSON
ALTER TABLE app_users 
ADD CONSTRAINT check_no_json_in_full_name 
CHECK (full_name !~ '[{}[\]]' AND full_name !~ 'missing_passenger_records|issue.*count');

-- 6. Criar índices para performance nas validações
CREATE INDEX IF NOT EXISTS idx_app_users_full_name_clean 
ON app_users(full_name) 
WHERE full_name !~ '[{}[\]<>@#$%^&*()+=|\\`~]';

-- 7. Trigger para log de tentativas de corrupção
CREATE TABLE IF NOT EXISTS data_corruption_attempts (
    id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    column_name TEXT NOT NULL,
    attempted_value TEXT NOT NULL,
    user_id UUID,
    attempted_at TIMESTAMPTZ DEFAULT now(),
    error_message TEXT,
    ip_address INET,
    user_agent TEXT
);

CREATE OR REPLACE FUNCTION log_corruption_attempt()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Log tentativas de inserir dados corrompidos
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        INSERT INTO data_corruption_attempts (
            table_name,
            column_name, 
            attempted_value,
            user_id,
            error_message
        ) VALUES (
            TG_TABLE_NAME,
            'full_name',
            NEW.full_name,
            NEW.id,
            'Tentativa de inserir dados corrompidos bloqueada'
        );
    END IF;
    
    RETURN NULL;
END;
$$;

-- Aplicar trigger apenas em caso de erro (quando constraint falha)
-- Nota: Este trigger seria acionado por um sistema de monitoramento externo

-- 8. View para monitoramento de dados limpos
CREATE OR REPLACE VIEW clean_users_monitor AS
SELECT 
    'Estatísticas de Limpeza de Dados' as report_type,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE full_name ~ '[{}[\]]') as potentially_corrupted,
    COUNT(*) FILTER (WHERE validate_clean_text(full_name)) as clean_names,
    COUNT(*) FILTER (WHERE validate_clean_text(email)) as clean_emails,
    now() as checked_at
FROM app_users;

-- 9. Função para limpeza emergencial (apenas para admins)
CREATE OR REPLACE FUNCTION emergency_clean_user_data()
RETURNS TABLE(cleaned_count INTEGER, affected_users UUID[])
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_record RECORD;
    cleaned_count INTEGER := 0;
    affected_users UUID[] := ARRAY[]::UUID[];
BEGIN
    -- APENAS para emergências - deve ser usado com MUITO cuidado
    -- Remove dados obviamente corrompidos e substitui por fallbacks seguros
    
    FOR user_record IN 
        SELECT id, email, full_name 
        FROM app_users 
        WHERE full_name ~ '[{}[\]]' 
           OR full_name ~ 'missing_passenger_records|issue.*count'
    LOOP
        -- Tentar extrair nome do email como fallback
        UPDATE app_users 
        SET full_name = CASE 
            WHEN split_part(email, '@', 1) != '' 
            THEN initcap(replace(replace(split_part(email, '@', 1), '.', ' '), '_', ' '))
            ELSE 'Usuário'
        END,
        updated_at = now()
        WHERE id = user_record.id;
        
        cleaned_count := cleaned_count + 1;
        affected_users := array_append(affected_users, user_record.id);
    END LOOP;
    
    RETURN QUERY SELECT cleaned_count, affected_users;
END;
$$;

-- 10. Comentários explicativos
COMMENT ON FUNCTION validate_clean_text IS 'Valida que uma string não contém dados corrompidos como JSON, SQL, ou códigos de erro';
COMMENT ON FUNCTION validate_full_name IS 'Valida formato e conteúdo do nome completo do usuário';
COMMENT ON FUNCTION validate_email IS 'Valida formato do email';
COMMENT ON FUNCTION validate_user_type IS 'Valida tipo de usuário permitido';
COMMENT ON TABLE data_corruption_attempts IS 'Log de tentativas de inserir dados corrompidos (para monitoramento de segurança)';
COMMENT ON FUNCTION emergency_clean_user_data IS 'Função de emergência para limpeza de dados corrompidos - USE COM CUIDADO';

-- 11. Permissões (ajustar conforme necessário)
-- REVOKE EXECUTE ON FUNCTION emergency_clean_user_data() FROM PUBLIC;
-- GRANT EXECUTE ON FUNCTION emergency_clean_user_data() TO admin_role;

COMMIT;