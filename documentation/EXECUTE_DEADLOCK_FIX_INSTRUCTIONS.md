# 🚨 INSTRUÇÕES PARA RESOLVER DEADLOCK NO SUPABASE

## Situação Atual
Detectamos um processo ativo (PID 258207) que pode estar causando deadlock no banco de dados. Como a conexão direta via psql não está funcionando, você deve executar o script de correção diretamente no painel web do Supabase.

## ⚡ SOLUÇÃO IMEDIATA

### Passo 1: Acessar o Painel do Supabase
1. Acesse: https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione o projeto **"opt mobilidade"** (ID: qlbwacmavngtonauxnte)

### Passo 2: Abrir o SQL Editor
1. No menu lateral, clique em **"SQL Editor"**
2. Clique em **"New query"** para criar uma nova consulta

### Passo 3: Executar o Script de Correção
1. Copie todo o conteúdo do arquivo `execute_deadlock_fix_web.sql`
2. Cole no SQL Editor
3. Clique em **"Run"** para executar

### Passo 4: Verificar Resultados
O script irá:
- ✅ Cancelar processos problemáticos
- ✅ Remover políticas RLS conflitantes
- ✅ Recriar políticas com sintaxe corrigida
- ✅ Desabilitar triggers de sincronização
- ✅ Executar diagnóstico final

## 🔍 VERIFICAÇÃO PÓS-EXECUÇÃO

Após executar o script, execute esta consulta para verificar o status:

```sql
SELECT diagnose_signup_issues_safe();
```

## 🧪 TESTE DO SIGNUP

Após a correção:
1. Abra o aplicativo Flutter
2. Tente criar uma nova conta
3. Verifique se o erro 500 foi resolvido

## 📊 MONITORAMENTO

Para monitorar processos ativos:

```sql
SELECT pid, state, query_start, LEFT(query, 100) as query_preview
FROM pg_stat_activity 
WHERE state = 'active'
ORDER BY query_start;
```

## 🆘 SE O PROBLEMA PERSISTIR

Se ainda houver deadlocks:

1. **Cancelar processo específico:**
```sql
SELECT pg_cancel_backend(258207); -- Substitua pelo PID problemático
```

2. **Forçar término (último recurso):**
```sql
SELECT pg_terminate_backend(258207); -- Substitua pelo PID problemático
```

3. **Verificar locks ativos:**
```sql
SELECT 
    l.pid,
    l.mode,
    l.granted,
    c.relname as table_name
FROM pg_locks l
JOIN pg_class c ON l.relation = c.oid
WHERE NOT l.granted
ORDER BY l.pid;
```

## 📝 ARQUIVOS RELACIONADOS

- `execute_deadlock_fix_web.sql` - Script principal para execução no painel web
- `fix_signup_error_500_safe.sql` - Script original com proteções anti-deadlock
- `DEADLOCK_RESOLUTION_GUIDE.md` - Guia completo de resolução de deadlocks

## ✅ PRÓXIMOS PASSOS

1. Execute o script no painel web
2. Teste o signup no aplicativo
3. Monitore logs de erro
4. Documente qualquer problema restante

---

**⚠️ IMPORTANTE:** Este script foi criado especificamente para resolver o deadlock atual e corrigir os erros de sintaxe SQL que estavam causando o erro 500 no signup.