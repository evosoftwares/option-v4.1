import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/driver_status_controller.dart';
import '../../services/location_service.dart';
import '../../widgets/driver_earnings_widget.dart';
import '../../widgets/driver_bottom_sheet.dart';
import '../../services/map_style_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionSub;
  late final LocationService _locationService;
  late final DriverStatusController _statusController;

  static const CameraPosition _initialPos = CameraPosition(
    target: LatLng(-23.5505, -46.6333),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiKey: const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: ''),
    );
    _statusController = DriverStatusController();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
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
      ));
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
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
    });
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
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _markers,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: ListenableBuilder(
              listenable: _statusController,
              builder: (context, _) {
                return DriverEarningsWidget(
                  driverStatus: _statusController.status,
                  onTap: _showEarningsDetails,
                );
              },
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
              minHeight: 140,
              maxHeight: 300,
            ),
          ),
        ],
      ),
    );
  }
}