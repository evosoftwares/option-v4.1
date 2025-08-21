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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionSub;
  late final LocationService _locationService;
  Future<app_user.User?>? _userFuture;

  FavoriteLocation? _origin;
  FavoriteLocation? _destination;
  
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
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'me');
        _markers.add(Marker(
          markerId: const MarkerId('me'),
          position: here,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),);
      });
      controller.animateCamera(CameraUpdate.newLatLng(here));
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
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
      _fitBounds();
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
      _fitBounds();
    }
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
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
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

  Widget _buildBottomSheetContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Para onde?',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildLocationCard(
                    label: 'Origem',
                    placeholder: 'Sua localização atual',
                    icon: Icons.my_location,
                    onTap: _pickOrigin,
                    value: _origin?.name ?? _origin?.address,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildLocationCard(
                    label: 'Destino',
                    placeholder: 'Para onde você quer ir?',
                    icon: Icons.location_on,
                    onTap: _pickDestination,
                    value: _destination?.name ?? _destination?.address,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick actions
                  Text(
                    'Acesso rápido',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.home,
                          label: 'Casa',
                          onTap: () {
                            // TODO: Implement home quick action
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.work,
                          label: 'Trabalho',
                          onTap: () {
                            // TODO: Implement work quick action
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          icon: Icons.star,
                          label: 'Favoritos',
                          onTap: () {
                            // TODO: Implement favorites quick action
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Trip button
                  if (_origin != null && _destination != null)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car),
                            const SizedBox(width: 8),
                            Text(
                              'Procurar corrida',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                              icon: Icons.my_location,
                              onTap: _pickOrigin,
                              value: _origin?.name ?? _origin?.address,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildLocationCard(
                              label: 'Destino',
                              placeholder: 'Para onde você quer ir?',
                              icon: Icons.location_on,
                              onTap: _pickDestination,
                              value: _destination?.name ?? _destination?.address,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Quick actions
                            Text(
                              'Acesso rápido',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickAction(
                                    icon: Icons.home,
                                    label: 'Casa',
                                    onTap: () {
                                      // TODO: Implement home quick action
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    icon: Icons.work,
                                    label: 'Trabalho',
                                    onTap: () {
                                      // TODO: Implement work quick action
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickAction(
                                    icon: Icons.star,
                                    label: 'Favoritos',
                                    onTap: () {
                                      // TODO: Implement favorites quick action
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Trip button
                            if (_origin != null && _destination != null)
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
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
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.directions_car),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Procurar corrida',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
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