import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';
import '../helpers/supabase_test_helper.dart';

void main() {
  group('Supabase Diagnostic Tests', () {
    setUpAll(() async {
      await SupabaseTestHelper.initialize();
    });

    test('should initialize SupabaseTestHelper without errors', () async {
      // This test just verifies that initialization works
      expect(SupabaseTestHelper.client, isNotNull);
    });

    test('should be able to perform basic database operation', () async {
      try {
        // Try a simple operation that doesn't require special permissions
        final result = await SupabaseTestHelper.client
            .from('app_users')
            .select('id')
            .limit(1);
        
        // If we get here without exception, the connection works
        expect(result, isA<List>());
      } catch (e) {
        // Print the error for debugging
        print('Database operation failed: $e');
        rethrow;
      }
    });

    test('should be able to insert data using admin client', () async {
       try {
         // Use unique email to avoid conflicts
         final testEmail = 'diagnostic.test.${DateTime.now().millisecondsSinceEpoch}@example.com';
         
         print('Testing with client type: ${SupabaseTestHelper.client.runtimeType}');
         
         // Clean up any existing test data first
         await SupabaseTestHelper.cleanDatabase();
         
         // First create the auth user using admin client
          final adminClient = SupabaseTestHelper.adminClient ?? SupabaseTestHelper.client;
          print('Admin client available: ${SupabaseTestHelper.adminClient != null}');
          print('Using client: ${adminClient.runtimeType}');
          
          final authResponse = await adminClient.auth.admin.createUser(
           AdminUserAttributes(
             email: testEmail,
             emailConfirm: true,
             userMetadata: {'full_name': 'Diagnostic Test User'},
           ),
         );
        
        final userId = authResponse.user!.id;
        
        // Then insert into app_users table using admin client
         final user = await adminClient
             .from('app_users')
             .insert({
               'id': userId,
               'email': testEmail,
               'full_name': 'Diagnostic Test User',
               'user_type': 'passenger',
               'status': 'active',
               'phone': 'pending',
             })
             .select()
             .single();
        
        expect(user['email'], equals(testEmail));
        expect(user['id'], equals(userId));
        
        // Clean up: delete app_users record and auth user
         await adminClient
             .from('app_users')
             .delete()
             .eq('id', userId);
             
         await adminClient.auth.admin.deleteUser(userId);
            
      } catch (e) {
        print('Insert operation failed: $e');
        rethrow;
      }
    });
  });
}