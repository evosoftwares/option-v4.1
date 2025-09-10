import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:option/exceptions/app_exceptions.dart';
import 'package:option/services/user_service.dart';
import 'package:option/utils/supabase_helper.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}

void main() {
  group('UserService', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      
      // Setup SupabaseHelper mock
      SupabaseHelper.markInitialized();
    });

    tearDown(() {
      reset(mockSupabaseClient);
      reset(mockQueryBuilder);
      reset(mockFilterBuilder);
    });

    group('createUser', () {
      test('should create user successfully with valid data', () async {
        // Arrange
        const authUserId = 'auth-123';
        const email = 'test@example.com';
        const fullName = 'Test User';
        const phone = '+5511999999999';
        const userType = 'passenger';
        
        final expectedUserData = {
          'id': authUserId,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'user_type': userType,
          'created_at': DateTime.now().toIso8601String(),
        };

        when(() => mockSupabaseClient.from('app_users')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', authUserId)).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);
        
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        final result = await UserService.createUser(
          authUserId: authUserId,
          email: email,
          fullName: fullName,
          phone: phone,
          userType: userType,
        );

        // Assert
        expect(result, isA<User>());
        expect(result.id, equals(authUserId));
        expect(result.email, equals(email));
        expect(result.fullName, equals(fullName));
        expect(result.phone, equals(phone));
        expect(result.userType, equals(userType));
        
        verify(() => mockSupabaseClient.from('app_users')).called(2);
        verify(() => mockQueryBuilder.insert(any())).called(1);
      });

      test('should throw DatabaseException when phone is null', () async {
        // Act & Assert
        expect(
          () => UserService.createUser(
            authUserId: 'auth-123',
            email: 'test@example.com',
            fullName: 'Test User',
            phone: null,
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()
              .having((e) => e.message, 'message', contains('Telefone é obrigatório'))),
        );
      });

      test('should throw DatabaseException when phone is empty', () async {
        // Act & Assert
        expect(
          () => UserService.createUser(
            authUserId: 'auth-123',
            email: 'test@example.com',
            fullName: 'Test User',
            phone: '',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()
              .having((e) => e.message, 'message', contains('Telefone é obrigatório'))),
        );
      });

      test('should throw UserAlreadyExistsException when user already exists', () async {
        // Arrange
        const authUserId = 'auth-123';
        const email = 'test@example.com';
        
        final existingUserData = {
          'id': authUserId,
          'email': email,
          'full_name': 'Existing User',
          'phone': '+5511999999999',
          'user_type': 'passenger',
          'created_at': DateTime.now().toIso8601String(),
        };

        when(() => mockSupabaseClient.from('app_users')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', authUserId)).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => existingUserData);

        // Act & Assert
        expect(
          () => UserService.createUser(
            authUserId: authUserId,
            email: email,
            fullName: 'Test User',
            phone: '+5511888888888',
            userType: 'passenger',
          ),
          throwsA(isA<UserAlreadyExistsException>()
              .having((e) => e.message, 'message', contains(email))),
        );
      });

      test('should validate email format', () async {
        // Act & Assert
        expect(
          () => UserService.createUser(
            authUserId: 'auth-123',
            email: 'invalid-email',
            fullName: 'Test User',
            phone: '+5511999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()
              .having((e) => e.message, 'message', contains('Dados inválidos'))),
        );
      });

      test('should validate phone format', () async {
        // Act & Assert
        expect(
          () => UserService.createUser(
            authUserId: 'auth-123',
            email: 'test@example.com',
            fullName: 'Test User',
            phone: 'invalid-phone',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()
              .having((e) => e.message, 'message', contains('Dados inválidos'))),
        );
      });

      test('should validate user type', () async {
        // Act & Assert
        expect(
          () => UserService.createUser(
            authUserId: 'auth-123',
            email: 'test@example.com',
            fullName: 'Test User',
            phone: '+5511999999999',
            userType: 'invalid-type',
          ),
          throwsA(isA<DatabaseException>()
              .having((e) => e.message, 'message', contains('Dados inválidos'))),
        );
      });

      test('should handle database insertion errors', () async {
        // Arrange
        const authUserId = 'auth-123';
        
        when(() => mockSupabaseClient.from('app_users')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', authUserId)).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);
        
        when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'Database error', code: '23505')
        );

        // Act & Assert
        expect(
          () => UserService.createUser(
            authUserId: authUserId,
            email: 'test@example.com',
            fullName: 'Test User',
            phone: '+5511999999999',
            userType: 'passenger',
          ),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('getUserById', () {
      test('should return user when found', () async {
        // Arrange
        const userId = 'user-123';
        final userData = {
          'id': userId,
          'email': 'test@example.com',
          'full_name': 'Test User',
          'phone': '+5511999999999',
          'user_type': 'passenger',
          'created_at': DateTime.now().toIso8601String(),
        };

        when(() => mockSupabaseClient.from('app_users')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => userData);

        // Act
        final result = await UserService.getUserById(userId);

        // Assert
        expect(result, isA<User>());
        expect(result!.id, equals(userId));
        expect(result.email, equals('test@example.com'));
        verify(() => mockSupabaseClient.from('app_users')).called(1);
      });

      test('should return null when user not found', () async {
        // Arrange
        const userId = 'nonexistent-user';

        when(() => mockSupabaseClient.from('app_users')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

        // Act
        final result = await UserService.getUserById(userId);

        // Assert
        expect(result, isNull);
        verify(() => mockSupabaseClient.from('app_users')).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return current authenticated user', () async {
        // Arrange
        const userId = 'current-user-123';
        final userData = {
          'id': userId,
          'email': 'current@example.com',
          'full_name': 'Current User',
          'phone': '+5511999999999',
          'user_type': 'passenger',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Mock auth user
        final mockAuthUser = MockUser();
        when(() => mockAuthUser.id).thenReturn(userId);
        when(() => mockSupabaseClient.auth).thenReturn(MockGoTrueClient());
        when(() => mockSupabaseClient.auth.currentUser).thenReturn(mockAuthUser);

        when(() => mockSupabaseClient.from('app_users')).thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => userData);

        // Act
        final result = await UserService.getCurrentUser();

        // Assert
        expect(result, isA<User>());
        expect(result!.id, equals(userId));
      });

      test('should return null when no authenticated user', () async {
        // Arrange
        when(() => mockSupabaseClient.auth).thenReturn(MockGoTrueClient());
        when(() => mockSupabaseClient.auth.currentUser).thenReturn(null);

        // Act
        final result = await UserService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });
  });
}

// Additional mocks for auth
class MockUser extends Mock implements User {}
class MockGoTrueClient extends Mock implements GoTrueClient {}