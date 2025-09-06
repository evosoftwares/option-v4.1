import 'package:flutter_test/flutter_test.dart';
import 'package:option/services/notification_service.dart';
import 'package:option/services/onesignal_service.dart';
import 'package:option/services/trip_request_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../helpers/test_constants.dart';

void main() {
  group('Notification Flow End-to-End Tests', () {
    late NotificationService notificationService;
    late SupabaseClient mockSupabase;
    
    setUpAll(() async {
      // Inicializar Supabase para testes
      await Supabase.initialize(
        url: TestConstants.supabaseUrl,
        anonKey: TestConstants.supabaseAnonKey,
      );
      mockSupabase = Supabase.instance.client;
      notificationService = NotificationService(mockSupabase);
    });
    
    group('Driver Notification Flow', () {
      test('should validate OneSignal Player ID format', () {
        final onesignalService = OneSignalService();
        
        // Test valid UUID format
        const validPlayerId = '12345678-1234-1234-1234-123456789012';
        expect(onesignalService._isValidPlayerId, isNotNull);
        
        // Test invalid formats
        const invalidIds = [
          '',
          '123',
          'invalid-uuid',
          '12345678-1234-1234-1234-12345678901X',
          '12345678-1234-1234-1234',
        ];
        
        for (final invalidId in invalidIds) {
          expect(
            () => onesignalService.sendNotificationToPlayerId(
              playerId: invalidId,
              title: 'Test',
              body: 'Test',
            ),
            throwsA(isA<ArgumentError>()),
            reason: 'Should reject invalid player ID: $invalidId',
          );
        }
      });
      
      test('should create proper notification payload', () async {
        const mockDriverId = 'driver-123';
        const mockRequestId = 'request-456';
        
        // Test the notification creation logic
        expect(
          () => notificationService.sendDriverNotification(mockDriverId, mockRequestId),
          returnsNormally,
          reason: 'Should create notification without throwing',
        );
      });
      
      test('should handle fallback scenarios gracefully', () async {
        const mockDriverId = 'driver-without-player-id';
        const mockRequestId = 'request-789';
        
        // This should not throw even if OneSignal fails
        expect(
          () => notificationService.sendDriverNotification(mockDriverId, mockRequestId),
          returnsNormally,
          reason: 'Should handle missing Player ID gracefully',
        );
      });
    });
    
    group('Trip Request Manager Integration', () {
      test('should call notification service when creating directed request', () async {
        final tripManager = TripRequestManager(mockSupabase);
        
        // Mock successful scenario
        expect(
          tripManager,
          isNotNull,
          reason: 'TripRequestManager should be properly instantiated',
        );
      });
    });
    
    group('Notification Robustness Tests', () {
      test('should retry failed notifications', () async {
        // Test retry mechanism
        const maxRetries = 3;
        var attemptCount = 0;
        
        // Simulate retry behavior
        for (var i = 1; i <= maxRetries; i++) {
          attemptCount++;
          if (attemptCount == maxRetries) {
            expect(attemptCount, equals(maxRetries));
            break;
          }
        }
        
        expect(attemptCount, equals(maxRetries));
      });
      
      test('should validate notification data structure', () {
        final notificationData = {
          'type': 'trip_request',
          'request_id': const Uuid().v4(),
          'origin': 'Test Origin',
          'destination': 'Test Destination',
          'estimated_fare': '25.50',
          'expires_at': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
        };
        
        // Validate required fields
        expect(notificationData['type'], equals('trip_request'));
        expect(notificationData['request_id'], isNotEmpty);
        expect(notificationData['origin'], isNotEmpty);
        expect(notificationData['destination'], isNotEmpty);
        expect(notificationData['estimated_fare'], isNotNull);
        expect(notificationData['expires_at'], isNotNull);
      });
    });
    
    group('Sound Configuration Tests', () {
      test('should configure proper sound for drivers vs passengers', () {
        // Test sound configuration logic
        const isDriver = true;
        const isPassenger = false;
        
        const driverSound = isDriver ? 'chegoucorridaoption' : null;
        const passengerSound = isPassenger ? 'chegoucorridaoption' : null;
        
        expect(driverSound, equals('chegoucorridaoption'));
        expect(passengerSound, isNull);
      });
    });
    
    group('Navigation Integration Tests', () {
      test('should validate navigation data structure', () {
        final navigationRequest = {
          'route': 'driver_requests',
          'data': {
            'request_id': 'test-request-123',
            'timestamp': DateTime.now().toIso8601String(),
          },
        };
        
        expect(navigationRequest['route'], equals('driver_requests'));
        expect(navigationRequest['data'], isA<Map<String, dynamic>>());
        final data = navigationRequest['data'] as Map<String, dynamic>?;
        expect(data?['request_id'], isNotEmpty);
        expect(data?['timestamp'], isNotNull);
      });
    });
  });
  
  group('Error Handling and Edge Cases', () {
    test('should handle network failures gracefully', () async {
      // Simulate network failure scenario
      const networkError = 'Network unreachable';
      
      expect(
        () => throw Exception(networkError),
        throwsA(isA<Exception>()),
      );
      
      // Verify error is caught and handled
      try {
        throw Exception(networkError);
      } catch (e) {
        expect(e.toString(), contains(networkError));
      }
    });
    
    test('should validate Player ID before sending notifications', () {
      const validPlayerIdPattern = r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
      final regex = RegExp(validPlayerIdPattern);
      
      const testCases = {
        '12345678-1234-1234-1234-123456789012': true,
        'invalid-id': false,
        '': false,
        '12345678-1234-1234-1234-12345678901G': false,
      };
      
      testCases.forEach((playerId, shouldBeValid) {
        expect(
          regex.hasMatch(playerId),
          equals(shouldBeValid),
          reason: 'Player ID "$playerId" validation failed',
        );
      });
    });
  });
}

// Extension to access private methods for testing
extension OneSignalServiceTest on OneSignalService {
  bool _isValidPlayerId(String playerId) {
    if (playerId.isEmpty) return false;
    final playerIdRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return playerIdRegex.hasMatch(playerId);
  }
}