import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:option/services/driver_excluded_zones_service.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';
import 'package:option/exceptions/app_exceptions.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, PostgrestClient, PostgrestFilterBuilder, PostgrestTransformBuilder])
import 'driver_excluded_zones_service_test.mocks.dart';

void main() {
  group('DriverExcludedZonesService', () {
    late DriverExcludedZonesService service;
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
      
      service = DriverExcludedZonesService(mockSupabase);
    });

    group('getDriverExcludedZones', () {
      test('should return list of excluded zones for a driver', () async {
        // Arrange
        final driverId = 'driver-123';
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
        final driverId = 'driver-123';
        final errorMessage = 'Database error';

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
        final driverId = 'driver-123';
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
        final driverId = 'non-existent-driver';

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
        final driverId = 'driver-123';

        // Mock driver exists check
        final driverExistsData = {
          'id': driverId,
          'user_id': 'user-123',
        };

        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => driverExistsData);

        // Mock existing zone check
        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('driver_id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('neighborhood_name', 'Moema')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('city', 'São Paulo')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('state', 'SP')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => {});

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
                  e.toString().contains('Esta zona já está na sua lista de exclusões')),
            ),
          ),
        );
      });

      test('should throw DatabaseException when database insert fails', () async {
        // Arrange
        final driverId = 'driver-123';
        final errorMessage = 'Insert failed';

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
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

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
    });

    group('addMultipleExcludedZones', () {
      test('should add multiple excluded zones successfully', () async {
        // Arrange
        final driverId = 'driver-123';
        final zones = [
          {
            'neighborhoodName': 'Moema',
            'city': 'São Paulo',
            'state': 'SP',
          },
          {
            'neighborhoodName': 'Copacabana',
            'city': 'Rio de Janeiro',
            'state': 'RJ',
          }
        ];

        final zonesData = [
          {
            'id': 'zone-1',
            'driver_id': driverId,
            'neighborhood_name': 'Moema',
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
        when(mockTransformBuilder.execute()).thenAnswer((_) async => zonesData);

        // Act
        final result = await service.addMultipleExcludedZones(
          driverId: driverId,
          zones: zones,
        );

        // Assert
        expect(result, isA<List<DriverExcludedZone>>());
        expect(result.length, 2);
        expect(result[0].neighborhoodName, 'Moema');
        expect(result[1].neighborhoodName, 'Copacabana');
      });

      test('should throw ValidationException when zones list is empty', () async {
        // Arrange
        final driverId = 'driver-123';
        final zones = <Map<String, String>>[];

        // Act & Assert
        expect(
          () => service.addMultipleExcludedZones(
            driverId: driverId,
            zones: zones,
          ),
          throwsA(
            allOf(
              isA<ValidationException>(),
              predicate((e) =>
                  e.toString().contains('Lista de zonas não pode estar vazia')),
            ),
          ),
        );
      });

      test('should throw ValidationException when driver does not exist', () async {
        // Arrange
        final driverId = 'non-existent-driver';
        final zones = [
          {
            'neighborhoodName': 'Moema',
            'city': 'São Paulo',
            'state': 'SP',
          }
        ];

        // Mock driver exists check - return null
        when(mockPostgrest.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', driverId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.addMultipleExcludedZones(
            driverId: driverId,
            zones: zones,
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
        final zoneId = 'zone-123';

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
        final zoneId = 'zone-123';
        final errorMessage = 'Delete failed';

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
  });
}