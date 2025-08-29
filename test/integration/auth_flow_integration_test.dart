import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/supabase_test_helper.dart';

void main() {
  group('Auth Flow Integration Tests', () {
    late SupabaseClient client;

    setUpAll(() async {
      await SupabaseTestHelper.initialize();
      client = SupabaseTestHelper.client;
    });

    setUp(() async {
      await SupabaseTestHelper.cleanDatabase();
    });

    group('User Data Integration', () {
      test('should create passenger with complete data', () async {
        // Act: Create passenger using helper
        final seededUser = await SupabaseTestHelper.seedPassenger();

        // Assert: Verify passenger was created with all required data
        expect(seededUser.userId, isNotNull);
        expect(seededUser.passengerId, isNotNull);
        
        // Verify app_users record
        final appUser = await client
            .from('app_users')
            .select()
            .eq('id', seededUser.userId)
            .single();
        
        expect(appUser['user_type'], equals('passenger'));
        expect(appUser['status'], equals('active'));
        
        // Verify passengers record
        final passenger = await client
            .from('passengers')
            .select()
            .eq('user_id', seededUser.userId)
            .single();
        
        expect(passenger['user_id'], equals(seededUser.userId));
        expect(passenger['consecutive_cancellations'], equals(0));
        expect(passenger['total_trips'], equals(0));
      });

      test('should create driver with complete data', () async {
        // Act: Create driver using helper
        final seededUser = await SupabaseTestHelper.seedDriver();

        // Assert: Verify driver was created with all required data
        expect(seededUser.userId, isNotNull);
        expect(seededUser.driverId, isNotNull);
        
        // Verify app_users record
        final appUser = await client
            .from('app_users')
            .select()
            .eq('id', seededUser.userId)
            .single();
        
        expect(appUser['user_type'], equals('driver'));
        expect(appUser['status'], equals('active'));
        
        // Verify drivers record
        final driver = await client
            .from('drivers')
            .select()
            .eq('user_id', seededUser.userId)
            .single();
        
        expect(driver['user_id'], equals(seededUser.userId));
        expect(driver['status'], equals('offline'));
        expect(driver['total_trips'], equals(0));
      });
    });

    group('Data Integrity Validation', () {
      test('should maintain referential integrity between tables', () async {
        // Arrange & Act: Create user with both records
        final seededUser = await SupabaseTestHelper.seedPassenger();

        // Assert: Verify foreign key relationships
        final appUserQuery = await client
            .from('app_users')
            .select()
            .eq('id', seededUser.userId)
            .single();

        final passengerQuery = await client
            .from('passengers')
            .select()
            .eq('user_id', seededUser.userId)
            .single();

        expect(appUserQuery['id'], equals(passengerQuery['user_id']));
      });

      test('should validate user type consistency', () async {
        // Test passenger type
        final passenger = await SupabaseTestHelper.seedPassenger();
        final passengerAppUser = await client
            .from('app_users')
            .select()
            .eq('id', passenger.userId)
            .single();
        expect(passengerAppUser['user_type'], equals('passenger'));

        // Test driver type
        final driver = await SupabaseTestHelper.seedDriver();
        final driverAppUser = await client
            .from('app_users')
            .select()
            .eq('id', driver.userId)
            .single();
        expect(driverAppUser['user_type'], equals('driver'));
      });
    });

    group('Basic Integration Validation', () {
      test('should successfully create and validate passenger data', () async {
        final seededUser = await SupabaseTestHelper.seedPassenger(
          fullName: 'Test Passenger',
        );

        // Validate returned data structure
        expect(seededUser.userId, isNotEmpty);
        expect(seededUser.passengerId, isNotEmpty);
        expect(seededUser.userId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
        expect(seededUser.passengerId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
      });

      test('should successfully create and validate driver data', () async {
        final seededUser = await SupabaseTestHelper.seedDriver();

        // Validate returned data structure
        expect(seededUser.userId, isNotEmpty);
        expect(seededUser.driverId, isNotEmpty);
        expect(seededUser.userId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
        expect(seededUser.driverId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
      });

      test('should create multiple users without conflicts', () async {
        final passenger1 = await SupabaseTestHelper.seedPassenger(
          fullName: 'Passenger One',
        );
        final passenger2 = await SupabaseTestHelper.seedPassenger(
          fullName: 'Passenger Two',
        );
        final driver1 = await SupabaseTestHelper.seedDriver();

        // All should have unique IDs
        expect(passenger1.userId, isNot(equals(passenger2.userId)));
        expect(passenger1.userId, isNot(equals(driver1.userId)));
        expect(passenger2.userId, isNot(equals(driver1.userId)));
        expect(passenger1.passengerId, isNot(equals(passenger2.passengerId)));
      });

      test('should handle passenger creation with custom parameters', () async {
        final customPassenger = await SupabaseTestHelper.seedPassenger(
          fullName: 'Custom Passenger Name',
        );

        expect(customPassenger.userId, isNotEmpty);
        expect(customPassenger.passengerId, isNotEmpty);
      });
    });
  });
}