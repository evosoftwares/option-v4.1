# Guia de Resolução de Deadlock - Erro 500 Signup

## Problema Identificado

**Erro**: `40P01: deadlock detected`

**Causa**: Múltiplos processos tentando executar operações DDL (ALTER TABLE, CREATE/DROP POLICY) simultaneamente nas tabelas `auth_sync_logs`, `sync_control` e `app_users`, criando um deadlock circular.

## Resolução Imediata

### 1. Identificar Processos em Deadlock

```sql
-- Verificar processos ativos que podem estar causando deadlock
SELECT 
    pid, 
    state, 
    query_start, 
    NOW() - query_start AS duration,
    LEFT(query, 100) AS query_preview
FROM pg_stat_activity 
WHERE state IN ('active', 'idle in transaction')
  AND (query LIKE '%auth_sync_logs%' 
       OR query LIKE '%sync_control%' 
       OR query LIKE '%app_users%'
       OR query LIKE '%fix_signup_error_500%')
ORDER BY query_start;
```

### 2. Cancelar Processos Problemáticos

```sql
-- Cancelar processos que estão rodando há mais de 5 minutos
SELECT pg_cancel_backend(pid)
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < NOW() - INTERVAL '5 minutes'
  AND (query LIKE '%auth_sync_logs%' 
       OR query LIKE '%sync_control%' 
       OR query LIKE '%app_users%');
```

### 3. Se Cancelamento Não Funcionar

```sql
-- Forçar término dos processos (use com cuidado)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state IN ('active', 'idle in transaction')
  AND query_start < NOW() - INTERVAL '10 minutes'
  AND (query LIKE '%fix_signup_error_500%');
```

## Solução Definitiva

### Use o Script Anti-Deadlock

Em vez do script original `fix_signup_error_500.sql`, use:

```bash
# Execute o script seguro
psql -f fix_signup_error_500_safe.sql
```

### Características do Script Seguro

1. **Advisory Locks**: Previne execução simultânea
2. **Transações Menores**: Reduz tempo de lock
3. **Ordem Segura**: DDL em sequência que evita deadlocks
4. **Verificações de Estado**: Detecta conflitos antes de executar
5. **Timeout Protection**: Evita travamentos longos

## Prevenção de Futuros Deadlocks

### 1. Nunca Execute Scripts Simultaneamente

```sql
-- Sempre verifique antes de executar
SELECT COUNT(*) as scripts_ativos
FROM pg_stat_activity 
WHERE query LIKE '%fix_signup_error_500%' 
  AND state = 'active';
```

### 2. Use o Diagnóstico Seguro

```sql
-- Em vez de diagnose_signup_issues(), use:
SELECT diagnose_signup_issues_safe();
```

### 3. Monitore Locks Ativos

```sql
-- Verificar locks ativos
SELECT 
    l.locktype,
    l.database,
    l.relation,
    l.mode,
    l.granted,
    a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.granted
ORDER BY l.relation;
```

## Opção de Emergência

Se o deadlock persistir mesmo com o script seguro:

```sql
-- ÚLTIMA OPÇÃO: Desabilitar triggers temporariamente
DROP TRIGGER IF EXISTS trigger_sync_auth_to_app ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;

-- Executar apenas as políticas RLS essenciais
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow signup to create app_users" ON app_users
    FOR INSERT
    WITH CHECK (auth.uid() = id OR auth.role() = 'service_role');

-- Testar signup
-- Recriar triggers depois que o signup funcionar
```

## Verificação Final

```sql
-- 1. Verificar se não há deadlocks ativos
SELECT COUNT(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock';

-- 2. Executar diagnóstico
SELECT diagnose_signup_issues_safe();

-- 3. Testar signup
-- (teste manual no aplicativo)

-- 4. Monitorar logs
SELECT * FROM auth_sync_logs 
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

## Arquivos Relacionados

- `fix_signup_error_500_safe.sql` - Script anti-deadlock
- `fix_signup_error_500.sql` - Script original (pode causar deadlock)
- `SIGNUP_ERROR_500_SOLUTION.md` - Documentação da solução original

## Próximos Passos

1. ✅ Execute o script anti-deadlock
2. ✅ Verifique o diagnóstico
3. ✅ Teste o processo de signup
4. ✅ Monitore por 24h para garantir estabilidade
5. ✅ Documente qualquer comportamento anômalo

---

**Importante**: Sempre use o script `fix_signup_error_500_safe.sql` em produção para evitar deadlocks futuros.