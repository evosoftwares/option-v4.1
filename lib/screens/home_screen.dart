import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber_clone/models/favorite_location.dart';
import 'package:uber_clone/screens/place_picker_screen.dart';
import 'package:uber_clone/services/location_service.dart';
import 'package:uber_clone/services/user_service.dart';
import 'package:uber_clone/models/user.dart' as app_user;
import 'package:uber_clone/widgets/logo_branding.dart';
import '../services/map_style_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionSub;
  late final LocationService _locationService;
  Future<app_user.User?>? _userFuture;

  FavoriteLocation? _origin;
  FavoriteLocation? _destination;

  static const CameraPosition _initialPos = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiKey: const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: ''),
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5),
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
        ));
      });
      controller.animateCamera(CameraUpdate.newLatLng(here));
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
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
      ));
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

  Widget _buildTopCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(
                    value?.isNotEmpty == true ? value! : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      color: value?.isNotEmpty == true ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
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
        Navigator.pushNamed(context, '/user-menu');
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
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: (c) {
                _mapController = c;
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(c);
                }
                // Apply centralized map style based on current theme
                MapStyleService.applyForContext(c, context);
              },
              initialCameraPosition: _initialPos,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopCard(
                    label: 'Origem',
                    placeholder: 'Onde você está?',
                    icon: Icons.my_location,
                    onTap: _pickOrigin,
                    value: _origin?.address,
                  ),
                  const SizedBox(height: 12),
                  _buildTopCard(
                    label: 'Destino',
                    placeholder: 'Para onde?',
                    icon: Icons.location_on,
                    onTap: _pickDestination,
                    value: _destination?.address,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (_origin != null && _destination != null)
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.directions_car),
              label: const Text('Procurar corrida'),
            )
          : null,
    );
  }
}