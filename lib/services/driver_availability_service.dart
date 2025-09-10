import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para monitoramento em tempo real da disponibilidade de motoristas
/// Conforme especificação: "A tela de seleção do Passageiro observa o status 
/// dos Condutores em tempo real e desativa visualmente aqueles que ficarem indisponíveis"
class DriverAvailabilityService {
  DriverAvailabilityService(this._supabase);
  
  final SupabaseClient _supabase;
  
  // Streams para monitoramento
  StreamSubscription<List<Map<String, dynamic>>>? _driversSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _tripsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _requestsSubscription;
  
  // Controllers para combinação de streams
  final _availabilityController = StreamController<Map<String, DriverAvailabilityStatus>>.broadcast();
  
  // Cache local de disponibilidade
  final Map<String, DriverAvailabilityStatus> _availabilityCache = {};
  
  /// Stream principal que emite mudanças de disponibilidade dos motoristas
  Stream<Map<String, DriverAvailabilityStatus>> get availabilityStream => _availabilityController.stream;
  
  /// Inicia o monitoramento em tempo real para uma lista de motoristas
  Future<void> startMonitoring(List<String> driverIds) async {
    await stopMonitoring();
    
    if (driverIds.isEmpty) return;
    
    // 1. Monitor tabela drivers - status online e aprovação
    _driversSubscription = _supabase
        .from('drivers')
        .stream(primaryKey: ['id'])
        .inFilter('id', driverIds)
        .listen(_handleDriversUpdate);
    
    // 2. Monitor tabela trips - viagens ativas
    _tripsSubscription = _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .listen(_handleTripsUpdate);
    
    // 3. Monitor tabela trip_requests - solicitações pendentes
    _requestsSubscription = _supabase
        .from('trip_requests')
        .stream(primaryKey: ['id'])
        .listen(_handleRequestsUpdate);
  }
  
  /// Para o monitoramento
  Future<void> stopMonitoring() async {
    await _driversSubscription?.cancel();
    await _tripsSubscription?.cancel(); 
    await _requestsSubscription?.cancel();
    
    _driversSubscription = null;
    _tripsSubscription = null;
    _requestsSubscription = null;
    
    _availabilityCache.clear();
  }
  
  /// Processa atualizações da tabela drivers
  Future<void> _handleDriversUpdate(List<Map<String, dynamic>> drivers) async {
    for (final driver in drivers) {
      final driverId = driver['id'] as String;
      
      // Usar nova lógica baseada em driver_status
      final driverStatusResponse = await _supabase
          .from('driver_effective_status')
          .select('effective_online')
          .eq('driver_id', driver['id'])
          .maybeSingle();
      
      final isOnline = driverStatusResponse?['effective_online'] as bool? ?? false;
      final isApproved = driver['approval_status'] == 'approved';
      final lastUpdate = driver['last_location_update'] as String?;
      
      // Verificar se localização está muito desatualizada (mais de 5 minutos)
      var isLocationCurrent = true;
      if (lastUpdate != null) {
        final lastUpdateTime = DateTime.parse(lastUpdate);
        final now = DateTime.now();
        isLocationCurrent = now.difference(lastUpdateTime).inMinutes <= 5;
      }
      
      _updateDriverAvailability(driverId, (current) => current.copyWith(
        isOnline: isOnline,
        isApproved: isApproved,
        hasCurrentLocation: isLocationCurrent,
      ));
    }
  }
  
  /// Processa atualizações da tabela trips
  void _handleTripsUpdate(List<Map<String, dynamic>> trips) {
    // Primeiro, marcar todos os motoristas como não estando em viagem
    final driversInTrip = <String>{};
    
    for (final trip in trips) {
      final driverId = trip['driver_id'] as String?;
      if (driverId != null) {
        driversInTrip.add(driverId);
      }
    }
    
    // Atualizar status dos motoristas
    for (final driverId in _availabilityCache.keys) {
      _updateDriverAvailability(driverId, (current) => current.copyWith(
        isInActiveTrip: driversInTrip.contains(driverId),
      ));
    }
  }
  
  /// Processa atualizações da tabela trip_requests
  void _handleRequestsUpdate(List<Map<String, dynamic>> requests) {
    // Primeiro, marcar todos os motoristas como não tendo solicitação pendente
    final driversWithPendingRequest = <String>{};
    
    for (final request in requests) {
      final driverId = request['target_driver_id'] as String?;
      if (driverId != null) {
        driversWithPendingRequest.add(driverId);
      }
    }
    
    // Atualizar status dos motoristas
    for (final driverId in _availabilityCache.keys) {
      _updateDriverAvailability(driverId, (current) => current.copyWith(
        hasPendingRequest: driversWithPendingRequest.contains(driverId),
      ));
    }
  }
  
  /// Atualiza o status de disponibilidade de um motorista
  void _updateDriverAvailability(
    String driverId, 
    DriverAvailabilityStatus Function(DriverAvailabilityStatus) update,
  ) {
    final current = _availabilityCache[driverId] ?? DriverAvailabilityStatus.initial(driverId);
    final updated = update(current);
    
    // Só emitir se houve mudança real
    if (current != updated) {
      _availabilityCache[driverId] = updated;
      _availabilityController.add(Map.from(_availabilityCache));
    }
  }
  
  /// Obtém o status atual de um motorista
  DriverAvailabilityStatus? getDriverStatus(String driverId) => _availabilityCache[driverId];
  
  /// Verifica se um motorista está disponível
  bool isDriverAvailable(String driverId) {
    final status = getDriverStatus(driverId);
    return status?.isAvailable ?? false;
  }
  
  /// Limpa recursos
  void dispose() {
    stopMonitoring();
    _availabilityController.close();
  }
}

/// Status de disponibilidade de um motorista
@immutable
class DriverAvailabilityStatus {
  const DriverAvailabilityStatus({
    required this.driverId,
    required this.isOnline,
    required this.isApproved,
    required this.hasCurrentLocation,
    required this.isInActiveTrip,
    required this.hasPendingRequest,
    required this.lastUpdated,
  });
  
  factory DriverAvailabilityStatus.initial(String driverId) => DriverAvailabilityStatus(
    driverId: driverId,
    isOnline: true, // Assumir disponível inicialmente
    isApproved: true,
    hasCurrentLocation: true,
    isInActiveTrip: false,
    hasPendingRequest: false,
    lastUpdated: DateTime.now(),
  );
  
  final String driverId;
  final bool isOnline;
  final bool isApproved;
  final bool hasCurrentLocation;
  final bool isInActiveTrip;
  final bool hasPendingRequest;
  final DateTime lastUpdated;
  
  /// Verdadeiro se o motorista está disponível para receber solicitações
  bool get isAvailable => 
      isOnline && 
      isApproved && 
      hasCurrentLocation && 
      !isInActiveTrip && 
      !hasPendingRequest;
  
  /// Razão da indisponibilidade (para UI)
  String get unavailabilityReason {
    if (!isOnline) return 'Offline';
    if (!isApproved) return 'Aguardando aprovação';
    if (!hasCurrentLocation) return 'Localização desatualizada';
    if (isInActiveTrip) return 'Em viagem';
    if (hasPendingRequest) return 'Ocupado';
    return '';
  }
  
  /// Ícone para mostrar na UI
  String get statusIcon {
    if (!isOnline) return '🔴';
    if (!isApproved) return '⏳';
    if (!hasCurrentLocation) return '📍';
    if (isInActiveTrip) return '🚗';
    if (hasPendingRequest) return '⏱️';
    return '🟢';
  }
  
  DriverAvailabilityStatus copyWith({
    bool? isOnline,
    bool? isApproved,
    bool? hasCurrentLocation,
    bool? isInActiveTrip,
    bool? hasPendingRequest,
  }) => DriverAvailabilityStatus(
    driverId: driverId,
    isOnline: isOnline ?? this.isOnline,
    isApproved: isApproved ?? this.isApproved,
    hasCurrentLocation: hasCurrentLocation ?? this.hasCurrentLocation,
    isInActiveTrip: isInActiveTrip ?? this.isInActiveTrip,
    hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
    lastUpdated: DateTime.now(),
  );
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverAvailabilityStatus &&
          runtimeType == other.runtimeType &&
          driverId == other.driverId &&
          isOnline == other.isOnline &&
          isApproved == other.isApproved &&
          hasCurrentLocation == other.hasCurrentLocation &&
          isInActiveTrip == other.isInActiveTrip &&
          hasPendingRequest == other.hasPendingRequest;
  
  @override
  int get hashCode =>
      driverId.hashCode ^
      isOnline.hashCode ^
      isApproved.hashCode ^
      hasCurrentLocation.hashCode ^
      isInActiveTrip.hashCode ^
      hasPendingRequest.hashCode;
  
  @override
  String toString() => 'DriverAvailabilityStatus('
      'id: $driverId, '
      'available: $isAvailable, '
      'reason: $unavailabilityReason'
      ')';
}