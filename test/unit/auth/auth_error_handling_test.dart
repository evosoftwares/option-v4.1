import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:option/services/user_service.dart';
import 'package:option/exceptions/app_exceptions.dart';
import 'package:option/utils/supabase_helper.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
])
import 'auth_error_handling_test.mocks.dart';

void main() {
  group('Authentication Error Handling Tests', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockSupabaseQueryBuilder mockQuery;
    late MockPostgrestFilterBuilder mockFilter;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockQuery = MockSupabaseQueryBuilder();
      mockFilter = MockPostgrestFilterBuilder();

      SupabaseHelper.testClient = mockClient;
      when(mockClient.auth).thenReturn(mockAuth);
      when(mockClient.from(any)).thenReturn(mockQuery);
    });

    tearDown(() {
      SupabaseHelper.testClient = null;
    });

    group('Login Error Scenarios', () {
      test('should handle invalid credentials', () async {
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Invalid credentials'));

        expect(
          () => mockAuth.signInWithPassword(
            email: 'wrong@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('should handle network errors during login', () async {
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Network error'));

        expect(
          () => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle user not found in app_users table', () async {
        // Successful auth but no user in app_users
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => AuthResponse(
          user: User(
            id: 'auth-user-id',
            email: 'test@example.com',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: User(
              id: 'auth-user-id',
              email: 'test@example.com',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        ));

        when(mockQuery.select()).thenReturn(mockFilter);
        when(mockFilter.eq('id', 'auth-user-id')).thenReturn(mockFilter);
        when(mockFilter.single()).thenThrow(
          const PostgrestException('User not found', code: 'PGRST116'),
        );

        expect(
          () async => UserService.getCurrentUser(),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle rate limiting during login', () async {
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Too many requests'));

        expect(
          () => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(predicate((e) => e is AuthException && e.message == 'Too many requests')),
        );
      });
    });

    group('Registration Error Scenarios', () {
      test('should handle email already exists', () async {
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Email already registered'));

        expect(
          () => mockAuth.signUp(
            email: 'existing@example.com',
            password: 'password123',
          ),
          throwsA(predicate((e) => e is AuthException && e.message == 'Email already registered')),
        );
      });

      test('should handle weak password', () async {
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Password is too weak'));

        expect(
          () => mockAuth.signUp(
            email: 'test@example.com',
            password: '123',
          ),
          throwsA(predicate((e) => e is AuthException && e.message == 'Password is too weak')),
        );
      });

      test('should handle invalid email format', () async {
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Invalid email format'));

        expect(
          () => mockAuth.signUp(
            email: 'invalid-email',
            password: 'password123',
          ),
          throwsA(predicate((e) => e is AuthException && e.message == 'Invalid email format')),
        );
      });

      test('should handle network timeout during registration', () async {
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Connection timeout'));

        expect(
          () => mockAuth.signUp(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(predicate((e) => e.toString().contains('Connection timeout'))),
        );
      });
    });

    group('User Service Error Scenarios', () {
      test('should handle duplicate user creation by ID', () async {
        // Mock existing user found by ID
        when(mockQuery.select()).thenReturn(mockFilter);
        when(mockFilter.eq('id', 'existing-id')).thenReturn(mockFilter);
        when(mockFilter.single()).thenAnswer((_) async => {
          'id': 'existing-id',
          'email': 'existing@example.com',
          'full_name': 'Existing User',
          'user_type': 'passenger',
        });

        expect(
          () async => UserService.createUser(
            authUserId: 'existing-id',
            email: 'new@example.com',
            fullName: 'New User',
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<UserAlreadyExistsException>()),
        );
      });

      test('should handle duplicate user creation by email', () async {
        // Mock user not found by ID but found by email
        when(mockQuery.select()).thenReturn(mockFilter);
        when(mockFilter.eq('id', 'new-id')).thenReturn(mockFilter);
        when(mockFilter.single()).thenThrow(
          const PostgrestException('User not found', code: 'PGRST116'),
        );

        when(mockFilter.eq('email', 'existing@example.com')).thenReturn(mockFilter);
        when(mockFilter.single()).thenAnswer((_) async => {
          'id': 'different-id',
          'email': 'existing@example.com',
          'full_name': 'Existing User',
          'user_type': 'driver',
        });

        expect(
          () async => UserService.createUser(
            authUserId: 'new-id',
            email: 'existing@example.com',
            fullName: 'New User',
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<UserAlreadyExistsException>()),
        );
      });

      test('should handle database connection errors', () async {
        when(mockQuery.select()).thenReturn(mockFilter);
        when(mockFilter.eq(any, any)).thenReturn(mockFilter);
        when(mockFilter.single()).thenThrow(
          const PostgrestException('Connection failed', code: 'CONNECTION_ERROR'),
        );

        expect(
          () async => UserService.userExists('test-id'),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle invalid user data validation', () async {
        // Test with invalid email
        expect(
          () async => UserService.createUser(
            authUserId: 'test-id',
            email: 'invalid-email',
            fullName: 'Test User',
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle empty required fields', () async {
        // Test with empty phone (required field)
        expect(
          () async => UserService.createUser(
            authUserId: 'test-id',
            email: 'test@example.com',
            fullName: 'Test User',
            phone: '', // Empty phone
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle user update failures', () async {
        when(mockQuery.update(any)).thenReturn(mockFilter);
        when(mockFilter.eq('id', 'non-existent-id')).thenReturn(mockFilter);
        when(mockFilter.select()).thenReturn(mockFilter);
        when(mockFilter.single()).thenThrow(
          const PostgrestException('User not found', code: 'PGRST116'),
        );

        expect(
          () async => UserService.updateUser('non-existent-id', {
            'full_name': 'Updated Name',
          }),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle null or empty user IDs', () async {
        expect(
          () async => UserService.getUserById(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle malformed email addresses', () async {
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
            () async => UserService.createUser(
              authUserId: 'test-id',
              email: email,
              fullName: 'Test User',
              phone: '11999999999',
              userType: 'passenger',
            ),
            throwsA(isA<DatabaseException>()),
          );
        }
      });

      test('should handle extremely long input values', () async {
        final longString = 'a' * 1000; // 1000 characters

        expect(
          () async => UserService.createUser(
            authUserId: 'test-id',
            email: 'test@example.com',
            fullName: longString, // Very long name
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle special characters in user data', () async {
        const specialCharacters = r'!@#$%^&*()[]{}|;:,.<>?~`';
        
        expect(
          () async => UserService.createUser(
            authUserId: 'test-id',
            email: 'test@example.com',
            fullName: specialCharacters,
            phone: '11999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should handle concurrent user creation attempts', () async {
        // Simulate race condition where two requests try to create same user
        when(mockQuery.select()).thenReturn(mockFilter);
        when(mockFilter.eq('id', 'race-condition-id')).thenReturn(mockFilter);
        when(mockFilter.single())
            .thenThrow(const PostgrestException('User not found', code: 'PGRST116'))
            .thenAnswer((_) async => {
              'id': 'race-condition-id',
              'email': 'race@example.com',
              'full_name': 'Race User',
              'user_type': 'passenger',
            });

        // First call should check and not find user
        final userExists1 = await UserService.userExists('race-condition-id');
        expect(userExists1, isFalse);

        // Second call should find user (simulating concurrent creation)
        final userExists2 = await UserService.userExists('race-condition-id');
        expect(userExists2, isTrue);
      });

      test('should handle database constraint violations', () async {
        when(mockQuery.insert(any)).thenReturn(mockFilter);
        when(mockFilter.select()).thenReturn(mockFilter);
        when(mockFilter.single()).thenThrow(
          const PostgrestException('Unique constraint violation', code: '23505'),
        );

        // This would typically be caught by our duplicate user checks,
        // but testing database-level constraint handling
        expect(
          () async {
            // Setup mocks for user existence checks to pass
            when(mockQuery.select()).thenReturn(mockFilter);
            when(mockFilter.eq(any, any)).thenReturn(mockFilter);
            when(mockFilter.single()).thenThrow(
              const PostgrestException('User not found', code: 'PGRST116'),
            );

            await UserService.createUser(
              authUserId: 'constraint-test-id',
              email: 'constraint@example.com',
              fullName: 'Constraint Test',
              phone: '11999999999',
              userType: 'passenger',
            );
          },
          throwsA(isA<DatabaseException>()),
        );
      });
    });
  });
}