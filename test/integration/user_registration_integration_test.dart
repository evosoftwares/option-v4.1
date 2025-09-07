import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/config/app_config.dart';
import '../../lib/exceptions/app_exceptions.dart';
import '../../lib/services/user_service.dart';
import '../../lib/utils/supabase_helper.dart';

void main() {
  group('User Registration Integration Tests', () {
    setUpAll(() async {
      // Initialize Supabase with local instance
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      SupabaseHelper.markInitialized();
    });

    tearDownAll(() async {
      // Cleanup test data
      try {
        await Supabase.instance.client
            .from('app_users')
            .delete()
            .ilike('email', '%test%');
      } catch (e) {
        print('Cleanup error: $e');
      }
    });

    test('should successfully register a new user', () async {
      // Arrange
      const testEmail = 'integration.test@example.com';
      const testName = 'Integration Test User';
      const testPhone = '+5511987654321';
      const testUserId = 'integration-test-user-123';
      
      // Clean up any existing test user
      try {
        await Supabase.instance.client
            .from('app_users')
            .delete()
            .eq('email', testEmail);
      } catch (e) {
        // Ignore cleanup errors
      }

      // Act
      final user = await UserService.createUser(
        authUserId: testUserId,
        email: testEmail,
        fullName: testName,
        phone: testPhone,
        userType: 'passenger',
      );

      // Assert
      expect(user.id, equals(testUserId));
      expect(user.email, equals(testEmail));
      expect(user.fullName, equals(testName));
      expect(user.phone, equals(testPhone));
      expect(user.userType, equals('passenger'));

      // Verify user exists in database
      final retrievedUser = await UserService.getUserById(testUserId);
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.email, equals(testEmail));
    });

    test('should fail when registering user with invalid email', () async {
      expect(
        () => UserService.createUser(
          authUserId: 'test-user-invalid-email',
          email: 'invalid-email-format',
          fullName: 'Test User',
          phone: '+5511987654321',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('should fail when registering user without phone', () async {
      expect(
        () => UserService.createUser(
          authUserId: 'test-user-no-phone',
          email: 'test.no.phone@example.com',
          fullName: 'Test User',
          phone: null,
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()
            .having((e) => e.message, 'message', contains('Telefone é obrigatório'))),
      );
    });

    test('should fail when registering duplicate user', () async {
      // Arrange
      const testEmail = 'duplicate.test@example.com';
      const testUserId = 'duplicate-test-user';
      
      // Clean up any existing test user
      try {
        await Supabase.instance.client
            .from('app_users')
            .delete()
            .eq('id', testUserId);
      } catch (e) {
        // Ignore cleanup errors
      }

      // Create first user
      await UserService.createUser(
        authUserId: testUserId,
        email: testEmail,
        fullName: 'First User',
        phone: '+5511987654321',
        userType: 'passenger',
      );

      // Act & Assert - Try to create duplicate
      expect(
        () => UserService.createUser(
          authUserId: testUserId,
          email: testEmail,
          fullName: 'Duplicate User',
          phone: '+5511987654322',
          userType: 'driver',
        ),
        throwsA(isA<UserAlreadyExistsException>()),
      );
    });

    test('should validate phone number format', () async {
      expect(
        () => UserService.createUser(
          authUserId: 'test-user-invalid-phone',
          email: 'test.invalid.phone@example.com',
          fullName: 'Test User',
          phone: 'invalid-phone',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('should validate user type', () async {
      expect(
        () => UserService.createUser(
          authUserId: 'test-user-invalid-type',
          email: 'test.invalid.type@example.com',
          fullName: 'Test User',
          phone: '+5511987654321',
          userType: 'invalid-type',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('should create driver user successfully', () async {
      // Arrange
      const testEmail = 'driver.test@example.com';
      const testUserId = 'driver-test-user';
      
      // Clean up any existing test user
      try {
        await Supabase.instance.client
            .from('app_users')
            .delete()
            .eq('id', testUserId);
      } catch (e) {
        // Ignore cleanup errors
      }

      // Act
      final user = await UserService.createUser(
        authUserId: testUserId,
        email: testEmail,
        fullName: 'Driver Test User',
        phone: '+5511987654321',
        userType: 'driver',
      );

      // Assert
      expect(user.userType, equals('driver'));
      
      // Verify user exists in database
      final retrievedUser = await UserService.getUserById(testUserId);
      expect(retrievedUser!.userType, equals('driver'));
    });

    test('should handle database connection errors gracefully', () async {
      // This test would require mocking network issues or database downtime
      // For now, we'll test that the service handles basic database errors
      
      expect(
        () => UserService.createUser(
          authUserId: '', // Invalid ID should cause database error
          email: 'error.test@example.com',
          fullName: 'Error Test User',
          phone: '+5511987654321',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}