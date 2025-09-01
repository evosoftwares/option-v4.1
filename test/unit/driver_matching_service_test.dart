import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';
import 'package:option/services/driver_matching_service.dart';

void main() {
  group('DriverMatchingService Unit Tests', () {
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
        expect(criteria.maxRadiusKm, equals(10.0));
        expect(criteria.vehicleCategory, equals('standard'));
        expect(criteria.needsPet, isFalse);
        expect(criteria.needsGrocery, isFalse);
        expect(criteria.needsCondo, isFalse);
        expect(criteria.needsAC, isFalse);
        expect(criteria.maxDrivers, equals(10));
      });

      test('should create MatchingCriteria with all optional parameters', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
          maxRadiusKm: 15,
          vehicleCategory: 'premium',
          needsPet: true,
          needsGrocery: true,
          needsCondo: true,
          needsAC: true,
          maxDrivers: 5,
        );

        // Assert
        expect(criteria.needsPet, isTrue);
        expect(criteria.needsGrocery, isTrue);
        expect(criteria.needsCondo, isTrue);
        expect(criteria.needsAC, isTrue);
        expect(criteria.maxDrivers, equals(5));
        expect(criteria.vehicleCategory, equals('premium'));
      });

      test('should use default values when not specified', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
        );

        // Assert
        expect(criteria.maxRadiusKm, equals(10.0));
        expect(criteria.vehicleCategory, isNull);
        expect(criteria.maxDrivers, equals(10));
        expect(criteria.needsPet, isFalse);
        expect(criteria.needsGrocery, isFalse);
        expect(criteria.needsCondo, isFalse);
        expect(criteria.needsAC, isFalse);
      });
    });

    group('DriverMatchResult', () {
      test('should create DriverMatchResult with all parameters', () {
        // Arrange
        final driver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '12345678901',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'standard',
          approvalStatus: 'approved',
          isOnline: true,
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: true,
          acceptsCondo: false,
          petFee: 0.0,
          groceryFee: 0.0,
          condoFee: 0.0,
          stopFee: 0.0,
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = DriverMatchResult(
          driver: driver,
          distanceKm: 2.5,
          estimatedArrivalMinutes: 8,
          matchScore: 0.95,
          isAvailable: true,
        );

        // Assert
        expect(result.driver.id, equals('driver-1'));
        expect(result.distanceKm, equals(2.5));
        expect(result.estimatedArrivalMinutes, equals(8));
        expect(result.matchScore, equals(0.95));
        expect(result.isAvailable, isTrue);
        expect(result.unavailabilityReason, isNull);
      });

      test('should create DriverMatchResult with unavailability reason', () {
        // Arrange
        final driver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '12345678901',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'standard',
          approvalStatus: 'approved',
          isOnline: false,
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          petFee: 0.0,
          groceryFee: 0.0,
          condoFee: 0.0,
          stopFee: 0.0,
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = DriverMatchResult(
          driver: driver,
          distanceKm: 2.5,
          estimatedArrivalMinutes: 8,
          matchScore: 0.95,
          isAvailable: false,
          unavailabilityReason: 'Driver is offline',
        );

        // Assert
        expect(result.isAvailable, isFalse);
        expect(result.unavailabilityReason, equals('Driver is offline'));
        expect(result.driver.isOnline, isFalse);
      });

      test('should handle match score boundaries', () {
        // Arrange
        final driver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '12345678901',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'standard',
          approvalStatus: 'approved',
          isOnline: true,
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          petFee: 0.0,
          groceryFee: 0.0,
          condoFee: 0.0,
          stopFee: 0.0,
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert - Perfect match
        final perfectMatch = DriverMatchResult(
          driver: driver,
          distanceKm: 0.1,
          estimatedArrivalMinutes: 1,
          matchScore: 1,
          isAvailable: true,
        );
        expect(perfectMatch.matchScore, equals(1.0));

        // Act & Assert - Poor match
        final poorMatch = DriverMatchResult(
          driver: driver,
          distanceKm: 15,
          estimatedArrivalMinutes: 45,
          matchScore: 0.1,
          isAvailable: true,
        );
        expect(poorMatch.matchScore, equals(0.1));
      });
    });

    group('Driver Model Validation', () {
      test('should validate driver preferences correctly', () {
        // Arrange & Act
        final petFriendlyDriver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '12345678901',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'standard',
          approvalStatus: 'approved',
          isOnline: true,
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          petFee: 0.0,
          groceryFee: 0.0,
          condoFee: 0.0,
          stopFee: 0.0,
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(petFriendlyDriver.acceptsPet, isTrue);
        expect(petFriendlyDriver.acceptsGrocery, isFalse);
        expect(petFriendlyDriver.acceptsCondo, isTrue);
        expect(petFriendlyDriver.acPolicy, equals('always_on'));
      });

      test('should validate driver status and ratings', () {
        // Arrange & Act
        final experiencedDriver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '12345678901',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'premium',
          approvalStatus: 'approved',
          isOnline: true,
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          petFee: 0.0,
          groceryFee: 0.0,
          condoFee: 0.0,
          stopFee: 0.0,
          acPolicy: 'always_on',
          ratings: 4.9,
          trips: 500,
          cancellations: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(experiencedDriver.category, equals('premium'));
        expect(experiencedDriver.approvalStatus, equals('approved'));
        expect(experiencedDriver.isOnline, isTrue);
        expect(experiencedDriver.ratings, equals(4.9));
        expect(experiencedDriver.trips, equals(500));
        expect(experiencedDriver.cancellations, equals(2));
        
        // Calculate cancellation rate
        final cancellationRate = experiencedDriver.cancellations / experiencedDriver.trips;
        expect(cancellationRate, lessThan(0.01)); // Less than 1% cancellation rate
      });

      test('should handle driver location data', () {
        // Arrange & Act
        final driver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '12345678901',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'standard',
          approvalStatus: 'approved',
          isOnline: true,
          currentLatitude: -23.5505, // São Paulo coordinates
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          petFee: 0.0,
          groceryFee: 0.0,
          condoFee: 0.0,
          stopFee: 0.0,
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(driver.currentLatitude, equals(-23.5505));
        expect(driver.currentLongitude, equals(-46.6333));
        expect(driver.currentLatitude, greaterThan(-90.0));
        expect(driver.currentLatitude, lessThan(90.0));
        expect(driver.currentLongitude, greaterThan(-180.0));
        expect(driver.currentLongitude, lessThan(180.0));
      });
    });

    group('Data Consistency', () {
      test('should maintain data consistency in MatchingCriteria', () {
        // Arrange & Act
        const criteria = MatchingCriteria(
          passengerLatitude: -23.5505,
          passengerLongitude: -46.6333,
          maxRadiusKm: 5,
          vehicleCategory: 'standard',
          needsPet: true,
          maxDrivers: 3,
        );

        // Assert
        expect(criteria.maxRadiusKm, greaterThan(0));
        expect(criteria.maxDrivers, greaterThan(0));
        expect(criteria.passengerLatitude, greaterThan(-90.0));
        expect(criteria.passengerLatitude, lessThan(90.0));
        expect(criteria.passengerLongitude, greaterThan(-180.0));
        expect(criteria.passengerLongitude, lessThan(180.0));
      });

      test('should maintain data consistency in DriverMatchResult', () {
        // Arrange
        final driver = Driver(
          id: 'driver-1',
          userId: 'user-1',
          cnhNumber: '12345678901',
          cnhExpiryDate: DateTime.now().add(const Duration(days: 365)),
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'standard',
          approvalStatus: 'approved',
          isOnline: true,
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          petFee: 0.0,
          groceryFee: 0.0,
          condoFee: 0.0,
          stopFee: 0.0,
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = DriverMatchResult(
          driver: driver,
          distanceKm: 2.5,
          estimatedArrivalMinutes: 8,
          matchScore: 0.95,
          isAvailable: true,
        );

        // Assert
        expect(result.distanceKm, greaterThanOrEqualTo(0));
        expect(result.estimatedArrivalMinutes, greaterThan(0));
        expect(result.matchScore, greaterThanOrEqualTo(0.0));
        expect(result.matchScore, lessThanOrEqualTo(1.0));
        expect(result.driver.id, isNotEmpty);
        expect(result.driver.userId, isNotEmpty);
      });
    });
  });
}