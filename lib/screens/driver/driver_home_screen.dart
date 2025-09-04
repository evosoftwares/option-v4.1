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
import '../../widgets/working_hours_dialog.dart';
import '../../controllers/driver_status_manager.dart';
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
    try {
      _carIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      // Fallback para o ícone padrão se houver erro
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
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
              icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
            icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
    HapticFeedback.mediumImpact();

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    final status = _statusController.status;
    
    // Se está online, vai offline diretamente
    if (status.isOnline) {
      await _statusController.toggleOnlineStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.offline_bolt, color: Colors.white),
                SizedBox(width: 8),
                Text('Você está agora offline'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Se está offline, verifica horário de trabalho antes de ficar online
    final canGoOnline = await _statusController.tryGoOnlineWithValidation();
    
    if (canGoOnline && mounted) {
      // Sucesso ao ficar online
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.online_prediction, color: Colors.white),
              SizedBox(width: 8),
              Text('Você está agora online e pronto para receber viagens!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (!canGoOnline && mounted) {
      // Tentativa fora do horário - mostrar feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.schedule, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Fora do horário de trabalho configurado')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Configurar',
            textColor: Colors.white,
            onPressed: () {
              // Mostrar diálogo de horário de trabalho
              showWorkingHoursDialog(
                context: context,
                statusController: _statusController,
                onWorkingHoursUpdated: () {
                  // Callback quando horários são atualizados
                },
              );
            },
          ),
        ),
      );
      
      // Também mostrar diálogo após um pequeno delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await showWorkingHoursDialog(
          context: context,
          statusController: _statusController,
          onWorkingHoursUpdated: () {
            // Callback quando horários são atualizados
          },
        );
      }
    }
  }

  Widget _buildGoButton(DriverStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                        style: textTheme.titleLarge?.copyWith(
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
    final textTheme = Theme.of(context).textTheme;

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
