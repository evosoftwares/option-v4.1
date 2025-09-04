-- Script de Monitoramento dos Logs de Sincronização
-- Execute este script no SQL Editor do Supabase para monitorar o sistema

-- ========================================
-- 1. VERIFICAR STATUS GERAL DO SISTEMA
-- ========================================

SELECT 
    'SISTEMA DE SINCRONIZAÇÃO - STATUS GERAL' as titulo,
    NOW() as timestamp_verificacao;

-- ========================================
-- 2. STATUS DAS POLÍTICAS RLS
-- ========================================

SELECT 
    'POLÍTICAS RLS' as categoria,
    schemaname,
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE tablename IN ('auth_sync_logs', 'sync_control', 'app_users')
    AND schemaname = 'public'
ORDER BY tablename;

-- ========================================
-- 3. CONFIGURAÇÃO DO SYNC_CONTROL
-- ========================================

SELECT 
    'CONFIGURAÇÃO SYNC_CONTROL' as categoria,
    feature_name,
    enabled,
    updated_at,
    CASE 
        WHEN enabled THEN '🟢 ATIVO'
        ELSE '🔴 DESABILITADO'
    END as status_visual
FROM sync_control
ORDER BY feature_name;

-- ========================================
-- 4. TRIGGERS ATIVOS
-- ========================================

SELECT 
    'TRIGGERS ATIVOS' as categoria,
    trigger_name,
    event_manipulation,
    action_timing,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_name LIKE '%sync%'
ORDER BY trigger_name;

-- ========================================
-- 5. LOGS DE ERRO RECENTES (ÚLTIMAS 24H)
-- ========================================

SELECT 
    'LOGS DE ERRO - ÚLTIMAS 24H' as categoria,
    event_type,
    operation,
    sync_status,
    error_message,
    created_at,
    AGE(NOW(), created_at) as tempo_decorrido
FROM auth_sync_logs 
WHERE sync_status = 'failed' 
    AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 20;

-- ========================================
-- 6. ESTATÍSTICAS DE SINCRONIZAÇÃO
-- ========================================

SELECT 
    'ESTATÍSTICAS DE SINCRONIZAÇÃO' as categoria,
    sync_status,
    COUNT(*) as total_eventos,
    MIN(created_at) as primeiro_evento,
    MAX(created_at) as ultimo_evento
FROM auth_sync_logs 
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY sync_status
ORDER BY sync_status;

-- ========================================
-- 7. VERIFICAR DEADLOCKS ATIVOS
-- ========================================

SELECT 
    'DEADLOCKS E LOCKS ATIVOS' as categoria,
    pid,
    state,
    wait_event_type,
    wait_event,
    query_start,
    AGE(NOW(), query_start) as duracao,
    LEFT(query, 100) as query_preview
FROM pg_stat_activity 
WHERE state = 'active'
    AND wait_event_type = 'Lock'
ORDER BY query_start;

-- ========================================
-- 8. PROCESSOS LONGOS (>5 MINUTOS)
-- ========================================

SELECT 
    'PROCESSOS LONGOS' as categoria,
    pid,
    state,
    query_start,
    AGE(NOW(), query_start) as duracao,
    LEFT(query, 150) as query_preview
FROM pg_stat_activity 
WHERE state = 'active'
    AND query_start < NOW() - INTERVAL '5 minutes'
    AND query NOT LIKE '%pg_stat_activity%'
ORDER BY query_start;

-- ========================================
-- 9. VERIFICAR INTEGRIDADE DOS DADOS
-- ========================================

-- Usuários em auth.users mas não em app_users
SELECT 
    'USUÁRIOS ÓRFÃOS - AUTH SEM APP_USERS' as categoria,
    COUNT(*) as total_usuarios_orfaos
FROM auth.users au
LEFT JOIN app_users ap ON au.id = ap.id
WHERE ap.id IS NULL
    AND au.created_at > NOW() - INTERVAL '24 hours';

-- Usuários em app_users mas não em auth.users
SELECT 
    'USUÁRIOS ÓRFÃOS - APP_USERS SEM AUTH' as categoria,
    COUNT(*) as total_usuarios_orfaos
FROM app_users ap
LEFT JOIN auth.users au ON ap.id = au.id
WHERE au.id IS NULL;

-- ========================================
-- 10. RESUMO FINAL
-- ========================================

SELECT 
    'RESUMO FINAL' as categoria,
    (
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM auth_sync_logs 
                WHERE sync_status = 'failed' 
                    AND created_at > NOW() - INTERVAL '1 hour'
            ) THEN '❌ ERROS RECENTES DETECTADOS'
            ELSE '✅ SISTEMA FUNCIONANDO NORMALMENTE'
        END
    ) as status_sistema,
    (
        SELECT COUNT(*) 
        FROM auth_sync_logs 
        WHERE sync_status = 'failed' 
            AND created_at > NOW() - INTERVAL '24 hours'
    ) as erros_ultimas_24h,
    (
        SELECT COUNT(*) 
        FROM pg_stat_activity 
        WHERE state = 'active' 
            AND wait_event_type = 'Lock'
    ) as deadlocks_ativos,
    NOW() as timestamp_verificacao;

-- ========================================
-- COMANDOS ÚTEIS PARA RESOLUÇÃO DE PROBLEMAS
-- ========================================

/*
-- CANCELAR PROCESSOS PROBLEMÁTICOS (SE NECESSÁRIO)
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < NOW() - INTERVAL '10 minutes'
  AND (query LIKE '%auth_sync_logs%' OR query LIKE '%sync_control%');

-- LIMPAR LOGS ANTIGOS (SE NECESSÁRIO)
DELETE FROM auth_sync_logs 
WHERE created_at < NOW() - INTERVAL '7 days';

-- REABILITAR SINCRONIZAÇÃO (QUANDO SEGURO)
UPDATE sync_control 
SET enabled = TRUE, updated_at = NOW()
WHERE feature_name = 'auth_to_app_sync';

-- DESABILITAR SINCRONIZAÇÃO (EM EMERGÊNCIA)
UPDATE sync_control 
SET enabled = FALSE, updated_at = NOW()
WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');
*/

-- ========================================
-- FIM DO SCRIPT DE MONITORAMENTO
-- ========================================

SELECT 
    '🎯 MONITORAMENTO CONCLUÍDO' as resultado,
    'Execute este script regularmente para monitorar o sistema' as instrucao,
    NOW() as timestamp_final;