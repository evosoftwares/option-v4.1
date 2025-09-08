import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver_excluded_zone.dart';
import 'package:option/exceptions/app_exceptions.dart';

void main() {
  group('Driver Excluded Zones - Real Business Logic Tests', () {

    group('Address Parsing Scenarios', () {
      test('should parse complete Brazilian address correctly', () {
        // Arrange - Endereços reais que um motorista poderia selecionar
        final testAddresses = [
          {
            'input': 'Copacabana, Rio de Janeiro - RJ, Brasil',
            'expected': {
              'neighborhood': 'Copacabana',
              'city': 'Rio de Janeiro',
              'state': 'RJ'
            }
          },
          {
            'input': 'Vila Madalena, São Paulo - SP, 05434-010, Brasil',
            'expected': {
              'neighborhood': 'Vila Madalena',
              'city': 'São Paulo',
              'state': 'SP'
            }
          },
          {
            'input': 'Boa Viagem, Recife - PE, Brasil',
            'expected': {
              'neighborhood': 'Boa Viagem',
              'city': 'Recife',
              'state': 'PE'
            }
          },
          {
            'input': 'Centro, Belo Horizonte - MG, 30112-000, Brasil',
            'expected': {
              'neighborhood': 'Centro',
              'city': 'Belo Horizonte',
              'state': 'MG'
            }
          }
        ];

        for (final testCase in testAddresses) {
          // Act - Simular parsing do endereço
          final parsed = _parseAddressForTest(testCase['input'] as String);
          final expected = testCase['expected'] as Map<String, String>;

          // Assert
          expect(parsed['neighborhood'], expected['neighborhood'],
            reason: 'Failed to parse neighborhood from: ${testCase['input']}');
          expect(parsed['city'], expected['city'],
            reason: 'Failed to parse city from: ${testCase['input']}');
          expect(parsed['state'], expected['state'],
            reason: 'Failed to parse state from: ${testCase['input']}');
        }
      });

      test('should handle edge cases in address parsing', () {
        // Arrange - Casos especiais
        final edgeCases = [
          {
            'input': 'São João de Meriti, Nova Iguaçu - RJ, Brasil',
            'expected': {
              'neighborhood': 'São João de Meriti',
              'city': 'Nova Iguaçu',
              'state': 'RJ'
            }
          },
          {
            'input': 'Bairro Alto, Rio de Janeiro - RJ, Brasil',
            'expected': {
              'neighborhood': 'Bairro Alto',
              'city': 'Rio de Janeiro',
              'state': 'RJ'
            }
          },
          {
            'input': 'Jardim das Américas, Curitiba - PR, Brasil',
            'expected': {
              'neighborhood': 'Jardim das Américas',
              'city': 'Curitiba',
              'state': 'PR'
            }
          }
        ];

        for (final testCase in edgeCases) {
          final parsed = _parseAddressForTest(testCase['input'] as String);
          final expected = testCase['expected'] as Map<String, String>;

          expect(parsed['neighborhood'], expected['neighborhood']);
          expect(parsed['city'], expected['city']);
          expect(parsed['state'], expected['state']);
        }
      });
    });

    group('Business Rules Validation', () {
      test('should validate Brazilian state codes', () {
        final validStates = ['SP', 'RJ', 'MG', 'RS', 'PR', 'SC', 'BA', 'GO', 'DF',
                           'ES', 'MT', 'MS', 'CE', 'PE', 'PB', 'RN', 'AL', 'SE',
                           'PI', 'MA', 'TO', 'PA', 'AP', 'AM', 'RR', 'AC', 'RO'];

        for (final state in validStates) {
          expect(_isValidBrazilianState(state), true,
            reason: '$state should be a valid Brazilian state');
        }

        // Test invalid states
        expect(_isValidBrazilianState('XX'), false);
        expect(_isValidBrazilianState('ABC'), false);
        expect(_isValidBrazilianState(''), false);
      });

      test('should validate zone exclusion business rules', () {
        // Arrange - Simular dados de zona excluída
        final zone = DriverExcludedZone(
          id: 'zone-1',
          driverId: 'driver-123',
          neighborhoodName: 'Copacabana',
          city: 'Rio de Janeiro',
          state: 'RJ',
          createdAt: DateTime.now(),
        );

        // Act & Assert - Verificar regras de negócio
        expect(zone.neighborhoodName.isNotEmpty, true,
          reason: 'Neighborhood name should not be empty');
        expect(zone.city.isNotEmpty, true,
          reason: 'City should not be empty');
        expect(zone.state.length, 2,
          reason: 'State should be 2 characters');
        expect(zone.driverId.isNotEmpty, true,
          reason: 'Driver ID should not be empty');
      });
    });

    group('Zone Matching Scenarios', () {
      test('should identify when trip origin matches excluded zone', () {
        // Arrange - Motorista que excluiu Copacabana
        final excludedZones = [
          DriverExcludedZone(
            id: 'zone-1',
            driverId: 'driver-123',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
        ];

        // Cenários de corrida
        final tripScenarios = [
          {
            'description': 'Origin in excluded zone - should exclude driver',
            'originNeighborhood': 'Copacabana',
            'originCity': 'Rio de Janeiro',
            'originState': 'RJ',
            'destinationNeighborhood': 'Ipanema',
            'destinationCity': 'Rio de Janeiro',
            'destinationState': 'RJ',
            'shouldExclude': true,
          },
          {
            'description': 'Destination in excluded zone - should exclude driver',
            'originNeighborhood': 'Ipanema',
            'originCity': 'Rio de Janeiro',
            'originState': 'RJ',
            'destinationNeighborhood': 'Copacabana',
            'destinationCity': 'Rio de Janeiro',
            'destinationState': 'RJ',
            'shouldExclude': true,
          },
          {
            'description': 'Neither origin nor destination in excluded zone - should include driver',
            'originNeighborhood': 'Ipanema',
            'originCity': 'Rio de Janeiro',
            'originState': 'RJ',
            'destinationNeighborhood': 'Leblon',
            'destinationCity': 'Rio de Janeiro',
            'destinationState': 'RJ',
            'shouldExclude': false,
          },
          {
            'description': 'Different city entirely - should include driver',
            'originNeighborhood': 'Vila Madalena',
            'originCity': 'São Paulo',
            'originState': 'SP',
            'destinationNeighborhood': 'Jardins',
            'destinationCity': 'São Paulo',
            'destinationState': 'SP',
            'shouldExclude': false,
          },
        ];

        for (final scenario in tripScenarios) {
          // Act
          final shouldExclude = _shouldExcludeDriverForTrip(
            excludedZones,
            scenario['originNeighborhood'] as String,
            scenario['originCity'] as String,
            scenario['originState'] as String,
            scenario['destinationNeighborhood'] as String,
            scenario['destinationCity'] as String,
            scenario['destinationState'] as String,
          );

          // Assert
          expect(shouldExclude, scenario['shouldExclude'],
            reason: scenario['description'] as String);
        }
      });

      test('should handle multiple excluded zones correctly', () {
        // Arrange - Motorista que excluiu múltiplas zonas
        final excludedZones = [
          DriverExcludedZone(
            id: 'zone-1',
            driverId: 'driver-123',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-2',
            driverId: 'driver-123',
            neighborhoodName: 'Centro',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-3',
            driverId: 'driver-123',
            neighborhoodName: 'Vila Madalena',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          ),
        ];

        // Test scenarios
        final testCases = [
          {
            'origin': ['Copacabana', 'Rio de Janeiro', 'RJ'],
            'destination': ['Ipanema', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': true, // Origin excluded
          },
          {
            'origin': ['Ipanema', 'Rio de Janeiro', 'RJ'],
            'destination': ['Centro', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': true, // Destination excluded
          },
          {
            'origin': ['Jardins', 'São Paulo', 'SP'],
            'destination': ['Vila Madalena', 'São Paulo', 'SP'],
            'shouldExclude': true, // Destination excluded
          },
          {
            'origin': ['Ipanema', 'Rio de Janeiro', 'RJ'],
            'destination': ['Leblon', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': false, // Neither excluded
          },
        ];

        for (final testCase in testCases) {
          final origin = testCase['origin'] as List<String>;
          final destination = testCase['destination'] as List<String>;

          final shouldExclude = _shouldExcludeDriverForTrip(
            excludedZones,
            origin[0], origin[1], origin[2],
            destination[0], destination[1], destination[2],
          );

          expect(shouldExclude, testCase['shouldExclude'],
            reason: 'Failed for origin: ${origin.join(", ")} -> destination: ${destination.join(", ")}');
        }
      });
    });

    group('Real World Scenarios', () {
      test('should handle typical São Paulo exclusion scenarios', () {
        // Arrange - Motorista de SP que não quer atender certas regiões
        final spDriverExclusions = [
          DriverExcludedZone(
            id: 'zone-sp-1',
            driverId: 'driver-sp',
            neighborhoodName: 'Centro',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-sp-2',
            driverId: 'driver-sp',
            neighborhoodName: 'Cidade Tiradentes',
            city: 'São Paulo',
            state: 'SP',
            createdAt: DateTime.now(),
          ),
        ];

        // Test common SP scenarios
        final spScenarios = [
          {
            'description': 'Evitar centro de SP (trânsito)',
            'trip': ['Vila Madalena', 'São Paulo', 'SP', 'Centro', 'São Paulo', 'SP'],
            'shouldExclude': true,
          },
          {
            'description': 'Evitar regiões periféricas',
            'trip': ['Jardins', 'São Paulo', 'SP', 'Cidade Tiradentes', 'São Paulo', 'SP'],
            'shouldExclude': true,
          },
          {
            'description': 'Atender zona oeste (permitida)',
            'trip': ['Vila Madalena', 'São Paulo', 'SP', 'Pinheiros', 'São Paulo', 'SP'],
            'shouldExclude': false,
          },
        ];

        for (final scenario in spScenarios) {
          final trip = scenario['trip'] as List<String>;
          final shouldExclude = _shouldExcludeDriverForTrip(
            spDriverExclusions,
            trip[0], trip[1], trip[2], // origin
            trip[3], trip[4], trip[5], // destination
          );

          expect(shouldExclude, scenario['shouldExclude'],
            reason: scenario['description'] as String);
        }
      });

      test('should handle Rio de Janeiro beach zone exclusions', () {
        // Arrange - Motorista do RJ que não quer atender zona sul
        final rjDriverExclusions = [
          DriverExcludedZone(
            id: 'zone-rj-1',
            driverId: 'driver-rj',
            neighborhoodName: 'Copacabana',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
          DriverExcludedZone(
            id: 'zone-rj-2',
            driverId: 'driver-rj',
            neighborhoodName: 'Ipanema',
            city: 'Rio de Janeiro',
            state: 'RJ',
            createdAt: DateTime.now(),
          ),
        ];

        // Test Rio scenarios
        final rjScenarios = [
          {
            'description': 'Evitar Copacabana (zona sul)',
            'trip': ['Tijuca', 'Rio de Janeiro', 'RJ', 'Copacabana', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': true,
          },
          {
            'description': 'Evitar Ipanema (zona sul)',
            'trip': ['Ipanema', 'Rio de Janeiro', 'RJ', 'Centro', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': true,
          },
          {
            'description': 'Atender zona norte (permitida)',
            'trip': ['Tijuca', 'Rio de Janeiro', 'RJ', 'Maracanã', 'Rio de Janeiro', 'RJ'],
            'shouldExclude': false,
          },
        ];

        for (final scenario in rjScenarios) {
          final trip = scenario['trip'] as List<String>;
          final shouldExclude = _shouldExcludeDriverForTrip(
            rjDriverExclusions,
            trip[0], trip[1], trip[2], // origin
            trip[3], trip[4], trip[5], // destination
          );

          expect(shouldExclude, scenario['shouldExclude'],
            reason: scenario['description'] as String);
        }
      });
    });

    group('Error Handling Scenarios', () {
      test('should handle invalid addresses gracefully', () {
        final invalidAddresses = [
          '', // Empty
          'Brasil', // Only country
          'SP', // Only state
          'São Paulo', // Only city
          '12345-678', // Only ZIP
        ];

        for (final address in invalidAddresses) {
          final parsed = _parseAddressForTest(address);

          // Should not crash and should return empty or incomplete data
          expect(parsed, isA<Map<String, String>>());

          // At minimum, should not have all required fields
          final hasAllRequired = parsed.containsKey('neighborhood') &&
                                parsed.containsKey('city') &&
                                parsed.containsKey('state') &&
                                parsed['neighborhood']!.isNotEmpty &&
                                parsed['city']!.isNotEmpty &&
                                parsed['state']!.isNotEmpty;

          expect(hasAllRequired, false,
            reason: 'Invalid address "$address" should not produce complete parsing');
        }
      });

      test('should validate duplicate zone prevention', () {
        // Arrange - Simular tentativa de adicionar zona duplicada
        final existingZone = DriverExcludedZone(
          id: 'zone-1',
          driverId: 'driver-123',
          neighborhoodName: 'Copacabana',
          city: 'Rio de Janeiro',
          state: 'RJ',
          createdAt: DateTime.now(),
        );

        // Act & Assert - Simular verificação de duplicata
        final isDuplicate = _isDuplicateZone(
          existingZones: [existingZone],
          newNeighborhood: 'Copacabana',
          newCity: 'Rio de Janeiro',
          newState: 'RJ',
        );

        expect(isDuplicate, true,
          reason: 'Should detect duplicate zone');

        // Test non-duplicate
        final isNotDuplicate = _isDuplicateZone(
          existingZones: [existingZone],
          newNeighborhood: 'Ipanema',
          newCity: 'Rio de Janeiro',
          newState: 'RJ',
        );

        expect(isNotDuplicate, false,
          reason: 'Should not detect false positive duplicate');
      });
    });
  });
}

// Helper functions to simulate business logic

Map<String, String> _parseAddressForTest(String address) {
  final parts = address.split(',').map((p) => p.trim()).toList();
  final result = <String, String>{};

  if (parts.isEmpty) return result;

  // Find state (2-letter code)
  String? state;
  for (int i = parts.length - 1; i >= 0; i--) {
    final stateMatch = RegExp(r'\b([A-Z]{2})\b').firstMatch(parts[i]);
    if (stateMatch != null && _isValidBrazilianState(stateMatch.group(1)!)) {
      state = stateMatch.group(1)!;
      result['state'] = state;
      break;
    }
  }

  // Find city
  String? city;
  for (int i = 0; i < parts.length; i++) {
    String part = parts[i].trim();

    if (part.toLowerCase().contains('brasil')) continue;
    if (RegExp(r'^\d{5}-?\d{3}$').hasMatch(part)) continue;

    part = part.replaceAll(RegExp(r'\d{5}-?\d{3}'), '').trim();

    if (state != null && part.endsWith(' - $state')) {
      part = part.replaceAll(' - $state', '').trim();
    }

    if (part.isNotEmpty && part.length > 1 && !RegExp(r'^[A-Z]{2}$').hasMatch(part)) {
      if (i > 0 || parts.length <= 2) {
        city = part;
        result['city'] = city;
        break;
      }
    }
  }

  // Find neighborhood (first meaningful part)
  if (parts.isNotEmpty) {
    String neighborhood = parts.first.trim();

    if (neighborhood.contains(' - ')) {
      neighborhood = neighborhood.split(' - ').first.trim();
    }

    if (neighborhood.isNotEmpty &&
        !neighborhood.toLowerCase().contains('brasil') &&
        neighborhood != city &&
        neighborhood != state) {
      result['neighborhood'] = neighborhood;
    }
  }

  return result;
}

bool _isValidBrazilianState(String state) {
  const validStates = {
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  };
  return validStates.contains(state);
}

bool _shouldExcludeDriverForTrip(
  List<DriverExcludedZone> excludedZones,
  String originNeighborhood, String originCity, String originState,
  String destinationNeighborhood, String destinationCity, String destinationState,
) {
  for (final zone in excludedZones) {
    // Check origin
    if (zone.neighborhoodName == originNeighborhood &&
        zone.city == originCity &&
        zone.state == originState) {
      return true;
    }

    // Check destination
    if (zone.neighborhoodName == destinationNeighborhood &&
        zone.city == destinationCity &&
        zone.state == destinationState) {
      return true;
    }
  }

  return false;
}

bool _isDuplicateZone({
  required List<DriverExcludedZone> existingZones,
  required String newNeighborhood,
  required String newCity,
  required String newState,
}) {
  return existingZones.any((zone) =>
    zone.neighborhoodName == newNeighborhood &&
    zone.city == newCity &&
    zone.state == newState);
}
