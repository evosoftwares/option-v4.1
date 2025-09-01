import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';
import 'package:option/models/trip_preferences.dart';
import 'package:option/models/vehicle_category.dart';
import 'package:option/services/individual_pricing_service.dart';

void main() {
  group('IndividualPricingService', () {
    test('calculateComponenteDistancia should calculate distance component correctly', () {
      // Arrange
      const distanceKm = 10.0;
      const pricePerKm = 2.5;
      final driver = Driver(
        id: '1',
        userId: 'user1',
        cnhNumber: '12345678901',
        cnhExpiryDate: DateTime(2025, 12, 31),
        brand: 'Toyota',
        model: 'Corolla',
        year: 2020,
        color: 'Branco',
        plate: 'ABC1234',
        category: 'standard',
        approvalStatus: 'approved',
        isOnline: true,
        acceptsPet: true,
        petFee: 5.0,
        acceptsGrocery: true,
        groceryFee: 3.0,
        acceptsCondo: true,
        condoFee: 2.0,
        stopFee: 1.0,
        customPricePerKm: pricePerKm,
        ratings: 4.5,
        trips: 100,
        cancellations: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      const categoryData = VehicleCategoryData(
        category: VehicleCategory.standard,
        basePricePerKm: 1.5,
        basePricePerMinute: 0.5,
      );

      // Act
      final result = IndividualPricingService.calculateComponenteDistancia(
        driver: driver,
        totalDistanceKm: distanceKm,
        categoryData: categoryData,
      );

      // Assert
      expect(result, equals(25.0)); // 10.0 * 2.5
    });

    test('calculateComponenteTempo should calculate time component correctly', () {
      // Arrange
      const durationMinutes = 30;
      const pricePerMinute = 0.8;
      final driver = Driver(
        id: '1',
        userId: 'user1',
        cnhNumber: '12345678901',
        cnhExpiryDate: DateTime(2025, 12, 31),
        brand: 'Toyota',
        model: 'Corolla',
        year: 2020,
        color: 'Branco',
        plate: 'ABC1234',
        category: 'standard',
        approvalStatus: 'approved',
        isOnline: true,
        acceptsPet: true,
        petFee: 5.0,
        acceptsGrocery: true,
        groceryFee: 3.0,
        acceptsCondo: true,
        condoFee: 2.0,
        stopFee: 1.0,
        customPricePerMinute: pricePerMinute,
        ratings: 4.5,
        trips: 100,
        cancellations: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      const categoryData = VehicleCategoryData(
        category: VehicleCategory.premium,
        basePricePerKm: 3,
        basePricePerMinute: 0.5,
      );

      // Act
      final result = IndividualPricingService.calculateComponenteTempo(
        driver: driver,
        totalDurationMinutes: durationMinutes,
        categoryData: categoryData,
      );

      // Assert
      expect(result, equals(24.0)); // 30 * 0.8
    });

    test('calculateDriverPrice should calculate total price with custom pricing', () {
      // Arrange
      final driver = Driver(
        id: '1',
        userId: 'user1',
        cnhNumber: '12345678901',
        cnhExpiryDate: DateTime(2025, 12, 31),
        brand: 'Toyota',
        model: 'Corolla',
        year: 2020,
        color: 'Branco',
        plate: 'ABC1234',
        category: 'economico',
        approvalStatus: 'approved',
        isOnline: true,
        acceptsPet: true,
        petFee: 5.0,
        acceptsGrocery: true,
        groceryFee: 3.0,
        acceptsCondo: true,
        condoFee: 2.0,
        stopFee: 1.0,
        customPricePerKm: 3,
        customPricePerMinute: 1,
        ratings: 4.5,
        trips: 100,
        cancellations: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      const categoryData = VehicleCategoryData(
        category: VehicleCategory.economico,
        basePricePerKm: 1.5,
        basePricePerMinute: 0.3,
      );
      
      const preferences = TripPreferences();

      // Act
      final result = IndividualPricingService.calculateDriverPrice(
        driver: driver,
        totalDistanceKm: 5,
        totalDurationMinutes: 20,
        categoryData: categoryData,
        preferences: preferences,
      );

      // Assert
      // Distance: 5.0 * 3.0 = 15.0
      // Time: 20 * 1.0 = 20.0
      // Total: 15.0 + 20.0 = 35.0
      expect(result, equals(35.0));
    });

    test('calculateDriverPrice should calculate total price with default pricing', () {
      // Arrange
      final driver = Driver(
        id: '2',
        userId: 'user2',
        cnhNumber: '12345678902',
        cnhExpiryDate: DateTime(2025, 12, 31),
        brand: 'Honda',
        model: 'Civic',
        year: 2021,
        color: 'Azul',
        plate: 'XYZ789',
        category: 'standard',
        approvalStatus: 'approved',
        isOnline: true,
        acceptsPet: true,
        petFee: 5.0,
        acceptsGrocery: true,
        groceryFee: 3.0,
        acceptsCondo: true,
        condoFee: 2.0,
        stopFee: 1.0,
        // No custom pricing
        ratings: 4.8,
        trips: 150,
        cancellations: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      const categoryData = VehicleCategoryData(
        category: VehicleCategory.standard,
        basePricePerKm: 2,
        basePricePerMinute: 0.5,
      );
      
      const preferences = TripPreferences();

      // Act
      final result = IndividualPricingService.calculateDriverPrice(
        driver: driver,
        totalDistanceKm: 8,
        totalDurationMinutes: 15,
        categoryData: categoryData,
        preferences: preferences,
      );

      // Assert
      // Distance: 8.0 * 2.0 = 16.0
      // Time: 15 * 0.5 = 7.5
      // Total: 16.0 + 7.5 = 23.5
      expect(result, equals(23.5));
    });
  });
}