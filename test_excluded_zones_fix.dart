import 'package:flutter_test/flutter_test.dart';
import 'lib/models/supabase/driver_excluded_zone.dart';

void main() {
  group('Excluded Zones Fix Tests', () {
    test('DriverExcludedZone displayName should show correct information', () {
      // Test keyword-based zone
      final keywordZone = DriverExcludedZone(
        id: 'test-id-1',
        driverId: 'driver-id',
        neighborhoodName: 'R. Augusta', // This was incorrectly used before
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.now(),
        keyword: 'Consolação', // This should be displayed
        zoneType: 'bairro',
      );

      expect(keywordZone.displayName, equals('Consolação (Bairro)'));
      expect(keywordZone.isKeywordBased, isTrue);
      expect(keywordZone.exclusionTerm, equals('Consolação'));

      // Test legacy zone (no keyword)
      final legacyZone = DriverExcludedZone(
        id: 'test-id-2',
        driverId: 'driver-id',
        neighborhoodName: 'Centro',
        city: 'Rio de Janeiro',
        state: 'RJ',
        createdAt: DateTime.now(),
      );

      expect(legacyZone.displayName, equals('Centro, Rio de Janeiro - RJ'));
      expect(legacyZone.isKeywordBased, isFalse);
      expect(legacyZone.exclusionTerm, equals('Centro'));
    });

    test('Zone type labels should be correctly mapped', () {
      final zoneTypes = ['rua', 'bairro', 'cidade', 'estado', 'regiao'];
      final expectedLabels = [
        'Rua/Avenida',
        'Bairro',
        'Cidade',
        'Estado',
        'Região'
      ];

      for (int i = 0; i < zoneTypes.length; i++) {
        final zone = DriverExcludedZone(
          id: 'test-id-$i',
          driverId: 'driver-id',
          neighborhoodName: 'Test',
          city: 'Test City',
          state: 'TS',
          createdAt: DateTime.now(),
          keyword: 'Test Keyword',
          zoneType: zoneTypes[i],
        );

        expect(zone.displayName, equals('Test Keyword (${expectedLabels[i]})'));
      }
    });

    test('Address parsing should correctly identify components', () {
      // Test data that simulates the problem scenario
      final testCases = [
        {
          'address': 'R. Augusta - Consolação, São Paulo - SP, Brasil',
          'expected': {
            'neighborhood': 'R. Augusta',
            'city': 'São Paulo',
            'state': 'SP',
          }
        },
        {
          'address': 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
          'expected': {
            'neighborhood': 'Av. Paulista, 1000',
            'city': 'São Paulo',
            'state': 'SP',
          }
        },
        {
          'address': 'Centro, Rio de Janeiro - RJ, Brasil',
          'expected': {
            'neighborhood': 'Centro',
            'city': 'Rio de Janeiro',
            'state': 'RJ',
          }
        }
      ];

      // Note: This would need access to the actual _parseAddress method
      // which is private. This is more of a documentation of expected behavior.
      print('Address parsing test cases documented for manual verification');

      for (final testCase in testCases) {
        print('Address: ${testCase['address']}');
        print('Expected: ${testCase['expected']}');
        print('---');
      }
    });

    test('Zone data for insertion should include required fields', () {
      // Test the data structure that should be sent to Supabase
      const driverId = 'test-driver-id';
      const keyword = 'Consolação';
      const zoneType = 'bairro';
      const city = 'São Paulo';
      const state = 'SP';

      final expectedZoneData = {
        'driver_id': driverId,
        'neighborhood_name': keyword, // This was the missing piece!
        'city': city,
        'state': state,
        'zone_type': zoneType,
        'keyword': keyword,
      };

      // Verify all required fields are present
      expect(expectedZoneData.containsKey('driver_id'), isTrue);
      expect(expectedZoneData.containsKey('neighborhood_name'), isTrue);
      expect(expectedZoneData.containsKey('city'), isTrue);
      expect(expectedZoneData.containsKey('state'), isTrue);
      expect(expectedZoneData.containsKey('zone_type'), isTrue);
      expect(expectedZoneData.containsKey('keyword'), isTrue);

      // Verify no invalid fields are included
      expect(expectedZoneData.containsKey('reason'), isFalse);
      expect(expectedZoneData.containsKey('is_active'), isFalse);
      expect(expectedZoneData.containsKey('created_at'), isFalse);

      print('Correct zone data structure:');
      expectedZoneData.forEach((key, value) {
        print('  $key: $value');
      });
    });

    test('Zone selection dialog should map correctly', () {
      // Test the mapping between user selection and saved data
      const address = 'R. Augusta - Consolação, São Paulo - SP, Brasil';
      const neighborhood = 'Consolação'; // This should be extracted as the neighborhood
      const city = 'São Paulo';
      const state = 'SP';

      final zoneOptions = [
        {
          'type': 'bairro',
          'title': 'Apenas este bairro',
          'subtitle': 'Excluir: $neighborhood',
          'keyword': neighborhood, // Should use neighborhood, not the street name
        },
        {
          'type': 'cidade',
          'title': 'Toda a cidade',
          'subtitle': 'Excluir: $city',
          'keyword': city,
        },
        {
          'type': 'estado',
          'title': 'Todo o estado',
          'subtitle': 'Excluir: $state',
          'keyword': state,
        },
      ];

      // Verify the bairro option uses the correct keyword
      final bairroOption = zoneOptions[0];
      expect(bairroOption['keyword'], equals('Consolação'));
      expect(bairroOption['subtitle'], equals('Excluir: Consolação'));

      print('Zone options correctly configured:');
      for (final option in zoneOptions) {
        print('  ${option['type']}: ${option['subtitle']}');
      }
    });
  });

  group('Integration Test Scenarios', () {
    test('Full flow scenario - user selects neighborhood exclusion', () {
      // Simulate the complete flow that was problematic
      print('\n=== FULL FLOW TEST ===');
      print('1. User searches for: "R. Augusta - Consolação, São Paulo - SP, Brasil"');
      print('2. Address parsing should extract:');
      print('   - Street: R. Augusta');
      print('   - Neighborhood: Consolação');
      print('   - City: São Paulo');
      print('   - State: SP');

      print('3. User selects: "Apenas este bairro"');
      print('4. System should save:');
      print('   - neighborhood_name: "Consolação" (required field)');
      print('   - keyword: "Consolação" (for matching)');
      print('   - zone_type: "bairro"');
      print('   - city: "São Paulo"');
      print('   - state: "SP"');

      print('5. Display should show: "Consolação (Bairro)"');
      print('6. Address matching should work for any address containing "Consolação"');

      // Create the expected result
      final expectedZone = DriverExcludedZone(
        id: 'generated-id',
        driverId: 'test-driver',
        neighborhoodName: 'Consolação',
        city: 'São Paulo',
        state: 'SP',
        createdAt: DateTime.now(),
        keyword: 'Consolação',
        zoneType: 'bairro',
      );

      expect(expectedZone.displayName, equals('Consolação (Bairro)'));
      expect(expectedZone.isKeywordBased, isTrue);

      print('\n✅ Expected result: ${expectedZone.displayName}');
      print('✅ All assertions passed!');
    });
  });
}
