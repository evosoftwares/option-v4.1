# Quadro-Resumo CRUD por Tabela

## Tabela: app_users

### Estrutura da Tabela

| Campo | Tipo | Nullable | Default | Descrição |
|-------|------|----------|---------|----------|
| id | uuid | NO | - | Chave primária |
| email | text | NO | - | Email do usuário |
| full_name | text | NO | - | Nome completo |
| phone | text | NO | 'pending' | Telefone |
| photo_url | text | YES | - | URL da foto |
| user_type | text | NO | - | Tipo de usuário (passenger/driver) |
| status | text | NO | 'active' | Status do usuário |
| created_at | timestamp | YES | now() | Data de criação |
| updated_at | timestamp | YES | now() | Data de atualização |
| user_id | uuid | YES | - | ID do usuário auth |
| fcm_token | text | YES | - | Token FCM |
| device_id | text | YES | - | ID do dispositivo |
| device_platform | text | YES | - | Plataforma do dispositivo |
| last_active_at | timestamp | YES | now() | Última atividade |

### Operações CRUD

#### CREATE (Criação)
- **Serviço**: `UserService.createUser()`
- **Validações**:
  - Nome completo obrigatório (mín. 2 caracteres)
  - Email válido e único
  - Telefone opcional (formato brasileiro)
  - Tipo de usuário válido (passenger/driver)
- **Triggers**: Sincronização bidirecional com `auth.users`

#### READ (Leitura)
- **Serviços**:
  - `UserService.getUserById()`
  - `UserService.getUserByEmail()`
  - `UserService.getCurrentUser()`
  - `UserService.getUsersByType()`
- **Filtros**: Por ID, email, tipo de usuário

#### UPDATE (Atualização)
- **Serviço**: `UserService.updateUser()`
- **Campos editáveis**:
  - `full_name` (obrigatório)
  - `phone` (opcional, validação de formato)
  - `photo_url` (opcional)
  - `user_type` (passenger/driver)
  - `status` (active/inactive)
- **Validações**:
  - Nome: não vazio, mín. 2 caracteres
  - Telefone: formato brasileiro (10-15 dígitos)
  - Detecção de dados corrompidos
- **Triggers**: Atualização automática de `updated_at`

#### DELETE (Exclusão)
- **Serviço**: `UserService.deactivateUser()`
- **Estratégia**: Soft delete (status = 'inactive')
- **Preservação**: Dados mantidos para auditoria

### Validações Implementadas

#### UserDataValidator
- `validateAndSanitizeFullName()`: Valida nome completo
- `validatePhone()`: Valida formato de telefone brasileiro
- `validateEmail()`: Valida formato de email
- `validateUserType()`: Valida tipo de usuário
- `validateUserData()`: Validação completa de dados

#### PhoneValidator
- Suporte a formatos: (11) 99999-9999, 11999999999
- Validação de DDD brasileiro (11-99)
- Celular: 9 dígitos após DDD
- Fixo: 8 dígitos após DDD

#### DatabaseConstraintsValidator
- Validação de constraints do banco
- Verificação de limites de caracteres
- Prevenção de dados corrompidos

### Testes de Validação

✅ **Testes Implementados**:
- Validação de nome completo
- Validação de formato de telefone
- Validação de dados de usuário completos
- Detecção de dados corrompidos

### Sincronização com Auth

- **Triggers bidirecionais** entre `auth.users` e `app_users`
- **Logs de auditoria** em `auth_sync_logs`
- **Validação de dados** antes da sincronização
- **Prevenção de corrupção** de dados

### Considerações de Segurança

- **RLS desabilitado** conforme diretrizes do projeto
- **Validação rigorosa** no nível da aplicação
- **Sanitização** de dados de entrada
- **Auditoria** de alterações via triggers

### Status de Implementação

| Operação | Status | Testes | Validação |
|----------|--------|--------|----------|
| CREATE | ✅ | ✅ | ✅ |
| READ | ✅ | ✅ | ✅ |
| UPDATE | ✅ | ✅ | ✅ |
| DELETE | ✅ | ⚠️ | ✅ |

**Legenda**:
- ✅ Implementado e testado
- ⚠️ Implementado, testes parciais
- ❌ Não implementado

### Próximos Passos

1. Implementar testes de integração para DELETE
2. Adicionar testes de performance para operações em lote
3. Documentar casos de uso específicos
4. Implementar métricas de monitoramento

---

*Última atualização: $(date)*
*Versão: 1.0*