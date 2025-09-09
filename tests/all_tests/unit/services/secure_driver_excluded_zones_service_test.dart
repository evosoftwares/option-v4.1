import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:option/services/secure_driver_excluded_zones_service.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';
import 'package:option/exceptions/app_exceptions.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, PostgrestClient, PostgrestFilterBuilder, PostgrestTransformBuilder])
import 'secure_driver_excluded_zones_service_test.mocks.dart';

void main() {
  group('SecureDriverExcludedZonesService', () {
    late SecureDriverExcludedZonesService service;
    late MockSupabaseClient mockSupabase;
    late MockPostgrestClient mockPostgrest;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockPostgrest = MockPostgrestClient();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      
      // Mock the Supabase client
      when(mockSupabase.from(any)).thenReturn(mockPostgrest);
      
      service = SecureDriverExcludedZonesService(mockSupabase);
    });

    group('getDriverExcludedZones', () {
      test('should return list of excluded zones for a driver', () async {
        // Arrange
        const driverId = 'driver-123';
        final zonesData = [
          {
            'id': 'zone-1',
            'driver_id': driverId,
            'neighborhood_name': 'Jardim Paulista',
            'city': 'São Paulo',
            'state': 'SP',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'zone-2',
            'driver_id': driverId,
            'neighborhood_name': 'Copacabana',
            'city': 'Rio de Janeiro',
            'state': 'RJ',
            'created_at': DateTime.now().toIso8601String(),
          }
        ];

        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false)).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.execute()).thenAnswer((_) async => zonesData);

        // Act
        final result = await service.getDriverExcludedZones(driverId);

        // Assert
        expect(result, isA<List<DriverExcludedZone>>());
        expect(result.length, 2);
        expect(result[0].id, 'zone-1');
        expect(result[0].neighborhoodName, 'Jardim Paulista');
        expect(result[1].id, 'zone-2');
        expect(result[1].neighborhoodName, 'Copacabana');
      });

      test('should throw DatabaseException when API call fails', () async {
        // Arrange
        const driverId = 'driver-123';
        const errorMessage = 'Database error';

        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', ascending: false)).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.execute()).thenThrow(PostgrestException(message: errorMessage));

        // Act & Assert
        expect(
          () => service.getDriverExcludedZones(driverId),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('addExcludedZone', () {
      test('should add a new excluded zone successfully', () async {
        // Arrange
        const driverId = 'driver-123';
        final zoneData = {
          'id': 'new-zone-123',
          'driver_id': driverId,
          'neighborhood_name': 'Moema',
          'city': 'São Paulo',
          'state': 'SP',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Mock driver exists check
        final driverExistsData = {
          'id': driverId,
          'user_id': 'user-123',
        };

        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => driverExistsData);

        // Mock the insert operation
        when(mockPostgrest.insert(any)).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.select()).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.single()).thenAnswer((_) async => zoneData);

        // Act
        final result = await service.addExcludedZone(
          driverId: driverId,
          neighborhoodName: 'Moema',
          city: 'São Paulo',
          state: 'SP',
        );

        // Assert
        expect(result, isA<DriverExcludedZone>());
        expect(result.id, 'new-zone-123');
        expect(result.neighborhoodName, 'Moema');
        expect(result.city, 'São Paulo');
        expect(result.state, 'SP');
      });

      test('should throw ValidationException when driver does not exist', () async {
        // Arrange
        const driverId = 'non-existent-driver';

        // Mock driver exists check - return null
        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.addExcludedZone(
            driverId: driverId,
            neighborhoodName: 'Moema',
            city: 'São Paulo',
            state: 'SP',
          ),
          throwsA(
            allOf(
              isA<ValidationException>(),
              predicate((e) =>
                  e.toString().contains('motorista não encontrado')),
            ),
          ),
        );
      });

      test('should throw ValidationException when zone already exists', () async {
        // Arrange
        const driverId = 'driver-123';

        // Mock driver exists check
        final driverExistsData = {
          'id': driverId,
          'user_id': 'user-123',
        };

        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => driverExistsData);

        // Mock existing zone check
        final existingZoneData = [
          {
            'id': 'existing-zone-123',
            'driver_id': driverId,
            'neighborhood_name': 'Moema',
            'city': 'São Paulo',
            'state': 'SP',
          }
        ];

        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('neighborhood_name', 'Moema')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('city', 'São Paulo')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('state', 'SP')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.execute()).thenAnswer((_) async => existingZoneData);

        // Act & Assert
        expect(
          () => service.addExcludedZone(
            driverId: driverId,
            neighborhoodName: 'Moema',
            city: 'São Paulo',
            state: 'SP',
          ),
          throwsA(
            allOf(
              isA<ValidationException>(),
              predicate((e) =>
                  e.toString().contains('Esta zona de exclusão já foi adicionada')),
            ),
          ),
        );
      });

      test('should throw DatabaseException when database insert fails', () async {
        // Arrange
        const driverId = 'driver-123';
        const errorMessage = 'Insert failed';

        // Mock driver exists check
        final driverExistsData = {
          'id': driverId,
          'user_id': 'user-123',
        };

        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => driverExistsData);

        // Mock existing zone check (no existing zones)
        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('neighborhood_name', 'Moema')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('city', 'São Paulo')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('state', 'SP')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.execute()).thenAnswer((_) async => []);

        // Mock the insert operation to fail
        when(mockPostgrest.insert(any)).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.select()).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.single()).thenThrow(PostgrestException(message: errorMessage));

        // Act & Assert
        expect(
          () => service.addExcludedZone(
            driverId: driverId,
            neighborhoodName: 'Moema',
            city: 'São Paulo',
            state: 'SP',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle foreign key constraint violation', () async {
        // Arrange
        const driverId = 'invalid-driver-id';
        const errorMessage = 'Foreign key constraint violation';
        const errorCode = '23503';

        // Mock driver exists check - return null
        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.addExcludedZone(
            driverId: driverId,
            neighborhoodName: 'Moema',
            city: 'São Paulo',
            state: 'SP',
          ),
          throwsA(
            allOf(
              isA<ValidationException>(),
              predicate((e) =>
                  e.toString().contains('motorista não encontrado')),
            ),
          ),
        );
      });
    });

    group('removeExcludedZone', () {
      test('should remove an excluded zone successfully', () async {
        // Arrange
        const zoneId = 'zone-123';

        when(mockPostgrest.delete()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', zoneId)).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.execute()).thenAnswer((_) async => []);

        // Act
        await service.removeExcludedZone(zoneId);

        // Assert
        verify(mockPostgrest.delete()).called(1);
        verify(mockFilterBuilder.eq('id', zoneId)).called(1);
      });

      test('should throw DatabaseException when delete fails', () async {
        // Arrange
        const zoneId = 'zone-123';
        const errorMessage = 'Delete failed';

        when(mockPostgrest.delete()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', zoneId)).thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.execute()).thenThrow(PostgrestException(message: errorMessage));

        // Act & Assert
        expect(
          () => service.removeExcludedZone(zoneId),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('isZoneExcluded', () {
      test('should return true when zone is excluded', () async {
        // Arrange
        const driverId = 'driver-123';
        const neighborhood = 'Moema';
        const city = 'São Paulo';
        const state = 'SP';

        final zoneData = {
          'id': 'zone-123',
          'driver_id': driverId,
          'neighborhood_name': neighborhood,
          'city': city,
          'state': state,
        };

        when(mockPostgrest.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('neighborhood_name', neighborhood)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('city', city)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('state', state)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => zoneData);

        // Act
        final result = await service.isZoneExcluded(
          driverId: driverId,
          neighborhoodName: neighborhood,
          city: city,
          state: state,
        );

        // Assert
        expect(result, true);
      });

      test('should return false when zone is not excluded', () async {
        // Arrange
        const driverId = 'driver-123';
        const neighborhood = 'Moema';
        const city = 'São Paulo';
        const state = 'SP';

        when(mockPostgrest.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('neighborhood_name', neighborhood)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('city', city)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('state', state)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Act
        final result = await service.isZoneExcluded(
          driverId: driverId,
          neighborhoodName: neighborhood,
          city: city,
          state: state,
        );

        // Assert
        expect(result, false);
      });
    });

    group('getExcludedZonesCount', () {
      test('should return correct count of excluded zones', () async {
        // Arrange
        const driverId = 'driver-123';
        final zonesData = [
          {'id': 'zone-1'},
          {'id': 'zone-2'},
          {'id': 'zone-3'},
        ];

        when(mockPostgrest.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.execute()).thenAnswer((_) async => zonesData);

        // Act
        final result = await service.getExcludedZonesCount(driverId);

        // Assert
        expect(result, 3);
      });

      test('should return zero when no zones exist', () async {
        // Arrange
        const driverId = 'driver-123';
        final zonesData = [];

        when(mockPostgrest.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.execute()).thenAnswer((_) async => zonesData);

        // Act
        final result = await service.getExcludedZonesCount(driverId);

        // Assert
        expect(result, 0);
      });
    });
  });
}