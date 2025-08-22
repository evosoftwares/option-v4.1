import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';
import '../../controllers/driver_status_controller.dart';
import '../../services/location_service.dart';
import '../../widgets/driver_earnings_widget.dart';
import '../../widgets/driver_bottom_sheet.dart';
import '../../services/map_style_service.dart';
import '../../services/driver_service.dart';
import '../../services/wallet_service.dart';
import '../../services/user_service.dart';
import '../../models/supabase/trip.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  List<LatLng> _progressPoints = [];
  Timer? _routeAnimTimer;
  int _routeAnimIndex = 0;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<Trip>>? _tripSub;
  String? _currentTripId;
  late final LocationService _locationService;
  late final DriverStatusController _statusController;
  int _lastProgressIndex = 0;

  String? _driverId; // cache do driverId para updates
  bool _revertingOnlineDueToPermission = false; // guarda para evitar loop ao reverter

  // Controle de envio para Supabase (throttle + movimentação mínima)
  DateTime? _lastLocationSentAt;
  LatLng? _lastSentLatLng;

  static const CameraPosition _initialPos = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiKey: AppConfig.googleMapsApiKey,
    );
    _statusController = DriverStatusController();
    _statusController.addListener(_onStatusChanged);
    _initLocation();
    _initActiveTrips();
  }

  @override
  void dispose() {
    _statusController.removeListener(_onStatusChanged);
    _positionSub?.cancel();
    _tripSub?.cancel();
    _routeAnimTimer?.cancel();
    _mapController?.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final current = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (current != null) {
      final controller = await _ensureController();
      final latLng = LatLng((current['lat'] as num).toDouble(), (current['lng'] as num).toDouble());
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 15),
      ),);
      _restartPositionStream();
    }
  }

  Future<void> _initActiveTrips() async {
    try {
      final user = await UserService.getCurrentUser();
      if (!mounted || user == null) return;
      final driverId = await WalletService().getDriverIdForUser(user.id);
      if (!mounted || driverId == null) return;

      _driverId = driverId; // manter em cache para updates de disponibilidade e localização

      _tripSub?.cancel();
      _tripSub = DriverService(Supabase.instance.client).streamDriverActiveTrips(driverId).listen((trips) async {
        if (!mounted) return;
        if (trips.isEmpty) {
          _currentTripId = null;
          _clearRoute();
          setState(() {
            _markers.removeWhere((m) => m.markerId.value == 'origin' || m.markerId.value == 'destination');
          });
          // Ajusta stream para modo sem corrida
          _restartPositionStream();
          return;
        }
        // Sort by createdAt desc to pick the latest active trip
        trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final trip = trips.first;
        if (_currentTripId == trip.id && _routePoints.isNotEmpty) {
          return; // Already displaying this trip
        }
        _currentTripId = trip.id;
        await _buildTripRoute(trip);
        // Ajusta stream para modo com corrida
        _restartPositionStream();
      });
    } catch (e) {
      // For now, swallow initialization errors silently to not break home screen
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

    // Configuração dinâmica baseada no estado
    int distanceFilter;
    int intervalSeconds;
    bool enableWakeLock;

    if (isOnline && _currentTripId != null) {
      // Em corrida: alta frequência e precisão
      distanceFilter = 5;
      intervalSeconds = 5;
      enableWakeLock = true;
    } else if (isOnline) {
      // Online sem corrida: equilíbrio
      distanceFilter = 20;
      intervalSeconds = 10;
      enableWakeLock = false;
    } else {
      // Offline: baixa frequência
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
        ),);
      });

      if (_statusController.isOnline) {
        controller.animateCamera(CameraUpdate.newLatLng(here));
      }

      // Atualiza progresso na rota quando há viagem ativa
      if (_currentTripId != null && _routePoints.length > 1) {
        _updateProgressToCurrentLocation(here);
      }

      // Persistir localização no Supabase quando online, com controle de taxa
      if (_statusController.isOnline && _driverId != null) {
        final now = DateTime.now();
        final lastAt = _lastLocationSentAt;
        final lastPoint = _lastSentLatLng;

        // Criterios: 5s ou movimento >= 50m
        bool shouldSend = false;
        if (lastAt == null || now.difference(lastAt) >= const Duration(seconds: 5)) {
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
            // silenciosamente ignora; haverá próxima tentativa
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
    // Atualiza disponibilidade no Supabase e reinicia stream com config adequada
    await _ensureDriverId();

    if (_statusController.isOnline) {
      // Garante permissão em segundo plano (Android)
      final ok = await _locationService.ensureLocationPermissions(background: true);
      if (!ok) {
        if (!_revertingOnlineDueToPermission) {
          _revertingOnlineDueToPermission = true;
          if (mounted) {
            final perm = await Geolocator.checkPermission();
            final isForever = perm == LocationPermission.deniedForever;
            if (isForever) {
              await showDialog<void>(
                context: context,
                builder: (ctx) {
                   final cs = Theme.of(ctx).colorScheme;
                   return AlertDialog(
                     title: const Text('Permissão de localização necessária'),
                     content: const Text(
                       'Para ficar online e receber corridas, permita a localização em segundo plano nas configurações do app. Você pode abrir diretamente os ajustes abaixo.',
                     ),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.of(ctx).pop(),
                         child: const Text('Cancelar'),
                       ),
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
                   );
                 },
               );
             } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Permissão de localização em segundo plano é necessária para ficar online.',
                  ),
                ),
              );
            }
          }
          // Reverte para offline
          _statusController.toggleOnlineStatus();
          // dá um pequeno tempo para evitar reentrância imediata
          await Future.delayed(const Duration(milliseconds: 200));
          _revertingOnlineDueToPermission = false;
        }
        return; // não continuar sem permissão
      }
    }

    if (_driverId != null) {
      try {
        await DriverService(Supabase.instance.client)
            .updateAvailability(_driverId!, _statusController.isOnline);
      } catch (_) {}
    }

    _restartPositionStream();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_mapControllerCompleter.isCompleted) {
      _mapControllerCompleter.complete(controller);
    }
    // Apply centralized map style based on current theme
    MapStyleService.applyForContext(controller, context);
  }

  void _navigateToDriverMenu() {
    Navigator.pushNamed(context, '/driver_menu');
  }

  Future<void> _buildTripRoute(Trip trip) async {
    final oLat = trip.originLatitude;
    final oLng = trip.originLongitude;
    final dLat = trip.destinationLatitude;
    final dLng = trip.destinationLongitude;

    if (oLat == 0.0 && oLng == 0.0) return;
    if (dLat == 0.0 && dLng == 0.0) return;

    // Set markers for origin/destination
    _setMarker('origin', oLat, oLng, BitmapDescriptor.hueGreen, title: 'Origem');
    _setMarker('destination', dLat, dLng, BitmapDescriptor.hueRed, title: 'Destino');

    _clearRoute();

    final route = await _locationService.getDrivingRoute(
      originLat: oLat,
      originLng: oLng,
      destLat: dLat,
      destLng: dLng,
    );
    if (!mounted || route == null) return;

    _routePoints = route.points;
    final colorScheme = Theme.of(context).colorScheme;

    setState(() {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route_base'),
        points: _routePoints,
        color: colorScheme.primary,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 1,
      ));

      // Initialize progress polyline at the starting point
      if (_routePoints.isNotEmpty) {
        _progressPoints = [_routePoints.first];
        _polylines.add(Polyline(
          polylineId: const PolylineId('route_progress'),
          points: List<LatLng>.from(_progressPoints),
          color: colorScheme.secondary,
          width: 8,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 2,
        ));
      }
    });

    await _fitRouteBounds();
    // Real-time progress will be updated from location stream; no time-based animation.
  }

  void _setMarker(String id, double lat, double lng, double hue, {String? title}) {
    final pos = LatLng(lat, lng);
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(Marker(
        markerId: MarkerId(id),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: title != null ? InfoWindow(title: title) : const InfoWindow(),
      ));
    });
  }

  Future<void> _fitRouteBounds() async {
    if (_routePoints.isEmpty) return;
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;
    for (final p in _routePoints) {
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
    _routeAnimTimer?.cancel();
    _routeAnimTimer = null;
    _routeAnimIndex = 0;
    _routePoints = [];
    _progressPoints = [];
    _lastProgressIndex = 0;
    setState(() {
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('route'));
    });
  }

  // Snap current position to nearest point along the route and update the progress polyline
  void _updateProgressToCurrentLocation(LatLng here) {
    if (_routePoints.length < 2) return;

    // Helper to convert lat/lng to local XY meters relative to a reference point (here)
    List<double> _toXY(LatLng p) {
      final lat0 = here.latitude * math.pi / 180.0;
      final dx = (p.longitude - here.longitude) * math.cos(lat0) * 111320.0; // meters per deg lon
      final dy = (p.latitude - here.latitude) * 110540.0; // meters per deg lat
      return [dx, dy];
    }

    final pXY = _toXY(here);
    double bestDist = double.infinity;
    int bestIndex = 0; // segment start index
    double bestT = 0.0;

    for (int i = _lastProgressIndex; i < _routePoints.length - 1; i++) {
      final a = _routePoints[i];
      final b = _routePoints[i + 1];
      final aXY = _toXY(a);
      final bXY = _toXY(b);
      final ab = [bXY[0] - aXY[0], bXY[1] - aXY[1]];
      final ap = [pXY[0] - aXY[0], pXY[1] - aXY[1]];
      final abLen2 = ab[0] * ab[0] + ab[1] * ab[1];
      if (abLen2 == 0) continue;
      double t = (ap[0] * ab[0] + ap[1] * ab[1]) / abLen2;
      t = t.clamp(0.0, 1.0);
      final proj = [aXY[0] + ab[0] * t, aXY[1] + ab[1] * t];
      final dx = pXY[0] - proj[0];
      final dy = pXY[1] - proj[1];
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < bestDist) {
        bestDist = dist;
        bestIndex = i;
        bestT = t;
      }
    }

    // If the closest point is far (e.g., > 150m), skip updates to avoid wrong snaps
    if (bestDist.isInfinite || bestDist > 150.0) return;

    // Interpolate snapped point in lat/lng
    LatLng _lerp(LatLng a, LatLng b, double t) {
      return LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
    }

    final snapped = _lerp(_routePoints[bestIndex], _routePoints[bestIndex + 1], bestT);

    // Prevent regress due to GPS noise
    if (bestIndex + (bestT > 0.8 ? 1 : 0) < _lastProgressIndex) {
      return;
    }

    _lastProgressIndex = math.max(_lastProgressIndex, bestIndex);

    final colorScheme = Theme.of(context).colorScheme;
    final newProgress = <LatLng>[]
      ..addAll(_routePoints.sublist(0, bestIndex + 1))
      ..add(snapped);

    setState(() {
      _progressPoints = newProgress;
      _polylines.removeWhere((p) => p.polylineId.value == 'route_progress');
      _polylines.add(Polyline(
        polylineId: const PolylineId('route_progress'),
        points: List<LatLng>.from(_progressPoints),
        color: colorScheme.secondary,
        width: 8,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 2,
      ));
    });
  }

  void _showEarningsDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ganhos Detalhados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: _statusController,
              builder: (context, _) {
                final status = _statusController.status;
                return Column(
                  children: [
                    _buildEarningsStat('Ganhos hoje', status.earningsDisplayText),
                    _buildEarningsStat('Viagens completadas', '${status.tripsCompleted}'),
                    _buildEarningsStat('Tempo online', _statusController.onlineTimeText),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsStat(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialPos,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _markers,
              polylines: _polylines,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: ListenableBuilder(
              listenable: _statusController,
              builder: (context, _) => DriverEarningsWidget(
                  driverStatus: _statusController.status,
                  onTap: _showEarningsDetails,
                ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _navigateToDriverMenu,
              backgroundColor: colorScheme.surface.withOpacity(0.95),
              foregroundColor: colorScheme.onSurface,
              elevation: 4,
              child: const Icon(Icons.menu),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DriverBottomSheet(
              statusController: _statusController,
            ),
          ),
        ],
      ),
    );
  }
}