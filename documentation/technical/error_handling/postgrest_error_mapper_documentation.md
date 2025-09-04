# Documentação do PostgrestErrorMapper

## Visão Geral
O `PostgrestErrorMapper` é um utilitário centralizado para mapear erros do PostgREST (Supabase) em exceções específicas da aplicação. Ele fornece uma camada de abstração que traduz erros técnicos do banco de dados em mensagens compreensíveis para os usuários finais.

## Arquitetura

### Estrutura de Classes

```dart
class PostgrestErrorMapper {
  static Exception mapError(PostgrestException exception, {Map<String, dynamic>? context})
}
```

### Tipos de Erros Mapeados

| Código PostgreSQL | Exceção Lançada | Descrição |
|------------------|-----------------|-----------|
| `23505` | `UniqueViolationException` | Violação de chave única |
| `23503` | `ForeignKeyViolationException` | Violação de chave estrangeira |
| `23514` | `CheckViolationException` | Violação de constraint CHECK |
| `23502` | `NotNullViolationException` | Violação de NOT NULL |
| `42501` | `InsufficientPrivilegesException` | Permissões insuficientes |
| `PGRST` | `PostgrestException` | Erro genérico do PostgREST |
| `JWT` | `AuthenticationException` | Erro de autenticação JWT |
| `404` | `ResourceNotFoundException` | Recurso não encontrado |

## Mapeamento Detalhado

### 1. UniqueViolationException (23505)
**Quando ocorre:**
- Tentativa de inserir registro com valor duplicado em campo UNIQUE
- Tentativa de atualizar para valor já existente

**Exemplo:**
```sql
-- Tabela users com email UNIQUE
INSERT INTO users (email) VALUES ('existing@email.com'); -- Erro 23505
```

**Mensagem ao usuário:** "Este email já está cadastrado. Por favor, use outro email."

### 2. ForeignKeyViolationException (23503)
**Quando ocorre:**
- Tentativa de referenciar ID que não existe
- Tentativa de deletar registro referenciado por outro

**Exemplo:**
```sql
-- Tentar criar trip com passenger_id que não existe
INSERT INTO trips (passenger_id) VALUES ('non-existent-user'); -- Erro 23503
```

**Mensagem ao usuário:** "Referência inválida. Verifique se os dados relacionados existem."

### 3. CheckViolationException (23514)
**Quando ocorre:**
- Violação de constraints CHECK do banco

**Exemplo:**
```sql
-- Constraint: CHECK (estimated_fare > 0)
INSERT INTO trips (estimated_fare) VALUES (-10); -- Erro 23514
```

**Mensagem ao usuário:** "Valor inválido fornecido. Por favor, verifique os dados."

### 4. NotNullViolationException (23502)
**Quando ocorre:**
- Tentativa de inserir NULL em campo NOT NULL

**Exemplo:**
```sql
-- Campo origin_address NOT NULL
INSERT INTO trips (origin_address) VALUES (NULL); -- Erro 23502
```

**Mensagem ao usuário:** "Campo obrigatório não preenchido."

### 5. InsufficientPrivilegesException (42501)
**Quando ocorre:**
- Usuário sem permissão para operação
- Tentativa de acessar dados de outro usuário

**Exemplo:**
```sql
-- Usuário tentando acessar dados de outro usuário
SELECT * FROM trips WHERE passenger_id = 'other-user'; -- Erro 42501
```

**Mensagem ao usuário:** "Você não tem permissão para esta ação."

## Integração com ErrorLoggingService

### Fluxo de Tratamento de Erros

1. **Captura do erro** no serviço
2. **Mapeamento** pela PostgrestErrorMapper
3. **Registro** no ErrorLoggingService
4. **Tradução** para mensagem amigável
5. **Apresentação** ao usuário

### Exemplo de Uso Completo

```dart
try {
  final trip = await createTrip(tripData);
  return trip;
} on PostgrestException catch (e) {
  // 1. Mapear erro
  final exception = PostgrestErrorMapper.mapError(e, context: {
    'operation': 'createTrip',
    'userId': userId,
  });
  
  // 2. Registrar erro
  await ErrorLoggingService.instance.logException(
    exception,
    context: {'tripData': tripData},
    type: AppErrorType.databaseError,
  );
  
  // 3. Relançar para camada superior tratar
  throw exception;
}
```

## Configuração de Políticas RLS

### Exemplo de Políticas que Geram Erros Mapeados

```sql
-- Política que pode gerar 42501
CREATE POLICY "Users can only access own trips" ON trips
  FOR SELECT USING (auth.uid() = passenger_id OR auth.uid() = driver_id);

-- Política que pode gerar 23505
CREATE POLICY "Unique active trip per user" ON trips
  FOR INSERT WITH CHECK (
    NOT EXISTS (
      SELECT 1 FROM trips 
      WHERE passenger_id = auth.uid() 
      AND status IN ('pending', 'accepted', 'in_progress')
    )
  );
```

## Mensagens Customizadas por Contexto

### TripService
- **23505 ao criar trip request**: "Você já tem uma solicitação ativa"
- **23503 ao aceitar trip**: "Solicitação de viagem não encontrada"
- **42501 ao acessar trip**: "Esta viagem não pertence a você"

### UserService
- **23505 ao registrar**: "Este email ou telefone já está cadastrado"
- **23502 ao atualizar perfil**: "Campo obrigatório não preenchido"

## Debugging e Troubleshooting

### Logs Detalhados

Cada erro registrado inclui:
- Código PostgreSQL original
- Mensagem técnica original
- Contexto da operação
- Stack trace
- Timestamp
- User ID (se disponível)

### Exemplo de Log

```json
{
  "error": {
    "code": "23505",
    "message": "duplicate key value violates unique constraint \"users_email_key\"",
    "detail": "Key (email)=(user@example.com) already exists.",
    "context": {
      "operation": "createUser",
      "userId": "auth-user-123",
      "email": "user@example.com"
    },
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

## Melhores Práticas

### 1. Sempre fornecer contexto
```dart
// Bom
PostgrestErrorMapper.mapError(e, context: {
  'operation': 'updateTrip',
  'tripId': tripId,
  'userId': userId,
});

// Ruim
PostgrestErrorMapper.mapError(e);
```

### 2. Tratar erros específicos
```dart
try {
  await operation();
} on UniqueViolationException catch (e) {
  // Tratamento específico
  showError('Este valor já existe');
} on ForeignKeyViolationException catch (e) {
  // Tratamento específico
  showError('Dados relacionados não encontrados');
}
```

### 3. Usar mensagens amigáveis
```dart
String getUserFriendlyMessage(Exception e) {
  if (e is UniqueViolationException) {
    return 'Este email já está cadastrado';
  }
  if (e is NotNullViolationException) {
    return 'Por favor, preencha todos os campos obrigatórios';
  }
  return 'Ocorreu um erro. Por favor, tente novamente.';
}
```

## Testes

### Testes Unitários

```dart
group('PostgrestErrorMapper', () {
  test('maps unique violation correctly', () {
    final exception = PostgrestException(
      message: 'duplicate key',
      code: '23505',
    );
    
    final result = PostgrestErrorMapper.mapError(exception);
    
    expect(result, isA<UniqueViolationException>());
  });
  
  test('maps foreign key violation correctly', () {
    final exception = PostgrestException(
      message: 'foreign key constraint',
      code: '23503',
    );
    
    final result = PostgrestErrorMapper.mapError(exception);
    
    expect(result, isA<ForeignKeyViolationException>());
  });
});
```

### Testes de Integração

```dart
group('Error handling integration', () {
  test('handles duplicate email registration', () async {
    // Setup
    await supabase.from('users').insert({
      'email': 'test@example.com',
      'name': 'Test User',
    });
    
    // Test
    expect(
      () => authService.register('test@example.com', 'password'),
      throwsA(isA<UniqueViolationException>()),
    );
  });
});
```

## Extensibilidade

### Adicionar Novos Tipos de Erro

```dart
// 1. Adicionar novo código
class PostgrestErrorMapper {
  static Exception mapError(PostgrestException exception, {Map<String, dynamic>? context}) {
    switch (exception.code) {
      case 'NEW_CODE':
        return NewCustomException(exception.message);
      // ... existing cases
    }
  }
}

// 2. Criar nova exceção
class NewCustomException implements Exception {
  final String message;
  NewCustomException(this.message);
}

// 3. Adicionar mensagem amigável
String getUserFriendlyMessage(Exception e) {
  if (e is NewCustomException) {
    return 'Mensagem personalizada para novo erro';
  }
  // ... existing messages
}