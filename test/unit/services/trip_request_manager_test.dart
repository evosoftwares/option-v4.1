import 'package:flutter_test/flutter_test.dart';
import 'package:option/models/supabase/driver.dart';
import 'package:option/models/trip_request_data.dart';
import 'package:option/services/trip_request_manager.dart';
import 'package:option/config/feature_flags.dart';

void main() {
  group('TripRequestManager Timeout Tests', () {
    late FeatureFlags featureFlags;
    
    setUp(() {
      featureFlags = FeatureFlags();
    });

    test('should use 10 second timeout from FeatureFlags', () {
      // Arrange
      final featureFlags = FeatureFlags();
      
      // Act & Assert
      expect(featureFlags.timeoutSeconds, equals(10));
    });

    test('should have timeout configuration of 10 seconds', () {
      // Act & Assert
      expect(featureFlags.timeoutSeconds, equals(10));
    });

    test('should have fallback system enabled', () {
      // Act & Assert
      expect(featureFlags.enableFallbackSystem, isTrue);
    });

    test('should have maximum fallback attempts configured', () {
      // Act & Assert
      expect(featureFlags.maxFallbackAttempts, equals(5));
    });

    test('should create TripRequestData with timeout configuration', () {
      // Arrange
      final tripData = TripRequestData(
        originAddress: 'Rua A, 123',
        originLatitude: -23.5489,
        originLongitude: -46.6388,
        destinationAddress: 'Rua B, 456',
        destinationLatitude: -23.5505,
        destinationLongitude: -46.6333,
        vehicleCategory: 'standard',
        needsPet: false,
        needsGrocery: false,
        needsCondo: false,
        estimatedDistanceKm: 5,
        estimatedDurationMinutes: 15,
        estimatedFare: 25,
      );
      
      // Act
      final databaseData = tripData.toDatabase(
        passengerId: 'passenger1',
        targetDriverId: 'driver1',
        fallbackDrivers: ['driver2', 'driver3'],
      );
      
      // Assert
      expect(databaseData['expires_at'], isNotNull);
      expect(databaseData['timeout_count'], equals(0));
      expect(databaseData['current_fallback_index'], equals(0));
      expect(databaseData['fallback_drivers'], equals(['driver2', 'driver3']));
    });

    test('should validate timeout duration calculation', () {
      // Arrange
      final timeoutSeconds = featureFlags.timeoutSeconds;
      final expectedDuration = Duration(seconds: timeoutSeconds);
      
      // Act & Assert
      expect(expectedDuration.inSeconds, equals(10));
      expect(expectedDuration.inMilliseconds, equals(10000));
    });

    test('should validate feature flags for timeout system', () {
      // Act & Assert
      expect(featureFlags.enablePushNotifications, isTrue);
      expect(featureFlags.enableMatchingLogs, isTrue);
      expect(featureFlags.fallbackPollingSeconds, equals(3));
    });
  });
}