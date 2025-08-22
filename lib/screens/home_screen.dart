import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../models/favorite_location.dart';
import 'place_picker_screen.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';
import '../models/user.dart' as app_user;
import '../widgets/logo_branding.dart';
import '../widgets/notification_icon_widget.dart';
import '../services/map_style_service.dart';
import '../theme/app_spacing.dart';
import '../services/recent_destinations_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  List<LatLng> _progressPoints = [];
  Timer? _routeAnimTimer;
  int _routeAnimIndex = 0;
  StreamSubscription<Position>? _positionSub;
  late final LocationService _locationService;
  Future<app_user.User?>? _userFuture;

  FavoriteLocation? _origin;
  FavoriteLocation? _destination;
  List<FavoriteLocation> _recentDestinations = [];
  
  final DraggableScrollableController _bottomSheetController = DraggableScrollableController();
  bool _isBottomSheetExpanded = false;

  static const CameraPosition _initialPos = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiKey: AppConfig.googleMapsApiKey,
    );
    _userFuture = UserService.getCurrentUser();
    _initLocation();
    _loadRecentDestinations();
  }

  Future<void> _initLocation() async {
    final current = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (current != null) {
      final controller = await _ensureController();
      final latLng = LatLng((current['lat'] as num).toDouble(), (current['lng'] as num).toDouble());
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 15)));
      _startPositionStream();
    }
  }

  Future<GoogleMapController> _ensureController() async {
    if (_mapController != null) return _mapController!;
    return _mapControllerCompleter.future;
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 5),
    ).listen((pos) async {
      final controller = await _ensureController();
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      // Não adicionar marker da posição atual - o mapa nativo já mostra
      controller.animateCamera(CameraUpdate.newLatLng(here));
    });
  }

  Future<void> _loadRecentDestinations() async {
    final recent = await RecentDestinationsService.instance.getRecentDestinations();
    if (mounted) {
      setState(() {
        _recentDestinations = recent;
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _routeAnimTimer?.cancel();
    _mapController?.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  Future<void> _pickOrigin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlacePickerScreen(title: 'Escolher origem')),
    );
    if (result is FavoriteLocation) {
      setState(() => _origin = result);
      _setMarker('origin', result.latitude, result.longitude, BitmapDescriptor.hueGreen);
      await _fitBounds();
      await _tryBuildRoute();
    }
  }

  Future<void> _pickDestination() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlacePickerScreen(title: 'Escolher destino')),
    );
    if (result is FavoriteLocation) {
      setState(() => _destination = result);
      _setMarker('destination', result.latitude, result.longitude, BitmapDescriptor.hueRed);
      await RecentDestinationsService.instance.addRecentDestination(result);
      await _loadRecentDestinations();
      await _fitBounds();
      await _tryBuildRoute();
    }
  }

  Future<void> _selectRecentDestination(FavoriteLocation destination) async {
    setState(() => _destination = destination);
    _setMarker('destination', destination.latitude, destination.longitude, BitmapDescriptor.hueRed);
    await RecentDestinationsService.instance.addRecentDestination(destination);
    await _loadRecentDestinations();
    await _fitBounds();
    await _tryBuildRoute();
  }

  void _setMarker(String id, double? lat, double? lng, double hue) {
    if (lat == null || lng == null) return;
    final pos = LatLng(lat, lng);
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(Marker(
        markerId: MarkerId(id),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      ),);
    });
  }

  Future<void> _fitBounds() async {
    if (_origin == null || _destination == null) return;
    final oLat = _origin!.latitude;
    final oLng = _origin!.longitude;
    final dLat = _destination!.latitude;
    final dLng = _destination!.longitude;
    if (oLat == null || oLng == null || dLat == null || dLng == null) return;

    final controller = await _ensureController();
    final sw = LatLng(
      math.min(oLat, dLat),
      math.min(oLng, dLng),
    );
    final ne = LatLng(
      math.max(oLat, dLat),
      math.max(oLng, dLng),
    );
    final bounds = LatLngBounds(southwest: sw, northeast: ne);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
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
    setState(() {
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('route'));
    });
  }

  Future<void> _tryBuildRoute() async {
    if (_origin == null || _destination == null) return;
    final oLat = _origin!.latitude;
    final oLng = _origin!.longitude;
    final dLat = _destination!.latitude;
    final dLng = _destination!.longitude;
    if (oLat == null || oLng == null || dLat == null || dLng == null) return;

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
    });

    await _fitRouteBounds();
    _startRouteAnimation(colorScheme);
  }

  void _startRouteAnimation(ColorScheme colorScheme) {
    if (_routePoints.length < 2) return;
    _progressPoints = [_routePoints.first];
    _routeAnimIndex = 1;

    // Duração aproximada: 8s para toda rota (ajustando passo por comprimento)
    final total = _routePoints.length;
    final stepMs = (8000 / total).clamp(12, 60).toInt();

    _routeAnimTimer?.cancel();
    _routeAnimTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      if (!mounted) return;
      if (_routeAnimIndex >= _routePoints.length) {
        timer.cancel();
        return;
      }
      _progressPoints.add(_routePoints[_routeAnimIndex]);
      _routeAnimIndex++;

      setState(() {
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
    });
  }

  Widget _buildLocationCard({
    required String label,
    required String placeholder,
    required IconData icon,
    required VoidCallback onTap,
    String? value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(icon, color: colorScheme.onSurface, size: AppSpacing.iconSm),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value?.isNotEmpty ?? false ? value! : placeholder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      color: value?.isNotEmpty ?? false 
                          ? colorScheme.onSurface 
                          : colorScheme.onSurfaceVariant,
                      fontWeight: value?.isNotEmpty ?? false 
                          ? FontWeight.w500 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.map_outlined,
              size: 60,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Seus destinos aparecerão aqui',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando você escolher um destino, ele será\nsalvo aqui para fácil acesso',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _navigateToMenu() async {
    final user = await _userFuture;
    if (user != null) {
      if (user.userType == 'driver') {
        Navigator.pushNamed(context, '/driver_menu');
      } else {
        Navigator.pushNamed(context, '/user_menu');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: LogoAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _navigateToMenu,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: NotificationIconWidget(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full screen map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (c) {
                _mapController = c;
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(c);
                }
                MapStyleService.applyForContext(c, context);
              },
              initialCameraPosition: _initialPos,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              polylines: _polylines,
            ),
          ),
          
          // Bottom sheet
          DraggableScrollableSheet(
            controller: _bottomSheetController,
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Para onde?',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  _buildLocationCard(
                                    label: 'Origem',
                                    placeholder: 'Sua localização atual',
                                    icon: Icons.my_location_outlined,
                                    onTap: _pickOrigin,
                                    value: _origin?.name ?? _origin?.address,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildLocationCard(
                                    label: 'Destino',
                                    placeholder: 'Para onde você quer ir?',
                                    icon: Icons.location_on_outlined,
                                    onTap: _pickDestination,
                                    value: _destination?.name ?? _destination?.address,
                                  ),
                                  
                                  const SizedBox(height: 32),
                            
                                  if (_recentDestinations.isNotEmpty) ...[
                                    Text(
                                      'Destinos recentes',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _recentDestinations.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final destination = _recentDestinations[index];
                                        return Card(
                                          elevation: 1,
                                          color: colorScheme.surface,
                                          child: ListTile(
                                            leading: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: colorScheme.primaryContainer,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                destination.type.icon,
                                                color: colorScheme.onPrimaryContainer,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              destination.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              destination.address,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap: () => _selectRecentDestination(destination),
                                          ),
                                        );
                                      },
                                    ),
                                  ] else
                                    _buildEmptyState(),
                                ],
                              ),
                            ),
                          ),
                          
                          // Fixed Trip button at bottom
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: (_origin != null && _destination != null) ? () {
                                  final o = _origin!;
                                  final d = _destination!;
                                  Navigator.pushNamed(
                                    context,
                                    '/trip_options',
                                    arguments: {
                                      'origin': {
                                        'id': o.id,
                                        'name': o.name,
                                        'address': o.address,
                                        'type': o.type.toString(),
                                        'latitude': o.latitude,
                                        'longitude': o.longitude,
                                        'placeId': o.placeId,
                                      },
                                      'destination': {
                                        'id': d.id,
                                        'name': d.name,
                                        'address': d.address,
                                        'type': d.type.toString(),
                                        'latitude': d.latitude,
                                        'longitude': d.longitude,
                                        'placeId': d.placeId,
                                      },
                                    },
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (_origin != null && _destination != null) 
                                      ? colorScheme.primary 
                                      : colorScheme.surfaceContainerHighest,
                                  foregroundColor: (_origin != null && _destination != null) 
                                      ? colorScheme.onPrimary 
                                      : colorScheme.onSurfaceVariant,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.directions_car_outlined, color: colorScheme.onPrimary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vamos',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: (_origin != null && _destination != null) 
                                            ? colorScheme.onPrimary 
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}