import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_sdk/google_places_sdk.dart';
import 'package:google_places_sdk/autocomplete_prediction.dart';
import 'package:google_places_sdk/place_details.dart';
import 'package:geocoding/geocoding.dart';

import '../../theme/app_theme.dart';

class PlacePickerScreen extends StatefulWidget {
  final String? title;
  final bool allowMultiple;
  final List<LatLng>? initialPlaces;

  const PlacePickerScreen({
    super.key,
    this.title,
    this.allowMultiple = false,
    this.initialPlaces,
  });

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  List<AutocompletePrediction> _suggestions = [];
  bool _isLoading = false;
  final String _googleApiKey = "AIzaSyB1WJiIpqAhWt0P_ZqlkbleZ5hUmqTQHBc"; // Replace with your actual API key

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-23.5505, -46.6333), // São Paulo
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      if (widget.allowMultiple) {
        _markers.add(
          Marker(
            markerId: MarkerId('marker_${_markers.length}'),
            position: position,
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      } else {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: position,
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      }
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _searchController.text = placemark.street != null && placemark.street!.isNotEmpty
            ? '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}'
            : '${placemark.subLocality}, ${placemark.locality}';
      } else {
        _searchController.text = 'Localização desconhecida';
      }
    } catch (e) {
      _searchController.text = 'Erro ao obter localização';
      print('Error during geocoding: $e');
    }
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final GooglePlaces googlePlaces = GooglePlaces();
      await googlePlaces.initialize(_googleApiKey);
      final List<AutocompletePrediction> predictions = await googlePlaces.getAutoCompletePredictions(query);
      setState(() {
        _suggestions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching places: $e');
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  void _selectPlace(AutocompletePrediction prediction) async {
    if (prediction.placeId == null) return;

    try {
      final PlaceDetails placeDetails = await GooglePlaces.fetchPlaceDetails(prediction.placeId!);

      if (placeDetails != null && placeDetails.result != null) {
        final location = LatLng(
          placeDetails.lat!,
          placeDetails.lng!,
        );
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15),
        );

        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId(prediction.placeId!),
              position: location,
              icon: BitmapDescriptor.defaultMarker,
            ),
          );
          _suggestions = [];
          _searchController.text = prediction.fullText ?? '';
        });
      } else {
        print('No place details found for ${prediction.placeId}');
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
  }

  void _savePlaces() {
    final places = _markers.map((marker) => marker.position).toList();
    Navigator.of(context).pop(places);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.uberBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.uberBlack,
        title: Text(widget.title ?? 'Selecionar Local'),
        actions: [
          if (_markers.isNotEmpty)
            TextButton(
              onPressed: _savePlaces,
              child: const Text(
                'Salvar',
                style: TextStyle(color: AppTheme.uberWhite),
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
              onChanged: _searchPlaces,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar lugares...',
                hintStyle: const TextStyle(color: AppTheme.uberLightGray),
                prefixIcon: const Icon(Icons.search, color: AppTheme.uberLightGray),
                filled: true,
                fillColor: AppTheme.uberDarkGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.uberDarkGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final prediction = _suggestions[index];
                  return ListTile(
                    title: Text(
                      prediction.structuredFormatting?.mainText ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      prediction.structuredFormatting?.secondaryText ?? '',
                      style: const TextStyle(color: AppTheme.uberLightGray),
                    ),
                    onTap: () => _selectPlace(prediction),
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
    );
  }
}