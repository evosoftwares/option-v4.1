import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import 'package:option/services/driver_service.dart';
import 'package:option/services/trip_service.dart';
import 'package:option/models/supabase/driver_offer.dart';
import '../../helpers/supabase_test_helper.dart';

void main() {
  group('DriverOffers Integration Flow', () {
    late DriverService driverService;
    late TripService tripService;
    late SupabaseClient client;

    setUpAll(() async {
      await SupabaseTestHelper.initialize();
      client = SupabaseTestHelper.client;
      driverService = DriverService(client);
      tripService = TripService(client);
    });

    setUp(() async {
      await SupabaseTestHelper.cleanDatabase();
    });

    test('create offer -> list pending -> accept -> verify flags', () async {
      // Arrange: seed passenger and driver
      final passenger = await SupabaseTestHelper.seedPassenger();
      final driver = await SupabaseTestHelper.seedDriver();

      // Create a trip request
      final tripRequest = await tripService.createTripRequest(
        passengerId: passenger.passengerId,
        originAddress: 'Origem A',
        originLatitude: -23.5505,
        originLongitude: -46.6333,
        destinationAddress: 'Destino B',
        destinationLatitude: -23.5596,
        destinationLongitude: -46.6588,
        vehicleCategory: 'standard',
        needsPet: false,
        needsGrocerySpace: false,
        isCondoDestination: false,
        isCondoOrigin: false,
        needsAc: false,
        numberOfStops: 0,
        estimatedDistanceKm: 10.5,
        estimatedDurationMinutes: 25,
        estimatedFare: 25,
      );

      // Act: driver creates an offer
      final offer = await driverService.createOffer(
        driverId: driver.driverId,
        requestId: tripRequest.id,
        driverDistanceKm: 1.2,
        driverEtaMinutes: 3,
        baseFare: 20,
        additionalFees: 5,
        notes: 'Chego rápido',
      );

      // Assert insertion
      expect(offer.id, isNotNull);
      expect(offer.driverId, equals(driver.driverId));
      expect(offer.tripId, equals(tripRequest.id));
      expect(offer.isAvailable, isTrue);
      expect(offer.wasSelected, isFalse);
      expect(offer.totalFare, closeTo(25.0, 0.001));

      // List by driver
      final offersByDriver =
          await driverService.getDriverOffers(driver.driverId);
      expect(offersByDriver, isNotEmpty);
      expect(offersByDriver.first.id, equals(offer.id));

      // Pending offers
      final pending = await driverService.getPendingOffers(driver.driverId);
      expect(pending.any((o) => o.id == offer.id), isTrue);

      // Update status to accepted (maps to flags)
      final updated =
          await driverService.updateOfferStatus(offer.id, 'accepted');
      expect(updated.wasSelected, isTrue);
      expect(updated.isAvailable, isFalse);

      // Pending should now exclude the accepted offer
      final pendingAfter =
          await driverService.getPendingOffers(driver.driverId);
      expect(pendingAfter.any((o) => o.id == offer.id), isFalse);
    });
  });
}
