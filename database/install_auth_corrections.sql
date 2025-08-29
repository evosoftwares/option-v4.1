-- ===============================================
-- SCRIPT DE INSTALAÇÃO: CORREÇÕES DO SISTEMA AUTH
-- Executa todas as correções de forma controlada
-- ===============================================

-- =============================================
-- VERIFICAÇÕES PRÉ-INSTALAÇÃO
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔍 Verificando pré-requisitos para instalação...';
    
    -- Verificar se estamos no ambiente correto
    IF current_database() = 'postgres' AND current_setting('server_version_num')::integer < 130000 THEN
        RAISE EXCEPTION 'PostgreSQL 13+ requerido para instalação';
    END IF;
    
    -- Verificar se tabelas críticas existem
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'app_users') THEN
        RAISE EXCEPTION 'Tabela app_users não encontrada. Verifique se o schema está correto.';
    END IF;
    
    RAISE NOTICE '✅ Pré-requisitos verificados';
END;
$$;

-- =============================================
-- INSTALAÇÃO FASE 1: FUNÇÕES DE BACKUP
-- =============================================

RAISE NOTICE '📦 Instalando funções de backup e rollback...';

-- Função para verificar se uma função existe
CREATE OR REPLACE FUNCTION function_exists(function_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = function_name 
          AND routine_type = 'FUNCTION'
    );
END;
$$ LANGUAGE plpgsql;

-- Carregar script de backup e rollback
\i backup_and_rollback.sql

-- Verificar se funções foram instaladas
DO $$
BEGIN
    IF NOT function_exists('create_migration_backup') THEN
        RAISE EXCEPTION 'Falha na instalação das funções de backup';
    END IF;
    RAISE NOTICE '✅ Funções de backup instaladas';
END;
$$;

-- =============================================
-- INSTALAÇÃO FASE 2: CORREÇÃO DE DADOS
-- =============================================

RAISE NOTICE '🔧 Instalando sistema de correção de dados...';

-- Carregar script de correção segura
\i safe_data_correction.sql

-- Verificar instalação
DO $$
BEGIN
    IF NOT function_exists('identify_corrupted_users') THEN
        RAISE EXCEPTION 'Falha na instalação das funções de correção';
    END IF;
    RAISE NOTICE '✅ Sistema de correção instalado';
END;
$$;

-- =============================================
-- INSTALAÇÃO FASE 3: TRIGGERS DE SINCRONIZAÇÃO
-- =============================================

RAISE NOTICE '🔄 Instalando sistema de sincronização...';

-- Carregar triggers (INATIVOS por padrão)
\i auth_sync_triggers.sql

-- Verificar instalação
DO $$
BEGIN
    IF NOT function_exists('sync_status_report') THEN
        RAISE EXCEPTION 'Falha na instalação dos triggers de sincronização';
    END IF;
    RAISE NOTICE '✅ Sistema de sincronização instalado (INATIVO)';
END;
$$;

-- =============================================
-- CONFIGURAÇÃO INICIAL SEGURA
-- =============================================

RAISE NOTICE '⚙️ Configurando estado inicial seguro...';

-- Garantir que sincronização está desabilitada
UPDATE sync_control SET enabled = FALSE WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');

-- Criar backup inicial
SELECT create_migration_backup();

-- Executar validação inicial
DO $$
DECLARE
    validation_result json;
BEGIN
    SELECT validate_data_integrity() INTO validation_result;
    RAISE NOTICE '📊 Validação inicial: %', validation_result;
END;
$$;

-- =============================================
-- RELATÓRIO DE INSTALAÇÃO
-- =============================================

CREATE OR REPLACE FUNCTION installation_report()
RETURNS json AS $$
DECLARE
    report json;
BEGIN
    SELECT json_build_object(
        'installation_date', NOW(),
        'database_name', current_database(),
        'postgresql_version', version(),
        'functions_installed', json_build_object(
            'backup_functions', function_exists('create_migration_backup'),
            'correction_functions', function_exists('identify_corrupted_users'),
            'sync_functions', function_exists('sync_status_report')
        ),
        'tables_created', json_build_object(
            'backup_tables', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_app_users_migration'),
            'correction_tables', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'corrupted_users_backup'),
            'sync_tables', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'auth_sync_logs')
        ),
        'triggers_installed', json_build_object(
            'auth_to_app', EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_sync_auth_to_app'),
            'app_to_auth', EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_sync_app_to_auth')
        ),
        'sync_status', (SELECT enabled FROM sync_control WHERE feature_name = 'auth_to_app_sync'),
        'initial_validation', validate_data_integrity()
    ) INTO report;
    
    RETURN report;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- FINALIZAÇÃO DA INSTALAÇÃO
-- =============================================

DO $$
DECLARE
    final_report json;
BEGIN
    RAISE NOTICE '🎉 Finalizando instalação...';
    
    -- Gerar relatório final
    SELECT installation_report() INTO final_report;
    
    RAISE NOTICE '📋 RELATÓRIO DE INSTALAÇÃO:';
    RAISE NOTICE '%', final_report;
    
    -- Verificar se tudo foi instalado corretamente
    IF NOT (
        function_exists('create_migration_backup') AND
        function_exists('identify_corrupted_users') AND
        function_exists('sync_status_report')
    ) THEN
        RAISE EXCEPTION '❌ Instalação incompleta. Verifique os logs acima.';
    END IF;
    
    RAISE NOTICE '✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 PRÓXIMOS PASSOS:';
    RAISE NOTICE '1. Executar testes de integridade no Flutter';
    RAISE NOTICE '2. Configurar feature flags conforme necessário';
    RAISE NOTICE '3. Monitorar logs antes de ativar funcionalidades';
    RAISE NOTICE '4. Consultar AUTH_CORRECTION_IMPLEMENTATION_GUIDE.md';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  IMPORTANTE:';
    RAISE NOTICE '   - Todos os triggers estão INATIVOS por segurança';
    RAISE NOTICE '   - Backup inicial foi criado automaticamente';
    RAISE NOTICE '   - Use enable_auth_sync() apenas após testes completos';
    RAISE NOTICE '';
    
END;
$$;

-- =============================================
-- COMANDOS ÚTEIS PÓS-INSTALAÇÃO
-- =============================================

-- Criar view para comandos úteis
CREATE OR REPLACE VIEW useful_commands AS
SELECT 
    'Verificar integridade' as command,
    'SELECT validate_data_integrity();' as sql_command
UNION ALL
SELECT 
    'Identificar dados corrompidos',
    'SELECT * FROM identify_corrupted_users();'
UNION ALL
SELECT 
    'Status da sincronização',
    'SELECT sync_status_report();'
UNION ALL
SELECT 
    'Relatório de correções',
    'SELECT data_correction_summary();'
UNION ALL
SELECT 
    'Backup completo',
    'SELECT create_migration_backup();'
UNION ALL
SELECT 
    'Habilitar sincronização (CUIDADO!)',
    'SELECT enable_auth_sync(''auth_to_app_sync'');'
UNION ALL
SELECT 
    'Desabilitar sincronização',
    'SELECT disable_auth_sync(''both'');'
UNION ALL
SELECT 
    'Rollback de emergência',
    'SELECT execute_migration_rollback();';

-- Limpeza de funções auxiliares
DROP FUNCTION IF EXISTS function_exists(TEXT);

-- =============================================
-- MENSAGEM FINAL
-- =============================================

RAISE NOTICE '📚 Consulte os comandos úteis:';
RAISE NOTICE '   SELECT * FROM useful_commands;';
RAISE NOTICE '';
RAISE NOTICE '🛠️  Sistema de correção Auth/Cadastro instalado e pronto!';

-- Exibir comandos úteis
SELECT * FROM useful_commands;