import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/zone_validation_service.dart';

void main() {
  group('ZoneValidationService', () {
    group('normalizeText', () {
      test('should normalize text by trimming and capitalizing', () {
        expect(ZoneValidationService.normalizeText('  são paulo  '), 'São Paulo');
        expect(ZoneValidationService.normalizeText('RIO DE JANEIRO'), 'Rio de Janeiro');
        expect(ZoneValidationService.normalizeText('copacabana'), 'Copacabana');
      });

      test('should handle empty and null values', () {
        expect(ZoneValidationService.normalizeText(''), '');
        expect(ZoneValidationService.normalizeText('   '), '');
      });
    });

    group('validateAndNormalizeState', () {
      test('should validate and normalize valid state codes', () {
        expect(ZoneValidationService.validateAndNormalizeState('sp'), 'SP');
        expect(ZoneValidationService.validateAndNormalizeState('SP'), 'SP');
        expect(ZoneValidationService.validateAndNormalizeState('  rj  '), 'RJ');
        expect(ZoneValidationService.validateAndNormalizeState('mg'), 'MG');
      });

      test('should throw exception for invalid state codes', () {
        expect(
          () => ZoneValidationService.validateAndNormalizeState('XX'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => ZoneValidationService.validateAndNormalizeState('123'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => ZoneValidationService.validateAndNormalizeState(''),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('hasReachedZoneLimit', () {
      test('should return true when limit is reached or exceeded', () {
        expect(ZoneValidationService.hasReachedZoneLimit(10), true);
        expect(ZoneValidationService.hasReachedZoneLimit(15), true);
        expect(ZoneValidationService.hasReachedZoneLimit(11), true);
      });

      test('should return false when limit is not reached', () {
        expect(ZoneValidationService.hasReachedZoneLimit(0), false);
        expect(ZoneValidationService.hasReachedZoneLimit(5), false);
        expect(ZoneValidationService.hasReachedZoneLimit(9), false);
      });
    });

    group('getRemainingZoneSlots', () {
      test('should return correct remaining slots', () {
        expect(ZoneValidationService.getRemainingZoneSlots(0), 10);
        expect(ZoneValidationService.getRemainingZoneSlots(5), 5);
        expect(ZoneValidationService.getRemainingZoneSlots(9), 1);
        expect(ZoneValidationService.getRemainingZoneSlots(10), 0);
        expect(ZoneValidationService.getRemainingZoneSlots(15), 0);
      });
    });

    group('validateAndNormalizeZoneData', () {
      test('should validate and normalize valid zone data', () async {
        final result = await ZoneValidationService.validateAndNormalizeZoneData(
          neighborhood: '  jardim paulista  ',
          city: '  são paulo  ',
          state: 'sp',
        );

        expect(result['neighborhood_name'], 'Jardim Paulista');
        expect(result['city'], 'São Paulo');
        expect(result['state'], 'SP');
      });

      test('should throw exception for invalid state', () async {
        expect(
          () => ZoneValidationService.validateAndNormalizeZoneData(
            neighborhood: 'Moema',
            city: 'São Paulo',
            state: 'XX',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty required fields', () async {
        expect(
          () => ZoneValidationService.validateAndNormalizeZoneData(
            neighborhood: '',
            city: 'São Paulo',
            state: 'SP',
          ),
          throwsA(isA<Exception>()),
        );

        expect(
          () => ZoneValidationService.validateAndNormalizeZoneData(
            neighborhood: 'Moema',
            city: '',
            state: 'SP',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}