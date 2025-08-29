import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/driver_matching_service.dart';
import 'package:option/models/supabase/driver.dart';

void main() {
  group('DriverMatchingService Integration Tests', () {

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

      test('should create MatchingCriteria with optional parameters', () {
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
      });
    });

    group('DriverMatchResult', () {
      test('should create DriverMatchResult with driver data', () {
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
          fees: {},
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
      });
    });

    group('Driver Model', () {
      test('should create Driver with all required fields', () {
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
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          fees: {},
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(driver.id, equals('driver-1'));
        expect(driver.brand, equals('Toyota'));
        expect(driver.model, equals('Corolla'));
        expect(driver.color, equals('Branco'));
        expect(driver.plate, equals('ABC-1234'));
        expect(driver.category, equals('standard'));
        expect(driver.isOnline, isTrue);
        expect(driver.acceptsPet, isTrue);
        expect(driver.acceptsGrocery, isFalse);
        expect(driver.acceptsCondo, isTrue);
        expect(driver.acPolicy, equals('always_on'));
        expect(driver.ratings, equals(4.8));
        expect(driver.trips, equals(150));
        expect(driver.cancellations, equals(5));
      });

      test('should create Driver copyWith method', () {
        // Arrange
        final originalDriver = Driver(
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
          fees: {},
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final modifiedDriver = originalDriver.copyWith(
          id: 'driver-2',
          ratings: 4.9,
          trips: 200,
        );

        // Assert
        expect(modifiedDriver.id, equals('driver-2'));
        expect(modifiedDriver.ratings, equals(4.9));
        expect(modifiedDriver.trips, equals(200));
        // Original values should remain
        expect(modifiedDriver.brand, equals('Toyota'));
        expect(modifiedDriver.model, equals('Corolla'));
        expect(modifiedDriver.acceptsPet, isTrue);
      });

      test('should convert Driver to and from JSON', () {
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
          fees: {},
          acPolicy: 'always_on',
          ratings: 4.8,
          trips: 150,
          cancellations: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final json = driver.toJson();
        final reconstructedDriver = Driver.fromJson(json);

        // Assert
        expect(reconstructedDriver.id, equals(driver.id));
        expect(reconstructedDriver.brand, equals(driver.brand));
        expect(reconstructedDriver.model, equals(driver.model));
        expect(reconstructedDriver.color, equals(driver.color));
        expect(reconstructedDriver.plate, equals(driver.plate));
        expect(reconstructedDriver.category, equals(driver.category));
        expect(reconstructedDriver.isOnline, equals(driver.isOnline));
        expect(reconstructedDriver.acceptsPet, equals(driver.acceptsPet));
        expect(reconstructedDriver.acceptsGrocery, equals(driver.acceptsGrocery));
        expect(reconstructedDriver.acceptsCondo, equals(driver.acceptsCondo));
        expect(reconstructedDriver.acPolicy, equals(driver.acPolicy));
        expect(reconstructedDriver.ratings, equals(driver.ratings));
        expect(reconstructedDriver.trips, equals(driver.trips));
        expect(reconstructedDriver.cancellations, equals(driver.cancellations));
      });
    });

    group('Service Integration', () {
       test('should validate MatchingCriteria defaults', () {
         // Arrange & Act
         const criteria = MatchingCriteria(
           passengerLatitude: -23.5505,
           passengerLongitude: -46.6333,
         );

         // Assert
         expect(criteria.maxRadiusKm, equals(10.0));
         expect(criteria.maxDrivers, equals(10));
         expect(criteria.needsPet, isFalse);
         expect(criteria.needsGrocery, isFalse);
         expect(criteria.needsCondo, isFalse);
         expect(criteria.needsAC, isFalse);
       });

      test('should handle empty criteria gracefully', () {
        // Arrange
        const criteria = MatchingCriteria(
          passengerLatitude: 0,
          passengerLongitude: 0,
        );

        // Act & Assert
        expect(criteria.passengerLatitude, equals(0.0));
        expect(criteria.passengerLongitude, equals(0.0));
        expect(criteria.maxRadiusKm, equals(10.0)); // Default value
        expect(criteria.maxDrivers, equals(10)); // Default value
      });

      test('should create DriverMatchResult with unavailable driver', () {
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
          isOnline: false, // Offline driver
          currentLatitude: -23.5505,
          currentLongitude: -46.6333,
          acceptsPet: true,
          acceptsGrocery: false,
          acceptsCondo: true,
          fees: {},
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
    });
  });
}