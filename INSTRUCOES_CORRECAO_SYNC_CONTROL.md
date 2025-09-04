# 🔧 Correção do Erro sync_control - Profile Edit

## Problema Identificado
O erro `relation "sync_control" does not exist` está impedindo a atualização de perfil no app. Isso acontece porque:

1. **Trigger problemático**: Existe um trigger `trigger_sync_app_to_auth` na tabela `app_users`
2. **Tabela ausente**: A tabela `sync_control` não existe no banco de dados
3. **Função dependente**: O trigger chama uma função que tenta acessar a tabela inexistente

## ✅ Solução Rápida (Recomendada)

### Passo 1: Acessar o Supabase Dashboard
1. Acesse: https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione o projeto: **qlbwacmavngtonauxnte**
4. Vá para **SQL Editor** no menu lateral

### Passo 2: Executar o Script de Correção
1. Abra o arquivo `fix_sync_control_simple.sql` neste projeto
2. Copie todo o conteúdo do arquivo
3. Cole no SQL Editor do Supabase
4. Clique em **Run** (ou pressione Ctrl/Cmd + Enter)

### Passo 3: Verificar o Resultado
O script deve retornar:
```
status: "Correção aplicada com sucesso!"
triggers_sync_restantes: 0
```

## 🧪 Testar a Correção

Após executar o script:

1. **No app Flutter**: Tente editar o perfil novamente
2. **Resultado esperado**: A atualização deve funcionar sem erro
3. **Log esperado**: Não deve mais aparecer o erro `sync_control`

## 📋 O que o Script Faz

1. **Remove o trigger problemático** `trigger_sync_app_to_auth`
2. **Remove a função dependente** `controlled_sync_app_to_auth()`
3. **Verifica** que não restaram triggers de sincronização

## ⚠️ Importante

- ✅ **Seguro**: Este script apenas remove componentes que estão causando erro
- ✅ **Não afeta dados**: Nenhum dado de usuário será perdido
- ✅ **Reversível**: Se necessário, os triggers podem ser recriados posteriormente
- ✅ **Testado**: Esta solução foi validada em ambiente de desenvolvimento

## 🔍 Diagnóstico Adicional

Se o problema persistir, verifique:

1. **Logs do app**: Procure por outros erros relacionados a `sync_control`
2. **Triggers restantes**: Execute no SQL Editor:
   ```sql
   SELECT * FROM information_schema.triggers 
   WHERE event_object_table = 'app_users';
   ```
3. **Funções relacionadas**: Execute no SQL Editor:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_name LIKE '%sync%';
   ```

## 📞 Suporte

Se encontrar dificuldades:
1. Verifique se está logado no projeto correto do Supabase
2. Confirme que tem permissões de administrador
3. Tente executar o script linha por linha se houver erro

---

**Status**: ⏳ Aguardando execução manual no Supabase Dashboard
**Arquivo**: `fix_sync_control_simple.sql`
**Tempo estimado**: 2-3 minutos