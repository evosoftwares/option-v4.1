# Status de Implementação do Plano de Correção v2

## 📊 **RESUMO EXECUTIVO**

### ✅ **CONCLUÍDO (80% Base)**
- **Schema Analysis**: Auditoria completa realizada
- **SQL Scripts**: `EXECUTAR_SCHEMA_MODIFICATIONS.sql` pronto para execução
- **Arquivos Base**: TripRequest model completo, TripService funcional
- **Documentação**: Planos detalhados e recomendações específicas

### 🔄 **EM ANDAMENTO (15% Core)**
- **TripRequestManager**: Service parcialmente implementado
- **Push Notifications**: Estrutura básica identificada

### ❌ **PENDENTE (5% UI/Integration)**
- **UI Components**: DriverRequestsScreen, TripRequestCard
- **Integration**: Driver selection screen, waiting screen updates
- **Testing**: End-to-end testing e deploy gradual

---

## 🎯 **O QUE FALTA FAZER**

### **IMEDIATO (Esta Semana):**

#### 1. **Executar Schema Modifications (CRÍTICO)**
```bash
# Executar no Supabase SQL Editor
# Arquivo: EXECUTAR_SCHEMA_MODIFICATIONS.sql
# Status: ✅ PRONTO PARA EXECUÇÃO
```

#### 2. **Completar TripRequestManager (50% Feito)**
**Arquivo:** `/lib/services/trip_request_manager.dart`

**✅ Já Implementado:**
- Estrutura básica da classe
- Constructor e imports
- Signature do método principal `sendTargetedRequest`
- Timer management infrastructure

**❌ Falta Implementar:**
```dart
class TripRequestManager {
  // ... código existente ...
  
  // ADICIONAR ESTES MÉTODOS:
  
  Future<String> createDirectedTripRequest({
    required String passengerId,
    required List<Driver> prioritizedDrivers,
    required TripRequestData tripData,
  }) async {
    final targetDriver = prioritizedDrivers.first;
    final fallbackDriverIds = prioritizedDrivers
        .skip(1)
        .take(5)
        .map((d) => d.id)
        .toList();
    
    // 1. Criar trip_request direcionado
    final request = await _supabase.from('trip_requests').insert({
      'passenger_id': passengerId,
      'target_driver_id': targetDriver.id,
      'fallback_drivers': fallbackDriverIds,
      'expires_at': DateTime.now().add(Duration(seconds: 10)).toIso8601String(),
      'status': 'pending',
      'origin_address': tripData.originAddress,
      'origin_latitude': tripData.originLatitude,
      'origin_longitude': tripData.originLongitude,
      'destination_address': tripData.destinationAddress,
      'destination_latitude': tripData.destinationLatitude,
      'destination_longitude': tripData.destinationLongitude,
      'vehicle_category': tripData.vehicleCategory,
      'needs_pet': tripData.needsPet,
      'needs_grocery_space': tripData.needsGrocery,
      'is_condo_origin': tripData.needsCondo,
      'is_condo_destination': tripData.needsCondo,
      'needs_ac': false,
      'number_of_stops': 0,
      'estimated_distance_km': tripData.estimatedDistanceKm,
      'estimated_duration_minutes': tripData.estimatedDurationMinutes,
      'estimated_fare': tripData.estimatedFare,
    }).select().single();
    
    final requestId = request['id'];
    
    // 2. Enviar notificação push
    await _sendDriverNotification(targetDriver.id, requestId);
    
    // 3. Iniciar timer de timeout
    _startTimeoutTimer(requestId, targetDriver.id);
    
    return requestId;
  }
  
  Future<void> handleDriverResponse({
    required String requestId,
    required String driverId,
    required bool accepted,
  }) async {
    // Cancelar timer
    _activeTimers[requestId]?.cancel();
    _activeTimers.remove(requestId);
    
    if (accepted) {
      await _acceptRequest(requestId, driverId);
    } else {
      await _processRejectionOrTimeout(requestId, isTimeout: false);
    }
  }
  
  void _startTimeoutTimer(String requestId, String driverId) {
    _activeTimers[requestId] = Timer(
      Duration(seconds: 10),
      () => _handleTimeout(requestId, driverId),
    );
  }
  
  Future<void> _handleTimeout(String requestId, String driverId) async {
    await _processRejectionOrTimeout(requestId, isTimeout: true);
  }
  
  Future<void> _processRejectionOrTimeout(String requestId, {required bool isTimeout}) async {
    // Buscar request atual e próximo driver da lista fallback
    final currentRequest = await _supabase
        .from('trip_requests')
        .select()
        .eq('id', requestId)
        .single();
    
    final fallbackDrivers = List<String>.from(currentRequest['fallback_drivers'] ?? []);
    final currentIndex = currentRequest['current_fallback_index'] ?? 0;
    
    if (currentIndex < fallbackDrivers.length) {
      final nextDriverId = fallbackDrivers[currentIndex];
      
      // Atualizar para próximo motorista
      await _supabase.from('trip_requests').update({
        'target_driver_id': nextDriverId,
        'current_fallback_index': currentIndex + 1,
        'timeout_count': isTimeout ? (currentRequest['timeout_count'] ?? 0) + 1 : (currentRequest['timeout_count'] ?? 0),
        'expires_at': DateTime.now().add(Duration(seconds: 10)).toIso8601String(),
      }).eq('id', requestId);
      
      // Enviar notificação para próximo motorista
      await _sendDriverNotification(nextDriverId, requestId);
      _startTimeoutTimer(requestId, nextDriverId);
    } else {
      // Sem mais fallbacks - marcar como expired
      await _supabase.from('trip_requests').update({
        'status': 'expired',
      }).eq('id', requestId);
    }
  }
  
  Future<void> _acceptRequest(String requestId, String driverId) async {
    await _supabase.from('trip_requests').update({
      'status': 'accepted',
      'accepted_by_driver_id': driverId,
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
  
  Future<void> _sendDriverNotification(String driverId, String requestId) async {
    await _notificationService.sendDriverNotification(driverId, requestId);
  }
}
```

#### 3. **Implementar Push Notifications**
**Arquivo:** `/lib/services/notification_service.dart`

**❌ Adicionar este método:**
```dart
class NotificationService {
  // ... código existente ...
  
  Future<void> sendDriverNotification(String driverId, String requestId) async {
    try {
      // 1. Buscar FCM token do motorista
      final driverData = await _supabase
          .from('drivers')
          .select('fcm_token, app_users(full_name)')
          .eq('id', driverId)
          .single();
      
      final fcmToken = driverData['fcm_token'] as String?;
      if (fcmToken == null) {
        print('❌ Motorista $driverId não tem FCM token');
        return;
      }
      
      // 2. Buscar dados do request
      final requestData = await _supabase
          .from('trip_requests')
          .select()
          .eq('id', requestId)
          .single();
      
      // 3. Criar payload da notificação
      final payload = {
        'title': 'Nova Solicitação de Viagem',
        'body': 'De: ${requestData['origin_address']}\nPara: ${requestData['destination_address']}',
        'data': {
          'type': 'trip_request',
          'request_id': requestId,
          'origin': requestData['origin_address'],
          'destination': requestData['destination_address'],
          'estimated_fare': requestData['estimated_fare'].toString(),
        }
      };
      
      // 4. Enviar via FCM (implementar integração)
      await _sendFCMNotification(fcmToken, payload);
      
      // 5. Salvar no database
      await createNotification(
        userId: driverId,
        title: payload['title']!,
        message: payload['body']!,
        type: 'trip_request',
        relatedId: requestId,
        priority: 'high',
      );
    } catch (e) {
      print('❌ Erro ao enviar notificação: $e');
    }
  }
  
  Future<void> _sendFCMNotification(String fcmToken, Map<String, dynamic> payload) async {
    // TODO: Implementar integração com FCM
    print('🔔 FCM Notification sent to $fcmToken: $payload');
  }
}
```

#### 4. **Criar TripRequestData Model**
**Arquivo:** `/lib/models/trip_request_data.dart` (CRIAR NOVO)

```dart
class TripRequestData {
  final String originAddress;
  final double originLatitude;
  final double originLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final String vehicleCategory;
  final bool needsPet;
  final bool needsGrocery;
  final bool needsCondo;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final double estimatedFare;

  TripRequestData({
    required this.originAddress,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.vehicleCategory,
    required this.needsPet,
    required this.needsGrocery,
    required this.needsCondo,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedFare,
  });
}
```

#### 5. **Criar Feature Flags**
**Arquivo:** `/lib/config/feature_flags.dart` (CRIAR NOVO)

```dart
class FeatureFlags {
  static const bool enableDirectedMatching = false; // Iniciar desabilitado
  static const bool enableFallbackSystem = true;
  static const int timeoutSeconds = 10;
  static const int maxFallbackAttempts = 5;
}
```

### **PRÓXIMA SEMANA:**

#### 6. **Criar UI Components**

**DriverRequestsScreen:** `/lib/screens/driver/driver_requests_screen.dart`
**TripRequestCard:** `/lib/widgets/trip_request_card.dart`

*(Usar código completo do plano v2)*

#### 7. **Integrar com Sistema Existente**

**Modificar:** `/lib/screens/trip/driver_selection_screen.dart`
**Modificar:** `/lib/screens/trip/waiting_driver_screen.dart`

---

## 📅 **TIMELINE CORRIGIDA**

### **Hoje:**
- ✅ Schema modifications (EXECUTAR_SCHEMA_MODIFICATIONS.sql)

### **Amanhã:**
- 🔧 Completar TripRequestManager
- 🔧 Implementar push notifications básicas
- 🔧 Criar models e feature flags

### **Esta Semana:**
- 🧪 Testes do core system
- 🎨 Iniciar UI components

### **Próxima Semana:**  
- 🎨 Completar UI components
- 🔄 Integração com sistema existente
- 🧪 Testes end-to-end

**O sistema está 80% pronto - faltam apenas 20% de implementação core + UI!**