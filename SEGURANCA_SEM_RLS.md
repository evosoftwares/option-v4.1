# Guia de Segurança sem RLS

## ⚠️ Importante
Com as políticas RLS desativadas, toda a segurança deve ser implementada no lado da aplicação Flutter.

## 🔒 Estratégias de Segurança

### 1. Validação de Usuário em Todas as Operações

```dart
// lib/services/auth_service.dart
class AuthService {
  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }
  
  static bool isAuthenticated() {
    return Supabase.instance.client.auth.currentUser != null;
  }
  
  static Future<bool> isUserAuthorized(String resourceUserId) async {
    final currentUserId = getCurrentUserId();
    return currentUserId != null && currentUserId == resourceUserId;
  }
}
```

### 2. Repository Pattern com Validação

```dart
// lib/repositories/base_repository.dart
abstract class BaseRepository {
  Future<T?> findByIdSecure<T>(String id, String userIdField) async {
    final currentUserId = AuthService.getCurrentUserId();
    if (currentUserId == null) throw UnauthorizedException();
    
    final response = await Supabase.instance.client
        .from(tableName)
        .select()
        .eq('id', id)
        .eq(userIdField, currentUserId)
        .maybeSingle();
        
    return response != null ? fromMap(response) : null;
  }
}
```

### 3. Middleware de Segurança

```dart
// lib/middleware/security_middleware.dart
class SecurityMiddleware {
  static Future<bool> validateUserAccess({
    required String resourceUserId,
    String? requiredRole,
  }) async {
    // Verificar autenticação
    if (!AuthService.isAuthenticated()) {
      throw UnauthorizedException('Usuário não autenticado');
    }
    
    final currentUserId = AuthService.getCurrentUserId()!;
    
    // Verificar se é o próprio usuário
    if (currentUserId == resourceUserId) {
      return true;
    }
    
    // Verificar role se necessário
    if (requiredRole != null) {
      final userRole = await _getUserRole(currentUserId);
      return userRole == requiredRole;
    }
    
    return false;
  }
  
  static Future<String?> _getUserRole(String userId) async {
    final response = await Supabase.instance.client
        .from('app_users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
        
    return response?['role'];
  }
}
```

### 4. Queries Seguras por Entidade

#### Trips
```dart
// lib/repositories/trip_repository.dart
class TripRepository {
  Future<List<Trip>> getUserTrips() async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) throw UnauthorizedException();
    
    final response = await Supabase.instance.client
        .from('trips')
        .select()
        .or('passenger_id.eq.$userId,driver_id.eq.$userId')
        .order('created_at', ascending: false);
        
    return response.map((json) => Trip.fromJson(json)).toList();
  }
}
```

#### Drivers
```dart
// lib/repositories/driver_repository.dart
class DriverRepository {
  Future<Driver?> getDriverProfile() async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) throw UnauthorizedException();
    
    final response = await Supabase.instance.client
        .from('drivers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
        
    return response != null ? Driver.fromJson(response) : null;
  }
}
```

#### Payments
```dart
// lib/repositories/payment_repository.dart
class PaymentRepository {
  Future<List<Payment>> getUserPayments() async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) throw UnauthorizedException();
    
    final response = await Supabase.instance.client
        .from('payments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
        
    return response.map((json) => Payment.fromJson(json)).toList();
  }
}
```

### 5. Interceptor Global

```dart
// lib/services/supabase_interceptor.dart
class SupabaseInterceptor {
  static void setupInterceptor() {
    // Adicionar user_id automaticamente em todas as inserções
    Supabase.instance.client.channel('public:*')
        .on(RealtimeListenTypes.insert, (payload) {
          // Log para auditoria
          print('Insert: ${payload.table} by ${AuthService.getCurrentUserId()}');
        });
  }
}
```

### 6. Validação de Formulários

```dart
// lib/validators/security_validators.dart
class SecurityValidators {
  static String? validateUserOwnership(String? resourceUserId) {
    final currentUserId = AuthService.getCurrentUserId();
    
    if (currentUserId == null) {
      return 'Usuário não autenticado';
    }
    
    if (resourceUserId != currentUserId) {
      return 'Acesso negado: recurso não pertence ao usuário';
    }
    
    return null;
  }
}
```

### 7. Exception Handling

```dart
// lib/exceptions/security_exceptions.dart
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Acesso não autorizado']);
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException([this.message = 'Operação não permitida']);
}
```

## 📋 Checklist de Segurança

### Para cada nova funcionalidade:
- [ ] Verificar autenticação do usuário
- [ ] Validar ownership dos recursos
- [ ] Filtrar dados por user_id
- [ ] Implementar logs de auditoria
- [ ] Testar cenários de acesso negado

### Para queries existentes:
- [ ] Adicionar filtro por user_id
- [ ] Remover dados sensíveis de outros usuários
- [ ] Validar parâmetros de entrada
- [ ] Implementar rate limiting se necessário

## 🔧 Implementação Gradual

1. **Fase 1**: Implementar AuthService e middleware
2. **Fase 2**: Atualizar repositories principais (trips, drivers, payments)
3. **Fase 3**: Adicionar validação em formulários
4. **Fase 4**: Implementar auditoria e logs
5. **Fase 5**: Testes de segurança

## 🚨 Monitoramento

```dart
// lib/services/security_monitor.dart
class SecurityMonitor {
  static void logSecurityEvent(String event, Map<String, dynamic> data) {
    print('SECURITY: $event - ${jsonEncode(data)}');
    // Enviar para serviço de monitoramento se necessário
  }
}
```

## ⚡ Performance

Sem RLS, as queries serão mais rápidas, mas certifique-se de:
- Usar índices apropriados
- Limitar resultados com `.limit()`
- Implementar paginação
- Cache dados quando apropriado

## 🔄 Migração Futura

Se decidir reativar RLS no futuro:
1. Manter a validação no app como backup
2. Implementar RLS gradualmente por tabela
3. Testar thoroughly antes de remover validação do app
4. Monitorar performance após reativação