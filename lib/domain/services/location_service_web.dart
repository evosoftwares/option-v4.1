import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'app_logger.dart';

class LocationServiceWeb {
  LocationServiceWeb({required this.apiKey});
  final String apiKey;

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final startTime = DateTime.now();
    
    if (query.isEmpty) {
      AppLogger.validation('search_query', false, entity: 'LocationServiceWeb', error: 'Empty query');
      return [];
    }
    
    AppLogger.process('Iniciando busca de lugares (Web - Offline)', tag: 'LOCATION');
    AppLogger.query('offline_places_search', 1, tag: 'LOCATION', filters: {'query': query, 'country': 'br'});
    
    try {
      // For web, we'll provide a simplified offline experience
      // Instead of calling Google Places API directly (which causes CORS issues),
      // we provide manual entry with Brazilian cities as suggestions
      
      final duration = DateTime.now().difference(startTime);
      AppLogger.success('Busca de lugares concluída (Web - Offline)', tag: 'LOCATION');
      AppLogger.performance('search_places_web', duration, tag: 'LOCATION');
      
      return _searchBrazilianPlaces(query);
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.error('Erro ao buscar lugares (Web)', tag: 'LOCATION', error: e);
      AppLogger.connectivity('API_ERROR', type: 'Places Search Web', tag: 'LOCATION', details: {
        'error': e.toString(),
        'query': query,
        'duration_ms': duration.inMilliseconds
      });
      
      return _createManualSearchResult(query);
    }
  }

  List<Map<String, dynamic>> _searchBrazilianPlaces(String query) {
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Add manual entry option first
    results.add({
      'placeId': 'manual_${query.hashCode}',
      'description': query,
      'mainText': query,
      'secondaryText': 'Endereço digitado manualmente',
    });

    // Brazilian cities and neighborhoods database for autocomplete
    final brazilianPlaces = [
      'São Paulo, SP, Brasil',
      'Rio de Janeiro, RJ, Brasil', 
      'Brasília, DF, Brasil',
      'Salvador, BA, Brasil',
      'Fortaleza, CE, Brasil',
      'Belo Horizonte, MG, Brasil',
      'Manaus, AM, Brasil',
      'Curitiba, PR, Brasil',
      'Recife, PE, Brasil',
      'Goiânia, GO, Brasil',
      'Belém, PA, Brasil',
      'Porto Alegre, RS, Brasil',
      'Guarulhos, SP, Brasil',
      'Campinas, SP, Brasil',
      'São Luís, MA, Brasil',
      'São Gonçalo, RJ, Brasil',
      'Maceió, AL, Brasil',
      'Duque de Caxias, RJ, Brasil',
      'Teresina, PI, Brasil',
      'Natal, RN, Brasil',
    ];

    // Filter Brazilian places based on query
    for (final place in brazilianPlaces) {
      if (place.toLowerCase().contains(lowerQuery)) {
        final parts = place.split(',');
        results.add({
          'placeId': 'city_${place.hashCode}',
          'description': place,
          'mainText': parts[0].trim(),
          'secondaryText': parts.length > 1 ? parts.sublist(1).join(',').trim() : 'Brasil',
        });
      }
      
      if (results.length >= 10) break; // Limit results
    }

    return results;
  }

  List<Map<String, dynamic>> _createManualSearchResult(String query) {
    return [
      {
        'placeId': 'manual_${query.hashCode}',
        'description': query,
        'mainText': query,
        'secondaryText': 'Endereço digitado manualmente',
      }
    ];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    // If manual place, return default coordinates
    if (placeId.startsWith('manual_')) {
      return {
        'name': 'Local digitado manualmente',
        'formattedAddress': 'Endereço digitado pelo usuário',
        'lat': -23.5505, // São Paulo default coordinates
        'lng': -46.6333,
        'placeId': placeId,
      };
    }

    // For city places, extract city info and provide estimated coordinates
    if (placeId.startsWith('city_')) {
      final cityCoordinates = {
        'São Paulo': {'lat': -23.5505, 'lng': -46.6333},
        'Rio de Janeiro': {'lat': -22.9068, 'lng': -43.1729},
        'Brasília': {'lat': -15.7801, 'lng': -47.9292},
        'Salvador': {'lat': -12.9714, 'lng': -38.5014},
        'Fortaleza': {'lat': -3.7319, 'lng': -38.5267},
        'Belo Horizonte': {'lat': -19.9191, 'lng': -43.9386},
        'Manaus': {'lat': -3.1190, 'lng': -60.0217},
        'Curitiba': {'lat': -25.4244, 'lng': -49.2654},
        'Recife': {'lat': -8.0476, 'lng': -34.8770},
        'Goiânia': {'lat': -16.6799, 'lng': -49.2532},
      };

      // Try to find the city in our coordinates database
      for (final city in cityCoordinates.keys) {
        if (placeId.toLowerCase().contains(city.toLowerCase())) {
          final coords = cityCoordinates[city]!;
          return {
            'name': city,
            'formattedAddress': '$city, Brasil',
            'lat': coords['lat'],
            'lng': coords['lng'],
            'placeId': placeId,
          };
        }
      }
    }

    // Fallback for any other place
    return {
      'name': 'Local selecionado',
      'formattedAddress': 'Endereço selecionado pelo usuário',
      'lat': -23.5505,
      'lng': -46.6333,
      'placeId': placeId,
    };
  }

  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine ||
          permission == LocationPermission.denied) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
      };
    } catch (e) {
      print('Erro ao obter localização atual (Web): $e');
      return null;
    }
  }

  // Web doesn't support background location tracking
  Future<bool> ensureLocationPermissions({bool background = false}) async {
    if (background) {
      print('Background location not supported on web platform');
      return false;
    }

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (e) {
      print('Erro ao verificar permissões (Web): $e');
      return false;
    }
  }

  Stream<Position> positionStream({
    bool background = false,
    int distanceFilter = 10,
    int? intervalSeconds,
    bool enableWakeLock = true,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) {
    if (background) {
      throw UnsupportedError('Background location not supported on web platform');
    }

    final settings = LocationSettings(
      distanceFilter: distanceFilter,
      accuracy: accuracy,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<RouteResult?> getDrivingRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      print('🗺️ Calculando rota (Web - Estimativa)');
      
      // Calculate approximate distance and time for web platform
      // This is a simplified implementation for the web
      const double earthRadius = 6371000; // meters
      final double lat1Rad = originLat * (math.pi / 180);
      final double lat2Rad = destLat * (math.pi / 180);
      final double deltaLatRad = (destLat - originLat) * (math.pi / 180);
      final double deltaLngRad = (destLng - originLng) * (math.pi / 180);

      final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
          math.cos(lat1Rad) * math.cos(lat2Rad) *
          math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
      final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      final int distanceMeters = (earthRadius * c).round();

      // Estimate duration based on average urban speed (30 km/h)
      final int durationSeconds = ((distanceMeters / 1000) / 30 * 3600).round();

      return RouteResult(
        points: [LatLng(originLat, originLng), LatLng(destLat, destLng)],
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
      
    } catch (e) {
      print('Erro ao obter rota (Web): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      print('🌍 Geocodificando endereço (Web - Estimativa): $address');
      
      // Simplified geocoding for web - try to extract city from address
      final lowerAddress = address.toLowerCase();
      
      final cityCoordinates = {
        'são paulo': {'latitude': -23.5505, 'longitude': -46.6333},
        'rio de janeiro': {'latitude': -22.9068, 'longitude': -43.1729},
        'brasília': {'latitude': -15.7801, 'longitude': -47.9292},
        'salvador': {'latitude': -12.9714, 'longitude': -38.5014},
        'fortaleza': {'latitude': -3.7319, 'longitude': -38.5267},
        'belo horizonte': {'latitude': -19.9191, 'longitude': -43.9386},
        'manaus': {'latitude': -3.1190, 'longitude': -60.0217},
        'curitiba': {'latitude': -25.4244, 'longitude': -49.2654},
        'recife': {'latitude': -8.0476, 'longitude': -34.8770},
        'goiânia': {'latitude': -16.6799, 'longitude': -49.2532},
        'porto alegre': {'latitude': -30.0346, 'longitude': -51.2177},
        'guarulhos': {'latitude': -23.4538, 'longitude': -46.5333},
        'campinas': {'latitude': -22.9056, 'longitude': -47.0608},
      };
      
      // Try to match city in address
      for (final city in cityCoordinates.keys) {
        if (lowerAddress.contains(city)) {
          final coords = cityCoordinates[city]!;
          print('✅ Geocodificação bem-sucedida (Web): $city');
          return {
            'latitude': coords['latitude'],
            'longitude': coords['longitude'],
            'formatted_address': address,
          };
        }
      }
      
      print('⚠️ Cidade não encontrada, usando coordenadas padrão de São Paulo');
      // Default to São Paulo coordinates
      return {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'formatted_address': address,
      };
      
    } catch (e) {
      print('❌ Exceção na geocodificação (Web): $e');
      return null;
    }
  }
}

class RouteResult {
  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;
}