import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:option/services/driver_excluded_zones_service.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';
import '../../helpers/supabase_test_helper.dart';

void main() {
  group('DriverExcludedZones Integration Tests', () {
    late DriverExcludedZonesService service;
    late SupabaseClient client;
    String? testDriverId;

    setUpAll(() async {
      await SupabaseTestHelper.initialize();
      client = SupabaseTestHelper.client;
      service = DriverExcludedZonesService(client);
      
      // Buscar um driver existente no banco de dados
      try {
        final response = await client
            .from('drivers')
            .select('id')
            .limit(1)
            .maybeSingle();
        
        if (response != null) {
          testDriverId = response['id'];
          print('Driver encontrado para teste: $testDriverId');
        } else {
          print('Nenhum driver disponível no banco de dados');
        }
      } catch (e) {
        print('Erro ao buscar driver: $e');
      }
    });

    setUp(() async {
      if (testDriverId != null) {
        // Limpar apenas as zonas excluídas do driver de teste
        try {
          await client
              .from('driver_excluded_zones')
              .delete()
              .eq('driver_id', testDriverId!);
        } catch (e) {
          print('Erro ao limpar zonas excluídas: $e');
        }
      }
    });

    tearDownAll(() async {
      // Limpar dados de teste após todos os testes
      try {
        await SupabaseTestHelper.cleanDatabase();
      } catch (e) {
        print('Erro ao limpar dados de teste: $e');
      }
    });

    test('should add and retrieve excluded zone', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Arrange
      const neighborhood = 'Vila Madalena';
      const city = 'São Paulo';
      const state = 'SP';

      // Act
      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: neighborhood,
        city: city,
        state: state,
      );

      // Assert
      final excludedZones = await service.getDriverExcludedZones(testDriverId!);
      expect(excludedZones, isNotEmpty);
      
      final zone = excludedZones.firstWhere(
        (z) => z.neighborhoodName == neighborhood && z.city == city && z.state == state,
      );
      expect(zone.driverId, equals(testDriverId!));
      expect(zone.neighborhoodName, equals(neighborhood));
      expect(zone.city, equals(city));
      expect(zone.state, equals(state));
      expect(zone.createdAt, isNotNull);
    });

    test('should check if zone is excluded', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Arrange
      const neighborhood = 'Pinheiros';
      const city = 'São Paulo';
      const state = 'SP';

      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: neighborhood,
        city: city,
        state: state,
      );

      // Act & Assert
      final isExcluded = await service.isZoneExcluded(
        driverId: testDriverId!,
        neighborhoodName: neighborhood,
        city: city,
        state: state,
      );
      expect(isExcluded, isTrue);

      final isNotExcluded = await service.isZoneExcluded(
        driverId: testDriverId!,
        neighborhoodName: 'Vila Olímpia',
        city: city,
        state: state,
      );
      expect(isNotExcluded, isFalse);
    });

    test('should get excluded zones count', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Arrange - adicionar algumas zonas
      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: 'Jardins',
        city: 'São Paulo',
        state: 'SP',
      );
      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: 'Moema',
        city: 'São Paulo',
        state: 'SP',
      );

      // Act
      final count = await service.getExcludedZonesCount(testDriverId!);

      // Assert
      expect(count, greaterThanOrEqualTo(2));
    });

    test('should get excluded zones by city', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Arrange
      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: 'Liberdade',
        city: 'São Paulo',
        state: 'SP',
      );
      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
      );

      // Act
      final spZones = await service.getExcludedZonesByCity(
        driverId: testDriverId!,
        city: 'São Paulo',
        state: 'SP',
      );

      // Assert
      expect(spZones, isNotEmpty);
      expect(spZones.length, greaterThanOrEqualTo(2));
      
      final neighborhoods = spZones.map((z) => z.neighborhoodName).toList();
      expect(neighborhoods, contains('Liberdade'));
      expect(neighborhoods, contains('Bela Vista'));
    });

    test('should remove excluded zone', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Arrange
      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: 'Consolação',
        city: 'São Paulo',
        state: 'SP',
      );

      final initialZones = await service.getDriverExcludedZones(testDriverId!);
      final zoneToRemove = initialZones.firstWhere(
        (z) => z.neighborhoodName == 'Consolação',
      );

      // Act
      await service.removeExcludedZone(zoneToRemove.id);

      // Assert
      final remainingZones = await service.getDriverExcludedZones(testDriverId!);
      final hasZone = remainingZones.any((z) => z.neighborhoodName == 'Consolação');
      expect(hasZone, isFalse);
    });

    test('should handle duplicate zone addition gracefully', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Arrange
      const neighborhood = 'República';
      const city = 'São Paulo';
      const state = 'SP';

      // Act - adicionar a mesma zona duas vezes
      await service.addExcludedZone(
        driverId: testDriverId!,
        neighborhoodName: neighborhood,
        city: city,
        state: state,
      );

      // Tentar adicionar novamente deve falhar
      expect(
        () => service.addExcludedZone(
          driverId: testDriverId!,
          neighborhoodName: neighborhood,
          city: city,
          state: state,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should return empty list for driver with no excluded zones', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Act
      final zones = await service.getDriverExcludedZones(testDriverId!);
      final count = await service.getExcludedZonesCount('non-existent-driver-id');

      // Assert
      expect(zones, isEmpty);
      expect(count, equals(0));
    });

    test('should handle non-existent zone check gracefully', () async {
      if (testDriverId == null) {
        markTestSkipped('Nenhum driver disponível no banco de dados');
        return;
      }
      
      // Act & Assert
      final isExcluded = await service.isZoneExcluded(
        driverId: testDriverId!,
        neighborhoodName: 'Vila Madalena',
        city: 'São Paulo',
        state: 'SP',
      );
      expect(isExcluded, isFalse);
    });
  });
}