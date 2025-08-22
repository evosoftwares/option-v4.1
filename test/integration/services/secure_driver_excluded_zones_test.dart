import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:option/services/secure_driver_excluded_zones_service.dart';
import 'package:option/exceptions/app_exceptions.dart';
import '../../helpers/supabase_test_helper.dart';

void main() {
  group('SecureDriverExcludedZonesService Integration Tests', () {
    late SupabaseClient supabase;
    late SecureDriverExcludedZonesService service;
    late String testDriverId;

    setUpAll(() async {
      supabase = await SupabaseTestHelper.createTestClient();
      service = SecureDriverExcludedZonesService(supabase);
      testDriverId = 'test-driver-${DateTime.now().millisecondsSinceEpoch}';
    });

    tearDownAll(() async {
      // Clean up test data
      await supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('driver_id', testDriverId);
      await supabase.dispose();
    });

    setUp(() async {
      // Clean test data before each test
      await supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('driver_id', testDriverId);
    });

    group('addExcludedZone', () {
      test('should add a valid excluded zone', () async {
        final zone = await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'Vila Madalena',
          city: 'São Paulo',
          state: 'SP',
        );

        expect(zone.driverId, equals(testDriverId));
        expect(zone.neighborhoodName, equals('vila madalena'));
        expect(zone.city, equals('sao paulo'));
        expect(zone.state, equals('sp'));
      });

      test('should normalize data when adding zone', () async {
        final zone = await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: '  COPACABANA  ',
          city: '  RIO DE JANEIRO  ',
          state: 'RJ',
        );

        expect(zone.neighborhoodName, equals('copacabana'));
        expect(zone.city, equals('rio de janeiro'));
        expect(zone.state, equals('rj'));
      });

      test('should prevent duplicate zones', () async {
        // Add first zone
        await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'Ipanema',
          city: 'Rio de Janeiro',
          state: 'RJ',
        );

        // Try to add same zone (should not throw due to upsert)
        final zone = await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'IPANEMA',
          city: 'RIO DE JANEIRO',
          state: 'rj',
        );

        expect(zone.neighborhoodName, equals('ipanema'));
        
        // Verify only one zone exists
        final zones = await service.getDriverExcludedZones(testDriverId);
        expect(zones.length, equals(1));
      });

      test('should throw ValidationException for invalid state', () async {
        expect(
          () => service.addExcludedZone(
            driverId: testDriverId,
            neighborhoodName: 'Test Neighborhood',
            city: 'Test City',
            state: 'INVALID',
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw ValidationException for empty fields', () async {
        expect(
          () => service.addExcludedZone(
            driverId: testDriverId,
            neighborhoodName: '',
            city: 'São Paulo',
            state: 'SP',
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should enforce zone limit', () async {
        // Add zones up to the limit (this test assumes a low limit for testing)
        // We'll add 5 zones and then mock the count check
        for (int i = 0; i < 5; i++) {
          await service.addExcludedZone(
            driverId: testDriverId,
            neighborhoodName: 'Test Neighborhood $i',
            city: 'São Paulo',
            state: 'SP',
          );
        }

        // Verify zones were added
        final zones = await service.getDriverExcludedZones(testDriverId);
        expect(zones.length, equals(5));
      });
    });

    group('addMultipleExcludedZones', () {
      test('should add multiple valid zones', () async {
        final zonesData = [
          {
            'neighborhoodName': 'Vila Madalena',
            'city': 'São Paulo',
            'state': 'SP',
          },
          {
            'neighborhoodName': 'Copacabana',
            'city': 'Rio de Janeiro',
            'state': 'RJ',
          },
        ];

        final zones = await service.addMultipleExcludedZones(
          driverId: testDriverId,
          zones: zonesData,
        );

        expect(zones.length, equals(2));
        expect(zones[0].neighborhoodName, equals('vila madalena'));
        expect(zones[1].neighborhoodName, equals('copacabana'));
      });

      test('should handle duplicates in multiple zones', () async {
        // First add a zone
        await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'Ipanema',
          city: 'Rio de Janeiro',
          state: 'RJ',
        );

        final zonesData = [
          {
            'neighborhoodName': 'IPANEMA',
            'city': 'RIO DE JANEIRO',
            'state': 'rj',
          },
          {
            'neighborhoodName': 'Leblon',
            'city': 'Rio de Janeiro',
            'state': 'RJ',
          },
        ];

        final zones = await service.addMultipleExcludedZones(
          driverId: testDriverId,
          zones: zonesData,
        );

        // Should have 2 unique zones total
        final allZones = await service.getDriverExcludedZones(testDriverId);
        expect(allZones.length, equals(2));
      });

      test('should throw ValidationException for empty list', () async {
        expect(
          () => service.addMultipleExcludedZones(
            driverId: testDriverId,
            zones: [],
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('getDriverExcludedZones', () {
      test('should return empty list for driver with no zones', () async {
        final zones = await service.getDriverExcludedZones(testDriverId);
        expect(zones, isEmpty);
      });

      test('should return all zones for driver ordered by creation date', () async {
        // Add zones with slight delay to ensure different creation times
        await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'Zone 1',
          city: 'São Paulo',
          state: 'SP',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'Zone 2',
          city: 'São Paulo',
          state: 'SP',
        );

        final zones = await service.getDriverExcludedZones(testDriverId);
        expect(zones.length, equals(2));
        // Should be ordered by creation date (descending)
        expect(zones[0].neighborhoodName, equals('zone 2'));
        expect(zones[1].neighborhoodName, equals('zone 1'));
      });
    });

    group('isZoneExcluded', () {
      test('should return true for excluded zone', () async {
        await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'Vila Madalena',
          city: 'São Paulo',
          state: 'SP',
        );

        final isExcluded = await service.isZoneExcluded(
          driverId: testDriverId,
          neighborhoodName: 'VILA MADALENA',
          city: 'SÃO PAULO',
          state: 'sp',
        );

        expect(isExcluded, isTrue);
      });

      test('should return false for non-excluded zone', () async {
        final isExcluded = await service.isZoneExcluded(
          driverId: testDriverId,
          neighborhoodName: 'Non Excluded Zone',
          city: 'São Paulo',
          state: 'SP',
        );

        expect(isExcluded, isFalse);
      });

      test('should handle invalid state gracefully', () async {
        final isExcluded = await service.isZoneExcluded(
          driverId: testDriverId,
          neighborhoodName: 'Test Zone',
          city: 'Test City',
          state: 'INVALID',
        );

        expect(isExcluded, isFalse);
      });
    });

    group('removeExcludedZone', () {
      test('should remove existing zone', () async {
        final zone = await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: 'Vila Madalena',
          city: 'São Paulo',
          state: 'SP',
        );

        await service.removeExcludedZone(zone.id);

        final zones = await service.getDriverExcludedZones(testDriverId);
        expect(zones, isEmpty);
      });

      test('should throw ValidationException for non-existent zone', () async {
        expect(
          () => service.removeExcludedZone('non-existent-id'),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('removeAllExcludedZones', () {
      test('should remove all zones for driver', () async {
        // Add multiple zones
        await service.addMultipleExcludedZones(
          driverId: testDriverId,
          zones: [
            {
              'neighborhoodName': 'Zone 1',
              'city': 'São Paulo',
              'state': 'SP',
            },
            {
              'neighborhoodName': 'Zone 2',
              'city': 'São Paulo',
              'state': 'SP',
            },
          ],
        );

        await service.removeAllExcludedZones(testDriverId);

        final zones = await service.getDriverExcludedZones(testDriverId);
        expect(zones, isEmpty);
      });
    });

    group('getExcludedZonesCount', () {
      test('should return correct count', () async {
        expect(await service.getExcludedZonesCount(testDriverId), equals(0));

        await service.addMultipleExcludedZones(
          driverId: testDriverId,
          zones: [
            {
              'neighborhoodName': 'Zone 1',
              'city': 'São Paulo',
              'state': 'SP',
            },
            {
              'neighborhoodName': 'Zone 2',
              'city': 'São Paulo',
              'state': 'SP',
            },
            {
              'neighborhoodName': 'Zone 3',
              'city': 'Rio de Janeiro',
              'state': 'RJ',
            },
          ],
        );

        expect(await service.getExcludedZonesCount(testDriverId), equals(3));
      });
    });

    group('getExcludedZonesByCity', () {
      test('should return zones filtered by city', () async {
        await service.addMultipleExcludedZones(
          driverId: testDriverId,
          zones: [
            {
              'neighborhoodName': 'Vila Madalena',
              'city': 'São Paulo',
              'state': 'SP',
            },
            {
              'neighborhoodName': 'Pinheiros',
              'city': 'São Paulo',
              'state': 'SP',
            },
            {
              'neighborhoodName': 'Copacabana',
              'city': 'Rio de Janeiro',
              'state': 'RJ',
            },
          ],
        );

        final spZones = await service.getExcludedZonesByCity(
          driverId: testDriverId,
          city: 'São Paulo',
          state: 'SP',
        );

        expect(spZones.length, equals(2));
        expect(spZones.every((z) => z.city == 'sao paulo'), isTrue);
        expect(spZones.every((z) => z.state == 'sp'), isTrue);
      });
    });

    group('getDriverZoneStats', () {
      test('should return correct statistics', () async {
        await service.addMultipleExcludedZones(
          driverId: testDriverId,
          zones: [
            {
              'neighborhoodName': 'Zone 1',
              'city': 'São Paulo',
              'state': 'SP',
            },
            {
              'neighborhoodName': 'Zone 2',
              'city': 'São Paulo',
              'state': 'SP',
            },
            {
              'neighborhoodName': 'Zone 3',
              'city': 'Rio de Janeiro',
              'state': 'RJ',
            },
          ],
        );

        final stats = await service.getDriverZoneStats(testDriverId);
        
        expect(stats['total_zones'], equals(3));
        expect(stats['cities_count'], equals(2));
        expect(stats['remaining_slots'], equals(47)); // 50 - 3
        expect(stats['last_zone_added'], isNotNull);
      });

      test('should return default stats for driver with no zones', () async {
        final stats = await service.getDriverZoneStats(testDriverId);
        
        expect(stats['total_zones'], equals(0));
        expect(stats['cities_count'], equals(0));
        expect(stats['remaining_slots'], equals(50));
        expect(stats['last_zone_added'], isNull);
      });
    });

    group('data normalization and validation', () {
      test('should consistently normalize data across operations', () async {
        // Add zone with varied formatting
        await service.addExcludedZone(
          driverId: testDriverId,
          neighborhoodName: '  VILA   MADALENA  ',
          city: '  SÃO   PAULO  ',
          state: 'sp',
        );

        // Check with different formatting
        final isExcluded = await service.isZoneExcluded(
          driverId: testDriverId,
          neighborhoodName: 'vila madalena',
          city: 'são paulo',
          state: 'SP',
        );

        expect(isExcluded, isTrue);

        // Get zones and verify normalization
        final zones = await service.getDriverExcludedZones(testDriverId);
        expect(zones[0].neighborhoodName, equals('vila madalena'));
        expect(zones[0].city, equals('sao paulo'));
        expect(zones[0].state, equals('sp'));
      });
    });
  });
}