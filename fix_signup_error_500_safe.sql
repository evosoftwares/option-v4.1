-- ===============================================
-- CORREÇÃO SEGURA DO ERRO 500 NO SIGNUP (ANTI-DEADLOCK)
-- ===============================================
-- Este script corrige problemas de sincronização evitando deadlocks
-- durante o processo de signup de novos usuários.

-- =============================================
-- 1. SISTEMA DE LOCK EXCLUSIVO PARA EVITAR DEADLOCKS
-- =============================================

-- Usar advisory lock para garantir execução exclusiva
SELECT pg_advisory_lock(12345678);

-- Verificar se já existe uma execução em andamento
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_stat_activity 
        WHERE query LIKE '%fix_signup_error_500%' 
        AND state = 'active' 
        AND pid != pg_backend_pid()
    ) THEN
        RAISE EXCEPTION 'Script já está sendo executado em outro processo. Aguarde a conclusão.';
    END IF;
END $$;

-- =============================================
-- 2. RESOLVER DEADLOCK ATUAL (SE EXISTIR)
-- =============================================

-- Cancelar transações longas que podem estar causando deadlock
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < NOW() - INTERVAL '5 minutes'
  AND query LIKE '%auth_sync_logs%' OR query LIKE '%sync_control%' OR query LIKE '%app_users%';

-- Aguardar um momento para que as transações sejam canceladas
SELECT pg_sleep(2);

-- =============================================
-- 3. OPERAÇÕES DDL EM ORDEM SEGURA (ANTI-DEADLOCK)
-- =============================================

-- ETAPA 1: Remover políticas existentes primeiro (ordem inversa de dependência)
BEGIN;
    DROP POLICY IF EXISTS "Users can update own data" ON app_users;
    DROP POLICY IF EXISTS "Users can view own data" ON app_users;
    DROP POLICY IF EXISTS "Allow signup to create app_users" ON app_users;
COMMIT;

BEGIN;
    DROP POLICY IF EXISTS "Allow system to manage sync control" ON sync_control;
    DROP POLICY IF EXISTS "Allow admin to read sync logs" ON auth_sync_logs;
    DROP POLICY IF EXISTS "Allow system to insert sync logs" ON auth_sync_logs;
COMMIT;

-- ETAPA 2: Habilitar RLS (operações mais leves)
BEGIN;
    ALTER TABLE auth_sync_logs ENABLE ROW LEVEL SECURITY;
COMMIT;

BEGIN;
    ALTER TABLE sync_control ENABLE ROW LEVEL SECURITY;
COMMIT;

BEGIN;
    ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
COMMIT;

-- ETAPA 3: Criar políticas em ordem de dependência
BEGIN;
    CREATE POLICY "Allow system to insert sync logs" ON auth_sync_logs
        FOR INSERT
        WITH CHECK (true);
COMMIT;

BEGIN;
    CREATE POLICY "Allow admin to read sync logs" ON auth_sync_logs
        FOR SELECT
        USING (auth.role() = 'service_role');
COMMIT;

BEGIN;
    CREATE POLICY "Allow system to manage sync control" ON sync_control
        FOR ALL
        USING (auth.role() = 'service_role');
COMMIT;

BEGIN;
    CREATE POLICY "Allow signup to create app_users" ON app_users
        FOR INSERT
        WITH CHECK (
            auth.uid() = id OR 
            auth.role() = 'service_role'
        );
COMMIT;

BEGIN;
    CREATE POLICY "Users can view own data" ON app_users
        FOR SELECT
        USING (
            auth.uid() = id OR 
            auth.role() = 'service_role'
        );
COMMIT;

BEGIN;
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
COMMIT;

-- =============================================
-- 4. ATUALIZAR CONFIGURAÇÃO DE TRIGGERS (OPERAÇÃO SEGURA)
-- =============================================

BEGIN;
    UPDATE sync_control 
    SET enabled = FALSE, updated_at = NOW()
    WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');
COMMIT;

-- =============================================
-- 5. FUNÇÃO DE DIAGNÓSTICO MELHORADA (ANTI-DEADLOCK)
-- =============================================

BEGIN;
CREATE OR REPLACE FUNCTION diagnose_signup_issues_safe()
RETURNS json AS $$
DECLARE
    result json;
    lock_acquired boolean := false;
BEGIN
    -- Tentar adquirir lock não-bloqueante
    SELECT pg_try_advisory_lock(87654321) INTO lock_acquired;
    
    IF NOT lock_acquired THEN
        RETURN json_build_object(
            'error', 'Diagnóstico em andamento em outro processo',
            'timestamp', NOW()
        );
    END IF;
    
    -- Executar diagnóstico com timeout
    SET statement_timeout = '30s';
    
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
        ),
        'deadlock_info', json_build_object(
            'active_connections', (
                SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active'
            ),
            'waiting_connections', (
                SELECT COUNT(*) FROM pg_stat_activity WHERE wait_event IS NOT NULL
            )
        )
    ) INTO result;
    
    -- Liberar lock
    PERFORM pg_advisory_unlock(87654321);
    
    RESET statement_timeout;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        -- Garantir que o lock seja liberado em caso de erro
        PERFORM pg_advisory_unlock(87654321);
        RESET statement_timeout;
        
        RETURN json_build_object(
            'error', SQLERRM,
            'timestamp', NOW()
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
COMMIT;

-- =============================================
-- 6. EXECUTAR DIAGNÓSTICO SEGURO
-- =============================================

SELECT diagnose_signup_issues_safe();

-- =============================================
-- 7. LIBERAR LOCK EXCLUSIVO
-- =============================================

SELECT pg_advisory_unlock(12345678);

-- =============================================
-- 8. INSTRUÇÕES PARA RESOLVER DEADLOCK ATUAL
-- =============================================

/*
SE VOCÊ ESTÁ VENDO ESTE SCRIPT DEVIDO A UM DEADLOCK:

1. PRIMEIRO, RESOLVA O DEADLOCK ATUAL:
   
   -- Verificar processos em deadlock
   SELECT pid, state, query_start, query 
   FROM pg_stat_activity 
   WHERE state IN ('active', 'idle in transaction')
   AND query LIKE '%auth_sync_logs%' OR query LIKE '%sync_control%' OR query LIKE '%app_users%';
   
   -- Cancelar processos problemáticos (substitua PID pelos valores reais)
   SELECT pg_cancel_backend(PID_DO_PROCESSO);
   
   -- Se necessário, forçar término
   SELECT pg_terminate_backend(PID_DO_PROCESSO);

2. AGUARDE 30 SEGUNDOS para que todas as transações sejam finalizadas

3. EXECUTE ESTE SCRIPT SEGURO em vez do original

4. MONITORE com: SELECT diagnose_signup_issues_safe();

5. TESTE o signup após a execução

OPÇÃO DE EMERGÊNCIA (se deadlock persistir):
-- Desabilitar triggers temporariamente
DROP TRIGGER IF EXISTS trigger_sync_auth_to_app ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;
*/

-- Script anti-deadlock executado com sucesso!
-- Execute: SELECT diagnose_signup_issues_safe(); para verificar o status
-- Teste o signup novamente.