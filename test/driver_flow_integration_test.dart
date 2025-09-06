import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';

void main() {
  group('Testes de Integração - Modelo Driver', () {
    group('Fluxo de Registro Completo', () {
      test('Deve criar motorista válido com dados completos', () {
        // Arrange
        final driverData = {
          'id': 'driver_123',
          'user_id': 'user_123',
          'vehicle_brand': 'Toyota',
          'vehicle_model': 'Corolla',
          'vehicle_year': 2021,
          'vehicle_color': 'Prata',
          'vehicle_plate': 'XYZ9876',
          'vehicle_category': 'standard',
          'is_online': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Act
        final driver = Driver.fromJson(driverData);

        // Assert
        expect(driver.id, equals('driver_123'));
        expect(driver.userId, equals('user_123'));
        expect(driver.brand, equals('Toyota'));
        expect(driver.model, equals('Corolla'));
        expect(driver.year, equals(2021));
        expect(driver.plate, equals('XYZ9876'));
        expect(driver.color, equals('Prata'));
        expect(driver.category, equals('standard'));
        expect(driver.isOnline, isFalse);
      });

      test('Deve validar dados incompletos', () {
        // Arrange
        final driverData = {
          'id': 'driver_456',
          'user_id': 'user_456',
          'vehicle_brand': '',
          'vehicle_model': '',
          'vehicle_year': 0,
          'vehicle_color': '',
          'vehicle_plate': '',
          'vehicle_category': '',
          'is_online': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Act
        final driver = Driver.fromJson(driverData);

        // Assert
        expect(driver.id, equals('driver_456'));
        expect(driver.brand, equals(''));
        expect(driver.model, equals(''));
        expect(driver.year, equals(0));
        expect(driver.plate, equals(''));
        expect(driver.color, equals(''));
        expect(driver.category, equals(''));
      });
    });

    group('Transição Online/Offline', () {
      test('Deve alternar status corretamente', () {
        // Arrange
        final driver = Driver(
          id: 'test_driver',
          userId: 'user_test',
          brand: 'Hyundai',
          model: 'HB20',
          year: 2022,
          color: 'Cinza',
          plate: 'READY123',
          category: 'standard',
          isOnline: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act - Alternar para online
        final onlineDriver = driver.copyWith(isOnline: true);
        
        // Assert
        expect(onlineDriver.isOnline, isTrue);
        expect(onlineDriver.id, equals(driver.id));
        expect(onlineDriver.brand, equals(driver.brand));

        // Act - Alternar para offline
        final offlineDriver = onlineDriver.copyWith(isOnline: false);
        
        // Assert
        expect(offlineDriver.isOnline, isFalse);
        expect(offlineDriver.id, equals(driver.id));
      });
    });

    group('Validação de Campos Obrigatórios', () {
      test('Deve validar campos obrigatórios do veículo', () {
        // Arrange
        final driver = Driver(
          id: 'valid_driver',
          userId: 'user_valid',
          brand: 'Ford',
          model: 'Ka',
          year: 2020,
          color: 'Azul',
          plate: 'FORD2020',
          category: 'standard',
          isOnline: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final json = driver.toJson();

        // Assert
        expect(json['vehicle_brand'], equals('Ford'));
        expect(json['vehicle_model'], equals('Ka'));
        expect(json['vehicle_year'], equals(2020));
        expect(json['vehicle_plate'], equals('FORD2020'));
        expect(json['vehicle_color'], equals('Azul'));
      });
    });
  });
}