import 'driver_status_controller.dart';

class DriverStatusManager {
  
  factory DriverStatusManager() => _instance;
  DriverStatusManager._internal();
  
  static final DriverStatusManager _instance = DriverStatusManager._internal();

  DriverStatusController? _controller;

  DriverStatusController get controller {
    if (_controller == null) {
      _controller = DriverStatusController();
      _controller!.initialize();
    }
    return _controller!;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}