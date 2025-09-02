import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_status.dart';
import '../models/supabase/driver_effective_status.dart';
import '../models/supabase/working_hours.dart';
import '../services/driver_service.dart';
import '../services/user_service.dart';
import '../services/wallet_service.dart';

class DriverStatusController extends ChangeNotifier {
  DriverStatus _status = DriverStatus.initial();
  Timer? _earningsTimer;
  Timer? _onlineTimer;
  DateTime? _onlineStartTime;
  String? _driverId;
  bool _isInitialized = false;
  late final DriverService _driverService;

  DriverStatusController() {
    _driverService = DriverService(Supabase.instance.client);
  }

  DriverStatus get status => _status;

  bool get isOnline => _status.isOnline;
  bool get isOffline => _status.isOffline;
  bool get isTransitioning => _status.isTransitioning;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        _driverId = await WalletService().getDriverIdForUser(user.id);
        if (_driverId != null) {
          // Load current status from database
          final currentStatus = await _loadDriverStatus(_driverId!);
          if (currentStatus != null) {
            _updateStatus(_status.copyWith(
              status: currentStatus ? DriverOnlineStatus.online : DriverOnlineStatus.offline,
              lastStatusChange: DateTime.now(),
            ));
            
            if (currentStatus) {
              _startOnlineTimer();
              _startEarningsSimulation();
            }
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      // Handle initialization errors silently
      _isInitialized = true;
    }
  }

  Future<bool?> _loadDriverStatus(String driverId) async {
    try {
      final effectiveStatus = await _driverService.getDriverEffectiveStatus(driverId);
      return effectiveStatus?.effectiveOnline;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _earningsTimer?.cancel();
    _onlineTimer?.cancel();
    super.dispose();
  }

  Future<void> toggleOnlineStatus() async {
    if (_status.isTransitioning) return;
    
    // Salvar o estado atual antes de mudar para transitioning
    final currentStatus = _status.status;
    
    _updateStatus(_status.copyWith(
      status: DriverOnlineStatus.transitioning,
      lastStatusChange: DateTime.now(),
    ));

    await Future.delayed(const Duration(seconds: 2));

    // Usar o estado anterior para decidir a próxima ação
    if (currentStatus == DriverOnlineStatus.online) {
      await _goOffline();
    } else {
      await _goOnline();
    }
  }

  /// Tenta ficar online com validação de horário de trabalho
  /// Retorna true se conseguiu ficar online, false se precisa mostrar diálogo
  Future<bool> tryGoOnlineWithValidation() async {
    if (_status.isTransitioning) return false;
    
    // Verificar se pode ficar online agora
    final canGoOnline = await canGoOnlineNow();
    if (canGoOnline) {
      await toggleOnlineStatus();
      return true;
    }
    
    return false; // Precisa mostrar diálogo
  }

  /// Verifica se o motorista pode ficar online agora baseado no horário de trabalho
  Future<bool> canGoOnlineNow() async {
    if (_driverId == null) return false;
    
    try {
      return await _driverService.canDriverGoOnline(_driverId!);
    } catch (e) {
      return false;
    }
  }

  /// Obtém os horários de trabalho do motorista
  Future<List<WorkingHours>> getWorkingHours() async {
    if (_driverId == null) return [];
    
    try {
      return await _driverService.getDriverWorkingHours(_driverId!);
    } catch (e) {
      return [];
    }
  }

  /// Atualiza os horários de trabalho do motorista
  Future<void> updateWorkingHours(List<WorkingHours> workingHours) async {
    if (_driverId == null) return;
    
    try {
      await _driverService.updateDriverWorkingHours(_driverId!, workingHours);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _goOnline() async {
    if (_driverId == null) {
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.offline,
        lastStatusChange: DateTime.now(),
      ));
      return;
    }

    try {
      // Atualizar a intenção online no banco de dados
      await _driverService.updateDriver(_driverId!, isOnline: true);
      
      _onlineStartTime = DateTime.now();
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.online,
        lastStatusChange: DateTime.now(),
      ));

      _startOnlineTimer();
      _startEarningsSimulation();
    } catch (e) {
      // Se falhar, voltar para offline
      _updateStatus(_status.copyWith(
        status: DriverOnlineStatus.offline,
        lastStatusChange: DateTime.now(),
      ));
    }
  }

  Future<void> _goOffline() async {
    if (_driverId != null) {
      try {
        // Atualizar a intenção offline no banco de dados
        await _driverService.updateDriver(_driverId!, isOnline: false);
      } catch (e) {
        // Continue mesmo se falhar a atualização no banco
      }
    }

    _onlineStartTime = null;
    _earningsTimer?.cancel();
    _onlineTimer?.cancel();

    _updateStatus(_status.copyWith(
      status: DriverOnlineStatus.offline,
      lastStatusChange: DateTime.now(),
    ));
  }

  void _startOnlineTimer() {
    _onlineTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_onlineStartTime != null) {
        final newOnlineTime = DateTime.now().difference(_onlineStartTime!) + _status.onlineTime;
        _updateStatus(_status.copyWith(onlineTime: newOnlineTime));
      }
    });
  }

  void _startEarningsSimulation() {
    _earningsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final random = (DateTime.now().millisecondsSinceEpoch % 100) / 100;
      final increment = 5.0 + (random * 15.0);
      final newEarnings = _status.todayEarnings + increment;
      final newTrips = _status.tripsCompleted + (random > 0.7 ? 1 : 0);

      _updateStatus(_status.copyWith(
        todayEarnings: newEarnings,
        tripsCompleted: newTrips,
      ),);
    });
  }

  void _updateStatus(DriverStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  String get onlineTimeText {
    final duration = _status.onlineTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m online hoje';
    } else if (minutes > 0) {
      return '${minutes}m online hoje';
    } else {
      return 'Recém conectado';
    }
  }
}