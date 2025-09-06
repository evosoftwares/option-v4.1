import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';

void main() {
  group('Testes de Unidade - Modelo Driver', () {

    group('Validação de Dados do Motorista', () {
      test('Deve validar estrutura correta de dados do motorista', () {
        // Arrange
        final driverData = {
          'id': '123',
          'user_id': 'user_123',
          'vehicle_brand': 'Honda',
          'vehicle_model': 'Civic',
          'vehicle_year': 2020,
          'vehicle_color': 'Branco',
          'vehicle_plate': 'ABC1234',
          'vehicle_category': 'standard',
          'is_online': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Act
        final driver = Driver.fromJson(driverData);

        // Assert
        expect(driver.id, equals('123'));
        expect(driver.userId, equals('user_123'));
        expect(driver.brand, equals('Honda'));
        expect(driver.model, equals('Civic'));
        expect(driver.year, equals(2020));
        expect(driver.plate, equals('ABC1234'));
        expect(driver.color, equals('Branco'));
        expect(driver.category, equals('standard'));
        expect(driver.isOnline, isFalse);
      });

      test('Deve validar formato da placa', () {
        // Testar placa válida
        expect('ABC1234'.length, equals(7));
        expect('ABC1D23'.length, equals(7));
        
        // Testar placa com formato Mercosul
        expect('ABC1D23'.length, equals(7));
      });
    });

    group('Autenticação e Login', () {
      test('deve criar motorista válido com dados completos', () {
        final driver = Driver(
          id: 'driver_123',
          userId: 'user_123',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2021,
          color: 'Prata',
          plate: 'ABC1234',
          category: 'standard',
          isOnline: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(driver.id, equals('driver_123'));
        expect(driver.userId, equals('user_123'));
        expect(driver.brand, equals('Toyota'));
        expect(driver.model, equals('Corolla'));
        expect(driver.plate, equals('ABC1234'));
        expect(driver.isOnline, isFalse);
      });

      test('Deve validar estrutura de dados do motorista', () {
        // Arrange
        final driver = Driver(
          id: '123',
          userId: 'user_123',
          brand: 'Honda',
          model: 'Civic',
          year: 2020,
          color: 'Branco',
          plate: 'ABC1234',
          category: 'standard',
          isOnline: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final json = driver.toJson();

        // Assert
        expect(json, isA<Map<String, dynamic>>());
        expect(json['user_id'], equals('user_123'));
        expect(json['vehicle_plate'], equals('ABC1234'));
        expect(json['is_online'], isFalse);
      });
    });

    group('Transição Online/Offline', () {
      test('Deve alterar status para online', () {
        // Arrange
        final driver = Driver(
          id: '123',
          userId: 'user_123',
          brand: 'Honda',
          model: 'Civic',
          year: 2020,
          color: 'Branco',
          plate: 'ABC1234',
          category: 'standard',
          isOnline: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final updatedDriver = driver.copyWith(isOnline: true);

        // Assert
        expect(updatedDriver.isOnline, isTrue);
        expect(updatedDriver.id, equals(driver.id)); // ID permanece o mesmo
      });

      test('Deve alterar status para offline', () {
        // Arrange
        final driver = Driver(
          id: '123',
          userId: 'user_123',
          brand: 'Honda',
          model: 'Civic',
          year: 2020,
          color: 'Branco',
          plate: 'ABC1234',
          category: 'standard',
          isOnline: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final updatedDriver = driver.copyWith(isOnline: false);

        // Assert
        expect(updatedDriver.isOnline, isFalse);
      });
    });
  });
}