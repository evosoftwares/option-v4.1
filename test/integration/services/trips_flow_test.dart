import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:option/services/trip_service.dart';
import '../../helpers/supabase_test_helper.dart';

void main() {
  group('Trips Integration Flow', () {
    late TripService tripService;
    late SupabaseClient client;

    setUpAll(() async {
      await SupabaseTestHelper.initialize();
      client = SupabaseTestHelper.client;
      tripService = TripService(client);
    });

    setUp(() async {
      await SupabaseTestHelper.cleanDatabase();
    });

    test('create trip -> query -> complete -> rate', () async {
      // Arrange: passenger + driver + trip request
      final passenger = await SupabaseTestHelper.seedPassenger();
      final driver = await SupabaseTestHelper.seedDriver();

      final tripRequest = await tripService.createTripRequest(
        passengerId: passenger.passengerId,
        originAddress: 'Rua A, 123',
        originLatitude: -23.55,
        originLongitude: -46.63,
        destinationAddress: 'Rua B, 456',
        destinationLatitude: -23.56,
        destinationLongitude: -46.65,
        vehicleCategory: 'standard',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoDestination: false,
        isCondoOrigin: false,
        needsAc: false,
        numberOfStops: 0,
        estimatedDistanceKm: 8,
        estimatedDurationMinutes: 20,
        estimatedFare: 20,
      );

      // Act: create a trip from the request
      final trip = await tripService.createTrip(
        tripRequestId: tripRequest.id,
        driverId: driver.driverId,
        passengerId: passenger.passengerId,
        originAddress: tripRequest.originAddress,
        originLatitude: tripRequest.originLatitude,
        originLongitude: tripRequest.originLongitude,
        destinationAddress: tripRequest.destinationAddress,
        destinationLatitude: tripRequest.destinationLatitude,
        destinationLongitude: tripRequest.destinationLongitude,
        actualDistanceKm: 8.2,
        actualDurationMinutes: 21,
        baseFare: 18,
        finalFare: 22,
      );

      // Assert creation
      expect(trip.id, isNotNull);
      expect(trip.tripRequestId, equals(tripRequest.id));
      expect(trip.driverId, equals(driver.driverId));
      expect(trip.passengerId, equals(passenger.passengerId));
      expect(trip.status, anyOf('ongoing', 'accepted', 'in_progress'));

      // Query by driver
      final ongoingByDriver = await tripService.getTrips(
        driverId: driver.driverId,
        status: trip.status,
      );
      expect(ongoingByDriver.any((t) => t.id == trip.id), isTrue);

      // Complete trip
      final completed = await tripService.completeTrip(
        tripId: trip.id,
        actualDistanceKm: 8.4,
        actualDurationMinutes: 22,
        finalFare: 23.5,
      );
      expect(completed.status, equals('completed'));
      expect(completed.finalFare, closeTo(23.5, 0.001));

      // Rate trip
      final rated = await tripService.rateTrip(
        tripId: trip.id,
        driverRating: 4.8,
        passengerRating: 5,
      );
      expect(rated.driverRating, closeTo(4.8, 0.001));
      expect(rated.passengerRating, closeTo(5.0, 0.001));

      // History check
      final completedByDriver = await tripService.getTrips(
        driverId: driver.driverId,
        status: 'completed',
      );
      expect(completedByDriver.any((t) => t.id == trip.id), isTrue);
    });
  });
}
