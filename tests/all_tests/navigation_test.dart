import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/favorite_location.dart';
import 'package:option/screens/trip/driver_selection_screen.dart';
import 'package:option/screens/trip/trip_options_screen.dart';

void main() {
  group('Navigation Tests', () {
    test('TripOptionsScreen.fromArgs deve funcionar corretamente', () {
      // Dados de teste similares aos passados pela navegação
      final args = {
        'origin': {
          'id': 'test-origin-id',
          'name': 'Minha Casa',
          'address': 'Rua das Flores, 123',
          'type': 'LocationType.home',
          'latitude': -23.5505,
          'longitude': -46.6333,
          'placeId': 'place123',
        },
        'destination': {
          'id': 'test-dest-id',
          'name': 'Shopping Center',
          'address': 'Av. Paulista, 1000',
          'type': 'LocationType.shopping',
          'latitude': -23.5510,
          'longitude': -46.6340,
          'placeId': 'place456',
        },
      };

      // Teste de criação do TripOptionsScreen
      expect(() => TripOptionsScreen.fromArgs(args), returnsNormally);
      
      final screen = TripOptionsScreen.fromArgs(args);
      expect(screen.origin.name, equals('Minha Casa'));
      expect(screen.destination.name, equals('Shopping Center'));
    });

    test('DriverSelectionScreen.fromArgs deve funcionar com argumentos do TripOptionsScreen', () {
      // Dados que serão passados pelo TripOptionsScreen
      final args = {
        'origin': {
          'id': 'test-origin-id',
          'name': 'Minha Casa',
          'address': 'Rua das Flores, 123',
          'type': 'LocationType.home',
          'latitude': -23.5505,
          'longitude': -46.6333,
          'placeId': 'place123',
        },
        'destination': {
          'id': 'test-dest-id',
          'name': 'Shopping Center',
          'address': 'Av. Paulista, 1000',
          'type': 'LocationType.shopping',
          'latitude': -23.5510,
          'longitude': -46.6340,
          'placeId': 'place456',
        },
        'vehicle_category': 'standard',
        'needsPet': false,
        'needsGrocery': true,
        'needsCondo': false,
        'appliedPromoCode': null,
        'promoDiscount': 0.0,
      };

      print('🧪 Testando DriverSelectionScreen.fromArgs');
      print('🧪 Args: $args');

      // Teste de criação do DriverSelectionScreen
      expect(() => DriverSelectionScreen.fromArgs(args), returnsNormally);
      
      final screen = DriverSelectionScreen.fromArgs(args);
      expect(screen.tripRequestData.originAddress, equals('Rua das Flores, 123'));
      expect(screen.tripRequestData.destinationAddress, equals('Av. Paulista, 1000'));
      expect(screen.tripRequestData.vehicleCategory, equals('standard'));
      expect(screen.tripRequestData.needsPet, equals(false));
      expect(screen.tripRequestData.needsGrocery, equals(true));
      
      print('✅ Teste passou com sucesso!');
    });

    test('FavoriteLocation.fromJson deve funcionar com dados de navegação', () {
      final json = {
        'id': 'test-id',
        'name': 'Local Teste',
        'address': 'Rua Teste, 123',
        'type': 'LocationType.other',
        'latitude': -23.5505,
        'longitude': -46.6333,
        'placeId': 'place123',
      };

      print('🧪 Testando FavoriteLocation.fromJson');
      print('🧪 JSON: $json');

      expect(() => FavoriteLocation.fromJson(json), returnsNormally);
      
      final location = FavoriteLocation.fromJson(json);
      expect(location.name, equals('Local Teste'));
      expect(location.address, equals('Rua Teste, 123'));
      expect(location.latitude, equals(-23.5505));
      expect(location.longitude, equals(-46.6333));
      
      print('✅ FavoriteLocation criado com sucesso!');
    });

    test('Teste de argumentos vazios deve funcionar', () {
      final emptyArgs = <String, dynamic>{};
      
      print('🧪 Testando argumentos vazios');
      
      // Deve criar objetos padrão sem falhar
      expect(() => DriverSelectionScreen.fromArgs(emptyArgs), throwsA(isA<TypeError>()));
      
      print('✅ Erro esperado para argumentos vazios');
    });
  });
}