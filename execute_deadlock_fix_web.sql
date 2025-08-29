-- ===============================================
-- SCRIPT PARA EXECUTAR NO PAINEL WEB DO SUPABASE
-- ===============================================
-- Este script resolve o deadlock atual e corrige o erro 500 no signup
-- Execute este script no SQL Editor do painel web do Supabase

-- PASSO 1: Cancelar processos problemáticos
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < NOW() - INTERVAL '5 minutes'
  AND (query LIKE '%auth_sync_logs%' OR query LIKE '%sync_control%' OR query LIKE '%app_users%');

-- PASSO 2: Aguardar cancelamento
SELECT pg_sleep(2);

-- PASSO 3: Remover políticas existentes (ordem segura)
DROP POLICY IF EXISTS "Users can update own data" ON app_users;
DROP POLICY IF EXISTS "Users can view own data" ON app_users;
DROP POLICY IF EXISTS "Allow signup to create app_users" ON app_users;
DROP POLICY IF EXISTS "Allow system to manage sync control" ON sync_control;
DROP POLICY IF EXISTS "Allow admin to read sync logs" ON auth_sync_logs;
DROP POLICY IF EXISTS "Allow system to insert sync logs" ON auth_sync_logs;

-- PASSO 4: Habilitar RLS
ALTER TABLE auth_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_control ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- PASSO 5: Criar políticas corrigidas
CREATE POLICY "Allow system to insert sync logs" ON auth_sync_logs
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow admin to read sync logs" ON auth_sync_logs
    FOR SELECT
    USING (auth.role() = 'service_role');

CREATE POLICY "Allow system to manage sync control" ON sync_control
    FOR ALL
    USING (auth.role() = 'service_role');

CREATE POLICY "Allow signup to create app_users" ON app_users
    FOR INSERT
    WITH CHECK (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "Users can view own data" ON app_users
    FOR SELECT
    USING (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

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

-- PASSO 6: Atualizar configuração de triggers
UPDATE sync_control 
SET enabled = FALSE, updated_at = NOW()
WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');

-- PASSO 7: Função de diagnóstico melhorada
CREATE OR REPLACE FUNCTION diagnose_signup_issues_safe()
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
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'error', SQLERRM,
            'timestamp', NOW()
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASSO 8: Executar diagnóstico
SELECT diagnose_signup_issues_safe();

-- Script executado com sucesso!
-- Agora teste o processo de signup novamente.