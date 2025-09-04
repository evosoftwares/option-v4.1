# Atualizações de Segurança Necessárias nos Services

## Resumo
Com a desativação das políticas RLS, todos os services que fazem queries no banco de dados precisam ser atualizados para incluir validações de `user_id` e verificações de autorização no lado da aplicação.

## Services que Precisam de Atualização

### 1. TripService (`lib/services/trip_service.dart`)
**Status**: ⚠️ CRÍTICO - Precisa de validação de ownership

**Métodos que precisam de validação**:
- `getTripRequests()` - Validar se passengerId pertence ao usuário atual
- `getTrips()` - Validar se passengerId/driverId pertence ao usuário atual
- `getTripHistory()` - Validar se passengerId/driverId pertence ao usuário atual
- `getUserLocations()` - Validar se userId é o usuário atual
- `subscribeToTripRequests()` - Validar ownership
- `getTargetedRequestsForDriver()` - Validar se driverId pertence ao usuário atual

**Implementação necessária**:
```dart
// Antes de cada query, adicionar:
final currentUserId = AuthService.getCurrentUserId();
if (currentUserId == null) throw AuthException('Usuário não autenticado');

// Para passageiros:
if (passengerId != null) {
  await AuthService.validateUserAccess(
    resourceUserId: passengerId,
    operation: 'getTripRequests'
  );
}

// Para motoristas:
if (driverId != null) {
  await AuthService.validateUserAccess(
    resourceUserId: driverId,
    operation: 'getDriverTrips'
  );
}
```

### 2. DriverWalletService (`lib/services/driver_wallet_service.dart`)
**Status**: ⚠️ CRÍTICO - Dados financeiros sensíveis

**Métodos que precisam de validação**:
- `getDriverWallet()` - Validar se userId é o usuário atual
- `getDriverWalletTransactions()` - Validar ownership
- `processTripPayment()` - Validar se driverId pertence ao usuário atual

### 3. WalletService (`lib/services/wallet_service.dart`)
**Status**: ⚠️ CRÍTICO - Dados financeiros sensíveis

**Métodos que precisam de validação**:
- `getWalletTransactions()` - Validar ownership
- `getPassengerIdForUser()` - Validar se userId é o usuário atual
- `getPassengerWalletTransactions()` - Validar ownership
- `debitTrip()` - Validar ownership
- `getPaymentMethods()` - Validar se userId é o usuário atual
- `getPassengerWalletSummary()` - Validar ownership

### 4. PaymentService (`lib/services/payment_service.dart`)
**Status**: ⚠️ CRÍTICO - Dados financeiros sensíveis

**Métodos que precisam de validação**:
- `getPaymentMethods()` - Já usa currentUser, mas precisa de validação adicional

### 5. RealSavedPlacesService (`lib/services/real_saved_places_service.dart`)
**Status**: ⚠️ MÉDIO - Dados pessoais

**Métodos que precisam de validação**:
- `getPlaces()` - Validar se userId é o usuário atual
- `hasPlaces()` - Validar se userId é o usuário atual

### 6. NotificationService (`lib/services/notification_service.dart`)
**Status**: ⚠️ MÉDIO - Dados pessoais

**Métodos que precisam de validação**:
- `streamUserNotifications()` - Validar se userId é o usuário atual

### 7. DriverService (`lib/services/driver_service.dart`)
**Status**: ⚠️ ALTO - Dados de motoristas

**Métodos que precisam de validação**:
- `getDriverActiveTrips()` - Validar se driverId pertence ao usuário atual
- `getNearbyDrivers()` - Método público, mas precisa de rate limiting

### 8. DriverScheduleService (`lib/services/driver_schedule_service.dart`)
**Status**: ⚠️ MÉDIO - Dados de horários

**Métodos que precisam de validação**:
- `getActiveSchedules()` - Validar se driverId pertence ao usuário atual

### 9. WorkingHoursService (`lib/services/working_hours_service.dart`)
**Status**: ⚠️ MÉDIO - Dados de horários

**Métodos que precisam de validação**:
- `getWorkingHours()` - Validar se driverId pertence ao usuário atual

### 10. SecureDriverExcludedZonesService (`lib/services/secure_driver_excluded_zones_service.dart`)
**Status**: ✅ PARCIAL - Já tem algumas validações, mas precisa revisar

## Padrão de Implementação

### 1. Validação Básica de Autenticação
```dart
static Future<void> _validateAuthentication() async {
  if (!AuthService.isAuthenticated()) {
    throw const AuthException('Usuário não autenticado');
  }
}
```

### 2. Validação de Ownership
```dart
static Future<void> _validateOwnership(String resourceUserId, String operation) async {
  await AuthService.validateUserAccess(
    resourceUserId: resourceUserId,
    operation: operation,
  );
}
```

### 3. Validação de Role (quando necessário)
```dart
static Future<void> _validateRole(String requiredRole, String operation) async {
  final hasRole = await AuthService.hasRole(requiredRole);
  if (!hasRole) {
    throw AuthException('Acesso negado: role $requiredRole necessária para $operation');
  }
}
```

### 4. Logging de Auditoria
```dart
static void _logAccess(String operation, String userId, {Map<String, dynamic>? context}) {
  print('🔒 [AUDIT] $operation - User: $userId - Context: ${context ?? {}}');
}
```

## Prioridade de Implementação

### Fase 1 - CRÍTICO (Implementar imediatamente)
1. **TripService** - Dados de viagens são críticos
2. **DriverWalletService** - Dados financeiros
3. **WalletService** - Dados financeiros
4. **PaymentService** - Dados financeiros

### Fase 2 - ALTO (Implementar em seguida)
1. **DriverService** - Dados de motoristas
2. **RealSavedPlacesService** - Dados pessoais

### Fase 3 - MÉDIO (Implementar depois)
1. **NotificationService** - Notificações
2. **DriverScheduleService** - Horários
3. **WorkingHoursService** - Horários

## Checklist de Implementação

Para cada service:
- [ ] Adicionar validação de autenticação em todos os métodos públicos
- [ ] Adicionar validação de ownership para recursos específicos do usuário
- [ ] Adicionar logging de auditoria para operações sensíveis
- [ ] Adicionar tratamento de exceções específicas
- [ ] Testar com usuários diferentes para garantir isolamento
- [ ] Documentar as mudanças de segurança

## Exemplo de Implementação Completa

```dart
// Exemplo para TripService.getTripRequests()
Future<List<TripRequest>> getTripRequests({
  String? passengerId,
  String? status,
  int? limit,
}) async {
  try {
    // 1. Validar autenticação
    await _validateAuthentication();
    
    // 2. Validar ownership se passengerId fornecido
    if (passengerId != null) {
      await _validateOwnership(passengerId, 'getTripRequests');
    } else {
      // Se não fornecido, usar o usuário atual
      final currentUserId = AuthService.getCurrentUserId()!;
      // Buscar passengerId do usuário atual
      passengerId = await _getPassengerIdForUser(currentUserId);
    }
    
    // 3. Log de auditoria
    _logAccess('getTripRequests', AuthService.getCurrentUserId()!, context: {
      'passengerId': passengerId,
      'status': status,
      'limit': limit,
    });
    
    // 4. Executar query com filtro obrigatório
    dynamic query = _supabase.from('trip_requests').select();
    
    // SEMPRE filtrar por passengerId (nunca permitir query sem filtro)
    query = query.eq('passenger_id', passengerId);
    
    if (status != null) {
      query = query.eq('status', status);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final response = await query.order('created_at', ascending: false);
    
    return response.map((json) => TripRequest.fromJson(json)).toList();
  } catch (e) {
    // Log do erro
    print('❌ [SECURITY] Erro em getTripRequests: $e');
    rethrow;
  }
}
```

## Notas Importantes

1. **Nunca permitir queries sem filtros de usuário** - Sempre filtrar por user_id, passenger_id, driver_id, etc.
2. **Validar ownership antes de executar queries** - Usar AuthService.validateUserAccess()
3. **Logar todas as operações sensíveis** - Para auditoria e debugging
4. **Tratar exceções específicas** - AuthException, DatabaseException, etc.
5. **Testar isolamento entre usuários** - Garantir que um usuário não acesse dados de outro

## Próximos Passos

1. Executar script `disable_all_rls.sql`
2. Implementar validações nos services críticos (Fase 1)
3. Testar isolamento entre usuários
4. Implementar validações nos services de alta prioridade (Fase 2)
5. Implementar validações nos services restantes (Fase 3)
6. Documentar e treinar equipe sobre novas práticas de segurança