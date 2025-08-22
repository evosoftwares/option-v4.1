import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geolocator_android/geolocator_android.dart';

class LocationService {

  LocationService({required this.apiKey});
  final String apiKey;

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$apiKey'
      '&language=pt-BR'
      '&components=country:br'
    );

    try {
      print('Fazendo requisição para: $url');
      final response = await http.get(url);
      
      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar se há erro na resposta da API
        if (data['status'] != 'OK') {
          print('Erro da API Google Places: ${data['status']} - ${data['error_message'] ?? 'Sem mensagem de erro'}');
          
          // Se a API falhar, retornar resultado básico para entrada manual
          return _createManualSearchResult(query);
        }
        
        final predictions = data['predictions'] as List? ?? [];
        
        return predictions.map((prediction) => {
            'placeId': prediction['place_id'],
            'description': prediction['description'],
            'mainText': prediction['structured_formatting']?['main_text'] ?? '',
            'secondaryText': prediction['structured_formatting']?['secondary_text'] ?? '',
          }).toList();
      } else {
        print('Erro HTTP: ${response.statusCode} - ${response.body}');
        // Se houve erro HTTP, retornar resultado básico para entrada manual
        return _createManualSearchResult(query);
      }
    } catch (e) {
      print('Erro ao buscar lugares: $e');
      // Se houve erro de conexão, retornar resultado básico para entrada manual
      return _createManualSearchResult(query);
    }
  }

  List<Map<String, dynamic>> _createManualSearchResult(String query) {
    // Criar um resultado básico para entrada manual quando a API falha
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
    // Se for um place manual, retornar detalhes básicos
    if (placeId.startsWith('manual_')) {
      return {
        'name': 'Local digitado manualmente',
        'formattedAddress': 'Endereço digitado pelo usuário',
        'lat': -23.5505, // Coordenadas padrão de São Paulo
        'lng': -46.6333,
        'placeId': placeId,
      };
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$apiKey'
      '&language=pt-BR'
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar se há erro na resposta da API
        if (data['status'] != 'OK') {
          print('Erro da API Place Details: ${data['status']} - ${data['error_message'] ?? 'Sem mensagem de erro'}');
          return null;
        }
        
        final result = data['result'];
        
        if (result != null) {
          return {
            'name': result['name'] ?? '',
            'formattedAddress': result['formatted_address'] ?? '',
            'lat': result['geometry']['location']['lat'],
            'lng': result['geometry']['location']['lng'],
            'placeId': placeId,
          };
        }
      } else {
        print('Erro HTTP (Place Details): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro ao obter detalhes do lugar: $e');
    }
    
    return null;
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
      print('Erro ao obter localização atual: $e');
      return null;
    }
  }

  // ------------------ BACKGROUND / STREAM ------------------
  /// Garante permissões para uso de localização. Quando [background] é true,
  /// solicita também permissão "sempre" no Android (locationAlways) e, em Android 13+, notificação.
  Future<bool> ensureLocationPermissions({bool background = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        print('Serviço de localização desativado no dispositivo.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Solicita permissão em segundo plano quando necessário (Android)
      if (background && Platform.isAndroid) {
        final status = await ph.Permission.locationAlways.status;
        if (!status.isGranted) {
          final result = await ph.Permission.locationAlways.request();
          if (!result.isGranted) {
            print('Permissão de localização em segundo plano não concedida.');
            return false;
          }
        }

        // Android 13+ exige permissão de notificação para exibir notificação do serviço em primeiro plano
        final notifStatus = await ph.Permission.notification.status;
        if (!notifStatus.isGranted) {
          final notifResult = await ph.Permission.notification.request();
          if (!notifResult.isGranted) {
            print('Permissão de notificação não concedida.');
            return false;
          }
        }
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      return true;
    } catch (e) {
      print('Erro ao verificar/perguntar permissões: $e');
      return false;
    }
  }

  /// Fornece um stream de posições com configurações adequadas para
  /// funcionamento em segundo plano no Android quando [background] = true.
  Stream<Position> positionStream({
    bool background = false,
    int distanceFilter = 10,
    int? intervalSeconds,
    bool enableWakeLock = true,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) {
    if (background && Platform.isAndroid) {
      final settings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: Duration(seconds: intervalSeconds ?? 10),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationText: 'Rastreamento de localização ativo',
          notificationTitle: 'OPTION em execução',
          enableWakeLock: enableWakeLock,
        ),
      );
      return Geolocator.getPositionStream(locationSettings: settings);
    }

    // Padrão (foreground ou iOS sem necessidade de notificação)
    final settings = LocationSettings(
      distanceFilter: distanceFilter,
      accuracy: accuracy,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  // ------------------ DIRECTIONS / ROUTE ------------------
  Future<RouteResult?> getDrivingRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&mode=driving'
      '&language=pt-BR'
      '&alternatives=false'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        print('Erro HTTP (Directions): ${response.statusCode} - ${response.body}');
        return null;
      }
      final data = json.decode(response.body);
      if (data['status'] != 'OK') {
        print('Erro da API Directions: ${data['status']} - ${data['error_message'] ?? 'Sem mensagem'}');
        return null;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first;
      final overview = route['overview_polyline']?['points'] as String?;
      if (overview == null) return null;

      final legs = route['legs'] as List?;
      int distanceMeters = 0;
      int durationSeconds = 0;
      if (legs != null && legs.isNotEmpty) {
        for (final leg in legs) {
          distanceMeters += (leg['distance']?['value'] as num?)?.toInt() ?? 0;
          durationSeconds += (leg['duration']?['value'] as num?)?.toInt() ?? 0;
        }
      }

      final points = _decodePolyline(overview);
      return RouteResult(
        points: points,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      print('Erro ao obter rota: $e');
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final latitude = lat / 1e5;
      final longitude = lng / 1e5;
      poly.add(LatLng(latitude, longitude));
    }

    return poly;
  }
}

class RouteResult {
  final List<LatLng> points;
  final int distanceMeters;
  final int durationSeconds;

  RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}