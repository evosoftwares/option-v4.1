import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/background_location_service.dart';

/// Estados do controlador de localização do motorista
enum DriverLocationStatus {
  initial,
  loading,
  tracking,
  stopped,
  error,
}

/// Controlador para gerenciar a localização do motorista
class DriverLocationController extends ChangeNotifier {
  DriverLocationStatus _status = DriverLocationStatus.initial;
  Position? _lastPosition;
  DateTime? _lastUpdate;
  String? _errorMessage;
  
  DriverLocationController();
  
  // Getters
  DriverLocationStatus get status => _status;
  Position? get lastPosition => _lastPosition;
  DateTime? get lastUpdate => _lastUpdate;
  String? get errorMessage => _errorMessage;
  bool get isTracking => _status == DriverLocationStatus.tracking;
  
  /// Inicia o tracking de localização
  Future<void> startLocationTracking() async {
    try {
      _status = DriverLocationStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      // Verificar se é motorista autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _setError('Usuário não autenticado');
        return;
      }
      
      // Verificar se é motorista no banco
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id, approval_status')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (driverResponse == null) {
        _setError('Usuário não é motorista');
        return;
      }
      
      if (driverResponse['approval_status'] != 'approved') {
        _setError('Motorista não aprovado');
        return;
      }
      
      // Atualizar driver_status para online_intent = true
      await Supabase.instance.client
          .from('driver_status')
          .upsert({
            'driver_id': driverResponse['id'],
            'online_intent': true,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      // Inicializar e iniciar o serviço de localização
      await BackgroundLocationService.initialize();
      await BackgroundLocationService.startLocationTracking();
      
      _status = DriverLocationStatus.tracking;
      notifyListeners();
      
    } catch (e) {
      _setError('Erro ao iniciar tracking: $e');
    }
  }
  
  /// Para o tracking de localização
  Future<void> stopLocationTracking() async {
    try {
      // Verificar se é motorista autenticado
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Buscar ID do motorista
        final driverResponse = await Supabase.instance.client
            .from('drivers')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();
        
        if (driverResponse != null) {
          // Atualizar driver_status para online_intent = false
          await Supabase.instance.client
              .from('driver_status')
              .upsert({
                'driver_id': driverResponse['id'],
                'online_intent': false,
                'updated_at': DateTime.now().toIso8601String(),
              });
        }
      }
      
      await BackgroundLocationService.stopLocationTracking();
      _status = DriverLocationStatus.stopped;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao parar tracking: $e');
    }
  }
  
  /// Atualiza o status da localização
  void updateLocationStatus(Position? position, DateTime? timestamp) {
    if (_status == DriverLocationStatus.tracking) {
      _lastPosition = position;
      _lastUpdate = timestamp;
      notifyListeners();
    }
  }
  
  /// Define um erro
  void _setError(String message) {
    _status = DriverLocationStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}