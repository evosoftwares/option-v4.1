import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/driver_status.dart';

class DriverStatusController extends ChangeNotifier {
  DriverStatus _status = DriverStatus.initial();
  Timer? _earningsTimer;
  Timer? _onlineTimer;
  DateTime? _onlineStartTime;

  DriverStatus get status => _status;

  bool get isOnline => _status.isOnline;
  bool get isOffline => _status.isOffline;
  bool get isTransitioning => _status.isTransitioning;

  @override
  void dispose() {
    _earningsTimer?.cancel();
    _onlineTimer?.cancel();
    super.dispose();
  }

  Future<void> toggleOnlineStatus() async {
    if (_status.isTransitioning) return;

    _updateStatus(_status.copyWith(
      status: DriverOnlineStatus.transitioning,
      lastStatusChange: DateTime.now(),
    ));

    await Future.delayed(const Duration(seconds: 2));

    if (_status.isOnline || _status.isTransitioning) {
      await _goOffline();
    } else {
      await _goOnline();
    }
  }

  Future<void> _goOnline() async {
    _onlineStartTime = DateTime.now();
    _updateStatus(_status.copyWith(
      status: DriverOnlineStatus.online,
      lastStatusChange: DateTime.now(),
    ));

    _startOnlineTimer();
    _startEarningsSimulation();
  }

  Future<void> _goOffline() async {
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
      ));
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