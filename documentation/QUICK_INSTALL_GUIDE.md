# ⚡ Guia de Instalação Rápida - Sistema Auth Corrections

## 🎯 **Erro Atual**
```
ERROR: 42883: function create_migration_backup() does not exist
```

**Causa**: As funções SQL ainda não foram instaladas no banco Supabase.

## 🔧 **Solução (3 Passos)**

### **PASSO 1: Instalar Funções de Backup**

No Supabase SQL Editor, copie e execute TODO o conteúdo do arquivo:
```
📁 database/backup_and_rollback.sql
```

**Conteúdo para executar:**

```sql
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
    
    -- Verificar usuários sem auth correspondente (simplificado)
    missing_auth_users := 0; -- Não conseguimos acessar auth.users diretamente
    
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
    
    -- Calcular score de integridade (0-100)
    IF total_users = 0 THEN
        integrity_score := 0;
    ELSE
        integrity_score := GREATEST(0, 100 - (
            (orphaned_passengers + orphaned_drivers + corrupted_names) * 100.0 / total_users
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
    
    RAISE NOTICE 'INTEGRIDADE: Score %, % issues encontrados', integrity_score, COALESCE(array_length(issues, 1), 0);
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

### **PASSO 2: Testar a Instalação**

Após executar o PASSO 1, teste:

```sql
-- Deve funcionar agora
SELECT create_migration_backup();
```

Se funcionou, você verá algo como:
```json
{
  "status": "success", 
  "timestamp": "2024-08-25...",
  "app_users_backed_up": 123,
  "passengers_backed_up": 45, 
  "drivers_backed_up": 67
}
```

### **PASSO 3: Instalar Resto do Sistema (Opcional)**

Se quiser o sistema completo, execute também:

1. **Correção de dados corrompidos**: `database/safe_data_correction.sql`
2. **Triggers de sincronização**: `database/auth_sync_triggers.sql`

## ✅ **Verificação Final**

Após a instalação, estes comandos devem funcionar:

```sql
-- Backup
SELECT create_migration_backup();

-- Validação de integridade  
SELECT validate_data_integrity();

-- Se instalou correção de dados
SELECT * FROM identify_corrupted_users();
```

## 🚨 **Importante**

- Execute **apenas** o conteúdo dos arquivos SQL no Supabase
- **NÃO** execute comandos como `\i` (são específicos do PostgreSQL local)
- Os arquivos `.dart` ficam no projeto Flutter, **NÃO** no banco

## 📞 **Em Caso de Erro**

Se der erro durante a instalação:

1. **Verifique se tem permissão** para criar funções no Supabase
2. **Execute os comandos um por vez** para identificar onde falha  
3. **Verifique se as tabelas base existem** (app_users, passengers, drivers)

Após resolver, **toda a funcionalidade estará disponível**! 🎉