-- =============================================
-- CORREÇÃO DO ERRO SYNC_CONTROL
-- =============================================
-- Este script corrige o erro "relation sync_control does not exist"
-- que ocorre durante updates na tabela app_users

-- Opção 1: Desabilitar temporariamente o trigger problemático
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;

-- Opção 2: Criar uma versão simplificada da função que não depende de sync_control
CREATE OR REPLACE FUNCTION controlled_sync_app_to_auth()
RETURNS TRIGGER AS $$
BEGIN
    -- Sincronização desabilitada por padrão até configuração adequada
    -- Log de sincronização desabilitada (apenas se tabela auth_sync_logs existir)
    BEGIN
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
            'Sincronização desabilitada - sync_control não configurado',
            'skipped'
        );
    EXCEPTION WHEN OTHERS THEN
        -- Se auth_sync_logs também não existir, apenas ignora
        NULL;
    END;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Opção 3: Criar uma versão simplificada da função is_sync_enabled
CREATE OR REPLACE FUNCTION is_sync_enabled(feature_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Verificar se a tabela sync_control existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'sync_control' 
        AND table_schema = 'public'
    ) THEN
        -- Se existe, usar a lógica original
        DECLARE
            enabled_status BOOLEAN;
        BEGIN
            SELECT enabled INTO enabled_status 
            FROM sync_control 
            WHERE sync_control.feature_name = is_sync_enabled.feature_name;
            
            RETURN COALESCE(enabled_status, FALSE);
        END;
    ELSE
        -- Se não existe, retornar FALSE (sincronização desabilitada)
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Verificar se o trigger precisa ser recriado
DO $$
BEGIN
    -- Recriar o trigger apenas se necessário
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_sync_app_to_auth'
        AND event_object_table = 'app_users'
    ) THEN
        CREATE TRIGGER trigger_sync_app_to_auth
            AFTER UPDATE ON app_users
            FOR EACH ROW
            EXECUTE FUNCTION controlled_sync_app_to_auth();
    END IF;
END $$;

-- Verificar o status após a correção
SELECT 
    'Trigger Status' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_sync_app_to_auth'
            AND event_object_table = 'app_users'
        ) THEN 'ATIVO'
        ELSE 'INATIVO'
    END as status;

SELECT 
    'Sync Control Table' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'sync_control'
            AND table_schema = 'public'
        ) THEN 'EXISTE'
        ELSE 'NÃO EXISTE'
    END as status;

-- Testar a função is_sync_enabled
SELECT 
    'Function Test' as check_type,
    is_sync_enabled('app_to_auth_sync') as result;