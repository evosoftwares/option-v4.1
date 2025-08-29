-- ===============================================
-- TRIGGERS BIDIRECIONAIS PARA SINCRONIZAÇÃO
-- auth.users ↔ app_users
-- FASE 2: Migração Incremental Reversível
-- ===============================================

-- =============================================
-- 1. TABELA DE LOG PARA AUDITORIA
-- =============================================

CREATE TABLE IF NOT EXISTS auth_sync_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL, -- 'auth_insert', 'auth_update', 'app_insert', 'app_update'
    user_id UUID NOT NULL,
    operation TEXT NOT NULL, -- 'sync_created', 'sync_updated', 'sync_failed'
    source_table TEXT NOT NULL, -- 'auth.users' ou 'app_users'
    target_table TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    error_message TEXT,
    sync_status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_auth_sync_logs_user_id ON auth_sync_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_sync_logs_event_type ON auth_sync_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_auth_sync_logs_created_at ON auth_sync_logs(created_at);

-- =============================================
-- 2. FUNÇÃO HELPER PARA VALIDAÇÃO DE DADOS
-- =============================================

CREATE OR REPLACE FUNCTION validate_sync_data(
    email TEXT,
    full_name TEXT DEFAULT NULL,
    phone TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Validações básicas
    IF email IS NULL OR email = '' THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar se não é dados corrompidos
    IF full_name IS NOT NULL THEN
        -- Detectar JSON structures
        IF full_name LIKE '%{%}%' OR full_name LIKE '%[%]%' THEN
            RETURN FALSE;
        END IF;
        
        -- Detectar mensagens de erro
        IF full_name LIKE '%missing_passenger_records%' OR 
           full_name LIKE '%error%' OR
           full_name LIKE 'PENDENTE_%' THEN
            RETURN FALSE;
        END IF;
    END IF;
    
    -- Validar telefone
    IF phone IS NOT NULL AND phone LIKE '%-164%' THEN
        RETURN FALSE; -- Telefone com timestamp
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. FUNÇÃO DE SINCRONIZAÇÃO AUTH → APP_USERS
-- =============================================

CREATE OR REPLACE FUNCTION sync_auth_to_app_users()
RETURNS TRIGGER AS $$
DECLARE
    existing_app_user RECORD;
    sync_log_id UUID;
    operation_type TEXT;
BEGIN
    -- Criar log inicial
    INSERT INTO auth_sync_logs (
        event_type,
        user_id,
        operation,
        source_table,
        target_table,
        new_data
    ) VALUES (
        TG_OP || '_auth_user',
        COALESCE(NEW.id, OLD.id),
        'sync_pending',
        'auth.users',
        'app_users',
        CASE WHEN NEW IS NOT NULL 
             THEN row_to_json(NEW) 
             ELSE NULL END
    ) RETURNING id INTO sync_log_id;

    -- Processar diferentes tipos de operações
    IF TG_OP = 'INSERT' THEN
        operation_type := 'sync_created';
        
        -- Verificar se já existe app_user
        SELECT * INTO existing_app_user 
        FROM app_users 
        WHERE id = NEW.id;
        
        IF NOT FOUND THEN
            -- Validar dados antes de inserir
            IF validate_sync_data(NEW.email, NULL, NULL) THEN
                BEGIN
                    -- Criar app_user básico
                    INSERT INTO app_users (
                        id,
                        user_id, -- Manter compatibilidade temporária
                        email,
                        full_name,
                        phone,
                        user_type,
                        status
                    ) VALUES (
                        NEW.id,
                        NEW.id, -- Duplicado temporariamente
                        NEW.email,
                        COALESCE(
                            NEW.raw_user_meta_data->>'full_name',
                            SPLIT_PART(NEW.email, '@', 1)
                        ),
                        NEW.phone,
                        COALESCE(
                            NEW.raw_user_meta_data->>'user_type',
                            'pending'
                        ),
                        'active'
                    );
                    
                    -- Atualizar log de sucesso
                    UPDATE auth_sync_logs 
                    SET operation = operation_type,
                        sync_status = 'completed'
                    WHERE id = sync_log_id;
                    
                EXCEPTION WHEN OTHERS THEN
                    -- Log de erro
                    UPDATE auth_sync_logs 
                    SET operation = 'sync_failed',
                        sync_status = 'failed',
                        error_message = SQLERRM
                    WHERE id = sync_log_id;
                    
                    RAISE WARNING 'Falha na sincronização auth→app_users: %', SQLERRM;
                END;
            ELSE
                -- Dados inválidos detectados
                UPDATE auth_sync_logs 
                SET operation = 'sync_failed',
                    sync_status = 'failed',
                    error_message = 'Dados corrompidos detectados'
                WHERE id = sync_log_id;
            END IF;
        END IF;
        
    ELSIF TG_OP = 'UPDATE' THEN
        operation_type := 'sync_updated';
        
        -- Atualizar app_user correspondente se existir
        IF EXISTS (SELECT 1 FROM app_users WHERE id = NEW.id) THEN
            -- Validar dados antes de atualizar
            IF validate_sync_data(NEW.email, NULL, NULL) THEN
                BEGIN
                    UPDATE app_users 
                    SET 
                        email = NEW.email,
                        phone = NEW.phone,
                        updated_at = NOW()
                    WHERE id = NEW.id;
                    
                    -- Atualizar log de sucesso
                    UPDATE auth_sync_logs 
                    SET operation = operation_type,
                        sync_status = 'completed'
                    WHERE id = sync_log_id;
                    
                EXCEPTION WHEN OTHERS THEN
                    -- Log de erro
                    UPDATE auth_sync_logs 
                    SET operation = 'sync_failed',
                        sync_status = 'failed',
                        error_message = SQLERRM
                    WHERE id = sync_log_id;
                END;
            ELSE
                -- Dados inválidos detectados
                UPDATE auth_sync_logs 
                SET operation = 'sync_failed',
                    sync_status = 'failed',
                    error_message = 'Dados corrompidos detectados'
                WHERE id = sync_log_id;
            END IF;
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        operation_type := 'sync_deleted';
        
        -- Soft delete no app_users
        UPDATE app_users 
        SET status = 'deleted',
            updated_at = NOW()
        WHERE id = OLD.id;
        
        -- Atualizar log
        UPDATE auth_sync_logs 
        SET operation = operation_type,
            sync_status = 'completed'
        WHERE id = sync_log_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. FUNÇÃO DE SINCRONIZAÇÃO APP_USERS → AUTH
-- =============================================

CREATE OR REPLACE FUNCTION sync_app_users_to_auth()
RETURNS TRIGGER AS $$
DECLARE
    sync_log_id UUID;
    operation_type TEXT;
BEGIN
    -- Criar log inicial
    INSERT INTO auth_sync_logs (
        event_type,
        user_id,
        operation,
        source_table,
        target_table,
        new_data
    ) VALUES (
        TG_OP || '_app_user',
        COALESCE(NEW.id, OLD.id),
        'sync_pending',
        'app_users',
        'auth.users',
        CASE WHEN NEW IS NOT NULL 
             THEN row_to_json(NEW) 
             ELSE NULL END
    ) RETURNING id INTO sync_log_id;

    -- Processar diferentes tipos de operações
    IF TG_OP = 'UPDATE' THEN
        operation_type := 'sync_updated';
        
        -- Sincronizar apenas campos específicos para auth.users
        IF (OLD.email != NEW.email OR OLD.phone != NEW.phone) THEN
            -- Validar dados antes de sincronizar
            IF validate_sync_data(NEW.email, NEW.full_name, NEW.phone) THEN
                BEGIN
                    UPDATE auth.users 
                    SET 
                        email = NEW.email,
                        phone = NEW.phone,
                        updated_at = NOW()
                    WHERE id = NEW.id;
                    
                    -- Atualizar log de sucesso
                    UPDATE auth_sync_logs 
                    SET operation = operation_type,
                        sync_status = 'completed'
                    WHERE id = sync_log_id;
                    
                EXCEPTION WHEN OTHERS THEN
                    -- Log de erro
                    UPDATE auth_sync_logs 
                    SET operation = 'sync_failed',
                        sync_status = 'failed',
                        error_message = SQLERRM
                    WHERE id = sync_log_id;
                    
                    RAISE WARNING 'Falha na sincronização app_users→auth: %', SQLERRM;
                END;
            ELSE
                -- Dados inválidos - não sincronizar
                UPDATE auth_sync_logs 
                SET operation = 'sync_failed',
                    sync_status = 'failed',
                    error_message = 'Dados corrompidos - sincronização bloqueada'
                WHERE id = sync_log_id;
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 5. CRIAR TRIGGERS (CONTROLADOS POR FLAG)
-- =============================================

-- Flag para controlar sincronização
CREATE TABLE IF NOT EXISTS sync_control (
    feature_name TEXT PRIMARY KEY,
    enabled BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inserir configurações padrão
INSERT INTO sync_control (feature_name, enabled) 
VALUES 
    ('auth_to_app_sync', FALSE),  -- FASE 1: Desabilitado
    ('app_to_auth_sync', FALSE)   -- FASE 1: Desabilitado
ON CONFLICT (feature_name) DO NOTHING;

-- Função para verificar se sync está habilitado
CREATE OR REPLACE FUNCTION is_sync_enabled(feature_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    enabled_status BOOLEAN;
BEGIN
    SELECT enabled INTO enabled_status 
    FROM sync_control 
    WHERE sync_control.feature_name = is_sync_enabled.feature_name;
    
    RETURN COALESCE(enabled_status, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Trigger com verificação de flag - AUTH → APP_USERS
CREATE OR REPLACE FUNCTION controlled_sync_auth_to_app()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se sincronização está habilitada
    IF is_sync_enabled('auth_to_app_sync') THEN
        RETURN sync_auth_to_app_users();
    END IF;
    
    -- Log de sincronização desabilitada
    INSERT INTO auth_sync_logs (
        event_type,
        user_id,
        operation,
        source_table,
        target_table,
        error_message,
        sync_status
    ) VALUES (
        TG_OP || '_auth_user',
        COALESCE(NEW.id, OLD.id),
        'sync_disabled',
        'auth.users',
        'app_users',
        'Sincronização desabilitada por feature flag',
        'skipped'
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger com verificação de flag - APP_USERS → AUTH
CREATE OR REPLACE FUNCTION controlled_sync_app_to_auth()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se sincronização está habilitada
    IF is_sync_enabled('app_to_auth_sync') THEN
        RETURN sync_app_users_to_auth();
    END IF;
    
    -- Log de sincronização desabilitada
    INSERT INTO auth_sync_logs (
        event_type,
        user_id,
        operation,
        source_table,
        target_table,
        error_message,
        sync_status
    ) VALUES (
        TG_OP || '_app_user',
        COALESCE(NEW.id, OLD.id),
        'sync_disabled',
        'app_users',
        'auth.users',
        'Sincronização desabilitada por feature flag',
        'skipped'
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 6. TRIGGERS PRINCIPAIS (INATIVOS INICIALMENTE)
-- =============================================

-- IMPORTANTE: Triggers criados mas INATIVOS até habilitação manual

-- Trigger: auth.users → app_users
DROP TRIGGER IF EXISTS trigger_sync_auth_to_app ON auth.users;
CREATE TRIGGER trigger_sync_auth_to_app
    AFTER INSERT OR UPDATE OR DELETE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION controlled_sync_auth_to_app();

-- Trigger: app_users → auth.users  
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;
CREATE TRIGGER trigger_sync_app_to_auth
    AFTER UPDATE ON app_users
    FOR EACH ROW
    EXECUTE FUNCTION controlled_sync_app_to_auth();

-- =============================================
-- 7. FUNÇÕES DE CONTROLE E MONITORAMENTO
-- =============================================

-- Habilitar sincronização
CREATE OR REPLACE FUNCTION enable_auth_sync(feature_name TEXT DEFAULT 'both')
RETURNS json AS $$
BEGIN
    IF feature_name = 'both' THEN
        UPDATE sync_control SET enabled = TRUE, updated_at = NOW()
        WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');
    ELSE
        UPDATE sync_control SET enabled = TRUE, updated_at = NOW()
        WHERE sync_control.feature_name = enable_auth_sync.feature_name;
    END IF;
    
    RETURN json_build_object(
        'status', 'enabled',
        'feature', feature_name,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Desabilitar sincronização
CREATE OR REPLACE FUNCTION disable_auth_sync(feature_name TEXT DEFAULT 'both')
RETURNS json AS $$
BEGIN
    IF feature_name = 'both' THEN
        UPDATE sync_control SET enabled = FALSE, updated_at = NOW()
        WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');
    ELSE
        UPDATE sync_control SET enabled = FALSE, updated_at = NOW()
        WHERE sync_control.feature_name = disable_auth_sync.feature_name;
    END IF;
    
    RETURN json_build_object(
        'status', 'disabled',
        'feature', feature_name,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Relatório de sincronização
CREATE OR REPLACE FUNCTION sync_status_report()
RETURNS json AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'sync_features', (
            SELECT json_agg(
                json_build_object(
                    'feature', feature_name,
                    'enabled', enabled,
                    'updated_at', updated_at
                )
            )
            FROM sync_control
        ),
        'recent_sync_events', (
            SELECT json_agg(
                json_build_object(
                    'event_type', event_type,
                    'operation', operation,
                    'sync_status', sync_status,
                    'created_at', created_at
                )
            )
            FROM (
                SELECT * FROM auth_sync_logs 
                ORDER BY created_at DESC 
                LIMIT 10
            ) recent
        ),
        'sync_stats', (
            SELECT json_build_object(
                'total_events', COUNT(*),
                'successful_syncs', COUNT(*) FILTER (WHERE sync_status = 'completed'),
                'failed_syncs', COUNT(*) FILTER (WHERE sync_status = 'failed'),
                'skipped_syncs', COUNT(*) FILTER (WHERE sync_status = 'skipped')
            )
            FROM auth_sync_logs
            WHERE created_at > NOW() - INTERVAL '24 hours'
        ),
        'timestamp', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- EXEMPLO DE USO
-- =============================================

/*
-- 1. VERIFICAR status atual
SELECT sync_status_report();

-- 2. HABILITAR sincronização (CUIDADO!)
-- SELECT enable_auth_sync('auth_to_app_sync');  -- Só auth→app
-- SELECT enable_auth_sync('both');              -- Ambos

-- 3. DESABILITAR se necessário
-- SELECT disable_auth_sync('both');

-- 4. MONITORAR logs de sincronização
SELECT * FROM auth_sync_logs 
ORDER BY created_at DESC 
LIMIT 10;

-- 5. VERIFICAR controles
SELECT * FROM sync_control;
*/

-- =============================================
-- COMENTÁRIOS IMPORTANTES
-- =============================================

/*
IMPORTANTE: 
- Os triggers são criados mas INATIVOS por padrão
- Usar enable_auth_sync() apenas após testes extensivos
- Monitorar auth_sync_logs constantemente após ativação
- Em caso de problemas, usar disable_auth_sync() imediatamente
- Triggers incluem validação de dados corrompidos
- Logs detalhados para auditoria completa
*/