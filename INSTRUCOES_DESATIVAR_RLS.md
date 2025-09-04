# 🔒 Instruções para Desativar RLS no Supabase

## ⚠️ IMPORTANTE
Como não conseguimos executar comandos SQL diretamente via API, você precisa executar o script manualmente no Dashboard do Supabase.

## 📋 Passos para Execução

### 1. Acessar o Dashboard do Supabase
1. Acesse: https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione o projeto: `qlbwacmavngtonauxnte`

### 2. Abrir o SQL Editor
1. No menu lateral, clique em **"SQL Editor"**
2. Clique em **"New query"** para criar uma nova consulta

### 3. Executar o Script
1. Copie todo o conteúdo do arquivo `disable_all_rls.sql`
2. Cole no editor SQL
3. Clique em **"Run"** para executar

### 4. Verificar Execução
Após executar o script, você deve ver mensagens indicando:
- ✅ Comandos `ALTER TABLE` executados com sucesso
- ✅ Comandos `DROP POLICY` executados (alguns podem falhar se as políticas não existirem)
- 📊 Status final mostrando RLS desabilitado para todas as tabelas

## 🔍 Verificação Manual

Para verificar se o RLS foi desabilitado corretamente, execute esta query no SQL Editor:

```sql
SELECT 
  schemaname, 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
  'app_users', 'drivers', 'passengers', 'trips', 'trip_requests',
  'driver_wallets', 'passenger_wallets', 'wallet_transactions',
  'passenger_wallet_transactions', 'payment_methods', 'notifications',
  'favorite_locations', 'driver_schedules', 'working_hours',
  'driver_excluded_zones', 'locations', 'auth_sync_logs', 'sync_control'
)
ORDER BY tablename;
```

**Resultado esperado:** Todas as tabelas devem mostrar `rowsecurity = false`

## 🛡️ Próximos Passos

Após desativar o RLS:

1. ✅ **AuthService implementado** - Já criado em `lib/services/auth_service.dart`
2. 🔄 **Atualizar Repositories** - Consulte `SECURITY_UPDATES_REQUIRED.md`
3. 🧪 **Testar Segurança** - Verificar isolamento entre usuários
4. 📝 **Implementar Auditoria** - Logs de operações sensíveis

## 🚨 Lembrete de Segurança

⚠️ **CRÍTICO**: Com o RLS desabilitado, toda a segurança agora depende da aplicação Flutter!

- Nunca execute queries sem filtros de `user_id`
- Sempre valide ownership antes de operações
- Implemente logging para auditoria
- Teste isolamento entre usuários

## 📞 Suporte

Se encontrar problemas:
1. Verifique se você tem permissões de administrador no projeto
2. Confirme que está no projeto correto (`qlbwacmavngtonauxnte`)
3. Tente executar o script em partes menores se houver timeout

---

**Status**: ⏳ Aguardando execução manual do script SQL
**Próximo**: Atualizar repositories com validações de segurança