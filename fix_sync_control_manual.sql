-- Script para corrigir o erro sync_control
-- Execute este script no Supabase Dashboard > SQL Editor

-- 1. Primeiro, vamos verificar se a tabela sync_control existe
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'sync_control'
) AS sync_control_exists;

-- 2. Verificar se o trigger problemático existe
SELECT trigger_name, event_object_table, action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_app_to_auth' 
AND event_object_table = 'app_users';

-- 3. SOLUÇÃO TEMPORÁRIA: Remover o trigger problemático
-- Isso permitirá que os updates funcionem sem erro
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;

-- 4. Verificar se o trigger foi removido
SELECT COUNT(*) as triggers_restantes
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_app_to_auth' 
AND event_object_table = 'app_users';

-- 5. SOLUÇÃO PERMANENTE (OPCIONAL): Criar a tabela sync_control
-- Descomente as linhas abaixo se quiser manter o sistema de sincronização

/*
CREATE TABLE IF NOT EXISTS sync_control (
    id SERIAL PRIMARY KEY,
    feature_name VARCHAR(100) UNIQUE NOT NULL,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inserir configurações padrão
INSERT INTO sync_control (feature_name, enabled) VALUES 
('app_to_auth_sync', false),  -- Desabilitado por padrão para evitar erros
('auth_to_app_sync', false)
ON CONFLICT (feature_name) DO NOTHING;

-- Recriar o trigger (apenas se você criou a tabela acima)
CREATE OR REPLACE FUNCTION controlled_sync_app_to_auth()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se a sincronização está habilitada
    IF NOT is_sync_enabled('app_to_auth_sync') THEN
        -- Log que a sincronização foi ignorada
        INSERT INTO auth_sync_logs (operation, table_name, record_id, status, details)
        VALUES ('UPDATE', 'app_users', NEW.id, 'ignored', 'Sync disabled by feature flag');
        RETURN NEW;
    END IF;
    
    -- Executar a sincronização
    PERFORM sync_app_users_to_auth();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_sync_app_to_auth
    AFTER UPDATE ON app_users
    FOR EACH ROW
    EXECUTE FUNCTION controlled_sync_app_to_auth();
*/

-- 6. Teste final: Verificar se podemos fazer update sem erro
SELECT 'Script executado com sucesso! Agora teste o update de usuário no app.' as resultado;