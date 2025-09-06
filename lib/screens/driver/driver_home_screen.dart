import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../controllers/driver_status_controller.dart';
import '../../controllers/driver_status_manager.dart';
import '../../exceptions/app_exceptions.dart';
import '../../models/driver_status.dart';
import '../../models/supabase/trip.dart';
import '../../services/driver_service.dart';
// import '../../services/fcm_service.dart'; // Removido - usando OneSignal
import '../../services/location_service.dart';
import '../../services/map_style_service.dart';
import '../../services/user_service.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/driver_earnings_widget.dart';
import '../../widgets/feedback/index.dart';

/// Production-ready main driver screen with enhanced UI and Uber-like design
class DriverHomeScreen extends StatefulWidget {
  /// Creates a new instance of [DriverHomeScreen]
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _blackCarIcon;

  late final LocationService _locationService;
  late final DriverStatusController _statusController;
  late final AnimationController _buttonController;
  late final Animation<double> _buttonScaleAnimation;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<Trip>>? _tripSub;
  String? _currentTripId;
  String? _driverId;
  bool _revertingOnlineDueToPermission = false;
  bool _isProcessingStatusChange = false;

  DateTime? _lastLocationSentAt;
  LatLng? _lastSentLatLng;

  // UI States

  static const CameraPosition _initialPos = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initServices();
    _loadCarIcon();
    _initLocation();
    _initActiveTrips();
  }

  Future<void> _loadCarIcon() async {
    // Inicializar ícone preto de fallback
    _blackCarIcon = BitmapDescriptor.defaultMarkerWithHue(0); // 0 = vermelho, mais escuro disponível
    
    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(50, 50)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      // Usar ícone preto de fallback se não houver o asset
      _carIcon = _blackCarIcon;
    }
  }

  void _initControllers() {
    _statusController = DriverStatusManager().controller;
    _statusController.addListener(_onStatusChanged);

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initServices() {
    _locationService = LocationService(
      apiKey: AppConfig.googleMapsApiKey,
    );

    // Inicializar FCM Service para notificações push
    // FCMService().initialize().catchError((e) => {
    //   debugPrint('Erro ao inicializar FCMService: $e');
    // }); // Removido - usando OneSignal
  }

  @override
  void dispose() {
    _statusController.removeListener(_onStatusChanged);
    _buttonController.dispose();
    _positionSub?.cancel();
    _tripSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final current = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (current != null) {
      final controller = await _ensureController();
      final latLng = LatLng(
        (current['lat'] as num).toDouble(),
        (current['lng'] as num).toDouble(),
      );
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15),
        ),
      );
      _restartPositionStream();
    }
  }

  Future<void> _initActiveTrips() async {
    try {
      final user = await UserService.getCurrentUser();
      if (!mounted || user == null) return;
      final driverId = await WalletService().getDriverIdForUser(user.id);
      if (!mounted || driverId == null) return;

      _driverId = driverId;

      _tripSub?.cancel();
      _tripSub = DriverService(Supabase.instance.client)
          .streamDriverActiveTrips(driverId)
          .listen((trips) async {
        if (!mounted) return;
        if (trips.isEmpty) {
          _currentTripId = null;
          _clearRoute();
          if (mounted) {
            setState(() {
              _markers.removeWhere(
                (m) =>
                    m.markerId.value == 'origin' ||
                    m.markerId.value == 'destination',
              );
            });
          }
          _restartPositionStream();
          return;
        }
        trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final trip = trips.first;
        if (_currentTripId == trip.id) return;
        _currentTripId = trip.id;
        await _buildTripRoute(trip);
        _restartPositionStream();
      });
    } on Exception {
      // Handle initialization errors silently
    }
  }

  Future<GoogleMapController> _ensureController() async {
    if (_mapController != null) return _mapController!;
    return _mapControllerCompleter.future;
  }

  void _restartPositionStream() {
    _positionSub?.cancel();
    _startPositionStream();
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    final isOnline = _statusController.isOnline;

    int distanceFilter;
    int intervalSeconds;
    bool enableWakeLock;

    if (isOnline && _currentTripId != null) {
      distanceFilter = 5;
      intervalSeconds = 5;
      enableWakeLock = true;
    } else if (isOnline) {
      distanceFilter = 20;
      intervalSeconds = 10;
      enableWakeLock = false;
    } else {
      distanceFilter = 25;
      intervalSeconds = 15;
      enableWakeLock = false;
    }

    _positionSub = _locationService
        .positionStream(
      background: isOnline,
      distanceFilter: distanceFilter,
      intervalSeconds: intervalSeconds,
      enableWakeLock: enableWakeLock,
    )
        .listen((pos) async {
      final controller = await _ensureController();
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'driver_location');
          _markers.add(
            Marker(
              markerId: const MarkerId('driver_location'),
              position: here,
              icon: _carIcon ?? _blackCarIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(title: 'Sua localização'),
            ),
          );
        });
      }

      if (_statusController.isOnline) {
        controller.animateCamera(CameraUpdate.newLatLng(here));
      }

      // Update location in Supabase when online
      if (_statusController.isOnline && _driverId != null) {
        final now = DateTime.now();
        final lastAt = _lastLocationSentAt;
        final lastPoint = _lastSentLatLng;

        var shouldSend = false;
        if (lastAt == null ||
            now.difference(lastAt) >= const Duration(seconds: 5)) {
          shouldSend = true;
        } else if (lastPoint != null) {
          final meters = Geolocator.distanceBetween(
            lastPoint.latitude,
            lastPoint.longitude,
            here.latitude,
            here.longitude,
          );
          if (meters >= 50) shouldSend = true;
        }

        if (shouldSend) {
          try {
            await DriverService(Supabase.instance.client)
                .updateLocation(_driverId!, pos.latitude, pos.longitude);
            _lastLocationSentAt = now;
            _lastSentLatLng = here;
          } catch (_) {
            // Silently ignore; will retry on next update
          }
        }
      }
    });
  }

  Future<void> _ensureDriverId() async {
    if (_driverId != null) return;
    final user = await UserService.getCurrentUser();
    if (user != null) {
      _driverId = await WalletService().getDriverIdForUser(user.id);
    }
  }

  Future<void> _onStatusChanged() async {
    if (!mounted || _isProcessingStatusChange) return;

    _isProcessingStatusChange = true;

    try {
      // Use post frame callback to avoid setState during build
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await _ensureDriverId();

        if (_statusController.isOnline) {
          final ok = await _locationService.ensureLocationPermissions(
              background: true);
          if (!ok) {
            if (!_revertingOnlineDueToPermission) {
              _revertingOnlineDueToPermission = true;
              if (mounted) {
                await _showLocationPermissionDialog();
              }
              if (mounted) {
                _statusController.toggleOnlineStatus();
              }
              await Future.delayed(const Duration(milliseconds: 200));
              _revertingOnlineDueToPermission = false;
            }
            return;
          }

          // Pulse animation removed
        } else {
          // Pulse animation removed
        }

        if (_driverId != null && mounted) {
          try {
            await DriverService(Supabase.instance.client)
                .updateAvailability(_driverId!, _statusController.isOnline);
          } catch (_) {}
        }

        if (mounted) {
          _restartPositionStream();
        }
      });
    } finally {
      _isProcessingStatusChange = false;
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    final perm = await Geolocator.checkPermission();
    final isForever = perm == LocationPermission.deniedForever;

    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.location_off,
            size: 48,
            color: cs.error,
          ),
          title: const Text('Permissão de localização necessária'),
          content: Text(
            isForever
                ? 'Para ficar online e receber corridas, permita a localização em segundo plano nas configurações do app.'
                : 'Permissão de localização em segundo plano é necessária para ficar online.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            if (isForever) ...[
              TextButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Ajustes de localização'),
              ),
              FilledButton(
                onPressed: () {
                  ph.openAppSettings();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Ajustes do app'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
    }
    MapStyleService.applyForContext(controller, context);
  }

  Future<void> _buildTripRoute(Trip trip) async {
    final oLat = trip.originLatitude;
    final oLng = trip.originLongitude;
    final dLat = trip.destinationLatitude;
    final dLng = trip.destinationLongitude;

    if (oLat == 0.0 && oLng == 0.0) return;
    if (dLat == 0.0 && dLng == 0.0) return;

    _setMarker('origin', oLat, oLng, 0, title: 'Origem');
    _setMarker('destination', dLat, dLng, 0, title: 'Destino');

    _clearRoute();

    final route = await _locationService.getDrivingRoute(
      originLat: oLat,
      originLng: oLng,
      destLat: dLat,
      destLng: dLng,
    );
    if (!mounted || route == null) return;

    final colorScheme = Theme.of(context).colorScheme;

    if (mounted) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_base'),
            points: route.points,
            color: colorScheme.primary,
            width: 6,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      });
    }

    await _fitRouteBounds(route.points);
  }

  void _setMarker(
    String id,
    double lat,
    double lng,
    double hue, {
    String? title,
  }) {
    final pos = LatLng(lat, lng);
    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == id);
        _markers.add(
          Marker(
            markerId: MarkerId(id),
            position: pos,
            icon: _carIcon ?? _blackCarIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow:
                title != null ? InfoWindow(title: title) : InfoWindow.noText,
          ),
        );
      });
    }
  }

  Future<void> _fitRouteBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final controller = await _ensureController();
    controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, AppSpacing.headerHeight));
  }

  void _clearRoute() {
    if (mounted) {
      setState(() {
        _polylines.removeWhere((p) => p.polylineId.value.startsWith('route'));
      });
    }
  }

    Future<void> _onGoButtonPressed() async {
    print('🔵 [DRIVER_HOME] _onGoButtonPressed iniciado');
    HapticFeedback.mediumImpact();

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final status = _statusController.status;
    print('🔵 [DRIVER_HOME] Status atual: ${status.status}, isOnline: ${status.isOnline}, isTransitioning: ${status.isTransitioning}');
    
    // Se está online, vai offline diretamente
    if (status.isOnline) {
      print('🔵 [DRIVER_HOME] Motorista está online, chamando toggleOnlineStatus para ficar offline');
      await _statusController.toggleOnlineStatus();
      if (mounted) {
        print('🔵 [DRIVER_HOME] Exibindo notificação de offline');
        _showOfflineNotification();
      }
      print('🔵 [DRIVER_HOME] _onGoButtonPressed concluído (ficou offline)');
      return;
    }
    
    // Se está offline, tenta ficar online diretamente
    print('🔵 [DRIVER_HOME] Motorista está offline, tentando ficar online');
    try {
      print('🔵 [DRIVER_HOME] Chamando toggleOnlineStatus...');
      await _statusController.toggleOnlineStatus();
      print('🔵 [DRIVER_HOME] toggleOnlineStatus concluído com sucesso');
      
      if (mounted) {
        print('🔵 [DRIVER_HOME] Ficou online, exibindo notificação de sucesso');
        // Sucesso ao ficar online - mostrar notificação visual
        _showSuccessOnlineNotification();
      }
      print('🔵 [DRIVER_HOME] _onGoButtonPressed concluído (processo de ficar online)');
    } on DocumentationRequiredException catch (e) {
      print('🔵 [DRIVER_HOME] Erro de documentação necessária: ${e.message}');
      // Mostrar dialog visual para documentos
      if (mounted) {
        await _showDocumentationRequiredDialog(e.message);
      }
    } on ValidationException catch (e) {
      print('🔵 [DRIVER_HOME] Erro de validação: ${e.message}');
      // Mostrar dialog visual para erros de validação
      if (mounted) {
        await _showValidationErrorDialog(e.message);
      }
    } catch (e, stackTrace) {
      print('🔵 [DRIVER_HOME] Erro genérico: $e');
      print('🔵 [DRIVER_HOME] Stack trace: $stackTrace');
      // Mostrar dialog visual para erro genérico
      if (mounted) {
        await _showGenericErrorDialog('Erro ao tentar ficar online. Verifique sua conexão e tente novamente.');
      }
    }
  }

  /// Mostra notificação visual de sucesso ao ficar online
  void _showSuccessOnlineNotification() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Online!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você está pronto para receber viagens!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Mostra notificação visual ao ficar offline
  void _showOfflineNotification() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Offline',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você não receberá novas viagens',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    // Auto close after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Mostra dialog visual para documentos obrigatórios não aprovados
  Future<void> _showDocumentationRequiredDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Documentos Pendentes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Entendi'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/driver-documents');
                      },
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Enviar Documentos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra dialog visual para erros de validação
  Future<void> _showValidationErrorDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Não é Possível Ficar Online',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Entendi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra dialog visual para erros genéricos
  Future<void> _showGenericErrorDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ops! Algo deu errado',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoButton(DriverStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    Color buttonColor;
    Color textColor;
    String buttonText;
    IconData? icon;

    if (status.isTransitioning) {
      buttonColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
      buttonText = '';
      icon = null;
    } else if (status.isOnline) {
      buttonColor = colorScheme.error;
      textColor = colorScheme.onError;
      buttonText = 'PARAR';
      icon = Icons.stop;
    } else {
      buttonColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      buttonText = 'IR';
      icon = Icons.play_arrow;
    }

    final Widget button = AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) => Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 4,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: status.isTransitioning
                ? Center(
                    child: AppLoading(
                      type: AppLoadingType.circular,
                      size: AppLoadingSize.medium,
                      color: textColor,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: textColor,
                          size: AppSpacing.lg,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Text(
                        buttonText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: textColor,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
    );

    // Pulse animation removed as requested

    return GestureDetector(
      onTap: status.isTransitioning ? null : _onGoButtonPressed,
      child: button,
    );
  }

  void _navigateToDriverMenu() {
    Navigator.pushNamed(context, '/driver_menu');
  }

  void _navigateToWallet() {
    Navigator.pushNamed(context, '/wallet');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialPos,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _markers,
              polylines: _polylines,
              style: '',
            ),
          ),

          // Top overlay with earnings
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Earnings widget
                ListenableBuilder(
                  listenable: _statusController,
                  builder: (context, _) => DriverEarningsWidget(
                    driverStatus: _statusController.status,
                    onTap: _navigateToWallet,
                  ),
                ),

                // Menu button (Emergência ocultado)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão Emergência ocultado
                    // DecoratedBox(
                    //   decoration: BoxDecoration(
                    //     color: colorScheme.surface.withOpacity(0.95),
                    //     borderRadius: BorderRadius.circular(AppSpacing.lg + AppSpacing.xs),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: AppColors.black.withOpacity(0.1),
                    //         blurRadius: AppSpacing.sm,
                    //         offset: const Offset(0, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   child: const CompactEmergencyButton(),
                    // ),
                    // const SizedBox(width: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _navigateToDriverMenu,
                        icon: Icon(
                          Icons.menu,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom "IR" button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: ListenableBuilder(
                listenable: _statusController,
                builder: (context, _) =>
                    _buildGoButton(_statusController.status),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
