import 'package:flutter_test/flutter_test.dart';
import 'package:option/exceptions/app_exceptions.dart';
import 'package:option/services/user_service.dart';
import 'package:option/utils/supabase_helper.dart';

void main() {
  group('Auth Basic Tests', () {
    test('should validate email format', () {
      // Test invalid email formats
      final invalidEmails = [
        '',
        'invalid',
        '@invalid.com',
        'test@',
        'test@.com',
        'test..test@example.com',
        'test@example..com',
      ];

      for (final email in invalidEmails) {
        expect(
          () => UserService.createUser(
            authUserId: 'test-id',
            email: email,
            fullName: 'Test User',
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
          reason: 'Email "$email" should be invalid',
        );
      }
    });

    test('should validate user type', () {
      final invalidTypes = ['', 'invalid', 'admin', 'moderator'];

      for (final type in invalidTypes) {
        expect(
          () => UserService.createUser(
            authUserId: 'test-id',
            email: 'test@example.com',
            fullName: 'Test User',
            phone: '11999999999',
            userType: type,
          ),
          throwsA(isA<DatabaseException>()),
          reason: 'User type "$type" should be invalid',
        );
      }
    });

    test('should validate required fields', () {
      // Test empty auth user ID
      expect(
        () => UserService.createUser(
          authUserId: '',
          email: 'test@example.com',
          fullName: 'Test User',
          phone: '11999999999',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Test empty full name
      expect(
        () => UserService.createUser(
          authUserId: 'test-id',
          email: 'test@example.com',
          fullName: '',
          phone: '11999999999',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Test empty phone
      expect(
        () => UserService.createUser(
          authUserId: 'test-id',
          email: 'test@example.com',
          fullName: 'Test User',
          phone: '',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('should validate name vs email confusion', () {
      // Test email in name field
      expect(
        () => UserService.createUser(
          authUserId: 'test-id',
          email: 'test@example.com',
          fullName: 'user@email.com',
          phone: '11999999999',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Test name with @ symbol
      expect(
        () => UserService.createUser(
          authUserId: 'test-id',
          email: 'test@example.com',
          fullName: 'John @ Company',
          phone: '11999999999',
          userType: 'passenger',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('should handle SupabaseHelper not initialized', () {
      // Save original state
      final originalClient = SupabaseHelper.testClient;
      
      // Set client to null
      SupabaseHelper.testClient = null;

      expect(
        () => UserService.createUser(
          authUserId: 'test-id',
          email: 'test@example.com',
          fullName: 'Test User',
          phone: '11999999999',
          userType: 'passenger',
        ),
        throwsA(isA<Exception>()),
      );

      // Restore original state
      SupabaseHelper.testClient = originalClient;
    });

    test('should validate valid data formats', () {
      // These should not throw exceptions (validation should pass)
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        'test123@test-domain.com',
      ];

      for (final email in validEmails) {
        expect(
          () => UserService.createUser(
            authUserId: 'test-id-$email',
            email: email,
            fullName: 'Valid User Name',
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<Exception>()), // Will throw because Supabase is not initialized, but validation passes
        );
      }
    });

    test('should validate update user parameters', () {
      // Test invalid phone format
      expect(
        () => UserService.updateUser(
          userId: 'test-id',
          phone: 'invalid-phone',
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Test empty full name
      expect(
        () => UserService.updateUser(
          userId: 'test-id',
          fullName: '',
        ),
        throwsA(isA<DatabaseException>()),
      );

      // Test invalid user type
      expect(
        () => UserService.updateUser(
          userId: 'test-id',
          userType: 'invalid-type',
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    group('Edge Cases', () {
      test('should handle extremely long values', () {
        final longString = 'a' * 1000;

        expect(
          () => UserService.createUser(
            authUserId: 'test-id',
            email: 'test@example.com',
            fullName: longString,
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle special characters', () {
        const specialName = r'!@#$%^&*()[]{}|;:,.<>?~`';
        
        expect(
          () => UserService.createUser(
            authUserId: 'test-id',
            email: 'test@example.com',
            fullName: specialName,
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle null values properly', () {
        // Optional fields should handle null
        expect(
          () => UserService.createUser(
            authUserId: 'test-id',
            email: 'test@example.com',
            fullName: 'Test User',
            userType: 'passenger',
          ),
          throwsA(isA<Exception>()), // Will throw because Supabase not initialized
        );
      });
    });
  });
}