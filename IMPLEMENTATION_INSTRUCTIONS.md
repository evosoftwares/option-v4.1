# Instruções para Implementação da Solução de Duplicidade de Documentos

## Visão Geral

Esta solução visa eliminar a duplicidade de armazenamento dos documentos CNH e CRLV, que atualmente são armazenados tanto na tabela `drivers` quanto na tabela `driver_documents`, causando fricção na experiência do usuário.

## Arquivos Criados

1. `migrate_documents.sql` - Script de migração para transferir documentos
2. `update_rls_policies.sql` - Atualização das políticas RLS
3. `driver_registration_flow.js` - Exemplo de fluxo de cadastro modificado
4. `api_updates.js` - Exemplo de atualização das APIs
5. `get_driver_documents_unified.sql` - Função RPC para unificar acesso aos documentos

## Passos de Implementação

### 1. Backup do Banco de Dados

Antes de qualquer alteração, faça um backup completo do banco de dados.

### 2. Executar Script de Migração

Execute o script `migrate_documents.sql` para transferir os documentos existentes:

```sql
-- Conecte-se ao banco de dados com privilégios de administrador
-- Execute o script migrate_documents.sql
```

### 3. Atualizar Políticas RLS

Execute o script `update_rls_policies.sql` para atualizar as políticas de acesso:

```sql
-- Execute o script update_rls_policies.sql
```

### 4. Adicionar Função RPC

Execute o script `get_driver_documents_unified.sql` para criar a função que unifica o acesso aos documentos:

```sql
-- Execute o script get_driver_documents_unified.sql
```

### 5. Atualizar Fluxo de Cadastro

Substitua o fluxo de cadastro atual pelo exemplo em `driver_registration_flow.js`, adaptando conforme necessário para a sua aplicação.

### 6. Atualizar APIs

Atualize as APIs de acesso aos documentos conforme o exemplo em `api_updates.js`.

### 7. Testar a Solução

Teste todas as funcionalidades relacionadas a documentos em ambiente de desenvolvimento antes de implantar em produção.

## Considerações Importantes

1. **Compatibilidade**: Esta solução mantém compatibilidade com versões anteriores, permitindo que sistemas existentes continuem funcionando durante a transição.

2. **Segurança**: As políticas RLS foram atualizadas para garantir que motoristas só possam acessar seus próprios documentos.

3. **Desempenho**: A função RPC `get_driver_documents_unified` otimiza o acesso aos documentos, reduzindo a necessidade de múltiplas consultas.

4. **Manutenção**: Após um período de transição, os campos `cnh_photo_url` e `crlv_photo_url` na tabela `drivers` podem ser descontinuados.

## Monitoramento Pós-Implementação

1. Monitorar erros relacionados ao acesso de documentos
2. Verificar desempenho das consultas
3. Acompanhar feedback dos usuários sobre a experiência de cadastro