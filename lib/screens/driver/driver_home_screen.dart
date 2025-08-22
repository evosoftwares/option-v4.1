import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../controllers/driver_status_controller.dart';
import '../../models/driver_status.dart';
import '../../models/supabase/trip.dart';
import '../../services/driver_service.dart';
import '../../services/location_service.dart';
import '../../services/map_style_service.dart';
import '../../services/user_service.dart';
import '../../services/wallet_service.dart';

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

  late final LocationService _locationService;
  late final DriverStatusController _statusController;
  late final AnimationController _pulseController;
  late final AnimationController _buttonController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _buttonScaleAnimation;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<Trip>>? _tripSub;
  String? _currentTripId;
  String? _driverId;
  bool _revertingOnlineDueToPermission = false;

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
    _initLocation();
    _initActiveTrips();
  }

  void _initControllers() {
    _statusController = DriverStatusController();
    _statusController.addListener(_onStatusChanged);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
  }

  void _initServices() {
    _locationService = LocationService(
      apiKey: AppConfig.googleMapsApiKey,
    );
  }

  @override
  void dispose() {
    _statusController.removeListener(_onStatusChanged);
    _statusController.dispose();
    _pulseController.dispose();
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
      await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 15),
      ));
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
          setState(() {
            _markers.removeWhere((m) =>
                m.markerId.value == 'origin' ||
                m.markerId.value == 'destination');
          });
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
      accuracy: LocationAccuracy.best,
    )
        .listen((pos) async {
      final controller = await _ensureController();
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'driver_location');
        _markers.add(Marker(
          markerId: const MarkerId('driver_location'),
          position: here,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Sua localização'),
        ));
      });

      if (_statusController.isOnline) {
        controller.animateCamera(CameraUpdate.newLatLng(here));
      }

      // Update location in Supabase when online
      if (_statusController.isOnline && _driverId != null) {
        final now = DateTime.now();
        final lastAt = _lastLocationSentAt;
        final lastPoint = _lastSentLatLng;

        bool shouldSend = false;
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
    await _ensureDriverId();

    if (_statusController.isOnline) {
      final ok =
          await _locationService.ensureLocationPermissions(background: true);
      if (!ok) {
        if (!_revertingOnlineDueToPermission) {
          _revertingOnlineDueToPermission = true;
          if (mounted) {
            await _showLocationPermissionDialog();
          }
          _statusController.toggleOnlineStatus();
          await Future.delayed(const Duration(milliseconds: 200));
          _revertingOnlineDueToPermission = false;
        }
        return;
      }

      // Start pulse animation when online
      _pulseController.repeat(reverse: true);
    } else {
      // Stop pulse animation when offline
      _pulseController.stop();
      _pulseController.reset();
    }

    if (_driverId != null) {
      try {
        await DriverService(Supabase.instance.client)
            .updateAvailability(_driverId!, _statusController.isOnline);
      } catch (_) {}
    }

    _restartPositionStream();
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

    _setMarker('origin', oLat, oLng, BitmapDescriptor.hueGreen,
        title: 'Origem');
    _setMarker('destination', dLat, dLng, BitmapDescriptor.hueRed,
        title: 'Destino');

    _clearRoute();

    final route = await _locationService.getDrivingRoute(
      originLat: oLat,
      originLng: oLng,
      destLat: dLat,
      destLng: dLng,
    );
    if (!mounted || route == null) return;

    final colorScheme = Theme.of(context).colorScheme;

    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route_base'),
        points: route.points,
        color: colorScheme.primary,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ));
    });

    await _fitRouteBounds(route.points);
  }

  void _setMarker(String id, double lat, double lng, double hue,
      {String? title}) {
    final pos = LatLng(lat, lng);
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(Marker(
        markerId: MarkerId(id),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow:
            title != null ? InfoWindow(title: title) : InfoWindow.noText,
      ));
    });
  }

  Future<void> _fitRouteBounds(List<LatLng> points) async {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

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
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  void _clearRoute() {
    setState(() {
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('route'));
    });
  }

  Future<void> _onGoButtonPressed() async {
    HapticFeedback.mediumImpact();

    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });

    await _statusController.toggleOnlineStatus();
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

    Widget button = Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: buttonColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: status.isTransitioning
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: textColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  buttonText,
                  style: textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );

    if (status.isOnline && !status.isTransitioning) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: button,
        ),
      );
    }

    button = AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _buttonScaleAnimation.value,
        child: button,
      ),
    );

    return GestureDetector(
      onTap: status.isTransitioning ? null : _onGoButtonPressed,
      child: button,
    );
  }

  void _navigateToDriverMenu() {
    Navigator.pushNamed(context, '/driver_menu');
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
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Earnings widget
                ListenableBuilder(
                  listenable: _statusController,
                  builder: (context, _) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusController.status.earningsDisplayText,
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Menu button
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
          ),

          // Bottom "IR" button
          Positioned(
            bottom: 32,
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
