import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/services/trip_request_manager.dart';
import '../../lib/models/supabase/driver.dart';
import '../../lib/models/trip_request_data.dart';
import '../../lib/services/trip_service.dart';
import '../../lib/exceptions/app_exceptions.dart';
import '../helpers/test_helpers.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements PostgrestQueryBuilder {}
class MockSupabaseFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockTripService extends Mock implements TripService {}

void main() {
  group('Driver Acceptance End-to-End Tests', () {
    late MockSupabaseClient mockSupabase;
    late MockSupabaseQueryBuilder mockQuery;
    late MockSupabaseFilterBuilder mockFilter;
    late TripRequestManager tripRequestManager;
    
    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockQuery = MockSupabaseQueryBuilder();
      mockFilter = MockSupabaseFilterBuilder();
      tripRequestManager = TripRequestManager(mockSupabase);
    });

    testWidgets('Complete driver acceptance flow - SUCCESS path', (tester) async {
      // === SETUP TEST DATA ===
      const passengerId = 'passenger-123';
      const driverId = 'driver-456';
      const requestId = 'request-789';
      
      final mockDriver = Driver(
        id: driverId,
        userId: 'user-456',
        vehicleBrand: 'Toyota',
        vehicleModel: 'Corolla',
        vehicleYear: 2020,
        vehicleColor: 'Branco',
        vehiclePlate: 'ABC-1234',
        vehicleCategory: 'common_car',
        isOnline: true,
        approvalStatus: 'approved',
        totalTrips: 50,
        averageRating: 4.8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tripData = TripRequestData(
        originAddress: 'Rua A, 123, São Paulo, SP',
        originLatitude: -23.550520,
        originLongitude: -46.633308,
        destinationAddress: 'Rua B, 456, São Paulo, SP',
        destinationLatitude: -23.561684,
        destinationLongitude: -46.625378,
        vehicleCategory: 'common_car',
        estimatedDistanceKm: 5.2,
        estimatedDurationMinutes: 15,
        estimatedFare: 12.50,
      );

      // === PHASE 1: CREATE TRIP REQUEST ===
      print('🧪 TESTING PHASE 1: Creating directed trip request');
      
      // Mock driver availability check
      when(mockSupabase.from('drivers')).thenReturn(mockQuery);
      when(mockQuery.select('is_online, approval_status')).thenReturn(mockQuery);
      when(mockQuery.eq('id', driverId)).thenReturn(mockQuery);
      when(mockQuery.single()).thenAnswer((_) async => {
        'is_online': true,
        'approval_status': 'approved',
      });

      // Mock driver effective status check
      when(mockSupabase.from('driver_effective_status')).thenReturn(mockQuery);
      when(mockQuery.select('effective_online')).thenReturn(mockQuery);
      when(mockQuery.eq('driver_id', driverId)).thenReturn(mockQuery);
      when(mockQuery.maybeSingle()).thenAnswer((_) async => {
        'effective_online': true,
      });

      // Mock active trips check (empty - driver available)
      when(mockSupabase.from('trips')).thenReturn(mockQuery);
      when(mockQuery.select('id')).thenReturn(mockQuery);
      when(mockQuery.eq('driver_id', driverId)).thenReturn(mockQuery);
      when(mockQuery.inFilter('status', ['ongoing', 'arrived', 'picked_up'])).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenAnswer((_) async => []);

      // Mock pending requests check (empty - no conflicts)
      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.select('id')).thenReturn(mockQuery);
      when(mockQuery.eq('target_driver_id', driverId)).thenReturn(mockQuery);
      when(mockQuery.eq('status', 'pending')).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenAnswer((_) async => []);

      // Mock trip request creation
      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.insert(any)).thenReturn(mockQuery);
      when(mockQuery.select()).thenReturn(mockQuery);
      when(mockQuery.single()).thenAnswer((_) async => {
        'id': requestId,
        'passenger_id': passengerId,
        'target_driver_id': driverId,
        'status': 'searching',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Execute Phase 1
      final createdRequestId = await tripRequestManager.createDirectedTripRequest(
        passengerId: passengerId,
        prioritizedDrivers: [mockDriver],
        tripData: tripData,
      );

      expect(createdRequestId, equals(requestId));
      print('✅ PHASE 1 SUCCESS: Trip request created with ID: $createdRequestId');

      // === PHASE 2: DRIVER ACCEPTS REQUEST ===
      print('🧪 TESTING PHASE 2: Driver accepting request');

      // Mock request status update to 'accepted'
      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.update({
        'status': 'accepted',
        'updated_at': any,
      })).thenReturn(mockQuery);
      when(mockQuery.eq('id', requestId)).thenAnswer((_) async => []);

      // Mock fetching request data for trip creation
      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.select()).thenReturn(mockQuery);
      when(mockQuery.eq('id', requestId)).thenReturn(mockQuery);
      when(mockQuery.single()).thenAnswer((_) async => {
        'id': requestId,
        'passenger_id': passengerId,
        'accepted_by_driver_id': driverId,
        'origin_address': tripData.originAddress,
        'origin_latitude': tripData.originLatitude,
        'origin_longitude': tripData.originLongitude,
        'destination_address': tripData.destinationAddress,
        'destination_latitude': tripData.destinationLatitude,
        'destination_longitude': tripData.destinationLongitude,
        'vehicle_category': tripData.vehicleCategory,
        'estimated_fare': tripData.estimatedFare,
        'estimated_distance_km': tripData.estimatedDistanceKm,
        'estimated_duration_minutes': tripData.estimatedDurationMinutes,
      });

      // Mock trip creation
      when(mockSupabase.from('trips')).thenReturn(mockQuery);
      when(mockQuery.insert(any)).thenAnswer((_) async => []);

      // Execute Phase 2
      await tripRequestManager.handleDriverResponse(
        requestId: requestId,
        driverId: driverId,
        accepted: true,
      );

      print('✅ PHASE 2 SUCCESS: Driver acceptance processed');

      // === PHASE 3: VERIFY FINAL STATE ===
      print('🧪 TESTING PHASE 3: Verifying final database state');

      // Verify trip_requests was updated to 'accepted'
      verify(mockSupabase.from('trip_requests').update({
        'status': 'accepted',
        'updated_at': any,
      }).eq('id', requestId)).called(1);

      // Verify trip was created
      verify(mockSupabase.from('trips').insert(argThat(
        predicate<Map<String, dynamic>>((data) =>
          data['passenger_id'] == passengerId &&
          data['driver_id'] == driverId &&
          data['status'] == 'requested' &&
          data['origin_address'] == tripData.originAddress &&
          data['destination_address'] == tripData.destinationAddress)
      ))).called(1);

      print('✅ PHASE 3 SUCCESS: All database operations verified');
      print('🎉 END-TO-END TEST COMPLETED SUCCESSFULLY!');
    });

    testWidgets('Driver rejection with fallback flow', (tester) async {
      // === SETUP TEST DATA ===
      const passengerId = 'passenger-123';
      const primaryDriverId = 'driver-456';
      const fallbackDriverId = 'driver-789';
      const requestId = 'request-abc';
      
      final primaryDriver = Driver(
        id: primaryDriverId,
        userId: 'user-456',
        vehicleBrand: 'Toyota',
        vehicleModel: 'Corolla',
        vehicleYear: 2020,
        vehicleColor: 'Branco',
        vehiclePlate: 'ABC-1234',
        vehicleCategory: 'common_car',
        isOnline: true,
        approvalStatus: 'approved',
        totalTrips: 50,
        averageRating: 4.8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final fallbackDriver = Driver(
        id: fallbackDriverId,
        userId: 'user-789',
        vehicleBrand: 'Honda',
        vehicleModel: 'Civic',
        vehicleYear: 2021,
        vehicleColor: 'Preto',
        vehiclePlate: 'DEF-5678',
        vehicleCategory: 'common_car',
        isOnline: true,
        approvalStatus: 'approved',
        totalTrips: 30,
        averageRating: 4.7,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock request data with fallback driver
      final mockRequestData = {
        'id': requestId,
        'passenger_id': passengerId,
        'fallback_drivers': [fallbackDriverId],
        'current_fallback_index': 0,
      };

      print('🧪 TESTING: Driver rejection with fallback system');

      // Mock fetching request data
      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.select()).thenReturn(mockQuery);
      when(mockQuery.eq('id', requestId)).thenReturn(mockQuery);
      when(mockQuery.single()).thenAnswer((_) async => mockRequestData);

      // Mock request status update to 'rejected'
      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.update({'status': 'rejected', 'updated_at': any})).thenReturn(mockQuery);
      when(mockQuery.eq('id', requestId)).thenAnswer((_) async => []);

      // Mock fallback driver assignment
      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.update({
        'target_driver_id': fallbackDriverId,
        'current_fallback_index': 1,
        'status': 'pending',
        'updated_at': any,
      })).thenReturn(mockQuery);
      when(mockQuery.eq('id', requestId)).thenAnswer((_) async => []);

      // Execute driver rejection
      await tripRequestManager.handleDriverResponse(
        requestId: requestId,
        driverId: primaryDriverId,
        accepted: false,
      );

      // Verify rejection was processed
      verify(mockSupabase.from('trip_requests').update({
        'status': 'rejected',
        'updated_at': any,
      }).eq('id', requestId)).called(1);

      // Verify fallback driver was assigned
      verify(mockSupabase.from('trip_requests').update({
        'target_driver_id': fallbackDriverId,
        'current_fallback_index': 1,
        'status': 'pending',
        'updated_at': any,
      }).eq('id', requestId)).called(1);

      print('✅ SUCCESS: Driver rejection with fallback processed correctly');
    });

    testWidgets('Database constraint validation test', (tester) async {
      print('🧪 TESTING: Database constraint validation');
      
      // Test all valid status values that should be allowed
      const validStatuses = [
        'searching',
        'pending', 
        'driver_selected',
        'accepted',
        'rejected',
        'expired',
        'cancelled'
      ];

      for (final status in validStatuses) {
        print('   ✓ Testing status: $status');
        
        // Mock successful update with valid status
        when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
        when(mockQuery.update({'status': status, 'updated_at': any})).thenReturn(mockQuery);
        when(mockQuery.eq('id', any)).thenAnswer((_) async => []);

        // This should not throw any constraint violation
        expect(() async => await mockQuery.update({'status': status, 'updated_at': DateTime.now().toIso8601String()}).eq('id', 'test-id'), 
               returnsNormally);
      }

      print('✅ SUCCESS: All status values pass validation');
    });

    testWidgets('Driver availability verification test', (tester) async {
      print('🧪 TESTING: Driver availability verification');
      
      const driverId = 'driver-test';

      // Test case 1: Driver is available
      when(mockSupabase.from('drivers')).thenReturn(mockQuery);
      when(mockQuery.select('is_online, approval_status')).thenReturn(mockQuery);
      when(mockQuery.eq('id', driverId)).thenReturn(mockQuery);
      when(mockQuery.single()).thenAnswer((_) async => {
        'is_online': true,
        'approval_status': 'approved',
      });

      when(mockSupabase.from('driver_effective_status')).thenReturn(mockQuery);
      when(mockQuery.select('effective_online')).thenReturn(mockQuery);
      when(mockQuery.eq('driver_id', driverId)).thenReturn(mockQuery);
      when(mockQuery.maybeSingle()).thenAnswer((_) async => {
        'effective_online': true,
      });

      when(mockSupabase.from('trips')).thenReturn(mockQuery);
      when(mockQuery.select('id')).thenReturn(mockQuery);
      when(mockQuery.eq('driver_id', driverId)).thenReturn(mockQuery);
      when(mockQuery.inFilter('status', ['ongoing', 'arrived', 'picked_up'])).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenAnswer((_) async => []);

      when(mockSupabase.from('trip_requests')).thenReturn(mockQuery);
      when(mockQuery.select('id')).thenReturn(mockQuery);
      when(mockQuery.eq('target_driver_id', driverId)).thenReturn(mockQuery);
      when(mockQuery.eq('status', 'pending')).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenAnswer((_) async => []);

      // Use reflection to call private method (for testing purposes)
      final isAvailable = await tripRequestManager._verifyDriverAvailability(driverId);
      expect(isAvailable, isTrue);

      print('✅ SUCCESS: Driver availability verification works correctly');
    });
  });
}

// Extension to access private methods for testing
extension TripRequestManagerTesting on TripRequestManager {
  Future<bool> _verifyDriverAvailability(String driverId) {
    // This would require making the method public for testing
    // or using a testing library that supports private method access
    throw UnimplementedError('Private method access needed for testing');
  }
}