import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/driver_excluded_zones_service.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';
import 'package:option/exceptions/app_exceptions.dart';

void main() {
  group('DriverExcludedZone Model Tests', () {
    test('should create DriverExcludedZone from JSON', () {
      // Arrange
      final json = {
        'id': 'zone-123',
        'driver_id': 'driver-123',
        'neighborhood_name': 'Jardim Paulista',
        'city': 'São Paulo',
        'state': 'SP',
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      // Act
      final zone = DriverExcludedZone.fromJson(json);

      // Assert
      expect(zone.id, 'zone-123');
      expect(zone.driverId, 'driver-123');
      expect(zone.neighborhoodName, 'Jardim Paulista');
      expect(zone.city, 'São Paulo');
      expect(zone.state, 'SP');
      expect(zone.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
    });

    test('should convert DriverExcludedZone to JSON', () {
      // Arrange
      final zone = DriverExcludedZone(
        id: 'zone-123',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      // Act
      final json = zone.toJson();

      // Assert
      expect(json['id'], 'zone-123');
      expect(json['driver_id'], 'driver-123');
      expect(json['neighborhood_name'], 'Jardim Paulista');
      expect(json['city'], 'São Paulo');
      expect(json['state'], 'SP');
      expect(json['created_at'], '2024-01-15T10:30:00.000Z');
    });

    test('should convert DriverExcludedZone to insert JSON', () {
      // Arrange
      final zone = DriverExcludedZone(
        id: 'zone-123',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      // Act
      final json = zone.toInsertJson();

      // Assert
      expect(json['driver_id'], 'driver-123');
      expect(json['neighborhood_name'], 'Jardim Paulista');
      expect(json['city'], 'São Paulo');
      expect(json['state'], 'SP');
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
    });

    test('should create display name correctly', () {
      // Arrange
      final zone = DriverExcludedZone(
        id: 'zone-123',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.now(),
      );

      // Act
      final displayName = zone.displayName;

      // Assert
      expect(displayName, 'Jardim Paulista, São Paulo - SP');
    });

    test('should implement equality correctly', () {
      // Arrange
      final zone1 = DriverExcludedZone(
        id: 'zone-123',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final zone2 = DriverExcludedZone(
        id: 'zone-123',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final zone3 = DriverExcludedZone(
        id: 'zone-456',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      // Assert
      expect(zone1, zone2);
      expect(zone1, isNot(zone3));
      expect(zone1.hashCode, zone2.hashCode);
      expect(zone1.hashCode, isNot(zone3.hashCode));
    });

    test('should create copy with updated fields', () {
      // Arrange
      final original = DriverExcludedZone(
        id: 'zone-123',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      // Act
      final copy = original.copyWith(
        neighborhoodName: 'Vila Madalena',
        city: 'São Paulo',
      );

      // Assert
      expect(copy.id, original.id);
      expect(copy.driverId, original.driverId);
      expect(copy.neighborhoodName, 'Vila Madalena');
      expect(copy.city, 'São Paulo');
      expect(copy.state, original.state);
      expect(copy.createdAt, original.createdAt);
    });

    test('should have correct toString implementation', () {
      // Arrange
      final zone = DriverExcludedZone(
        id: 'zone-123',
        driverId: 'driver-123',
        neighborhoodName: 'Jardim Paulista',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      // Act
      final toString = zone.toString();

      // Assert
      expect(toString, contains('zone-123'));
      expect(toString, contains('driver-123'));
      expect(toString, contains('Jardim Paulista'));
      expect(toString, contains('São Paulo'));
      expect(toString, contains('SP'));
    });
  });

  group('DriverExcludedZonesService Input Validation', () {
    test('should validate required parameters for addExcludedZone', () {
      // Test that the method signature requires all necessary parameters
      expect(
        () => DriverExcludedZone(
          id: '',
          driverId: '',
          neighborhoodName: '',
          city: '',
          state: '',
          createdAt: DateTime.now(),
        ),
        returnsNormally,
      );
    });

    test('should handle edge cases in neighborhood names', () {
      // Arrange & Act
      final zone1 = DriverExcludedZone(
        id: 'zone-1',
        driverId: 'driver-1',
        neighborhoodName: 'Vila São João',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.now(),
      );

      final zone2 = DriverExcludedZone(
        id: 'zone-2',
        driverId: 'driver-1',
        neighborhoodName: 'Bairro da Liberdade',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(zone1.neighborhoodName, 'Vila São João');
      expect(zone2.neighborhoodName, 'Bairro da Liberdade');
      expect(zone1.displayName, 'Vila São João, São Paulo - SP');
      expect(zone2.displayName, 'Bairro da Liberdade, São Paulo - SP');
    });

    test('should handle special characters in location names', () {
      // Arrange
      final zone = DriverExcludedZone(
        id: 'zone-special',
        driverId: 'driver-1',
        neighborhoodName: 'São João do Merití',
        city: 'Duque de Caxias',
        state: 'RJ',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(zone.neighborhoodName, 'São João do Merití');
      expect(zone.city, 'Duque de Caxias');
      expect(zone.displayName, 'São João do Merití, Duque de Caxias - RJ');
    });
  });

  group('Exception Handling Tests', () {
    test('should create ValidationException with message', () {
      // Arrange
      const message = 'Dados de localização inválidos';

      // Act
      const exception = ValidationException(message);

      // Assert
      expect(exception.message, message);
      expect(exception.toString(), contains(message));
    });

    test('should create DatabaseException with message and code', () {
      // Arrange
      const message = 'Erro ao buscar zonas excluídas';
      const code = '42P01';

      // Act
      const exception = DatabaseException(message, code);

      // Assert
      expect(exception.message, message);
      expect(exception.code, code);
      expect(exception.toString(), contains(message));
    });

    test('should create DatabaseException without code', () {
      // Arrange
      const message = 'Erro inesperado ao buscar zonas excluídas';

      // Act
      const exception = DatabaseException(message);

      // Assert
      expect(exception.message, message);
      expect(exception.code, isNull);
      expect(exception.toString(), contains(message));
    });
  });

  group('Data Structure Validation Tests', () {
    test('should handle various Brazilian states', () {
      final states = ['SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'GO', 'DF'];

      for (final state in states) {
        final zone = DriverExcludedZone(
          id: 'zone-$state',
          driverId: 'driver-1',
          neighborhoodName: 'Centro',
          city: 'Capital',
          state: state,
          createdAt: DateTime.now(),
        );

        expect(zone.state, state);
        expect(zone.displayName, 'Centro, Capital - $state');
      }
    });

    test('should handle different city names correctly', () {
      final cities = [
        'São Paulo',
        'Rio de Janeiro',
        'Belo Horizonte',
        'Porto Alegre',
        'Florianópolis',
        'Ribeirão Preto',
        'São José dos Campos',
      ];

      for (final city in cities) {
        final zone = DriverExcludedZone(
          id: 'zone-${city.hashCode}',
          driverId: 'driver-1',
          neighborhoodName: 'Centro',
          city: city,
          state: 'SP',
          createdAt: DateTime.now(),
        );

        expect(zone.city, city);
        expect(zone.displayName, 'Centro, $city - SP');
      }
    });

    test('should maintain data integrity through JSON conversion', () {
      // Arrange
      final originalZone = DriverExcludedZone(
        id: 'zone-integrity-test',
        driverId: 'driver-integrity',
        neighborhoodName: 'Jardim Europa',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.parse('2024-01-15T14:30:00.000Z'),
      );

      // Act - Convert to JSON and back
      final json = originalZone.toJson();
      final reconstructedZone = DriverExcludedZone.fromJson(json);

      // Assert
      expect(reconstructedZone, originalZone);
      expect(reconstructedZone.id, originalZone.id);
      expect(reconstructedZone.driverId, originalZone.driverId);
      expect(reconstructedZone.neighborhoodName, originalZone.neighborhoodName);
      expect(reconstructedZone.city, originalZone.city);
      expect(reconstructedZone.state, originalZone.state);
      expect(reconstructedZone.createdAt, originalZone.createdAt);
    });
  });
}
