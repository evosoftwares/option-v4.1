import 'package:flutter_test/flutter_test.dart';
import 'package:option/screens/trip/trip_options_screen.dart';
import 'package:option/screens/trip/driver_selection_screen.dart';
import 'package:option/models/favorite_location.dart';
import 'package:option/models/trip_request_data.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('Trip Flow Integration Tests', () {
    
    test('Simulação completa do fluxo de navegação', () {
      print('🧪 === INICIANDO TESTE DE INTEGRAÇÃO COMPLETO ===');
      
      // 1. DADOS DE ORIGEM E DESTINO (como vêm do PassengerHomeScreen)
      final originData = {
        'id': 'origin-123',
        'name': 'Casa do João',
        'address': 'Rua das Flores, 123 - Jardins, São Paulo',
        'type': 'LocationType.home',
        'latitude': -23.5505,
        'longitude': -46.6333,
        'placeId': 'ChIJAVkDPzdZzpQRMuGYZWhHBGg',
      };
      
      final destinationData = {
        'id': 'dest-456',
        'name': 'Shopping Eldorado',
        'address': 'Av. Rebouças, 3970 - Pinheiros, São Paulo',
        'type': 'LocationType.shopping',
        'latitude': -23.5613,
        'longitude': -46.6927,
        'placeId': 'ChIJVVWnEwlYzpQRa0xDBBcPu24',
      };
      
      print('📍 Origem: ${originData['name']} (${originData['latitude']}, ${originData['longitude']})');
      print('📍 Destino: ${destinationData['name']} (${destinationData['latitude']}, ${destinationData['longitude']})');
      
      // 2. TESTE DO TripOptionsScreen.fromArgs
      print('\n🎯 TESTANDO TripOptionsScreen.fromArgs...');
      final tripOptionsArgs = {
        'origin': originData,
        'destination': destinationData,
      };
      
      final tripOptionsScreen = TripOptionsScreen.fromArgs(tripOptionsArgs);
      expect(tripOptionsScreen.origin.name, equals('Casa do João'));
      expect(tripOptionsScreen.destination.name, equals('Shopping Eldorado'));
      print('✅ TripOptionsScreen criado com sucesso');
      
      // 3. SIMULAÇÃO DOS ARGUMENTOS DO TripOptionsScreen para DriverSelectionScreen
      print('\n🚗 TESTANDO navegação para DriverSelectionScreen...');
      final driverSelectionArgs = {
        'origin': tripOptionsScreen.origin.toJson(),
        'destination': tripOptionsScreen.destination.toJson(),
        'vehicle_category': 'standard',
        'needsPet': false,
        'needsGrocery': true,
        'needsCondo': false,
        'appliedPromoCode': null,
        'promoDiscount': 0.0,
      };
      
      print('🔍 Args para DriverSelectionScreen:');
      driverSelectionArgs.forEach((key, value) {
        if (key == 'origin' || key == 'destination') {
          print('  $key: ${(value as Map)['name']} - ${(value as Map)['address']}');
        } else {
          print('  $key: $value');
        }
      });
      
      // 4. TESTE DO DriverSelectionScreen.fromArgs
      print('\n🎯 TESTANDO DriverSelectionScreen.fromArgs...');
      final driverSelectionScreen = DriverSelectionScreen.fromArgs(driverSelectionArgs);
      
      // Verificar se os objetos foram criados corretamente
      expect(driverSelectionScreen.tripRequestData, isA<TripRequestData>());
      expect(driverSelectionScreen.userPosition, isA<Position>());
      
      print('✅ DriverSelectionScreen criado com sucesso');
      print('📊 TripRequestData:');
      print('  - Origem: ${driverSelectionScreen.tripRequestData.originAddress}');
      print('  - Destino: ${driverSelectionScreen.tripRequestData.destinationAddress}');
      print('  - Categoria: ${driverSelectionScreen.tripRequestData.vehicleCategory}');
      print('  - Coordenadas origem: (${driverSelectionScreen.tripRequestData.originLatitude}, ${driverSelectionScreen.tripRequestData.originLongitude})');
      print('  - Coordenadas destino: (${driverSelectionScreen.tripRequestData.destinationLatitude}, ${driverSelectionScreen.tripRequestData.destinationLongitude})');
      
      print('📍 Position:');
      print('  - Latitude: ${driverSelectionScreen.userPosition.latitude}');
      print('  - Longitude: ${driverSelectionScreen.userPosition.longitude}');
      print('  - Timestamp: ${driverSelectionScreen.userPosition.timestamp}');
      
      // 5. VERIFICAÇÕES DE INTEGRIDADE DOS DADOS
      print('\n🔍 VERIFICANDO INTEGRIDADE DOS DADOS...');
      
      // Verificar se as coordenadas não são zero
      expect(driverSelectionScreen.tripRequestData.originLatitude, isNot(equals(0.0)));
      expect(driverSelectionScreen.tripRequestData.originLongitude, isNot(equals(0.0)));
      expect(driverSelectionScreen.tripRequestData.destinationLatitude, isNot(equals(0.0)));
      expect(driverSelectionScreen.tripRequestData.destinationLongitude, isNot(equals(0.0)));
      
      // Verificar se os endereços não estão vazios
      expect(driverSelectionScreen.tripRequestData.originAddress, isNotEmpty);
      expect(driverSelectionScreen.tripRequestData.destinationAddress, isNotEmpty);
      
      // Verificar categoria do veículo
      expect(driverSelectionScreen.tripRequestData.vehicleCategory, equals('standard'));
      
      print('✅ Todos os dados estão íntegros');
      
      // 6. TESTE DE CASOS EXTREMOS
      print('\n⚠️  TESTANDO CASOS EXTREMOS...');
      
      // Teste com argumentos mínimos
      final minimalArgs = {
        'origin': {
          'address': 'Origem Teste',
          'latitude': -23.5505,
          'longitude': -46.6333,
        },
        'destination': {
          'address': 'Destino Teste', 
          'latitude': -23.5613,
          'longitude': -46.6927,
        },
      };
      
      expect(() => DriverSelectionScreen.fromArgs(minimalArgs), returnsNormally);
      print('✅ Argumentos mínimos funcionam');
      
      print('\n🎉 === TESTE DE INTEGRAÇÃO COMPLETO PASSOU ===');
    });
    
    test('Teste de erro com argumentos corrompidos', () {
      print('🧪 === TESTANDO ARGUMENTOS CORROMPIDOS ===');
      
      // Argumentos com dados corrompidos
      final corruptedArgs = {
        'origin': {
          'address': 'Origem Teste',
          'latitude': 'invalid', // String em vez de double
          'longitude': -46.6333,
        },
        'destination': {
          'address': 'Destino Teste',
          'latitude': -23.5613,
          'longitude': null, // null em vez de double
        },
      };
      
      // Deve funcionar mesmo com dados corrompidos (por causa dos fallbacks)
      expect(() => DriverSelectionScreen.fromArgs(corruptedArgs), returnsNormally);
      print('✅ Sistema resiliente a dados corrompidos');
    });
  });
}