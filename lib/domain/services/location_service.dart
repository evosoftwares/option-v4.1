import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart' as ph;

import 'app_logger.dart';

class LocationService {

  LocationService({required this.apiKey});
  final String apiKey;

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final startTime = DateTime.now();

    if (query.isEmpty) {
      AppLogger.validation('search_query', false, entity: 'LocationService', error: 'Empty query');
      return [];
    }

    AppLogger.process('Iniciando busca de lugares', tag: 'LOCATION');
    AppLogger.query('google_places_api', 1, tag: 'LOCATION', filters: {'query': query, 'country': 'br'});

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$apiKey'
      '&language=pt-BR'
      '&components=country:br'
    );

    try {
      AppLogger.network('Google Places API Request', url.toString(), method: 'GET', tag: 'LOCATION');
      final response = await http.get(url);

      final duration = DateTime.now().difference(startTime);
      AppLogger.network('Google Places API Response', url.toString(),
        method: 'GET',
        statusCode: response.statusCode,
        duration: duration,
        tag: 'LOCATION'
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verificar se há erro na resposta da API
        if (data['status'] != 'OK') {
          AppLogger.warning('Erro da API Google Places', tag: 'LOCATION');
          AppLogger.debug('API Error Details', tag: 'LOCATION', data: {
            'status': data['status'],
            'error_message': data['error_message'] ?? 'Sem mensagem de erro',
            'query': query
          });

          AppLogger.rateLimit('google_places_api', 'quota_exceeded', tag: 'LOCATION');

          // Se a API falhar, retornar resultado básico para entrada manual
          return _createManualSearchResult(query);
        }

        final predictions = data['predictions'] as List? ?? [];

        AppLogger.success('Busca de lugares concluída', tag: 'LOCATION');
        AppLogger.performance('search_places', duration, tag: 'LOCATION', metrics: {
          'results_count': predictions.length,
          'query_length': query.length,
          'api_status': data['status']
        });

        return predictions.map((prediction) => {
            'placeId': prediction['place_id'],
            'description': prediction['description'],
            'mainText': prediction['structured_formatting']?['main_text'] ?? '',
            'secondaryText': prediction['structured_formatting']?['secondary_text'] ?? '',
          },).toList();
      } else {
        AppLogger.network('HTTP Error', url.toString(),
          method: 'GET',
          statusCode: response.statusCode,
          duration: duration,
          tag: 'LOCATION'
        );
        AppLogger.error('Erro HTTP na busca de lugares', tag: 'LOCATION', error: 'Status: ${response.statusCode}');

        // Se houve erro HTTP, retornar resultado básico para entrada manual
        return _createManualSearchResult(query);
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      AppLogger.error('Erro ao buscar lugares', tag: 'LOCATION', error: e);
      AppLogger.connectivity('API_ERROR', type: 'Google Places', tag: 'LOCATION', details: {
        'error': e.toString(),
        'query': query,
        'duration_ms': duration.inMilliseconds
      });

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
          // Extrair informações de bairro, cidade e estado
          final addressComponents = result['address_components'] as List?;
          String? neighborhood;
          String? city;
          String? state;

          if (addressComponents != null) {
            for (final component in addressComponents) {
              final types = List<String>.from(component['types'] ?? []);

              // Bairro pode ser sublocality_level_1, neighborhood, ou political
              if (neighborhood == null && (
                types.contains('sublocality_level_1') ||
                types.contains('neighborhood') ||
                types.contains('sublocality')
              )) {
                neighborhood = component['long_name'] as String?;
              }

              // Cidade pode ser locality, administrative_area_level_2
              if (city == null && (
                types.contains('locality') ||
                types.contains('administrative_area_level_2')
              )) {
                city = component['long_name'] as String?;
              }

              // Estado é administrative_area_level_1
              if (state == null && types.contains('administrative_area_level_1')) {
                state = component['short_name'] as String?;
              }
            }
          }

          return {
            'name': result['name'] ?? '',
            'formattedAddress': result['formatted_address'] ?? '',
            'lat': result['geometry']['location']['lat'],
            'lng': result['geometry']['location']['lng'],
            'placeId': placeId,
            'neighborhood': neighborhood,
            'city': city,
            'state': state,
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
      var distanceMeters = 0;
      var durationSeconds = 0;
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

  /// Geocodifica um endereço para obter coordenadas (latitude/longitude)
  /// e informações de bairro, cidade e estado
  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeComponent(address)}'
      '&key=$apiKey'
      '&language=pt-BR'
      '&components=country:BR'
    );

    try {
      print('🌍 Geocodificando endereço: $address');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final result = results.first;
            final location = result['geometry']['location'];
            final formattedAddress = result['formatted_address'];

            // Extrair informações de bairro, cidade e estado
            final addressComponents = result['address_components'] as List?;
            String? neighborhood;
            String? city;
            String? state;

            if (addressComponents != null) {
              for (final component in addressComponents) {
                final types = List<String>.from(component['types'] ?? []);

                // Bairro pode ser sublocality_level_1, neighborhood, ou political
                if (neighborhood == null && (
                  types.contains('sublocality_level_1') ||
                  types.contains('neighborhood') ||
                  types.contains('sublocality')
                )) {
                  neighborhood = component['long_name'] as String?;
                }

                // Cidade pode ser locality, administrative_area_level_2
                if (city == null && (
                  types.contains('locality') ||
                  types.contains('administrative_area_level_2')
                )) {
                  city = component['long_name'] as String?;
                }

                // Estado é administrative_area_level_1
                if (state == null && types.contains('administrative_area_level_1')) {
                  state = component['short_name'] as String?;
                }
              }
            }

            print('✅ Geocodificação bem-sucedida: $formattedAddress');
            print('   📍 Bairro: ${neighborhood ?? 'N/A'}, Cidade: ${city ?? 'N/A'}, Estado: ${state ?? 'N/A'}');

            return {
              'latitude': location['lat'].toDouble(),
              'longitude': location['lng'].toDouble(),
              'formatted_address': formattedAddress,
              'neighborhood': neighborhood,
              'city': city,
              'state': state,
            };
          }
        } else {
          print('❌ Erro na geocodificação: ${data['status']} - ${data['error_message'] ?? 'Sem mensagem'}');
        }
      } else {
        print('❌ Erro HTTP na geocodificação: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exceção na geocodificação: $e');
    }

    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final poly = <LatLng>[];
    var index = 0, len = encoded.length;
    var lat = 0, lng = 0;

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

  /// Extrai informações de bairro de um endereço completo usando geocoding reverso
  /// quando apenas coordenadas estão disponíveis
  Future<Map<String, dynamic>?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$latitude,$longitude'
      '&key=$apiKey'
      '&language=pt-BR'
    );

    try {
      print('🔄 Geocodificação reversa: $latitude, $longitude');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final result = results.first;
            final formattedAddress = result['formatted_address'];

            // Extrair informações de bairro, cidade e estado
            final addressComponents = result['address_components'] as List?;
            String? neighborhood;
            String? city;
            String? state;

            if (addressComponents != null) {
              for (final component in addressComponents) {
                final types = List<String>.from(component['types'] ?? []);

                if (neighborhood == null && (
                  types.contains('sublocality_level_1') ||
                  types.contains('neighborhood') ||
                  types.contains('sublocality')
                )) {
                  neighborhood = component['long_name'] as String?;
                }

                if (city == null && (
                  types.contains('locality') ||
                  types.contains('administrative_area_level_2')
                )) {
                  city = component['long_name'] as String?;
                }

                if (state == null && types.contains('administrative_area_level_1')) {
                  state = component['short_name'] as String?;
                }
              }
            }

            print('✅ Geocodificação reversa bem-sucedida');
            print('   📍 Bairro: ${neighborhood ?? 'N/A'}, Cidade: ${city ?? 'N/A'}, Estado: ${state ?? 'N/A'}');

            return {
              'latitude': latitude,
              'longitude': longitude,
              'formatted_address': formattedAddress,
              'neighborhood': neighborhood,
              'city': city,
              'state': state,
            };
          }
        } else {
          print('❌ Erro na geocodificação reversa: ${data['status']}');
        }
      } else {
        print('❌ Erro HTTP na geocodificação reversa: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exceção na geocodificação reversa: $e');
    }

    return null;
  }

  /// Extrai informações de bairro de um endereço com múltiplas estratégias para garantir 100% de cobertura
  /// Combina regex avançado + análise semântica + fallbacks inteligentes
  static Map<String, String?> parseAddressString(String fullAddress) {
    String? neighborhood;
    String? city;
    String? state;

    try {
      if (fullAddress.trim().isEmpty) {
        return {'neighborhood': null, 'city': null, 'state': null};
      }

      final originalAddress = fullAddress.trim();
      print('🔍 Analisando endereço: "$originalAddress"');

      // ESTRATÉGIA 1: Regex específico para padrões brasileiros
      final result1 = _extractWithBrazilianPatterns(originalAddress);
      if (result1['neighborhood'] != null) {
        print('✅ Estratégia 1 (padrões BR): Bairro encontrado');
        return result1;
      }

      // ESTRATÉGIA 2: Separadores múltiplos
      final result2 = _extractWithMultipleSeparators(originalAddress);
      if (result2['neighborhood'] != null) {
        print('✅ Estratégia 2 (separadores): Bairro encontrado');
        return result2;
      }

      // ESTRATÉGIA 3: Análise semântica por palavras-chave
      final result3 = _extractWithSemanticAnalysis(originalAddress);
      if (result3['neighborhood'] != null) {
        print('✅ Estratégia 3 (semântica): Bairro encontrado');
        return result3;
      }

      // ESTRATÉGIA 4: Fallback inteligente - usar partes do endereço como bairro
      final result4 = _extractWithIntelligentFallback(originalAddress);
      if (result4['neighborhood'] != null) {
        print('✅ Estratégia 4 (fallback): Bairro inferido');
        return result4;
      }

      // ESTRATÉGIA 5: Último recurso - usar o endereço completo para matching
      final result5 = _createFallbackForMatching(originalAddress);
      print('⚠️ Estratégia 5 (último recurso): Usando endereço completo para matching');
      return result5;

    } catch (e) {
      print('❌ Erro ao extrair informações do endereço: $e');
      // Mesmo com erro, retornar algo útil para matching
      return _createFallbackForMatching(fullAddress);
    }
  }

  /// Estratégia 1: Padrões específicos para endereços brasileiros
  static Map<String, String?> _extractWithBrazilianPatterns(String address) {
    // Padrões mais específicos para endereços brasileiros
    final patterns = [
      // Formato: "Rua X, 123 - Bairro - Cidade - Estado"
      RegExp(r'^.*?(?:,\s*\d+)?\s*-\s*([^-]+?)\s*-\s*([^-]+?)\s*-\s*([A-Z]{2})(?:\s*-.*)?$'),
      // Formato: "Rua X, 123, Bairro, Cidade - Estado"
      RegExp(r'^.*?(?:,\s*\d+)?,\s*([^,]+?),\s*([^,-]+?)\s*-\s*([A-Z]{2})(?:\s|$)'),
      // Formato: "Rua X, 123 - Bairro, Cidade - Estado"
      RegExp(r'^.*?(?:,\s*\d+)?\s*-\s*([^,]+?),\s*([^-]+?)\s*-\s*([A-Z]{2})(?:\s|$)'),
      // Formato: "Endereço - Bairro - Cidade/Estado"
      RegExp(r'^.*?\s*-\s*([^-]+?)\s*-\s*([^/]+?)/([A-Z]{2})(?:\s|$)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(address);
      if (match != null && match.groupCount >= 3) {
        final neighborhood = match.group(1)?.trim();
        final city = match.group(2)?.trim();
        final state = match.group(3)?.trim().toUpperCase();

        if (neighborhood != null && neighborhood.isNotEmpty &&
            city != null && city.isNotEmpty &&
            state != null && state.length == 2) {
          return {
            'neighborhood': neighborhood,
            'city': city,
            'state': state,
          };
        }
      }
    }
    return {'neighborhood': null, 'city': null, 'state': null};
  }

  /// Estratégia 2: Múltiplos separadores e normalização
  static Map<String, String?> _extractWithMultipleSeparators(String address) {
    // Normalizar diferentes tipos de separadores
    String normalized = address
        .replaceAll(' - ', ' | ')
        .replaceAll(', ', ' | ')
        .replaceAll(' – ', ' | ')  // travessão longo
        .replaceAll('  ', ' ')     // espaços duplos
        .trim();

    final parts = normalized.split(' | ').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (parts.length >= 3) {
      // Procurar estado (sempre últimas 2 letras ou parte que termina com estado)
      String? state;
      int stateIndex = -1;

      for (int i = parts.length - 1; i >= 0; i--) {
        final part = parts[i];
        // Estado pode ser "SP", "RJ", ou "São Paulo - SP"
        final stateMatch = RegExp(r'\b([A-Z]{2})(?:\s|$)').firstMatch(part);
        if (stateMatch != null) {
          state = stateMatch.group(1);
          stateIndex = i;
          break;
        }
      }

      if (state != null && stateIndex >= 2) {
        // Cidade é a parte antes do estado
        final city = parts[stateIndex - 1].replaceAll(RegExp(r'\s*-\s*[A-Z]{2}$'), '').trim();
        // Bairro é a parte antes da cidade
        final neighborhood = parts[stateIndex - 2].trim();

        if (neighborhood.isNotEmpty && city.isNotEmpty) {
          return {
            'neighborhood': neighborhood,
            'city': city,
            'state': state,
          };
        }
      }
    }
    return {'neighborhood': null, 'city': null, 'state': null};
  }

  /// Estratégia 3: Análise semântica por palavras-chave conhecidas
  static Map<String, String?> _extractWithSemanticAnalysis(String address) {
    // Palavras-chave que indicam bairros conhecidos
    final knownNeighborhoods = [
      'centro', 'copacabana', 'ipanema', 'leblon', 'barra', 'tijuca', 'botafogo',
      'flamengo', 'jardins', 'moema', 'vila madalena', 'pinheiros', 'itaim',
      'consolação', 'bela vista', 'liberdade', 'higienópolis', 'perdizes',
      'boa vista', 'savassi', 'funcionários', 'lourdes', 'centro histórico',
    ];

    final lowerAddress = address.toLowerCase();

    for (final neighborhood in knownNeighborhoods) {
      if (lowerAddress.contains(neighborhood)) {
        // Encontrou bairro conhecido, tentar extrair cidade e estado também
        final stateMatch = RegExp(r'\b([A-Z]{2})\b').firstMatch(address);

        return {
          'neighborhood': _capitalizeWords(neighborhood),
          'city': _inferCityFromNeighborhood(neighborhood),
          'state': stateMatch?.group(1),
        };
      }
    }
    return {'neighborhood': null, 'city': null, 'state': null};
  }

  /// Estratégia 4: Fallback inteligente baseado na estrutura
  static Map<String, String?> _extractWithIntelligentFallback(String address) {
    // Remover números de endereço e CEP para focar na localização
    String cleaned = address
        .replaceAll(RegExp(r',?\s*\d+[a-zA-Z]?(?:\s*-\s*\d+[a-zA-Z]?)?'), '') // números
        .replaceAll(RegExp(r'\b\d{5}-?\d{3}\b'), '') // CEP
        .replaceAll(RegExp(r'\b(rua|r\.|avenida|av\.|travessa|trav\.|alameda|al\.)', caseSensitive: false), '')
        .trim();

    // Dividir o que restou e usar a primeira parte significativa como bairro
    final parts = cleaned.split(RegExp(r'[-,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      String potentialNeighborhood = parts[0].trim();

      // Se a primeira parte é muito longa, pode ser rua + bairro
      if (potentialNeighborhood.length > 30 && parts.length > 1) {
        potentialNeighborhood = parts[1].trim();
      }

      // Validar se não é apenas um nome de rua
      if (potentialNeighborhood.isNotEmpty && !potentialNeighborhood.toLowerCase().startsWith('rua ')) {
        final state = _extractStateFromParts(parts);

        return {
          'neighborhood': _capitalizeWords(potentialNeighborhood),
          'city': parts.length > 2 ? _capitalizeWords(parts[parts.length - 2]) : null,
          'state': state,
        };
      }
    }
    return {'neighborhood': null, 'city': null, 'state': null};
  }

  /// Estratégia 5: Último recurso - criar dados úteis para matching
  static Map<String, String?> _createFallbackForMatching(String address) {
    // Mesmo sem parsing perfeito, criar algo útil para o sistema de exclusão
    final cleanAddress = address.trim();

    if (cleanAddress.isEmpty) {
      return {'neighborhood': 'endereço não informado', 'city': null, 'state': null};
    }

    // Usar palavras-chave do endereço como "bairro" para matching
    final words = cleanAddress
        .replaceAll(RegExp(r'[,\-]'), ' ')
        .split(' ')
        .where((w) => w.trim().length > 2)
        .map((w) => w.trim())
        .toList();

    // Criar um "bairro virtual" combinando palavras significativas
    final virtualNeighborhood = words.take(3).join(' ');
    final state = _extractStateFromText(cleanAddress);

    return {
      'neighborhood': virtualNeighborhood.isNotEmpty ? virtualNeighborhood : cleanAddress,
      'city': null,
      'state': state,
    };
  }

  /// Utilitários auxiliares
  static String _capitalizeWords(String text) {
    return text.split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  static String? _inferCityFromNeighborhood(String neighborhood) {
    final neighborhoodToCityMap = {
      'copacabana': 'Rio de Janeiro',
      'ipanema': 'Rio de Janeiro',
      'leblon': 'Rio de Janeiro',
      'barra': 'Rio de Janeiro',
      'tijuca': 'Rio de Janeiro',
      'jardins': 'São Paulo',
      'moema': 'São Paulo',
      'vila madalena': 'São Paulo',
      'pinheiros': 'São Paulo',
      'itaim': 'São Paulo',
      'savassi': 'Belo Horizonte',
      'funcionários': 'Belo Horizonte',
    };

    return neighborhoodToCityMap[neighborhood.toLowerCase()];
  }

  static String? _extractStateFromParts(List<String> parts) {
    for (final part in parts.reversed) {
      final stateMatch = RegExp(r'\b([A-Z]{2})\b').firstMatch(part);
      if (stateMatch != null) {
        return stateMatch.group(1);
      }
    }
    return null;
  }

  static String? _extractStateFromText(String text) {
    final stateMatch = RegExp(r'\b([A-Z]{2})\b').firstMatch(text);
    return stateMatch?.group(1);
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
