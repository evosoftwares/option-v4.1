import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';
import 'package:option/services/secure_driver_excluded_zones_service.dart';
import 'package:option/services/driver_excluded_zones_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('DriverExcludedZones Integration Tests', () {
    late SecureDriverExcludedZonesService secureService;
    late DriverExcludedZonesService regularService;
    late SupabaseClient supabase;

    // Test driver ID - this should be a valid driver in your test database
    const testDriverId = 'test-driver-123';
    const testNeighborhood = 'Test Neighborhood';
    const testCity = 'Test City';
    const testState = 'TS';

    setUpAll(() async {
      // Initialize Supabase client
      // Note: In a real test environment, you would use test credentials
      supabase = Supabase.instance.client;
      secureService = SecureDriverExcludedZonesService(supabase);
      regularService = DriverExcludedZonesService(supabase);
    });

    group('Zone Management Flow', () {
      late String createdZoneId;

      test('should add a new excluded zone', () async {
        // This test would typically be skipped in CI/CD environments
        // as it requires a real database connection
        // skipTest: true

        try {
          final zone = await secureService.addExcludedZone(
            driverId: testDriverId,
            neighborhoodName: testNeighborhood,
            city: testCity,
            state: testState,
          );

          expect(zone, isA<DriverExcludedZone>());
          expect(zone.driverId, testDriverId);
          expect(zone.neighborhoodName, testNeighborhood);
          expect(zone.city, testCity);
          expect(zone.state, testState);
          
          createdZoneId = zone.id;
        } catch (e) {
          // If the driver doesn't exist, we expect a validation error
          expect(e.toString(), contains('motorista não encontrado'));
        }
      });

      test('should list excluded zones for driver', () async {
        // skipTest: true

        try {
          final zones = await secureService.getDriverExcludedZones(testDriverId);
          expect(zones, isA<List<DriverExcludedZone>>());
          
          // If we successfully created a zone, it should be in the list
          if (createdZoneId.isNotEmpty) {
            expect(zones.any((zone) => zone.id == createdZoneId), true);
          }
        } catch (e) {
          // Handle case where driver doesn't exist
          expect(e.toString(), contains('motorista não encontrado'));
        }
      });

      test('should check if zone is excluded', () async {
        // skipTest: true

        try {
          final isExcluded = await secureService.isZoneExcluded(
            driverId: testDriverId,
            neighborhoodName: testNeighborhood,
            city: testCity,
            state: testState,
          );

          // If we successfully created the zone, it should be excluded
          if (createdZoneId.isNotEmpty) {
            expect(isExcluded, true);
          }
        } catch (e) {
          // Handle case where driver doesn't exist
          expect(e.toString(), contains('motorista não encontrado'));
        }
      });

      test('should get excluded zones count', () async {
        // skipTest: true

        try {
          final count = await secureService.getExcludedZonesCount(testDriverId);
          expect(count, isA<int>());
          expect(count, greaterThanOrEqualTo(0));
        } catch (e) {
          // Handle case where driver doesn't exist
          expect(e.toString(), contains('motorista não encontrado'));
        }
      });

      test('should remove excluded zone', () async {
        // skipTest: true

        // Only run this test if we successfully created a zone
        if (createdZoneId.isNotEmpty) {
          try {
            await secureService.removeExcludedZone(createdZoneId);
            // Verify the zone was removed
            final zones = await secureService.getDriverExcludedZones(testDriverId);
            expect(zones.any((zone) => zone.id == createdZoneId), false);
          } catch (e) {
            // Handle case where driver doesn't exist
            expect(e.toString(), contains('motorista não encontrado'));
          }
        }
      });
    });

    group('Error Handling', () {
      test('should handle non-existent driver gracefully', () async {
        const fakeDriverId = 'fake-driver-id-that-does-not-exist';

        // Test with secure service
        expect(
          () => secureService.addExcludedZone(
            driverId: fakeDriverId,
            neighborhoodName: 'Test',
            city: 'Test City',
            state: 'TS',
          ),
          throwsA(
            predicate((e) => e.toString().contains('motorista não encontrado')),
          ),
        );

        // Test with regular service
        expect(
          () => regularService.addExcludedZone(
            driverId: fakeDriverId,
            neighborhoodName: 'Test',
            city: 'Test City',
            state: 'TS',
          ),
          throwsA(
            predicate((e) => e.toString().contains('motorista não encontrado')),
          ),
        );
      });

      test('should prevent duplicate zones', () async {
        // skipTest: true

        try {
          // Add a zone
          await secureService.addExcludedZone(
            driverId: testDriverId,
            neighborhoodName: 'Duplicate Test',
            city: 'Test City',
            state: 'TS',
          );

          // Try to add the same zone again - should throw an error
          await secureService.addExcludedZone(
            driverId: testDriverId,
            neighborhoodName: 'Duplicate Test',
            city: 'Test City',
            state: 'TS',
          );

          // If we get here, the test failed
          fail('Expected ValidationException for duplicate zone');
        } catch (e) {
          // Either the driver doesn't exist or we got the expected duplicate error
          if (!e.toString().contains('motorista não encontrado')) {
            expect(e.toString(), contains('Esta zona'));
          }
        }
      });
    });

    group('Multiple Zones Operations', () {
      test('should add multiple zones at once', () async {
        // skipTest: true

        final zones = [
          {
            'neighborhoodName': 'Multiple Test 1',
            'city': 'Test City 1',
            'state': 'T1',
          },
          {
            'neighborhoodName': 'Multiple Test 2',
            'city': 'Test City 2',
            'state': 'T2',
          }
        ];

        try {
          final addedZones = await regularService.addMultipleExcludedZones(
            driverId: testDriverId,
            zones: zones,
          );

          expect(addedZones, isA<List<DriverExcludedZone>>());
          expect(addedZones.length, 2);

          // Clean up
          for (final zone in addedZones) {
            await regularService.removeExcludedZone(zone.id);
          }
        } catch (e) {
          // Handle case where driver doesn't exist
          expect(e.toString(), contains('motorista não encontrado'));
        }
      });

      test('should handle empty zones list', () async {
        expect(
          () => regularService.addMultipleExcludedZones(
            driverId: testDriverId,
            zones: [],
          ),
          throwsA(
            predicate((e) => e.toString().contains('Lista de zonas não pode estar vazia')),
          ),
        );
      });
    });
  });
}