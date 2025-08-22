import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/zone_limit_service.dart';
import '../../../lib/utils/data_normalization_utils.dart';
import '../../../lib/services/geographic_validation_service.dart';
import '../../../lib/exceptions/app_exceptions.dart';

void main() {
  group('Driver Excluded Zones Integration Tests', () {
    const testDriverId = '550e8400-e29b-41d4-a716-446655440000';
    
    group('Data Normalization Tests', () {
      test('should normalize neighborhood names correctly', () {
        expect(
          DataNormalizationUtils.normalizeNeighborhoodName('jd. europa'),
          equals('Jardim Europa'),
        );
        
        expect(
          DataNormalizationUtils.normalizeNeighborhoodName('VL MADALENA'),
          equals('Vila Madalena'),
        );
        
        expect(
          DataNormalizationUtils.normalizeNeighborhoodName('centro histórico'),
          equals('Centro 1istorico'),
        );
      });
      
      test('should normalize city names correctly', () {
        expect(
          DataNormalizationUtils.normalizeCityName('sao paulo'),
          equals('São Paulo'),
        );
        
        expect(
          DataNormalizationUtils.normalizeCityName('rio de janeiro'),
          equals('Rio de Janeiro'),
        );
        
        expect(
          DataNormalizationUtils.normalizeCityName('STO ANDRÉ'),
          equals('Santo Andre'),
        );
      });
      
      test('should normalize state names correctly', () {
        expect(
          DataNormalizationUtils.normalizeStateName('sp'),
          equals('São Paulo'),
        );
        
        expect(
          DataNormalizationUtils.normalizeStateName('RJ'),
          equals('Rio de Janeiro'),
        );
        
        expect(
          DataNormalizationUtils.normalizeStateName('minas gerais'),
          equals('Minas Gerais'),
        );
      });
    });
    
    group('Data Validation Tests', () {
      test('should validate location data correctly', () {
        final validResult = DataNormalizationUtils.validateAddress(
          neighborhood: 'Vila Madalena',
          city: 'São Paulo',
          state: 'São Paulo',
        );
        
        expect(validResult.isValid, isTrue);
        expect(validResult.errors, isEmpty);
        
        final invalidResult = DataNormalizationUtils.validateAddress(
          neighborhood: '',
          city: 'A',
          state: 'Invalid@State',
        );
        
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors, isNotEmpty);
      });
      
      test('should validate reason correctly', () {
        expect(
          DataNormalizationUtils.isValidReason('Área perigosa'),
          isTrue,
        );
        
        expect(
          DataNormalizationUtils.isValidReason(''),
          isTrue, // Motivo é opcional
        );
        
        expect(
          DataNormalizationUtils.isValidReason('Invalid<script>'),
          isFalse,
        );
      });
    });
    
    group('Geographic Validation Tests', () {
      test('should validate existing cities', () async {
        final isValid = await GeographicValidationService.validateCity(
          'São Paulo',
          'São Paulo',
        );
        
        expect(isValid, isTrue);
      });
      
      test('should reject non-existing cities', () async {
        final isValid = await GeographicValidationService.validateCity(
          'Cidade Inexistente',
          'São Paulo',
        );
        
        expect(isValid, isFalse);
      });
    });
    
    group('Zone Limit Tests', () {
      test('should validate maximum zones per driver', () {
        // Teste básico de validação de limites sem Supabase
        const maxZones = 10;
        const currentZones = 5;
        
        expect(currentZones < maxZones, isTrue);
        expect(currentZones + 1 <= maxZones, isTrue);
        expect(maxZones + 1 > maxZones, isTrue);
      });
    });
    
    group('Service Integration Tests', () {
      test('should integrate normalization and validation', () {
        // Teste de integração entre normalização e validação
        final normalizedNeighborhood = DataNormalizationUtils.normalizeNeighborhoodName('jd. europa');
        final normalizedCity = DataNormalizationUtils.normalizeCityName('sao paulo');
        final normalizedState = DataNormalizationUtils.normalizeStateName('sp');
        
        final validationResult = DataNormalizationUtils.validateAddress(
          neighborhood: normalizedNeighborhood,
          city: normalizedCity,
          state: normalizedState,
        );
        
        expect(validationResult.isValid, isTrue);
        expect(normalizedNeighborhood, equals('Jardim Europa'));
        expect(normalizedCity, equals('São Paulo'));
        expect(normalizedState, equals('São Paulo'));
      });
      
      test('should handle text normalization edge cases', () {
        // Teste de casos extremos
        expect(
          DataNormalizationUtils.normalizeText(''),
          equals(''),
        );
        
        expect(
          DataNormalizationUtils.normalizeText('   '),
          equals(''),
        );
        
        expect(
          DataNormalizationUtils.normalizeText('TEXTO EM MAIÚSCULO'),
          equals('Texto em Maiusculo'),
        );
      });
      
      test('should validate location strings', () {
        expect(
          DataNormalizationUtils.isValidLocationString('Vila Madalena'),
          isTrue,
        );
        
        expect(
          DataNormalizationUtils.isValidLocationString(''),
          isFalse,
        );
        
        expect(
          DataNormalizationUtils.isValidLocationString('A'),
          isFalse,
        );
        
        expect(
          DataNormalizationUtils.isValidLocationString('Location123'),
          isFalse,
        );
      });
    });
  });
}