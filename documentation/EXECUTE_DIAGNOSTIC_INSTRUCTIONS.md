# 🔍 Instruções para Diagnóstico do Erro de Inserção em app_users

## ⚠️ Situação Atual
Após aplicar as correções anteriores, ainda há um erro "Database error saving new user" no processo de signup. Este diagnóstico identificará a causa específica.

## 📋 Pré-requisitos
- Acesso ao painel web do Supabase
- Projeto Option v4.1 selecionado
- Permissões de administrador no projeto

## 🚀 Passos para Execução

### 1. Acessar o Supabase Dashboard
1. Abra [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Faça login na sua conta
3. Selecione o projeto **Option v4.1**

### 2. Abrir o SQL Editor
1. No menu lateral esquerdo, clique em **"SQL Editor"**
2. Clique em **"New query"** para criar uma nova consulta

### 3. Executar o Script de Diagnóstico
1. Abra o arquivo `diagnose_app_users_insert.sql`
2. **Copie TODO o conteúdo** do arquivo
3. **Cole no SQL Editor** do Supabase
4. Clique em **"Run"** (botão verde) para executar

### 4. Analisar os Resultados

O script retornará várias seções de diagnóstico. **Preste atenção especial a:**

#### 🔍 Seção Crítica: `test_app_users_insert_safe()`
Esta função tentará fazer uma inserção de teste e retornará:
- ✅ **Se success: true** → A inserção funciona, o problema pode estar no código Flutter
- ❌ **Se success: false** → Mostrará o erro exato que está bloqueando a inserção

#### 📊 Outras Seções Importantes:
1. **Estrutura da tabela** - Campos obrigatórios
2. **Constraints** - Validações que podem estar falhando
3. **Políticas RLS** - Permissões de inserção
4. **Triggers ativos** - Processos que podem estar interferindo
5. **Dados corrompidos** - Registros que podem causar conflitos

### 5. Interpretar os Resultados

#### ✅ Se o teste de inserção for bem-sucedido:
- O problema está no código Flutter ou na autenticação
- Verificar se `auth.uid()` está sendo passado corretamente
- Verificar se todos os campos obrigatórios estão sendo enviados

#### ❌ Se o teste de inserção falhar:
O erro retornado indicará exatamente o que corrigir:

**Possíveis erros e soluções:**

| Erro | Causa Provável | Solução |
|------|----------------|----------|
| `violates check constraint` | Validação de dados falhando | Verificar constraints na seção 2 |
| `permission denied` | Problema de RLS | Verificar políticas na seção 3 |
| `null value in column` | Campo obrigatório faltando | Verificar campos required na seção 6 |
| `duplicate key value` | Conflito de ID | Verificar dados corrompidos na seção 7 |
| `trigger function returned null` | Trigger bloqueando | Verificar triggers na seção 5 |

### 6. Próximos Passos Baseados no Resultado

#### 📤 Compartilhar Resultados
Após executar o diagnóstico:
1. **Copie TODOS os resultados** do SQL Editor
2. **Cole em um arquivo de texto** ou compartilhe diretamente
3. **Inclua especialmente** o resultado de `test_app_users_insert_safe()`

#### 🔧 Aplicar Correções
Baseado no diagnóstico, criaremos um script específico para corrigir o problema identificado.

## ⏱️ Tempo Estimado
- **Execução do diagnóstico:** 2-3 minutos
- **Análise dos resultados:** 5 minutos
- **Aplicação da correção:** 5-10 minutos

## 🆘 Solução de Problemas

### Se o script não executar:
1. Verifique se copiou o script completo
2. Certifique-se de estar no projeto correto
3. Verifique se tem permissões de administrador

### Se houver timeout:
1. Execute o script em seções menores
2. Comece apenas com `SELECT test_app_users_insert_safe();`

### Se não conseguir interpretar os resultados:
1. Copie e compartilhe todos os resultados
2. Focaremos na análise conjunta

## 📞 Suporte
Se encontrar qualquer dificuldade durante a execução, compartilhe:
1. A seção específica onde ocorreu o problema
2. A mensagem de erro exata (se houver)
3. Screenshots do SQL Editor (se necessário)

---

**🎯 Objetivo:** Identificar a causa exata do erro "Database error saving new user" para aplicar uma correção direcionada e resolver definitivamente o problema de signup.