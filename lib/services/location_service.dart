import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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
          return [];
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
      }
    } catch (e) {
      print('Erro ao buscar lugares: $e');
    }
    
    return [];
  }

  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
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
}