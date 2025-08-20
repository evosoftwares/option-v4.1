import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  final String apiKey;

  LocationService({required this.apiKey});

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
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        
        return predictions.map((prediction) {
          return {
            'placeId': prediction['place_id'],
            'description': prediction['description'],
            'mainText': prediction['structured_formatting']['main_text'] ?? '',
            'secondaryText': prediction['structured_formatting']['secondary_text'] ?? '',
          };
        }).toList();
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
    // Implementação para obter localização atual
    // Requer permissões de localização
    return null;
  }
}