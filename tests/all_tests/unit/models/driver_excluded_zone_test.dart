import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';

void main() {
  group('DriverExcludedZone', () {
    group('fromJson', () {
      test('should create DriverExcludedZone from valid JSON', () {
        final json = {
          'id': 'zone-123',
          'driver_id': 'driver-456',
          'neighborhood_name': 'Jardim Paulista',
          'city': 'São Paulo',
          'state': 'SP',
          'created_at': '2023-01-01T10:00:00Z',
        };

        final zone = DriverExcludedZone.fromJson(json);

        expect(zone.id, 'zone-123');
        expect(zone.driverId, 'driver-456');
        expect(zone.neighborhoodName, 'Jardim Paulista');
        expect(zone.city, 'São Paulo');
        expect(zone.state, 'SP');
        expect(zone.createdAt, DateTime.parse('2023-01-01T10:00:00Z'));
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'zone-123',
          'driver_id': 'driver-456',
          'neighborhood_name': 'Copacabana',
          'city': 'Rio de Janeiro',
          'state': 'RJ',
          'created_at': '2023-01-01T10:00:00Z',
        };

        final zone = DriverExcludedZone.fromJson(json);

        expect(zone.id, 'zone-123');
        expect(zone.driverId, 'driver-456');
        expect(zone.neighborhoodName, 'Copacabana');
        expect(zone.city, 'Rio de Janeiro');
        expect(zone.state, 'RJ');
        expect(zone.createdAt, DateTime.parse('2023-01-01T10:00:00Z'));
      });
    });

    group('toJson', () {
      test('should convert DriverExcludedZone to JSON', () {
        final zone = DriverExcludedZone(
          id: 'zone-123',
          driverId: 'driver-456',
          neighborhoodName: 'Moema',
          city: 'São Paulo',
          state: 'SP',
          createdAt: DateTime.parse('2023-01-01T10:00:00Z'),
        );

        final json = zone.toJson();

        expect(json['id'], 'zone-123');
        expect(json['driver_id'], 'driver-456');
        expect(json['neighborhood_name'], 'Moema');
        expect(json['city'], 'São Paulo');
        expect(json['state'], 'SP');
        expect(json['created_at'], '2023-01-01T10:00:00.000Z');
      });
    });

    group('copyWith', () {
      test('should create a copy with updated values', () {
        final originalZone = DriverExcludedZone(
          id: 'zone-123',
          driverId: 'driver-456',
          neighborhoodName: 'Moema',
          city: 'São Paulo',
          state: 'SP',
          createdAt: DateTime.parse('2023-01-01T10:00:00Z'),
        );

        final updatedZone = originalZone.copyWith(
          neighborhoodName: 'Jardim Paulista',
          city: 'São Paulo',
        );

        expect(updatedZone.id, 'zone-123');
        expect(updatedZone.driverId, 'driver-456');
        expect(updatedZone.neighborhoodName, 'Jardim Paulista');
        expect(updatedZone.city, 'São Paulo');
        expect(updatedZone.state, 'SP');
        expect(updatedZone.createdAt, DateTime.parse('2023-01-01T10:00:00Z'));
      });

      test('should create identical copy when no parameters provided', () {
        final originalZone = DriverExcludedZone(
          id: 'zone-123',
          driverId: 'driver-456',
          neighborhoodName: 'Moema',
          city: 'São Paulo',
          state: 'SP',
          createdAt: DateTime.parse('2023-01-01T10:00:00Z'),
        );

        final copiedZone = originalZone.copyWith();

        expect(copiedZone.id, originalZone.id);
        expect(copiedZone.driverId, originalZone.driverId);
        expect(copiedZone.neighborhoodName, originalZone.neighborhoodName);
        expect(copiedZone.city, originalZone.city);
        expect(copiedZone.state, originalZone.state);
        expect(copiedZone.createdAt, originalZone.createdAt);
      });
    });
  });
}