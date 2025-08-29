-- ===============================================
-- CORREÇÃO DO ERRO 500 NO SIGNUP DO SUPABASE
-- ===============================================
-- Este script corrige problemas de sincronização que causam erro 500
-- durante o processo de signup de novos usuários.

-- =============================================
-- 1. CONFIGURAR RLS PARA TABELAS DE SINCRONIZAÇÃO
-- =============================================

-- Habilitar RLS nas tabelas de sincronização se não estiver habilitado
ALTER TABLE auth_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_control ENABLE ROW LEVEL SECURITY;

-- Política para permitir inserção de logs durante signup
-- (necessário para que os triggers funcionem)
DROP POLICY IF EXISTS "Allow system to insert sync logs" ON auth_sync_logs;
CREATE POLICY "Allow system to insert sync logs" ON auth_sync_logs
    FOR INSERT
    WITH CHECK (true); -- Permite inserção para qualquer usuário/sistema

-- Política para leitura de logs (apenas para service_role)
DROP POLICY IF EXISTS "Allow admin to read sync logs" ON auth_sync_logs;
CREATE POLICY "Allow admin to read sync logs" ON auth_sync_logs
    FOR SELECT
    USING (auth.role() = 'service_role');

-- Política para sync_control (apenas sistema)
DROP POLICY IF EXISTS "Allow system to manage sync control" ON sync_control;
CREATE POLICY "Allow system to manage sync control" ON sync_control
    FOR ALL
    USING (auth.role() = 'service_role');

-- =============================================
-- 2. VERIFICAR E CORRIGIR CONFIGURAÇÃO DOS TRIGGERS
-- =============================================

-- Garantir que os triggers estão desabilitados por padrão
UPDATE sync_control 
SET enabled = FALSE, updated_at = NOW()
WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');

-- =============================================
-- 3. OPÇÃO TEMPORÁRIA: DESABILITAR TRIGGERS COMPLETAMENTE
-- =============================================
-- Descomente as linhas abaixo se o problema persistir

-- DROP TRIGGER IF EXISTS trigger_sync_auth_to_app ON auth.users;
-- DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;

-- =============================================
-- 4. CONFIGURAR RLS PARA APP_USERS (ESSENCIAL)
-- =============================================

-- Garantir que app_users tem RLS habilitado
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- Política para permitir inserção durante signup
DROP POLICY IF EXISTS "Allow signup to create app_users" ON app_users;
CREATE POLICY "Allow signup to create app_users" ON app_users
    FOR INSERT
    WITH CHECK (
        -- Permite inserção se o ID corresponde ao usuário autenticado
        -- ou se é uma operação do sistema (service_role)
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

-- Política para leitura de próprios dados
DROP POLICY IF EXISTS "Users can view own data" ON app_users;
CREATE POLICY "Users can view own data" ON app_users
    FOR SELECT
    USING (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

-- Política para atualização de próprios dados
DROP POLICY IF EXISTS "Users can update own data" ON app_users;
CREATE POLICY "Users can update own data" ON app_users
    FOR UPDATE
    USING (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    )
    WITH CHECK (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

-- =============================================
-- 5. FUNÇÃO DE DIAGNÓSTICO
-- =============================================

CREATE OR REPLACE FUNCTION diagnose_signup_issues()
RETURNS json AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'timestamp', NOW(),
        'rls_status', json_build_object(
            'auth_sync_logs', (
                SELECT rowsecurity 
                FROM pg_tables 
                WHERE tablename = 'auth_sync_logs' AND schemaname = 'public'
            ),
            'sync_control', (
                SELECT rowsecurity 
                FROM pg_tables 
                WHERE tablename = 'sync_control' AND schemaname = 'public'
            ),
            'app_users', (
                SELECT rowsecurity 
                FROM pg_tables 
                WHERE tablename = 'app_users' AND schemaname = 'public'
            )
        ),
        'sync_control_status', (
            SELECT json_agg(
                json_build_object(
                    'feature', feature_name,
                    'enabled', enabled,
                    'updated_at', updated_at
                )
            )
            FROM sync_control
        ),
        'triggers_status', json_build_object(
            'auth_to_app_trigger', (
                SELECT COUNT(*) > 0
                FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_sync_auth_to_app'
            ),
            'app_to_auth_trigger', (
                SELECT COUNT(*) > 0
                FROM information_schema.triggers 
                WHERE trigger_name = 'trigger_sync_app_to_auth'
            )
        ),
        'recent_errors', (
            SELECT json_agg(
                json_build_object(
                    'event_type', event_type,
                    'operation', operation,
                    'error_message', error_message,
                    'created_at', created_at
                )
            )
            FROM (
                SELECT * FROM auth_sync_logs 
                WHERE sync_status = 'failed' 
                ORDER BY created_at DESC 
                LIMIT 5
            ) recent_errors
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 6. EXECUTAR DIAGNÓSTICO
-- =============================================

-- Executar diagnóstico para verificar o status
SELECT diagnose_signup_issues();

-- =============================================
-- 7. INSTRUÇÕES DE USO
-- =============================================

/*
APÓS EXECUTAR ESTE SCRIPT:

1. Teste o signup novamente
2. Se ainda houver erro 500, execute:
   
   -- Desabilitar triggers temporariamente
   DROP TRIGGER IF EXISTS trigger_sync_auth_to_app ON auth.users;
   DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;
   
3. Para reabilitar os triggers após correção:
   
   -- Recriar triggers
   CREATE TRIGGER trigger_sync_auth_to_app
       AFTER INSERT OR UPDATE OR DELETE ON auth.users
       FOR EACH ROW
       EXECUTE FUNCTION controlled_sync_auth_to_app();
   
   CREATE TRIGGER trigger_sync_app_to_auth
       AFTER UPDATE ON app_users
       FOR EACH ROW
       EXECUTE FUNCTION controlled_sync_app_to_auth();

4. Monitorar logs:
   SELECT * FROM auth_sync_logs ORDER BY created_at DESC LIMIT 10;

5. Verificar status:
   SELECT diagnose_signup_issues();
*/

-- =============================================
-- 8. LIMPEZA DE LOGS ANTIGOS (OPCIONAL)
-- =============================================

-- Remover logs antigos para evitar acúmulo
-- DELETE FROM auth_sync_logs WHERE created_at < NOW() - INTERVAL '7 days';

-- Script de correção do erro 500 no signup executado com sucesso!
-- Execute: SELECT diagnose_signup_issues(); para verificar o status
-- Teste o signup novamente. Se persistir o erro, desabilite os triggers temporariamente.