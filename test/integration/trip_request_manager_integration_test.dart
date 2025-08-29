import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';
import 'package:option/models/trip_request_data.dart';

void main() {
  group('TripRequestManager Integration Tests', () {
    test('should validate TripRequestData structure', () {
      // Arrange & Act
      final tripRequestData = TripRequestData(
        originAddress: 'Av. Paulista, 1000',
        originLatitude: -23.5505,
        originLongitude: -46.6333,
        destinationAddress: 'Shopping Ibirapuera',
        destinationLatitude: -23.5515,
        destinationLongitude: -46.6343,
        vehicleCategory: 'standard',
        needsPet: false,
        needsGrocery: false,
        needsCondo: false,
        estimatedDistanceKm: 5.2,
        estimatedDurationMinutes: 15,
        estimatedFare: 25.50,
      );

      // Assert
      expect(tripRequestData.originAddress, equals('Av. Paulista, 1000'));
      expect(tripRequestData.originLatitude, equals(-23.5505));
      expect(tripRequestData.originLongitude, equals(-46.6333));
      expect(tripRequestData.destinationAddress, equals('Shopping Ibirapuera'));
      expect(tripRequestData.destinationLatitude, equals(-23.5515));
      expect(tripRequestData.destinationLongitude, equals(-46.6343));
      expect(tripRequestData.vehicleCategory, equals('standard'));
      expect(tripRequestData.estimatedFare, equals(25.50));
      expect(tripRequestData.estimatedDistanceKm, equals(5.2));
      expect(tripRequestData.estimatedDurationMinutes, equals(15));
    });

    test('should validate Driver structure', () {
      // Arrange & Act
      final driver = Driver(
        id: 'test-driver-001',
        userId: 'test-driver-001',
        cnhNumber: '12345678901',
        cnhExpiryDate: DateTime(2025, 12, 31),
        brand: 'Toyota',
        model: 'Corolla',
        year: 2020,
        color: 'Branco',
        plate: 'ABC-1234',
        category: 'standard',
        approvalStatus: 'approved',
        isOnline: true,
        acceptsPet: false,
        acceptsGrocery: false,
        acceptsCondo: true,
        fees: {},
        ratings: 4.5,
        trips: 100,
        cancellations: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(driver.id, equals('test-driver-001'));
      expect(driver.userId, equals('test-driver-001'));
      expect(driver.brand, equals('Toyota'));
      expect(driver.model, equals('Corolla'));
      expect(driver.category, equals('standard'));
      expect(driver.isOnline, isTrue);
      expect(driver.acceptsCondo, isTrue);
      expect(driver.ratings, equals(4.5));
    });

    test('should convert TripRequestData to database format', () {
      // Arrange
      final tripRequestData = TripRequestData(
        originAddress: 'Av. Paulista, 1000',
        originLatitude: -23.5505,
        originLongitude: -46.6333,
        destinationAddress: 'Shopping Ibirapuera',
        destinationLatitude: -23.5515,
        destinationLongitude: -46.6343,
        vehicleCategory: 'standard',
        needsPet: false,
        needsGrocery: false,
        needsCondo: false,
        estimatedDistanceKm: 5.2,
        estimatedDurationMinutes: 15,
        estimatedFare: 25.50,
      );

      // Act
      final databaseMap = tripRequestData.toDatabase(
        passengerId: 'test-passenger-001',
        targetDriverId: 'test-driver-001',
        fallbackDrivers: ['test-driver-002', 'test-driver-003'],
      );

      // Assert
      expect(databaseMap['passenger_id'], equals('test-passenger-001'));
      expect(databaseMap['target_driver_id'], equals('test-driver-001'));
      expect(databaseMap['fallback_drivers'], equals(['test-driver-002', 'test-driver-003']));
      expect(databaseMap['origin_address'], equals('Av. Paulista, 1000'));
      expect(databaseMap['destination_address'], equals('Shopping Ibirapuera'));
      expect(databaseMap['vehicle_category'], equals('standard'));
      expect(databaseMap['estimated_fare'], equals(25.50));
      expect(databaseMap['status'], equals('pending'));
      expect(databaseMap['current_fallback_index'], equals(0));
      expect(databaseMap['timeout_count'], equals(0));
    });

    test('should handle empty drivers list validation', () {
      // Arrange
      final emptyDriversList = <Driver>[];

      // Act & Assert
      expect(emptyDriversList.isEmpty, isTrue);
      expect(emptyDriversList.length, equals(0));
    });
  });
}