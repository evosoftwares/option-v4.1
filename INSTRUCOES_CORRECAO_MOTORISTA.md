# Instruções para Correção de Associação de Perfil de Motorista

## Problema Identificado

Usuários com `user_type='driver'` não possuem registros correspondentes na tabela `drivers`, causando erro "Perfil de motorista não encontrado" na tela de carteira.

## Solução Implementada

### 1. Scripts Criados

- **`diagnostico_associacao_motorista.sql`**: Script para diagnosticar o problema
- **`correcao_associacao_motorista.sql`**: Script para corrigir automaticamente as associações
- **`teste_validacao_correcao.sql`**: Script para validar se a correção funcionou

### 2. Melhorias no Código Flutter

- **`WalletScreen`**: Melhorado tratamento de erro com mensagem mais clara e botão de retry
- **`_ErrorState`**: Widget aprimorado com ícone, mensagem detalhada e ação de retry

## Passos para Implementação

### Passo 1: Diagnóstico Inicial

1. Acesse o Supabase SQL Editor
2. Execute o script `diagnostico_associacao_motorista.sql`
3. Anote quantos usuários têm o problema

### Passo 2: Validação Pré-Correção

1. Execute o script `teste_validacao_correcao.sql`
2. Documente o estado atual:
   - Total de usuários driver
   - Total de registros drivers
   - Usuários sem perfil driver

### Passo 3: Aplicar Correção

1. Execute o script `correcao_associacao_motorista.sql`
2. O script irá:
   - Criar função `fix_driver_associations()` para correção única
   - Executar a correção automática
   - Criar função `auto_create_driver_record()` para prevenção futura
   - Criar trigger `auto_create_driver_record_trigger` para novos casos
   - Mostrar relatório de resultados

### Passo 4: Validação Pós-Correção

1. Execute novamente `teste_validacao_correcao.sql`
2. Verifique se:
   - Número de "usuários sem perfil driver" = 0
   - Funções e trigger foram criados corretamente
   - Não há erros nos logs

### Passo 5: Teste no Aplicativo

1. Faça hot reload do aplicativo Flutter
2. Teste com usuário que tinha o problema:
   - Acesse a tela de carteira
   - Verifique se carrega corretamente
   - Se ainda houver erro, use o botão "Recarregar Perfil"

## Estrutura da Correção

### Função `fix_driver_associations()`

- **Propósito**: Correção única de associações faltantes
- **Ação**: Cria registros básicos na tabela `drivers` para usuários com `user_type='driver'`
- **Valores**: Usa placeholders como "PENDENTE_CADASTRO" para campos obrigatórios
- **Status**: Define `approval_status='pending'` para novos registros

### Trigger `auto_create_driver_record_trigger`

- **Propósito**: Prevenção automática de futuros problemas
- **Ativação**: Quando `user_type` é alterado para 'driver'
- **Ação**: Cria automaticamente registro na tabela `drivers`
- **Segurança**: Verifica se registro já existe antes de criar

### Melhorias na UI

- **Mensagem de erro mais clara**: "Perfil de motorista não encontrado"
- **Ícone visual**: Ícone de erro para melhor UX
- **Botão de retry**: "Recarregar Perfil" para tentar novamente
- **Texto explicativo**: Orientação sobre próximos passos

## Campos Criados Automaticamente

```sql
cnh_number: 'PENDENTE_CADASTRO'
vehicle_brand: 'PENDENTE'
vehicle_model: 'PENDENTE'
vehicle_plate: 'PENDENTE'
approval_status: 'pending'
is_online: false
acepts_pet: false
... (outros campos com valores padrão)
```

## Monitoramento

### Queries de Monitoramento

```sql
-- Verificar usuários sem perfil driver
SELECT COUNT(*) FROM app_users au
WHERE au.user_type = 'driver'
    AND NOT EXISTS (SELECT 1 FROM drivers d WHERE d.user_id = au.id);

-- Verificar registros criados hoje
SELECT COUNT(*) FROM drivers 
WHERE DATE(created_at) = CURRENT_DATE 
    AND cnh_number = 'PENDENTE_CADASTRO';
```

### Logs a Observar

- Erros de constraint violation
- Falhas na criação de registros
- Ativação do trigger
- Performance da função de correção

## Rollback (Se Necessário)

```sql
-- Remover trigger
DROP TRIGGER IF EXISTS auto_create_driver_record_trigger ON app_users;

-- Remover funções
DROP FUNCTION IF EXISTS auto_create_driver_record();
DROP FUNCTION IF EXISTS fix_driver_associations();

-- Remover registros criados pela correção (CUIDADO!)
-- DELETE FROM drivers WHERE cnh_number = 'PENDENTE_CADASTRO';
```

## Próximos Passos

1. **Implementar onboarding completo**: Guiar motoristas para completar cadastro
2. **Validação de dados**: Adicionar validações para campos obrigatórios
3. **Notificações**: Alertar motoristas sobre cadastro pendente
4. **Dashboard admin**: Monitorar motoristas com status 'pending'

## Considerações de Segurança

- ✅ Não usa RLS (conforme restrição do projeto)
- ✅ Usa triggers bem documentados
- ✅ Valores placeholder seguros
- ✅ Verificações de existência antes de criar
- ✅ Tratamento de erros robusto

## Teste de Regressão

1. Criar usuário com `user_type='passenger'` → Não deve criar registro driver
2. Alterar `user_type` de 'passenger' para 'driver' → Deve criar registro driver
3. Alterar `user_type` de 'driver' para 'passenger' → Registro driver permanece
4. Tentar criar driver duplicado → Deve ser impedido por constraint

---

**Importante**: Execute sempre em ambiente de desenvolvimento primeiro e faça backup antes de aplicar em produção.