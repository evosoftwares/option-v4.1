# Solução para Erro 500 no Signup do Supabase

## 🚨 Problema Identificado

O erro 500 no endpoint `/auth/v1/signup` está sendo causado pelos **triggers de sincronização** entre `auth.users` e `app_users`. Mesmo com os triggers configurados como "desabilitados" por padrão, eles ainda estão ativos e tentando executar operações que falham devido a:

1. **Políticas RLS mal configuradas** nas tabelas `auth_sync_logs` e `sync_control`
2. **Conflitos de permissão** durante a inserção de logs de sincronização
3. **Triggers ativos** mesmo quando marcados como desabilitados

## 🔍 Análise da Causa Raiz

### Estrutura do Problema:
```
Signup Request → auth.users (INSERT) → trigger_sync_auth_to_app → 
controlled_sync_auth_to_app() → INSERT auth_sync_logs → RLS BLOCK → ERROR 500
```

### Arquivos Envolvidos:
- `database/auth_sync_triggers.sql` - Triggers de sincronização
- `supabase.md` - Schema do banco (confirma existência das tabelas)
- Tabelas: `auth_sync_logs`, `sync_control`, `app_users`

## 🛠️ Solução Implementada

### 1. Script de Correção Criado
**Arquivo:** `fix_signup_error_500.sql`

**O que o script faz:**
- ✅ Configura RLS adequadamente para `auth_sync_logs` e `sync_control`
- ✅ Cria políticas que permitem inserção de logs durante signup
- ✅ Garante que triggers estão desabilitados por padrão
- ✅ Configura RLS para `app_users` com políticas corretas
- ✅ Inclui função de diagnóstico para monitoramento

### 2. Políticas RLS Configuradas

```sql
-- Permite inserção de logs durante signup
CREATE POLICY "Allow system to insert sync logs" ON auth_sync_logs
    FOR INSERT WITH CHECK (true);

-- Permite criação de app_users durante signup
CREATE POLICY "Allow signup to create app_users" ON app_users
    FOR INSERT WITH CHECK (
        auth.uid() = id OR auth.role() = 'service_role'
    );
```

## 🚀 Passos para Implementação

### Passo 1: Executar o Script de Correção
```bash
# No Supabase Dashboard → SQL Editor
# Copie e execute o conteúdo de: fix_signup_error_500.sql
# NOTAS DE COMPATIBILIDADE:
# - Removidos comandos RAISE NOTICE (não suportados)
# - Substituído auth.jwt() ->> por auth.role() (compatibilidade de tipos)
# - Corrigida função diagnose_signup_issues() para usar pg_tables em vez de information_schema.tables
```

### Passo 2: Verificar Status
```sql
-- Executar função de diagnóstico
SELECT diagnose_signup_issues();
```

### Passo 3: Testar Signup
1. Teste o processo de signup na aplicação
2. Monitore os logs no console do navegador
3. Verifique se o erro 500 foi resolvido

### Passo 4: Se o Problema Persistir
```sql
-- SOLUÇÃO TEMPORÁRIA: Desabilitar triggers completamente
DROP TRIGGER IF EXISTS trigger_sync_auth_to_app ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_app_to_auth ON app_users;
```

## 📊 Monitoramento

### Verificar Logs de Sincronização
```sql
SELECT * FROM auth_sync_logs 
WHERE sync_status = 'failed' 
ORDER BY created_at DESC 
LIMIT 10;
```

### Status dos Triggers
```sql
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers 
WHERE trigger_name LIKE '%sync%';
```

### Status do Sync Control
```sql
SELECT feature_name, enabled, updated_at 
FROM sync_control;
```

## 🔄 Reabilitação dos Triggers (Futuro)

Quando os problemas forem totalmente resolvidos:

```sql
-- 1. Recriar triggers
CREATE TRIGGER trigger_sync_auth_to_app
    AFTER INSERT OR UPDATE OR DELETE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION controlled_sync_auth_to_app();

-- 2. Habilitar sincronização gradualmente
SELECT enable_auth_sync('auth_to_app_sync');

-- 3. Monitorar logs
SELECT * FROM auth_sync_logs ORDER BY created_at DESC LIMIT 20;
```

## ⚠️ Considerações Importantes

1. **Backup**: Sempre faça backup antes de executar scripts SQL
2. **Teste**: Teste em ambiente de desenvolvimento primeiro
3. **Monitoramento**: Monitore logs após implementação
4. **Rollback**: Mantenha plano de rollback preparado

## 🎯 Próximos Passos Recomendados

1. **Imediato**: Executar `fix_signup_error_500.sql`
2. **Teste**: Verificar se signup funciona
3. **Monitoramento**: Acompanhar logs por 24h
4. **Otimização**: Revisar triggers para melhor performance
5. **Documentação**: Atualizar documentação do projeto

## 📞 Suporte

Se o problema persistir após implementação:
1. Verifique logs detalhados com `SELECT diagnose_signup_issues();`
2. Considere desabilitar triggers temporariamente
3. Analise políticas RLS específicas do seu ambiente
4. Verifique configurações de autenticação do Supabase

---

**Status**: ✅ Solução implementada e pronta para teste
**Prioridade**: 🔴 Alta - Afeta funcionalidade crítica de signup
**Impacto**: 📈 Resolve erro 500 e permite cadastro de novos usuários