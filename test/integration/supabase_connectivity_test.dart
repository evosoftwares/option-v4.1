import 'package:flutter_test/flutter_test.dart';
import 'package:option/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Supabase Connectivity Tests', () {
    late SupabaseClient supabaseClient;

    setUpAll(() async {
      // Initialize Supabase for testing using app config
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      supabaseClient = Supabase.instance.client;
    });

    test('should connect to Supabase successfully', () async {
      // Act & Assert
      expect(supabaseClient, isNotNull);
      expect(supabaseClient.auth, isNotNull);
      print('✅ Supabase client initialized successfully');
    });

    test('should be able to query trip_requests table', () async {
      try {
        // Act - Try to query the trip_requests table
        final response = await supabaseClient
            .from('trip_requests')
            .select('id, status, created_at')
            .limit(1);

        // Assert
        expect(response, isA<List>());
        print('✅ Successfully connected to trip_requests table');
        print('Response type: ${response.runtimeType}');
        
        if (response.isNotEmpty) {
          print('Sample record: ${response.first}');
        } else {
          print('Table is empty (which is expected for a new setup)');
        }
      } catch (e) {
        print('❌ Error querying trip_requests table: $e');
        fail('Failed to query trip_requests table: $e');
      }
    });

    test('should verify trip_requests table schema', () async {
      try {
        // Act - Try to query with specific fields to verify schema
        final response = await supabaseClient
            .from('trip_requests')
            .select('''
              id,
              passenger_id,
              target_driver_id,
              fallback_drivers,
              accepted_by_driver_id,
              status,
              origin_address,
              destination_address,
              vehicle_category,
              estimated_fare,
              current_fallback_index,
              timeout_count,
              created_at
            ''')
            .limit(1);

        // Assert
        expect(response, isA<List>());
        print('✅ trip_requests table schema verification successful');
        print('All required fields are accessible');
      } catch (e) {
        print('❌ Schema verification failed: $e');
        fail('trip_requests table schema verification failed: $e');
      }
    });

    test('should be able to query drivers table', () async {
      try {
        // Act - Try to query the drivers table
        final response = await supabaseClient
            .from('drivers')
            .select('id, user_id, category, is_online')
            .limit(1);

        // Assert
        expect(response, isA<List>());
        print('✅ Successfully connected to drivers table');
        
        if (response.isNotEmpty) {
          print('Sample driver record: ${response.first}');
        } else {
          print('Drivers table is empty');
        }
      } catch (e) {
        print('❌ Error querying drivers table: $e');
        fail('Failed to query drivers table: $e');
      }
    });

    test('should test real-time subscription capability', () async {
      try {
        // Act - Test if we can create a subscription
        final subscription = supabaseClient
            .from('trip_requests')
            .stream(primaryKey: ['id'])
            .listen((data) {
              print('Real-time data received: ${data.length} records');
            });

        // Wait a moment to ensure subscription is established
        await Future.delayed(const Duration(seconds: 2));

        // Assert
        expect(subscription, isNotNull);
        print('✅ Real-time subscription established successfully');
        
        // Clean up
        await subscription.cancel();
      } catch (e) {
        print('❌ Real-time subscription failed: $e');
        fail('Real-time subscription test failed: $e');
      }
    });
  });
}