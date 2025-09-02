import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'module_loader.dart';

// Tipos de mapa (mantidos para compatibilidade, mas não usados diretamente)
typedef MapLatLng = dynamic;
typedef MapMarker = dynamic;
typedef MapController = dynamic;
typedef MapType = dynamic;

class LazyMaps {
  factory LazyMaps() => _instance;
  LazyMaps._internal();
  static final LazyMaps _instance = LazyMaps._internal();

  bool _isLoaded = false;
  Completer<void>? _loadCompleter;
  dynamic _mapsLibrary;

  Future<void> loadMapsModule() async {
    if (_isLoaded) return;

    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<void>();

    try {
      dev.log('🗺️ Carregando Google Maps...', name: 'LazyMaps');
      
      // Simulação de carregamento do módulo
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verificar se o módulo maps está disponível
      final moduleLoader = ModuleLoader();
      await moduleLoader.loadModule(ModuleType.advancedMaps);
      
      _isLoaded = true;
      _loadCompleter!.complete();
      
      dev.log('✅ Google Maps carregado com sucesso', name: 'LazyMaps');
    } catch (e) {
      dev.log('❌ Erro ao carregar Google Maps: $e', name: 'LazyMaps');
      _loadCompleter!.completeError(e);
    }
  }

  Widget buildMapWidget({
    required maps.LatLng initialLocation,
    Set<maps.Marker>? markers,
    void Function(maps.GoogleMapController)? onMapCreated,
    void Function(maps.LatLng)? onTap,
    maps.MapType mapType = maps.MapType.normal,
    bool myLocationEnabled = true,
    bool myLocationButtonEnabled = true,
    bool zoomControlsEnabled = true,
  }) {
    if (!_isLoaded) {
      return FutureBuilder<void>(
        future: loadMapsModule(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }
          return _buildGoogleMap(
            initialLocation: initialLocation,
            markers: markers,
            onMapCreated: onMapCreated,
            onTap: onTap,
            mapType: mapType,
            myLocationEnabled: myLocationEnabled,
            myLocationButtonEnabled: myLocationButtonEnabled,
            zoomControlsEnabled: zoomControlsEnabled,
          );
        },
      );
    }

    return _buildGoogleMap(
      initialLocation: initialLocation,
      markers: markers,
      onMapCreated: onMapCreated,
      onTap: onTap,
      mapType: mapType,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
    );
  }

  Widget _buildGoogleMap({
    required maps.LatLng initialLocation,
    Set<maps.Marker>? markers,
    void Function(maps.GoogleMapController)? onMapCreated,
    void Function(maps.LatLng)? onTap,
    maps.MapType mapType = maps.MapType.normal,
    bool myLocationEnabled = true,
    bool myLocationButtonEnabled = true,
    bool zoomControlsEnabled = true,
  }) => maps.GoogleMap(
      initialCameraPosition: maps.CameraPosition(
        target: initialLocation,
        zoom: 14,
      ),
      markers: markers ?? <maps.Marker>{},
      onMapCreated: onMapCreated,
      onTap: onTap,
      mapType: mapType,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
    );

  Widget _buildLoadingWidget() => Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando Google Maps...'),
            Text('Aguarde um momento'),
          ],
        ),
      ),
    );

  Widget _buildErrorWidget(String error) => Container(
      color: Colors.red[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Erro ao carregar mapa'),
            Text(error, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _isLoaded = false;
                _loadCompleter = null;
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );

  static Future<maps.LatLng> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return maps.LatLng(position.latitude, position.longitude);
    } catch (e) {
      dev.log('❌ Erro ao obter localização: $e', name: 'LazyMaps');
      // Localização padrão (São Paulo)
      return const maps.LatLng(-23.5505, -46.6333);
    }
  }

  static Future<bool> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}