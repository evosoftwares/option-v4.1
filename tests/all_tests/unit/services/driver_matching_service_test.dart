import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/driver_matching_service.dart';

void main() {
  group('DriverMatchingService', () {
    group('MatchingCriteria', () {
      test('should create MatchingCriteria with required parameters', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
          vehicleCategory: 'standard',
        );

        // Assert
        expect(criteria.passengerLatitude, equals(-23.5505));
        expect(criteria.passengerLongitude, equals(-46.6333));
        expect(criteria.vehicleCategory, equals('standard'));
        expect(criteria.maxRadiusKm, equals(10.0));
        expect(criteria.maxDrivers, equals(10));
      });

      test('should create MatchingCriteria with all parameters', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
          vehicleCategory: 'premium',
          needsPet: true,
          needsGrocery: true,
          needsCondo: true,
          needsAC: true,
          maxDrivers: 5,
        );

        // Assert
        expect(criteria.passengerLatitude, equals(-23.5505));
        expect(criteria.passengerLongitude, equals(-46.6333));
        expect(criteria.vehicleCategory, equals('premium'));
        expect(criteria.needsPet, isTrue);
        expect(criteria.needsGrocery, isTrue);
        expect(criteria.needsCondo, isTrue);
        expect(criteria.needsAC, isTrue);
        expect(criteria.maxDrivers, equals(5));
      });

      test('should have default values for optional parameters', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
          vehicleCategory: 'standard',
        );

        // Assert
        expect(criteria.needsPet, isFalse);
        expect(criteria.needsGrocery, isFalse);
        expect(criteria.needsCondo, isFalse);
        expect(criteria.needsAC, isFalse);
        expect(criteria.maxDrivers, equals(10));
        expect(criteria.maxRadiusKm, equals(10.0));
      });

      test('should validate toString method', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
          vehicleCategory: 'standard',
        );

        // Assert
        final stringRepresentation = criteria.toString();
        expect(stringRepresentation, contains('MatchingCriteria'));
        expect(stringRepresentation, contains('-23.5505'));
        expect(stringRepresentation, contains('-46.6333'));
        expect(stringRepresentation, contains('standard'));
      });

      test('should create criteria with minimal parameters', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
        );

        // Assert
        expect(criteria.passengerLatitude, equals(-23.5505));
        expect(criteria.passengerLongitude, equals(-46.6333));
        expect(criteria.vehicleCategory, isNull);
        expect(criteria.maxRadiusKm, equals(10.0));
        expect(criteria.maxDrivers, equals(10));
        expect(criteria.needsPet, isFalse);
        expect(criteria.needsGrocery, isFalse);
        expect(criteria.needsCondo, isFalse);
        expect(criteria.needsAC, isFalse);
      });
    });
  });
}