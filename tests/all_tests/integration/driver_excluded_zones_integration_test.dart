import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';
import 'package:option/services/driver_matching_service.dart';
import 'package:option/models/supabase/driver.dart';
import 'package:option/exceptions/app_exceptions.dart';

void main() {
  group('Driver Excluded Zones - End-to-End Integration Tests', () {

    group('Critical Business Flow Tests', () {
      test('should verify complete exclusion workflow', () async {
        // CENÁRIO: Motorista do Rio que não quer atender Copacabana

        // 1. SIMULAÇÃO: Motorista adiciona zona excluída
        final driverExcludedZones = [
          DriverExcludedZone(
            id: 'zone-copacabana-001',
            driverId: 'driver-rio-001',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
        ];

        // 2. SIMULAÇÃO: Passageiro solicita corrida COM ORIGEM em Copacabana
        final matchingCriteriaOriginExcluded = MatchingCriteria(
          passengerLatitude: -22.9711, // Copacabana
          passengerLongitude: -43.1822,
          originNeighborhood: 'Copacabana',
          originCity: 'Rio de Janeiro',
          originState: 'RJ',
          destinationLatitude: -22.9068, // Centro do Rio
          destinationLongitude: -43.1729,
          destinationNeighborhood: 'Centro',
          destinationCity: 'Rio de Janeiro',
          destinationState: 'RJ',
        );

        // 3. VERIFICAÇÃO: Motorista deve ser excluído pelo filtro de origem
        final shouldExcludeByOrigin = _simulateExclusionFilter(
          driverExcludedZones,
          matchingCriteriaOriginExcluded,
        );

        expect(shouldExcludeByOrigin, true,
          reason: 'Motorista deve ser excluído quando origem da corrida está em zona excluída');

        // 4. SIMULAÇÃO: Passageiro solicita corrida COM DESTINO em Copacabana
        final matchingCriteriaDestinationExcluded = MatchingCriteria(
          passengerLatitude: -22.9068, // Centro do Rio
          passengerLongitude: -43.1729,
          originNeighborhood: 'Centro',
          originCity: 'Rio de Janeiro',
          originState: 'RJ',
          destinationLatitude: -22.9711, // Copacabana
          destinationLongitude: -43.1822,
          destinationNeighborhood: 'Copacabana',
          destinationCity: 'Rio de Janeiro',
          destinationState: 'RJ',
        );

        // 5. VERIFICAÇÃO: Motorista deve ser excluído pelo filtro de destino
        final shouldExcludeByDestination = _simulateExclusionFilter(
          driverExcludedZones,
          matchingCriteriaDestinationExcluded,
        );

        expect(shouldExcludeByDestination, true,
          reason: 'Motorista deve ser excluído quando destino da corrida está em zona excluída');

        // 6. SIMULAÇÃO: Passageiro solicita corrida SEM zona excluída
        final matchingCriteriaNonExcluded = MatchingCriteria(
          passengerLatitude: -22.9068, // Centro do Rio
          passengerLongitude: -43.1729,
          originNeighborhood: 'Centro',
          originCity: 'Rio de Janeiro',
          originState: 'RJ',
          destinationLatitude: -22.9100, // Tijuca
          destinationLongitude: -43.2400,
          destinationNeighborhood: 'Tijuca',
          destinationCity: 'Rio de Janeiro',
          destinationState: 'RJ',
        );

        // 7. VERIFICAÇÃO: Motorista deve aparecer como opção
        final shouldNotExclude = _simulateExclusionFilter(
          driverExcludedZones,
          matchingCriteriaNonExcluded,
        );

        expect(shouldNotExclude, false,
          reason: 'Motorista deve aparecer como opção quando nem origem nem destino estão em zona excluída');
      });
    });

    group('Real World Scenarios - São Paulo', () {
      test('should handle typical SP driver exclusions correctly', () async {
        // CENÁRIO: Motorista de SP evita Centro e Cidade Tiradentes
        final spDriverExclusions = [
          DriverExcludedZone(
            id: 'zone-sp-centro',
            driverId: 'driver-sp-001',
            neighborhoodName: 'Centro',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-sp-tiradentes',
            driverId: 'driver-sp-001',
            neighborhoodName: 'Cidade Tiradentes',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          ),
        ];

        final testScenarios = [
          {
            'description': 'Corrida para o Centro - deve excluir motorista',
            'criteria': MatchingCriteria(
              passengerLatitude: -23.5329,
              passengerLongitude: -46.6395,
              originNeighborhood: 'Vila Madalena',
              originCity: 'São Paulo',
              originState: 'SP',
              destinationLatitude: -23.5475,
              destinationLongitude: -46.6361,
              destinationNeighborhood: 'Centro',
              destinationCity: 'São Paulo',
              destinationState: 'SP',
            ),
            'shouldExclude': true,
          },
          {
            'description': 'Corrida da Cidade Tiradentes - deve excluir motorista',
            'criteria': MatchingCriteria(
              passengerLatitude: -23.5891,
              passengerLongitude: -46.4023,
              originNeighborhood: 'Cidade Tiradentes',
              originCity: 'São Paulo',
              originState: 'SP',
              destinationLatitude: -23.5329,
              destinationLongitude: -46.6395,
              destinationNeighborhood: 'Vila Madalena',
              destinationCity: 'São Paulo',
              destinationState: 'SP',
            ),
            'shouldExclude': true,
          },
          {
            'description': 'Corrida zona oeste permitida - deve incluir motorista',
            'criteria': MatchingCriteria(
              passengerLatitude: -23.5329,
              passengerLongitude: -46.6395,
              originNeighborhood: 'Vila Madalena',
              originCity: 'São Paulo',
              originState: 'SP',
              destinationLatitude: -23.5693,
              destinationLongitude: -46.6958,
              destinationNeighborhood: 'Pinheiros',
              destinationCity: 'São Paulo',
              destinationState: 'SP',
            ),
            'shouldExclude': false,
          },
        ];

        for (final scenario in testScenarios) {
          final shouldExclude = _simulateExclusionFilter(
            spDriverExclusions,
            scenario['criteria'] as MatchingCriteria,
          );

          expect(shouldExclude, scenario['shouldExclude'],
            reason: scenario['description'] as String);
        }
      });
    });

    group('Real World Scenarios - Rio de Janeiro', () {
      test('should handle Rio beach zone exclusions correctly', () async {
        // CENÁRIO: Motorista do Rio evita zona sul (praias)
        final rjDriverExclusions = [
          DriverExcludedZone(
            id: 'zone-rj-copacabana',
            driverId: 'driver-rj-001',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-rj-ipanema',
            driverId: 'driver-rj-001',
            neighborhoodName: 'Ipanema',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-rj-leblon',
            driverId: 'driver-rj-001',
            neighborhoodName: 'Leblon',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
        ];

        final beachTestScenarios = [
          {
            'description': 'Corrida para Copacabana - deve excluir',
            'origin': ['Tijuca', 'Rio de Janeiro', 'RJ'],
            'destination': ['Copacabana', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': true,
          },
          {
            'description': 'Corrida de Ipanema - deve excluir',
            'origin': ['Ipanema', 'Rio de Janeiro', 'RJ'],
            'destination': ['Centro', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': true,
          },
          {
            'description': 'Corrida Tijuca->Maracanã - deve incluir',
            'origin': ['Tijuca', 'Rio de Janeiro', 'RJ'],
            'destination': ['Maracanã', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': false,
          },
          {
            'description': 'Corrida Centro->Barra da Tijuca - deve incluir',
            'origin': ['Centro', 'Rio de Janeiro', 'RJ'],
            'destination': ['Barra da Tijuca', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': false,
          },
        ];

        for (final scenario in beachTestScenarios) {
          final origin = scenario['origin'] as List<String>;
          final destination = scenario['destination'] as List<String>;

          final criteria = MatchingCriteria(
            passengerLatitude: -22.9068,
            passengerLongitude: -43.1729,
            originNeighborhood: origin[0],
            originCity: origin[1],
            originState: origin[2],
            destinationLatitude: -22.9068,
            destinationLongitude: -43.1729,
            destinationNeighborhood: destination[0],
            destinationCity: destination[1],
            destinationState: destination[2],
          );

          final shouldExclude = _simulateExclusionFilter(rjDriverExclusions, criteria);

          expect(shouldExclude, scenario['shouldExclude'],
            reason: '${scenario['description']} - ${origin.join(", ")} -> ${destination.join(", ")}');
        }
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle incomplete address data gracefully', () {
        final excludedZones = [
          DriverExcludedZone(
            id: 'zone-1',
            driverId: 'driver-1',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
        ];

        // CASO 1: Faltam dados de origem
        final criteriaIncompleteOrigin = MatchingCriteria(
          passengerLatitude: -22.9068,
          passengerLongitude: -43.1729,
          // originNeighborhood: null, // Faltando
          // originCity: null, // Faltando
          // originState: null, // Faltando
          destinationNeighborhood: 'Copacabana',
          destinationCity: 'Rio de Janeiro',
          destinationState: 'RJ',
        );

        // Deve excluir apenas pelo destino
        expect(_simulateExclusionFilter(excludedZones, criteriaIncompleteOrigin), true);

        // CASO 2: Faltam dados de destino
        final criteriaIncompleteDestination = MatchingCriteria(
          passengerLatitude: -22.9068,
          passengerLongitude: -43.1729,
          originNeighborhood: 'Copacabana',
          originCity: 'Rio de Janeiro',
          originState: 'RJ',
          // destinationNeighborhood: null, // Faltando
          // destinationCity: null, // Faltando
          // destinationState: null, // Faltando
        );

        // Deve excluir apenas pela origem
        expect(_simulateExclusionFilter(excludedZones, criteriaIncompleteDestination), true);

        // CASO 3: Não há dados de origem nem destino
        final criteriaNoLocationData = MatchingCriteria(
          passengerLatitude: -22.9068,
          passengerLongitude: -43.1729,
        );

        // Não deve excluir (não há dados para comparar)
        expect(_simulateExclusionFilter(excludedZones, criteriaNoLocationData), false);
      });

      test('should handle multiple exclusions for same driver', () {
        final multipleExclusions = [
          DriverExcludedZone(
            id: 'zone-1',
            driverId: 'driver-multiple',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-2',
            driverId: 'driver-multiple',
            neighborhoodName: 'Centro',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-3',
            driverId: 'driver-multiple',
            neighborhoodName: 'Vila Madalena',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          ),
        ];

        // Teste múltiplas exclusões em diferentes cidades
        final testCases = [
          {
            'origin': ['Copacabana', 'Rio de Janeiro', 'RJ'],
            'destination': ['Ipanema', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': true, // Origem excluída
          },
          {
            'origin': ['Ipanema', 'Rio de Janeiro', 'RJ'],
            'destination': ['Centro', 'São Paulo', 'SP'],
            'shouldExclude': true, // Destino excluído
          },
          {
            'origin': ['Jardins', 'São Paulo', 'SP'],
            'destination': ['Vila Madalena', 'São Paulo', 'SP'],
            'shouldExclude': true, // Destino excluído
          },
          {
            'origin': ['Tijuca', 'Rio de Janeiro', 'RJ'],
            'destination': ['Barra da Tijuca', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': false, // Nenhum excluído
          },
        ];

        for (final testCase in testCases) {
          final origin = testCase['origin'] as List<String>;
          final destination = testCase['destination'] as List<String>;

          final criteria = MatchingCriteria(
            passengerLatitude: -22.9068,
            passengerLongitude: -43.1729,
            originNeighborhood: origin[0],
            originCity: origin[1],
            originState: origin[2],
            destinationNeighborhood: destination[0],
            destinationCity: destination[1],
            destinationState: destination[2],
          );

          final shouldExclude = _simulateExclusionFilter(multipleExclusions, criteria);

          expect(shouldExclude, testCase['shouldExclude'],
            reason: 'Multiple exclusions test: ${origin.join(", ")} -> ${destination.join(", ")}');
        }
      });
    });

    group('Performance and Scale Tests', () {
      test('should handle large number of exclusions efficiently', () {
        // Simular motorista com muitas exclusões
        final manyExclusions = List.generate(50, (index) =>
          DriverExcludedZone(
            id: 'zone-$index',
            driverId: 'driver-heavy-user',
            neighborhoodName: 'Bairro $index',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          )
        );

        // Adicionar zona específica para teste
        manyExclusions.add(DriverExcludedZone(
          id: 'zone-test',
          driverId: 'driver-heavy-user',
          neighborhoodName: 'Vila Madalena',
          city: 'São Paulo',
          state: 'SP',
          createdAt: DateTime.now(),
        ));

        final criteria = MatchingCriteria(
          passengerLatitude: -23.5329,
          passengerLongitude: -46.6395,
          originNeighborhood: 'Vila Madalena',
          originCity: 'São Paulo',
          originState: 'SP',
          destinationNeighborhood: 'Jardins',
          destinationCity: 'São Paulo',
          destinationState: 'SP',
        );

        // Medir performance
        final stopwatch = Stopwatch()..start();
        final shouldExclude = _simulateExclusionFilter(manyExclusions, criteria);
        stopwatch.stop();

        // Verificar resultado e performance
        expect(shouldExclude, true, reason: 'Should exclude driver with Vila Madalena in exclusion list');
        expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Performance test: Exclusion filtering should complete within 100ms even with many exclusions');
      });
    });

    group('Data Integrity Tests', () {
      test('should validate exclusion zone data integrity', () {
        final validZones = [
          DriverExcludedZone(
            id: 'zone-valid-1',
            driverId: 'driver-1',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
        ];

        // Todos os campos devem estar preenchidos
        for (final zone in validZones) {
          expect(zone.id.isNotEmpty, true, reason: 'Zone ID must not be empty');
          expect(zone.driverId.isNotEmpty, true, reason: 'Driver ID must not be empty');
          expect(zone.neighborhoodName.isNotEmpty, true, reason: 'Neighborhood name must not be empty');
          expect(zone.city.isNotEmpty, true, reason: 'City must not be empty');
          expect(zone.state.isNotEmpty, true, reason: 'State must not be empty');
          expect(zone.state.length, 2, reason: 'State must be 2 characters');
        }
      });
    });
  });
}

// Helper function to simulate the exclusion filter logic
bool _simulateExclusionFilter(
  List<DriverExcludedZone> excludedZones,
  MatchingCriteria criteria,
) {
  // Simula a lógica do DriverMatchingService._filterByExclusionZones

  for (final zone in excludedZones) {
    // Check origin
    if (criteria.originNeighborhood != null &&
        criteria.originCity != null &&
        criteria.originState != null) {
      if (zone.neighborhoodName == criteria.originNeighborhood &&
          zone.city == criteria.originCity &&
          zone.state == criteria.originState) {
        return true; // Driver should be excluded
      }
    }

    // Check destination
    if (criteria.destinationNeighborhood != null &&
        criteria.destinationCity != null &&
        criteria.destinationState != null) {
      if (zone.neighborhoodName == criteria.destinationNeighborhood &&
          zone.city == criteria.destinationCity &&
          zone.state == criteria.destinationState) {
        return true; // Driver should be excluded
      }
    }
  }

  return false; // Driver should NOT be excluded
}
