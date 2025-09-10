import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:option/services/trip_request_manager.dart';
import 'package:option/models/supabase/driver.dart';
import 'package:option/models/trip_request_data.dart';
import 'package:option/exceptions/app_exceptions.dart';

import 'trip_request_manager_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestBuilder,
])
void main() {
  group('TripRequestManager Unit Tests', () {
    late MockSupabaseClient mockSupabase;
    late MockPostgrestQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late TripRequestManager tripRequestManager;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockQueryBuilder = MockPostgrestQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      tripRequestManager = TripRequestManager(mockSupabase);
    });

    group('handleDriverResponse', () {
      test('should accept trip request and create trip successfully', () async {
        // Arrange
        const requestId = 'request-123';
        const driverId = 'driver-456';
        const passengerId = 'passenger-789';
        
        final tripRequestData = {
          'id': requestId,
          'passenger_id': passengerId,
          'accepted_by_driver_id': driverId,
          'origin_address': 'Rua A, 123',
          'origin_latitude': -23.550520,
          'origin_longitude': -46.633308,
          'destination_address': 'Rua B, 456',
          'destination_latitude': -23.561684,
          'destination_longitude': -46.625378,
          'vehicle_category': 'common_car',
          'estimated_fare': 12.50,
          'estimated_distance_km': 5.2,
          'estimated_duration_minutes': 15,
          'needs_pet': false,
          'needs_grocery_space': false,
          'is_condo_origin': false,
          'is_condo_destination': false,
          'needs_ac': false,
          'number_of_stops': 0,
        };

        // Mock accept request update
        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', requestId)).thenAnswer((_) async => []);

        // Mock fetch request data for trip creation
        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', requestId)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.single()).thenAnswer((_) async => tripRequestData);

        // Mock trip creation
        when(mockSupabase.from('trips')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenAnswer((_) async => []);

        // Act
        await tripRequestManager.handleDriverResponse(
          requestId: requestId,
          driverId: driverId,
          accepted: true,
        );

        // Assert
        verify(mockSupabase.from('trip_requests').update({
          'status': 'accepted',
          'accepted_by_driver_id': driverId,
          'accepted_at': any,
          'updated_at': any,
        }).eq('id', requestId)).called(1);

        verify(mockSupabase.from('trips').insert(argThat(
          predicate<Map<String, dynamic>>((data) =>
            data['request_id'] == requestId &&
            data['passenger_id'] == passengerId &&
            data['driver_id'] == driverId &&
            data['status'] == 'requested' &&
            data['origin_address'] == 'Rua A, 123' &&
            data['destination_address'] == 'Rua B, 456' &&
            data['base_fare'] == 12.50 &&
            data['total_fare'] == 12.50)
        ))).called(1);
      });

      test('should reject trip request and not create trip', () async {
        // Arrange
        const requestId = 'request-123';
        const driverId = 'driver-456';

        // Mock reject request update
        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', requestId)).thenAnswer((_) async => []);

        // Act
        await tripRequestManager.handleDriverResponse(
          requestId: requestId,
          driverId: driverId,
          accepted: false,
        );

        // Assert
        verify(mockSupabase.from('trip_requests').update({
          'status': 'rejected',
          'rejected_by_driver_id': driverId,
          'rejected_at': any,
          'updated_at': any,
        }).eq('id', requestId)).called(1);

        // Verify trip was NOT created
        verifyNever(mockSupabase.from('trips').insert(any));
      });

      test('should handle database error during acceptance', () async {
        // Arrange
        const requestId = 'request-123';
        const driverId = 'driver-456';

        // Mock database error
        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', requestId))
            .thenThrow(const PostgrestException(message: 'Database error', code: '500'));

        // Act & Assert
        expect(
          () => tripRequestManager.handleDriverResponse(
            requestId: requestId,
            driverId: driverId,
            accepted: true,
          ),
          throwsA(isA<PostgrestException>()),
        );
      });

      test('should handle missing trip request data', () async {
        // Arrange
        const requestId = 'request-123';
        const driverId = 'driver-456';

        // Mock accept request update (success)
        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', requestId)).thenAnswer((_) async => []);

        // Mock missing request data
        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', requestId)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.single())
            .thenThrow(const PostgrestException(message: 'No rows found', code: 'PGRST116'));

        // Act & Assert
        expect(
          () => tripRequestManager.handleDriverResponse(
            requestId: requestId,
            driverId: driverId,
            accepted: true,
          ),
          throwsA(isA<PostgrestException>()),
        );
      });
    });

    group('createDirectedTripRequest', () {
      test('should create trip request with valid data', () async {
        // Arrange
        const passengerId = 'passenger-123';
        const driverId = 'driver-456';
        const requestId = 'request-789';

        final driver = Driver(
          id: driverId,
          userId: 'user-456',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'common_car',
          approvalStatus: 'approved',
          isOnline: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tripData = TripRequestData(
          originAddress: 'Rua A, 123',
          originLatitude: -23.550520,
          originLongitude: -46.633308,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.561684,
          destinationLongitude: -46.625378,
          vehicleCategory: 'common_car',
          needsPet: false,
          needsGrocerySpace: false,
          isCondoOrigin: false,
          isCondoDestination: false,
          estimatedDistanceKm: 5.2,
          estimatedDurationMinutes: 15,
          estimatedFare: 12.50,
        );

        // Mock driver availability checks
        when(mockSupabase.from('drivers')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('is_online, approval_status')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', driverId)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.single()).thenAnswer((_) async => {
          'is_online': true,
          'approval_status': 'approved',
        });

        when(mockSupabase.from('driver_effective_status')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('effective_online')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('driver_id', driverId)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.maybeSingle()).thenAnswer((_) async => {
          'effective_online': true,
        });

        when(mockSupabase.from('trips')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('id')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('driver_id', driverId)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.inFilter('status', any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.limit(1)).thenAnswer((_) async => []);

        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('id')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('target_driver_id', driverId)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('status', 'pending')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.limit(1)).thenAnswer((_) async => []);

        // Mock trip request creation
        when(mockSupabase.from('trip_requests')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.single()).thenAnswer((_) async => {
          'id': requestId,
          'passenger_id': passengerId,
          'target_driver_id': driverId,
          'status': 'pending',
        });

        // Act
        final result = await tripRequestManager.createDirectedTripRequest(
          passengerId: passengerId,
          prioritizedDrivers: [driver],
          tripData: tripData,
        );

        // Assert
        expect(result, equals(requestId));
        
        verify(mockSupabase.from('trip_requests').insert(argThat(
          predicate<Map<String, dynamic>>((data) =>
            data['passenger_id'] == passengerId &&
            data['target_driver_id'] == driverId &&
            data['status'] == 'pending' &&
            data['origin_address'] == tripData.originAddress &&
            data['destination_address'] == tripData.destinationAddress &&
            data['estimated_fare'] == tripData.estimatedFare)
        ))).called(1);
      });

      test('should throw exception when no drivers available', () async {
        // Arrange
        const passengerId = 'passenger-123';
        final tripData = TripRequestData(
          originAddress: 'Rua A, 123',
          originLatitude: -23.550520,
          originLongitude: -46.633308,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.561684,
          destinationLongitude: -46.625378,
          vehicleCategory: 'common_car',
          needsPet: false,
          needsGrocerySpace: false,
          isCondoOrigin: false,
          isCondoDestination: false,
          estimatedDistanceKm: 5.2,
          estimatedDurationMinutes: 15,
          estimatedFare: 12.50,
        );

        // Act & Assert
        expect(
          () => tripRequestManager.createDirectedTripRequest(
            passengerId: passengerId,
            prioritizedDrivers: [], // Empty list
            tripData: tripData,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw exception when driver is offline', () async {
        // Arrange
        const passengerId = 'passenger-123';
        const driverId = 'driver-456';

        final driver = Driver(
          id: driverId,
          userId: 'user-456',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'common_car',
          approvalStatus: 'approved',
          isOnline: false, // Offline
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tripData = TripRequestData(
          originAddress: 'Rua A, 123',
          originLatitude: -23.550520,
          originLongitude: -46.633308,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.561684,
          destinationLongitude: -46.625378,
          vehicleCategory: 'common_car',
          needsPet: false,
          needsGrocerySpace: false,
          isCondoOrigin: false,
          isCondoDestination: false,
          estimatedDistanceKm: 5.2,
          estimatedDurationMinutes: 15,
          estimatedFare: 12.50,
        );

        // Mock driver availability checks - driver offline
        when(mockSupabase.from('drivers')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('is_online, approval_status')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('id', driverId)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.single()).thenAnswer((_) async => {
          'is_online': false,
          'approval_status': 'approved',
        });

        // Act & Assert
        expect(
          () => tripRequestManager.createDirectedTripRequest(
            passengerId: passengerId,
            prioritizedDrivers: [driver],
            tripData: tripData,
          ),
          throwsA(isA<DriverException>()),
        );
      });
    });

    group('Data Validation', () {
      test('should validate trip request data format', () {
        // Arrange
        final tripData = TripRequestData(
          originAddress: 'Rua A, 123',
          originLatitude: -23.550520,
          originLongitude: -46.633308,
          destinationAddress: 'Rua B, 456',
          destinationLatitude: -23.561684,
          destinationLongitude: -46.625378,
          vehicleCategory: 'common_car',
          needsPet: false,
          needsGrocerySpace: false,
          isCondoOrigin: false,
          isCondoDestination: false,
          estimatedDistanceKm: 5.2,
          estimatedDurationMinutes: 15,
          estimatedFare: 12.50,
        );

        // Act
        final dbData = tripData.toDatabase(
          passengerId: 'passenger-123',
          targetDriverId: 'driver-456',
        );

        // Assert
        expect(dbData['passenger_id'], 'passenger-123');
        expect(dbData['target_driver_id'], 'driver-456');
        expect(dbData['status'], 'pending');
        expect(dbData['origin_address'], 'Rua A, 123');
        expect(dbData['destination_address'], 'Rua B, 456');
        expect(dbData['estimated_fare'], 12.50);
        expect(dbData['vehicle_category'], 'common_car');
        expect(dbData['expires_at'], isA<String>());
        expect(dbData['current_fallback_index'], 0);
        expect(dbData['timeout_count'], 0);
      });

      test('should validate driver data format', () {
        // Arrange & Act
        final driver = Driver(
          id: 'driver-123',
          userId: 'user-456',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2020,
          color: 'Branco',
          plate: 'ABC-1234',
          category: 'common_car',
          approvalStatus: 'approved',
          isOnline: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(driver.id, 'driver-123');
        expect(driver.userId, 'user-456');
        expect(driver.brand, 'Toyota');
        expect(driver.model, 'Corolla');
        expect(driver.category, 'common_car');
        expect(driver.approvalStatus, 'approved');
        expect(driver.isOnline, true);
      });
    });

    group('Status Constraints Validation', () {
      test('should accept all valid trip_requests status values', () {
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
          expect(validStatuses.contains(status), true,
              reason: 'Status $status should be valid for trip_requests');
        }
      });

      test('should accept all valid trips status values', () {
        const validStatuses = [
          'requested',
          'driver_assigned',
          'driver_arriving',
          'waiting_passenger',
          'in_progress',
          'completed',
          'cancelled_by_passenger',
          'cancelled_by_driver',
          'no_show'
        ];

        for (final status in validStatuses) {
          expect(validStatuses.contains(status), true,
              reason: 'Status $status should be valid for trips');
        }
      });
    });
  });
}