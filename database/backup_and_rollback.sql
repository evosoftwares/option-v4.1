-- ===============================================
-- SCRIPTS DE BACKUP E ROLLBACK AUTOMÁTICO
-- Correção Segura do Sistema de Auth/Cadastro
-- ===============================================

-- =============================================
-- 1. CRIAÇÃO DE TABELAS DE BACKUP
-- =============================================

-- Backup da tabela app_users (principal)
CREATE TABLE IF NOT EXISTS backup_app_users_migration AS 
SELECT * FROM app_users WHERE 1=0; -- Estrutura sem dados

-- Backup da tabela passengers
CREATE TABLE IF NOT EXISTS backup_passengers_migration AS 
SELECT * FROM passengers WHERE 1=0;

-- Backup da tabela drivers  
CREATE TABLE IF NOT EXISTS backup_drivers_migration AS 
SELECT * FROM drivers WHERE 1=0;

-- =============================================
-- 2. FUNÇÃO DE BACKUP COMPLETO
-- =============================================

CREATE OR REPLACE FUNCTION create_migration_backup()
RETURNS json AS $$
DECLARE
    app_users_count INTEGER;
    passengers_count INTEGER;  
    drivers_count INTEGER;
    result json;
BEGIN
    -- Limpar backups anteriores
    TRUNCATE backup_app_users_migration;
    TRUNCATE backup_passengers_migration;
    TRUNCATE backup_drivers_migration;
    
    -- Fazer backup das tabelas
    INSERT INTO backup_app_users_migration SELECT * FROM app_users;
    INSERT INTO backup_passengers_migration SELECT * FROM passengers;
    INSERT INTO backup_drivers_migration SELECT * FROM drivers;
    
    -- Contar registros copiados
    SELECT COUNT(*) INTO app_users_count FROM backup_app_users_migration;
    SELECT COUNT(*) INTO passengers_count FROM backup_passengers_migration;  
    SELECT COUNT(*) INTO drivers_count FROM backup_drivers_migration;
    
    result := json_build_object(
        'status', 'success',
        'timestamp', NOW(),
        'app_users_backed_up', app_users_count,
        'passengers_backed_up', passengers_count,
        'drivers_backed_up', drivers_count
    );
    
    RAISE NOTICE 'BACKUP COMPLETO: % usuários, % passageiros, % motoristas', 
                 app_users_count, passengers_count, drivers_count;
                 
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. FUNÇÃO DE ROLLBACK COMPLETO
-- =============================================

CREATE OR REPLACE FUNCTION execute_migration_rollback()
RETURNS json AS $$
DECLARE
    app_users_restored INTEGER;
    passengers_restored INTEGER;
    drivers_restored INTEGER;
    result json;
BEGIN
    RAISE NOTICE 'INICIANDO ROLLBACK COMPLETO...';
    
    -- Desabilitar triggers temporariamente para evitar cascata
    SET session_replication_role = replica;
    
    -- Restaurar tabelas na ordem correta (dependências)
    TRUNCATE app_users CASCADE;
    TRUNCATE passengers CASCADE;
    TRUNCATE drivers CASCADE;
    
    -- Restaurar dados do backup
    INSERT INTO app_users SELECT * FROM backup_app_users_migration;
    INSERT INTO passengers SELECT * FROM backup_passengers_migration;
    INSERT INTO drivers SELECT * FROM backup_drivers_migration;
    
    -- Reabilitar triggers
    SET session_replication_role = DEFAULT;
    
    -- Contar registros restaurados
    SELECT COUNT(*) INTO app_users_restored FROM app_users;
    SELECT COUNT(*) INTO passengers_restored FROM passengers;
    SELECT COUNT(*) INTO drivers_restored FROM drivers;
    
    result := json_build_object(
        'status', 'rollback_completed',
        'timestamp', NOW(),
        'app_users_restored', app_users_restored,
        'passengers_restored', passengers_restored,
        'drivers_restored', drivers_restored
    );
    
    RAISE NOTICE 'ROLLBACK COMPLETO: % usuários, % passageiros, % motoristas restaurados', 
                 app_users_restored, passengers_restored, drivers_restored;
                 
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. FUNÇÃO DE VALIDAÇÃO DE INTEGRIDADE
-- =============================================

CREATE OR REPLACE FUNCTION validate_data_integrity()
RETURNS json AS $$
DECLARE
    total_users INTEGER;
    orphaned_passengers INTEGER;
    orphaned_drivers INTEGER;
    corrupted_names INTEGER;
    missing_auth_users INTEGER;
    result json;
    integrity_score DECIMAL;
    issues text[] := '{}';
BEGIN
    RAISE NOTICE 'VALIDANDO INTEGRIDADE DOS DADOS...';
    
    -- Contar total de usuários
    SELECT COUNT(*) INTO total_users FROM app_users;
    
    -- Verificar passageiros órfãos
    SELECT COUNT(*) INTO orphaned_passengers 
    FROM passengers p 
    WHERE NOT EXISTS (SELECT 1 FROM app_users a WHERE a.id = p.user_id);
    
    -- Verificar motoristas órfãos
    SELECT COUNT(*) INTO orphaned_drivers
    FROM drivers d
    WHERE NOT EXISTS (SELECT 1 FROM app_users a WHERE a.id = d.user_id);
    
    -- Verificar nomes corrompidos
    SELECT COUNT(*) INTO corrupted_names
    FROM app_users 
    WHERE full_name LIKE '%{%}%'
       OR full_name LIKE '%[%]%'
       OR full_name LIKE '%missing_passenger_records%'
       OR full_name LIKE '%issue%'
       OR full_name LIKE '%count%'
       OR full_name LIKE '%error%';
    
    -- Verificar usuários sem auth correspondente
    SELECT COUNT(*) INTO missing_auth_users
    FROM app_users a
    WHERE NOT EXISTS (
        SELECT 1 FROM auth.users au WHERE au.id = a.id
    );
    
    -- Adicionar issues encontrados
    IF orphaned_passengers > 0 THEN
        issues := array_append(issues, orphaned_passengers || ' passageiros órfãos');
    END IF;
    
    IF orphaned_drivers > 0 THEN
        issues := array_append(issues, orphaned_drivers || ' motoristas órfãos');
    END IF;
    
    IF corrupted_names > 0 THEN
        issues := array_append(issues, corrupted_names || ' nomes corrompidos');
    END IF;
    
    IF missing_auth_users > 0 THEN
        issues := array_append(issues, missing_auth_users || ' usuários sem auth');
    END IF;
    
    -- Calcular score de integridade (0-100)
    IF total_users = 0 THEN
        integrity_score := 0;
    ELSE
        integrity_score := GREATEST(0, 100 - (
            (orphaned_passengers + orphaned_drivers + corrupted_names + missing_auth_users) * 100.0 / total_users
        ));
    END IF;
    
    result := json_build_object(
        'status', CASE WHEN array_length(issues, 1) = 0 THEN 'healthy' ELSE 'issues_found' END,
        'timestamp', NOW(),
        'total_users', total_users,
        'integrity_score', ROUND(integrity_score, 2),
        'issues', issues,
        'details', json_build_object(
            'orphaned_passengers', orphaned_passengers,
            'orphaned_drivers', orphaned_drivers, 
            'corrupted_names', corrupted_names,
            'missing_auth_users', missing_auth_users
        )
    );
    
    RAISE NOTICE 'INTEGRIDADE: Score %, % issues encontrados', integrity_score, array_length(issues, 1);
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 5. FUNÇÃO DE MONITORAMENTO EM TEMPO REAL
-- =============================================

CREATE OR REPLACE FUNCTION monitor_migration_progress()
RETURNS json AS $$
DECLARE
    current_stats json;
    backup_stats json;
    changes_detected BOOLEAN := FALSE;
    result json;
BEGIN
    -- Stats atuais
    SELECT json_build_object(
        'app_users', (SELECT COUNT(*) FROM app_users),
        'passengers', (SELECT COUNT(*) FROM passengers),
        'drivers', (SELECT COUNT(*) FROM drivers),
        'timestamp', NOW()
    ) INTO current_stats;
    
    -- Stats do backup para comparação
    SELECT json_build_object(
        'app_users', (SELECT COUNT(*) FROM backup_app_users_migration),
        'passengers', (SELECT COUNT(*) FROM backup_passengers_migration),
        'drivers', (SELECT COUNT(*) FROM backup_drivers_migration)
    ) INTO backup_stats;
    
    -- Detectar mudanças
    IF (current_stats->>'app_users')::int != (backup_stats->>'app_users')::int OR
       (current_stats->>'passengers')::int != (backup_stats->>'passengers')::int OR
       (current_stats->>'drivers')::int != (backup_stats->>'drivers')::int THEN
        changes_detected := TRUE;
    END IF;
    
    result := json_build_object(
        'current', current_stats,
        'backup', backup_stats,
        'changes_detected', changes_detected,
        'migration_active', changes_detected
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 6. CIRCUIT BREAKER PARA ROLLBACK AUTOMÁTICO
-- =============================================

CREATE OR REPLACE FUNCTION check_migration_health()
RETURNS json AS $$
DECLARE
    integrity_result json;
    integrity_score DECIMAL;
    issues_count INTEGER;
    should_rollback BOOLEAN := FALSE;
    result json;
BEGIN
    -- Verificar integridade atual
    SELECT validate_data_integrity() INTO integrity_result;
    
    integrity_score := (integrity_result->>'integrity_score')::DECIMAL;
    issues_count := array_length(
        ARRAY(SELECT json_array_elements_text(integrity_result->'issues')), 1
    );
    
    -- Critérios para rollback automático
    IF integrity_score < 95.0 OR issues_count > 5 THEN
        should_rollback := TRUE;
        RAISE WARNING 'CIRCUIT BREAKER ATIVADO: Score=%, Issues=%', integrity_score, issues_count;
    END IF;
    
    result := json_build_object(
        'integrity_score', integrity_score,
        'issues_count', COALESCE(issues_count, 0),
        'should_rollback', should_rollback,
        'status', CASE 
            WHEN should_rollback THEN 'CRITICAL'
            WHEN integrity_score < 98.0 THEN 'WARNING'
            ELSE 'HEALTHY'
        END,
        'timestamp', NOW()
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 7. LIMPEZA DE BACKUP (USAR APENAS APÓS SUCESSO)
-- =============================================

CREATE OR REPLACE FUNCTION cleanup_migration_backup()
RETURNS json AS $$
BEGIN
    DROP TABLE IF EXISTS backup_app_users_migration;
    DROP TABLE IF EXISTS backup_passengers_migration;
    DROP TABLE IF EXISTS backup_drivers_migration;
    
    RETURN json_build_object(
        'status', 'cleanup_completed',
        'timestamp', NOW(),
        'message', 'Tabelas de backup removidas com sucesso'
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- COMENTÁRIOS DE USO
-- =============================================

/* 
COMO USAR ESTES SCRIPTS:

1. ANTES DA MIGRAÇÃO:
   SELECT create_migration_backup();

2. DURANTE A MIGRAÇÃO (monitoramento):
   SELECT monitor_migration_progress();
   SELECT check_migration_health();

3. SE ALGO DER ERRADO:
   SELECT execute_migration_rollback();

4. APÓS SUCESSO CONFIRMADO:
   SELECT cleanup_migration_backup();

EXEMPLO DE USO COMPLETO:
```sql
-- Criar backup
SELECT create_migration_backup();

-- Executar suas mudanças aqui...

-- Verificar integridade
SELECT validate_data_integrity();

-- Se tudo ok, limpar backup
-- SELECT cleanup_migration_backup();

-- Se algo deu errado, fazer rollback
-- SELECT execute_migration_rollback();
```
*/