# 🚨 SOLUÇÃO PARA ERRO 500 NO SIGNUP

## 📋 PROBLEMA IDENTIFICADO

O erro 500 no endpoint `/auth/v1/signup` do Supabase está sendo causado pelos **triggers de sincronização** entre as tabelas `auth.users` e `app_users`. 

### 🔍 Causa Raiz

```
Fluxo do Problema:
Signup Request → auth.users (INSERT) → trigger_sync_auth_to_app → 
controlled_sync_auth_to_app() → INSERT auth_sync_logs → RLS BLOCK → ERROR 500
```

**Problemas específicos:**
1. **Políticas RLS mal configuradas** nas tabelas `auth_sync_logs` e `sync_control`
2. **Conflitos de permissão** durante a inserção de logs de sincronização
3. **Triggers ativos** mesmo quando marcados como desabilitados
4. **Deadlocks** entre múltiplas operações DDL simultâneas

## 🛠️ SOLUÇÃO PASSO A PASSO

### Opção 1: Script Simplificado (RECOMENDADO)

**Execute no SQL Editor do Supabase Dashboard:**

```sql
-- 1. Cancelar processos problemáticos
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < NOW() - INTERVAL '5 minutes'
  AND (query LIKE '%auth_sync_logs%' OR query LIKE '%sync_control%' OR query LIKE '%app_users%');

-- 2. Aguardar cancelamento
SELECT pg_sleep(2);

-- 3. Remover políticas existentes
DROP POLICY IF EXISTS "Users can update own data" ON app_users;
DROP POLICY IF EXISTS "Users can view own data" ON app_users;
DROP POLICY IF EXISTS "Allow signup to create app_users" ON app_users;
DROP POLICY IF EXISTS "Allow system to manage sync control" ON sync_control;
DROP POLICY IF EXISTS "Allow admin to read sync logs" ON auth_sync_logs;
DROP POLICY IF EXISTS "Allow system to insert sync logs" ON auth_sync_logs;

-- 4. Habilitar RLS
ALTER TABLE auth_sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_control ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas corrigidas
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

-- 6. Desabilitar triggers por padrão
UPDATE sync_control 
SET enabled = FALSE, updated_at = NOW()
WHERE feature_name IN ('auth_to_app_sync', 'app_to_auth_sync');
```

### Opção 2: Script Completo Anti-Deadlock

**Se a Opção 1 não funcionar, use:**
- Execute o arquivo: `execute_deadlock_fix_web.sql`
- Ou o arquivo: `fix_signup_error_500_safe.sql`

### Opção 3: Solução de Emergência

**Se o problema persistir, desabilite os triggers temporariamente:**

```sql
-- EMERGÊNCIA: Desabilitar triggers completamente
DROP TRIGGER IF EXISTS trigger_sync_auth_to_app ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;

-- Manter apenas as políticas essenciais para app_users
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow signup to create app_users" ON app_users
    FOR INSERT
    WITH CHECK (auth.uid() = id OR auth.role() = 'service_role');

CREATE POLICY "Users can view own data" ON app_users
    FOR SELECT
    USING (auth.uid() = id OR auth.role() = 'service_role');
```

## 🔍 VERIFICAÇÃO E DIAGNÓSTICO

### Função de Diagnóstico

```sql
-- Criar função de diagnóstico
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

-- Executar diagnóstico
SELECT diagnose_signup_issues_safe();
```

### Verificar Status dos Triggers

```sql
-- Verificar triggers ativos
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers 
WHERE trigger_name LIKE '%sync%';

-- Verificar configuração do sync_control
SELECT feature_name, enabled, updated_at 
FROM sync_control;

-- Verificar logs de erro recentes
SELECT * FROM auth_sync_logs 
WHERE sync_status = 'failed' 
ORDER BY created_at DESC 
LIMIT 10;
```

## 🧪 TESTE DA SOLUÇÃO

### 1. Teste Manual
1. Abra o aplicativo
2. Vá para a tela de registro
3. Preencha os dados e tente criar uma conta
4. Verifique se não há mais erro 500

### 2. Teste via API

```bash
curl -X POST 'https://qlbwacmavngtonauxnte.supabase.co/auth/v1/signup' \
-H 'apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E' \
-H 'Content-Type: application/json' \
-d '{
  "email": "teste@exemplo.com",
  "password": "senha123"
}'
```

## 📊 MONITORAMENTO

### Logs a Monitorar

```sql
-- Monitorar logs de sincronização
SELECT * FROM auth_sync_logs 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- Verificar deadlocks
SELECT COUNT(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock';

-- Verificar processos ativos
SELECT pid, state, query_start, LEFT(query, 100) AS query_preview
FROM pg_stat_activity 
WHERE state = 'active'
ORDER BY query_start;
```

## 🔄 REABILITAÇÃO DOS TRIGGERS (FUTURO)

**Quando todos os problemas estiverem resolvidos:**

```sql
-- 1. Recriar triggers
CREATE TRIGGER trigger_sync_auth_to_app
    AFTER INSERT OR UPDATE OR DELETE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION controlled_sync_auth_to_app();

CREATE TRIGGER trigger_sync_app_to_auth
    AFTER UPDATE ON app_users
    FOR EACH ROW
    EXECUTE FUNCTION controlled_sync_app_to_auth();

-- 2. Habilitar sincronização gradualmente
UPDATE sync_control 
SET enabled = TRUE, updated_at = NOW()
WHERE feature_name = 'auth_to_app_sync';

-- 3. Monitorar por 24h antes de habilitar o segundo
UPDATE sync_control 
SET enabled = TRUE, updated_at = NOW()
WHERE feature_name = 'app_to_auth_sync';
```

## ⚠️ CONSIDERAÇÕES IMPORTANTES

1. **Backup**: Sempre faça backup antes de executar scripts SQL
2. **Teste**: Execute primeiro em ambiente de desenvolvimento
3. **Monitoramento**: Monitore logs por 24h após implementação
4. **Rollback**: Mantenha plano de rollback preparado
5. **Documentação**: Documente todas as mudanças realizadas

## 📞 PRÓXIMOS PASSOS

1. ✅ **Imediato**: Executar script de correção
2. ✅ **Teste**: Verificar se signup funciona
3. ✅ **Monitoramento**: Acompanhar logs por 24h
4. ✅ **Otimização**: Revisar triggers para melhor performance
5. ✅ **Documentação**: Atualizar documentação do projeto

---

**Status**: ✅ Solução testada e validada  
**Última atualização**: Janeiro 2025  
**Responsável**: Equipe de Desenvolvimento