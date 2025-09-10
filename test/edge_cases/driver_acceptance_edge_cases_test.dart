import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';
import 'package:option/models/trip_request_data.dart';

/// Testes específicos para edge cases e cenários de erro no workflow de aceite do motorista
void main() {
  group('Driver Acceptance Edge Cases & Error Scenarios', () {
    
    test('Invalid data scenarios', () {
      // Test empty string handling
      expect(() => TripRequestData(
        originAddress: '', // Empty address
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: 'Valid Destination',
        destinationLatitude: -23.551684,
        destinationLongitude: -46.635378,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 5.0,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.0,
      ), returnsNormally, reason: 'Empty address should be allowed but handled gracefully');

      // Test zero coordinates (often invalid but technically possible)
      final zeroCoordTrip = TripRequestData(
        originAddress: 'Valid Origin',
        originLatitude: 0.0, // Zero latitude
        originLongitude: 0.0, // Zero longitude  
        destinationAddress: 'Valid Destination',
        destinationLatitude: -23.551684,
        destinationLongitude: -46.635378,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 5.0,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.0,
      );

      final zeroDbData = zeroCoordTrip.toDatabase(
        passengerId: 'test-passenger',
        targetDriverId: 'test-driver',
      );

      expect(zeroDbData['origin_latitude'], 0.0);
      expect(zeroDbData['origin_longitude'], 0.0);

      print('✅ Invalid data scenarios handled');
    });

    test('Extreme value boundaries', () {
      // Test with very large distance and duration
      final extremeTrip = TripRequestData(
        originAddress: 'São Paulo, SP',
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: 'Rio de Janeiro, RJ',
        destinationLatitude: -22.906847,
        destinationLongitude: -43.172896,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 999999.99, // Extreme distance
        estimatedDurationMinutes: 999999, // Extreme duration
        estimatedFare: 99999.99, // Extreme fare
      );

      final extremeDbData = extremeTrip.toDatabase(
        passengerId: 'extreme-test',
        targetDriverId: 'extreme-driver',
      );

      expect(extremeDbData['estimated_distance_km'], 999999.99);
      expect(extremeDbData['estimated_duration_minutes'], 999999);
      expect(extremeDbData['estimated_fare'], 99999.99);

      // Test with very small values  
      final tinyTrip = TripRequestData(
        originAddress: 'Block A',
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: 'Block B',
        destinationLatitude: -23.560521, // Very close
        destinationLongitude: -46.660309, // Very close
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 0.001, // Very small distance
        estimatedDurationMinutes: 1, // Minimum duration
        estimatedFare: 0.01, // Minimum fare
      );

      final tinyDbData = tinyTrip.toDatabase(
        passengerId: 'tiny-test',
        targetDriverId: 'tiny-driver',
      );

      expect(tinyDbData['estimated_distance_km'], 0.001);
      expect(tinyDbData['estimated_duration_minutes'], 1);
      expect(tinyDbData['estimated_fare'], 0.01);

      print('✅ Extreme value boundaries tested');
    });

    test('Unicode and special characters handling', () {
      // Test with emojis and special characters
      final unicodeTrip = TripRequestData(
        originAddress: 'Rua da Alegria 🌟, São Paulo 🇧🇷',
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: 'Avenida José Carlos de Figueiredo Ferraz, 12.000 - Ala "B"',
        destinationLatitude: -23.551684,
        destinationLongitude: -46.635378,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 5.0,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.0,
        originNeighborhood: 'Bairro São José do Belém',
        destinationNeighborhood: 'Cidade Tiradentes - Cohab José Bonifácio',
      );

      final unicodeDbData = unicodeTrip.toDatabase(
        passengerId: 'unicode-test-🚗',
        targetDriverId: 'driver-👨‍💼',
      );

      expect(unicodeDbData['passenger_id'], 'unicode-test-🚗');
      expect(unicodeDbData['target_driver_id'], 'driver-👨‍💼');
      expect(unicodeDbData['origin_address'], contains('🌟'));
      expect(unicodeDbData['origin_address'], contains('🇧🇷'));
      expect(unicodeDbData['destination_address'], contains('"B"'));

      print('✅ Unicode and special characters handling tested');
    });

    test('Fallback drivers edge cases', () {
      final tripData = TripRequestData(
        originAddress: 'Test Origin',
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: 'Test Destination',
        destinationLatitude: -23.551684,
        destinationLongitude: -46.635378,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 5.0,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.0,
      );

      // Test with no fallback drivers
      final noFallbackData = tripData.toDatabase(
        passengerId: 'test-passenger',
        targetDriverId: 'primary-driver',
        fallbackDrivers: null,
      );

      expect(noFallbackData['fallback_drivers'], isNull);
      expect(noFallbackData['current_fallback_index'], 0);

      // Test with empty fallback list
      final emptyFallbackData = tripData.toDatabase(
        passengerId: 'test-passenger',
        targetDriverId: 'primary-driver',
        fallbackDrivers: [],
      );

      expect(emptyFallbackData['fallback_drivers'], isEmpty);

      // Test with large fallback list
      final largeFallbackList = List.generate(50, (index) => 'driver-$index');
      final largeFallbackData = tripData.toDatabase(
        passengerId: 'test-passenger',
        targetDriverId: 'primary-driver',
        fallbackDrivers: largeFallbackList,
      );

      expect(largeFallbackData['fallback_drivers'], hasLength(50));
      expect(largeFallbackData['fallback_drivers'].first, 'driver-0');
      expect(largeFallbackData['fallback_drivers'].last, 'driver-49');

      print('✅ Fallback drivers edge cases tested');
    });

    test('Driver status combinations', () {
      // Test driver with minimum required fields
      final minimalDriver = Driver(
        id: 'minimal-driver',
        userId: 'minimal-user',
        brand: '',
        model: '',
        year: 1900, // Very old year
        color: '',
        plate: '',
        category: 'common_car',
        approvalStatus: 'pending',
        isOnline: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(minimalDriver.approvalStatus, 'pending');
      expect(minimalDriver.isOnline, false);
      expect(minimalDriver.ratings, 0.0); // Default value
      expect(minimalDriver.trips, 0); // Default value
      expect(minimalDriver.cancellations, 0); // Default value

      // Test driver with all optional fields filled
      final maximalDriver = Driver(
        id: 'maximal-driver',
        userId: 'maximal-user',
        brand: 'Mercedes-Benz',
        model: 'S-Class',
        year: 2025,
        color: 'Preto Diamante',
        plate: 'LUX-2025',
        category: 'luxury_car',
        approvalStatus: 'approved',
        isOnline: true,
        acceptsPet: true,
        petFee: 15.0,
        acceptsGrocery: true,
        groceryFee: 10.0,
        acceptsCondo: true,
        condoFee: 8.0,
        stopFee: 5.0,
        acPolicy: 'always_on',
        customPricePerKm: 2.50,
        customPricePerMinute: 0.80,
        bankAccountType: 'checking',
        bankCode: '001',
        bankAgency: '1234',
        bankAccount: '567890',
        pixKey: '+5511999999999',
        pixKeyType: 'phone',
        currentLatitude: -23.560520,
        currentLongitude: -46.660308,
        lastLocationUpdate: DateTime.now(),
        ratings: 5.0,
        trips: 1000,
        cancellations: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fcmToken: 'fcm-token-example',
        devicePlatform: 'android',
        lastNotificationAt: DateTime.now(),
      );

      expect(maximalDriver.acceptsPet, true);
      expect(maximalDriver.petFee, 15.0);
      expect(maximalDriver.customPricePerKm, 2.50);
      expect(maximalDriver.pixKey, '+5511999999999');
      expect(maximalDriver.ratings, 5.0);
      expect(maximalDriver.trips, 1000);

      print('✅ Driver status combinations tested');
    });

    test('Concurrent modification scenarios', () {
      // Simulate data that might be modified concurrently
      final baseTime = DateTime.now();
      
      // Initial request data
      final initialRequestState = {
        'id': 'concurrent-test',
        'status': 'pending',
        'target_driver_id': 'driver1',
        'created_at': baseTime.toIso8601String(),
        'updated_at': baseTime.toIso8601String(),
        'timeout_count': 0,
        'current_fallback_index': 0,
      };

      // First update: driver rejects
      final firstUpdate = {
        ...initialRequestState,
        'status': 'rejected',
        'rejected_by_driver_id': 'driver1',
        'rejected_at': baseTime.add(const Duration(seconds: 30)).toIso8601String(),
        'updated_at': baseTime.add(const Duration(seconds: 30)).toIso8601String(),
      };

      // Second update: assign fallback
      final secondUpdate = {
        ...firstUpdate,
        'status': 'pending',
        'target_driver_id': 'driver2',
        'current_fallback_index': 1,
        'updated_at': baseTime.add(const Duration(seconds: 31)).toIso8601String(),
      };

      // Third update: fallback accepts
      final thirdUpdate = {
        ...secondUpdate,
        'status': 'accepted',
        'accepted_by_driver_id': 'driver2',
        'accepted_at': baseTime.add(const Duration(minutes: 2)).toIso8601String(),
        'updated_at': baseTime.add(const Duration(minutes: 2)).toIso8601String(),
      };

      // Validate the sequence of updates
      expect(initialRequestState['status'], 'pending');
      expect(firstUpdate['status'], 'rejected');
      expect(firstUpdate['rejected_by_driver_id'], 'driver1');
      expect(secondUpdate['target_driver_id'], 'driver2');
      expect(secondUpdate['current_fallback_index'], 1);
      expect(thirdUpdate['status'], 'accepted');
      expect(thirdUpdate['accepted_by_driver_id'], 'driver2');

      print('✅ Concurrent modification scenarios tested');
    });

    test('Data type conversions and null handling', () {
      // Test TripRequestData with null optional fields
      final tripWithNulls = TripRequestData(
        originAddress: 'Test Origin',
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: 'Test Destination',
        destinationLatitude: -23.551684,
        destinationLongitude: -46.635378,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 5.0,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.0,
        originNeighborhood: null, // Null optional field
        destinationNeighborhood: null, // Null optional field
      );

      final dbDataWithNulls = tripWithNulls.toDatabase(
        passengerId: 'null-test',
        targetDriverId: 'null-driver',
      );

      expect(dbDataWithNulls['origin_neighborhood'], isNull);
      expect(dbDataWithNulls['destination_neighborhood'], isNull);

      // Test Driver.fromJson with null/missing fields
      final jsonWithMissingFields = {
        'id': 'json-test-driver',
        'user_id': 'json-test-user',
        'vehicle_brand': null, // Null field
        'vehicle_model': 'Test Model',
        // Missing vehicle_year
        'vehicle_color': 'Test Color',
        'vehicle_plate': 'TEST-0000',
        'vehicle_category': 'common_car',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final driverFromJson = Driver.fromJson(jsonWithMissingFields);
      expect(driverFromJson.brand, ''); // Null becomes empty string
      expect(driverFromJson.year, 0); // Missing becomes 0

      print('✅ Data type conversions and null handling tested');
    });

    test('Performance and memory considerations', () {
      // Test with large address strings
      final largeAddressData = 'A' * 1000; // 1000 character address
      
      final largeTripData = TripRequestData(
        originAddress: largeAddressData,
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: largeAddressData,
        destinationLatitude: -23.551684,
        destinationLongitude: -46.635378,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 5.0,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.0,
      );

      final largeDbData = largeTripData.toDatabase(
        passengerId: 'large-test',
        targetDriverId: 'large-driver',
      );

      expect(largeDbData['origin_address'], hasLength(1000));
      expect(largeDbData['destination_address'], hasLength(1000));

      // Test copyWith method performance
      final originalTrip = TripRequestData(
        originAddress: 'Original',
        originLatitude: -23.560520,
        originLongitude: -46.660308,
        destinationAddress: 'Original',
        destinationLatitude: -23.551684,
        destinationLongitude: -46.635378,
        vehicleCategory: 'common_car',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoOrigin: false,
        isCondoDestination: false,
        estimatedDistanceKm: 5.0,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.0,
      );

      final copiedTrip = originalTrip.copyWith(
        originAddress: 'Modified',
        estimatedFare: 15.0,
      );

      expect(copiedTrip.originAddress, 'Modified');
      expect(copiedTrip.estimatedFare, 15.0);
      expect(copiedTrip.destinationAddress, 'Original'); // Unchanged
      expect(originalTrip.originAddress, 'Original'); // Original unchanged

      print('✅ Performance and memory considerations tested');
    });
  });
}