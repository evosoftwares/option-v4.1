import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../services/location_service.dart';
import '../models/favorite_location.dart';
import '../services/map_style_service.dart';
// removed: import '../../theme/app_theme.dart';

class PlacePickerScreen extends StatefulWidget {
  final String? title;
  final bool allowMultiple;
  final List<LatLng>? initialPlaces;
  final String? apiKey;

  const PlacePickerScreen({
    super.key,
    this.title,
    this.allowMultiple = false,
    this.initialPlaces,
    this.apiKey,
  });

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  late final LocationService _locationService;
  Map<String, dynamic>? _selectedDetails;
  LatLng? _selectedLatLng;
  // Multi-select support
  final List<FavoriteLocation> _multiSelected = [];

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-23.5505, -46.6333), // São Paulo
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      apiKey: widget.apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: ''),
    );

    if (widget.initialPlaces != null) {
      _markers.addAll(
        widget.initialPlaces!.asMap().entries.map((entry) {
          return Marker(
            markerId: MarkerId('marker_${entry.key}'),
            position: entry.value,
            icon: BitmapDescriptor.defaultMarker,
          );
        }),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Apply centralized map style based on current theme
    MapStyleService.applyForContext(controller, context);
  }

  Future<void> _onMapTap(LatLng position) async {
    if (widget.allowMultiple) {
      // For multi-select, each tap adds a marker and a favorite location entry
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final p = placemarks.isNotEmpty ? placemarks.first : null;
        final street = (p?.street ?? '').trim();
        final subLocality = (p?.subLocality ?? '').trim();
        final locality = (p?.locality ?? '').trim();
        final address = [street, subLocality, locality].where((s) => s.isNotEmpty).join(', ');
        final fav = FavoriteLocation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: street.isNotEmpty ? street : 'Parada',
          address: address.isNotEmpty ? address : 'Endereço não informado',
          type: LocationType.other,
          latitude: position.latitude,
          longitude: position.longitude,
          placeId: null,
        );
        setState(() {
          _multiSelected.add(fav);
          _markers.add(
            Marker(
              markerId: MarkerId('marker_${_markers.length + 1}'),
              position: position,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
          _selectedDetails = null;
          _selectedLatLng = null;
        });
      } catch (e) {
        // Ignore reverse geocoding errors silently for UX
      }
      return;
    }

    setState(() {
      if (widget.allowMultiple) {
        // handled above
      } else {
        _markers
          ..clear()
          ..add(
            Marker(
              markerId: const MarkerId('selected_location'),
              position: position,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
      }
      _selectedDetails = null;
      _selectedLatLng = position;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final street = (p.street ?? '').trim();
        final subLocality = (p.subLocality ?? '').trim();
        final locality = (p.locality ?? '').trim();
        _searchController.text = [street, subLocality, locality]
            .where((s) => s.isNotEmpty)
            .join(', ');
      } else {
        _searchController.text = 'Localização desconhecida';
      }
    } catch (e) {
      _searchController.text = 'Erro ao obter localização';
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    final results = await _locationService.searchPlaces(query);
    if (!mounted) return;

    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    final placeId = prediction['placeId'] as String?;
    if (placeId == null) return;

    final details = await _locationService.getPlaceDetails(placeId);
    if (!mounted || details == null) return;

    final lat = details['lat'] as num?;
    final lng = details['lng'] as num?;
    if (lat == null || lng == null) return;

    final location = LatLng(lat.toDouble(), lng.toDouble());

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 15),
    );

    if (widget.allowMultiple) {
      // Add without clearing existing markers
      final fav = FavoriteLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: (details['name'] as String?)?.trim().isNotEmpty == true
            ? details['name'] as String
            : (prediction['mainText'] as String? ?? 'Parada'),
        address: (details['formattedAddress'] as String?) ?? (prediction['description'] as String? ?? ''),
        type: LocationType.other,
        latitude: location.latitude,
        longitude: location.longitude,
        placeId: details['placeId'] as String?,
      );
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: location,
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
        _suggestions = [];
        _searchController.clear();
        _searchFocus.unfocus();
        _multiSelected.add(fav);
      });
      return;
    }

    setState(() {
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: MarkerId(placeId),
            position: location,
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      _suggestions = [];
      _searchController.text = prediction['description'] as String? ?? '';
      _searchFocus.unfocus();
      _selectedDetails = details;
      _selectedLatLng = location;
    });
  }

  Future<LocationType?> _chooseType() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<LocationType>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text('Selecione o tipo', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final type in LocationType.values)
                      ListTile(
                        leading: Icon(type.icon, color: colorScheme.primary),
                        title: Text(type.label, style: TextStyle(color: colorScheme.onSurface)),
                        subtitle: Text(type.description, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        onTap: () => Navigator.pop(context, type),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _savePlaces() async {
    // If multiple selection mode, return all selected places
    if (widget.allowMultiple) {
      if (_multiSelected.isNotEmpty) {
        Navigator.of(context).pop(_multiSelected);
      }
      return;
    }

    // Compose a FavoriteLocation from the selected details or map tap
    final type = await _chooseType();
    if (type == null) return;

    final details = _selectedDetails;
    final pos = _selectedLatLng ?? (_markers.isNotEmpty ? _markers.first.position : null);

    if (details != null && pos != null) {
      final fav = FavoriteLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: (details['name'] as String?)?.trim().isNotEmpty == true ? details['name'] as String : 'Local favorito',
        address: (details['formattedAddress'] as String?) ?? (_searchController.text.isNotEmpty ? _searchController.text : 'Endereço não informado'),
        type: type,
        latitude: pos.latitude,
        longitude: pos.longitude,
        placeId: details['placeId'] as String?,
      );
      if (!mounted) return;
      Navigator.of(context).pop(fav);
      return;
    }

    if (pos != null) {
      final fav = FavoriteLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _searchController.text.isNotEmpty
            ? _searchController.text.split(',').first.trim()
            : 'Local favorito',
        address: _searchController.text.isNotEmpty
            ? _searchController.text
            : 'Endereço não informado',
        type: type,
        latitude: pos.latitude,
        longitude: pos.longitude,
        placeId: null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(fav);
      return;
    }

    // If nothing selected, do nothing
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        title: Text(
          widget.title ?? 'Selecionar local',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        actions: [
          if (_markers.isNotEmpty)
            TextButton(
              onPressed: _savePlaces,
              child: Text(
                'Salvar',
                style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _searchPlaces,
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar lugares... ',
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (_suggestions.isNotEmpty)
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outlineVariant),
                itemBuilder: (context, index) {
                  final s = _suggestions[index];
                  final mainText = s['mainText'] as String? ?? '';
                  final secondaryText = s['secondaryText'] as String? ?? '';
                  return ListTile(
                    title: Text(
                      mainText,
                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      secondaryText,
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    onTap: () => _selectPlace(s),
                  );
                },
              ),
            ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialCameraPosition,
              onTap: _onMapTap,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
          ),
        ],
      ),
      floatingActionButton: _markers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _savePlaces,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar'),
            )
          : null,
    );
  }
}