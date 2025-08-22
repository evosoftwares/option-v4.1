import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/zone_validation_service.dart';
import 'package:option/exceptions/app_exceptions.dart';

void main() {
  group('ZoneValidationService', () {
    group('normalizeText', () {
      test('should convert to lowercase', () {
        expect(ZoneValidationService.normalizeText('SÃO PAULO'), equals('sao paulo'));
      });

      test('should trim whitespace', () {
        expect(ZoneValidationService.normalizeText('  Rio de Janeiro  '), equals('rio de janeiro'));
      });

      test('should remove multiple spaces', () {
        expect(ZoneValidationService.normalizeText('Belo   Horizonte'), equals('belo horizonte'));
      });

      test('should remove accents', () {
        expect(ZoneValidationService.normalizeText('Brasília'), equals('brasilia'));
        expect(ZoneValidationService.normalizeText('São José'), equals('sao jose'));
        expect(ZoneValidationService.normalizeText('Açaí'), equals('acai'));
      });

      test('should handle empty string', () {
        expect(ZoneValidationService.normalizeText(''), equals(''));
      });

      test('should handle complex normalization', () {
        expect(
          ZoneValidationService.normalizeText('  SÃO  JOSÉ   DOS   CAMPOS  '),
          equals('sao jose dos campos'),
        );
      });
    });

    group('validateAndNormalizeState', () {
      test('should validate valid state codes', () {
        expect(ZoneValidationService.validateAndNormalizeState('SP'), equals('sp'));
        expect(ZoneValidationService.validateAndNormalizeState('rj'), equals('rj'));
        expect(ZoneValidationService.validateAndNormalizeState('MG'), equals('mg'));
      });

      test('should validate state names', () {
        expect(ZoneValidationService.validateAndNormalizeState('São Paulo'), equals('sp'));
        expect(ZoneValidationService.validateAndNormalizeState('Rio de Janeiro'), equals('rj'));
        expect(ZoneValidationService.validateAndNormalizeState('MINAS GERAIS'), equals('mg'));
      });

      test('should throw ValidationException for invalid states', () {
        expect(
          () => ZoneValidationService.validateAndNormalizeState('XX'),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => ZoneValidationService.validateAndNormalizeState('Invalid State'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw ValidationException for empty state', () {
        expect(
          () => ZoneValidationService.validateAndNormalizeState(''),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateAndNormalizeNeighborhood', () {
      test('should validate and normalize neighborhood names', () {
        expect(
          ZoneValidationService.validateAndNormalizeNeighborhood('Vila Madalena'),
          equals('vila madalena'),
        );
        expect(
          ZoneValidationService.validateAndNormalizeNeighborhood('  COPACABANA  '),
          equals('copacabana'),
        );
      });

      test('should throw ValidationException for empty neighborhood', () {
        expect(
          () => ZoneValidationService.validateAndNormalizeNeighborhood(''),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => ZoneValidationService.validateAndNormalizeNeighborhood('   '),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateAndNormalizeCity', () {
      test('should validate and normalize city names', () {
        expect(
          ZoneValidationService.validateAndNormalizeCity('São Paulo'),
          equals('sao paulo'),
        );
        expect(
          ZoneValidationService.validateAndNormalizeCity('  RIO DE JANEIRO  '),
          equals('rio de janeiro'),
        );
      });

      test('should throw ValidationException for empty city', () {
        expect(
          () => ZoneValidationService.validateAndNormalizeCity(''),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => ZoneValidationService.validateAndNormalizeCity('   '),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateLocationExists', () {
      test('should return true for valid normalized locations', () async {
        final result = await ZoneValidationService.validateLocationExists(
          neighborhood: 'Vila Madalena',
          city: 'São Paulo',
          state: 'SP',
        );
        expect(result, isTrue);
      });

      test('should return false for invalid state', () async {
        final result = await ZoneValidationService.validateLocationExists(
          neighborhood: 'Test Neighborhood',
          city: 'Test City',
          state: 'INVALID',
        );
        expect(result, isFalse);
      });

      test('should return false for empty fields', () async {
        final result = await ZoneValidationService.validateLocationExists(
          neighborhood: '',
          city: 'São Paulo',
          state: 'SP',
        );
        expect(result, isFalse);
      });
    });

    group('validateAndNormalizeZoneData', () {
      test('should validate and normalize complete zone data', () async {
        final result = await ZoneValidationService.validateAndNormalizeZoneData(
          neighborhood: '  VILA MADALENA  ',
          city: '  SÃO PAULO  ',
          state: 'SP',
        );

        expect(result['neighborhood_name'], equals('vila madalena'));
        expect(result['city'], equals('sao paulo'));
        expect(result['state'], equals('sp'));
      });

      test('should throw ValidationException for invalid data', () async {
        expect(
          () => ZoneValidationService.validateAndNormalizeZoneData(
            neighborhood: '',
            city: 'São Paulo',
            state: 'SP',
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('createZoneIdentifier', () {
      test('should create normalized zone identifier', () {
        final identifier = ZoneValidationService.createZoneIdentifier(
          neighborhood: '  VILA MADALENA  ',
          city: '  SÃO PAULO  ',
          state: 'SP',
        );
        expect(identifier, equals('vila madalena|sao paulo|sp'));
      });

      test('should handle accents in zone identifier', () {
        final identifier = ZoneValidationService.createZoneIdentifier(
          neighborhood: 'Açaí',
          city: 'São José',
          state: 'CE',
        );
        expect(identifier, equals('acai|sao jose|ce'));
      });
    });

    group('zone limits', () {
      test('hasReachedZoneLimit should return correct values', () {
        expect(ZoneValidationService.hasReachedZoneLimit(0), isFalse);
        expect(ZoneValidationService.hasReachedZoneLimit(25), isFalse);
        expect(ZoneValidationService.hasReachedZoneLimit(49), isFalse);
        expect(ZoneValidationService.hasReachedZoneLimit(50), isTrue);
        expect(ZoneValidationService.hasReachedZoneLimit(51), isTrue);
      });

      test('getRemainingZoneSlots should return correct values', () {
        expect(ZoneValidationService.getRemainingZoneSlots(0), equals(50));
        expect(ZoneValidationService.getRemainingZoneSlots(25), equals(25));
        expect(ZoneValidationService.getRemainingZoneSlots(49), equals(1));
        expect(ZoneValidationService.getRemainingZoneSlots(50), equals(0));
        expect(ZoneValidationService.getRemainingZoneSlots(51), equals(-1));
      });
    });

    group('edge cases', () {
      test('should handle special characters in text normalization', () {
        expect(
          ZoneValidationService.normalizeText('São João-da-Boa-Vista'),
          equals('sao joao-da-boa-vista'),
        );
      });

      test('should handle numbers in location names', () {
        expect(
          ZoneValidationService.normalizeText('Setor Oeste 1'),
          equals('setor oeste 1'),
        );
      });

      test('should validate all Brazilian states', () {
        const states = [
          'ac', 'al', 'ap', 'am', 'ba', 'ce', 'df', 'es', 'go',
          'ma', 'mt', 'ms', 'mg', 'pa', 'pb', 'pr', 'pe', 'pi',
          'rj', 'rn', 'rs', 'ro', 'rr', 'sc', 'sp', 'se', 'to',
        ];

        for (final state in states) {
          expect(
            ZoneValidationService.validateAndNormalizeState(state),
            equals(state),
          );
          expect(
            ZoneValidationService.validateAndNormalizeState(state.toUpperCase()),
            equals(state),
          );
        }
      });
    });
  });
}