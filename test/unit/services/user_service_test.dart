import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:option/exceptions/app_exceptions.dart';
import 'package:option/services/user_service.dart';
import 'package:option/utils/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
])
import 'user_service_test.mocks.dart';

void main() {
  group('UserService', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();

      // Setup SupabaseHelper mock
      SupabaseHelper.testClient = mockSupabaseClient;

      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
    });

    group('createUser', () {
      test('should create user successfully with valid data', () async {
        // Arrange
        const authUserId = 'test-user-id';
        const email = 'test@example.com';
        const fullName = 'Test User';
        const phone = '11999999999';
        const userType = 'passenger';

        // Mock successful user check (user doesn't exist)
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'User not found', code: 'PGRST116')
        );

        // Mock successful user creation
        final expectedUserData = {
          'id': authUserId,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'user_type': userType,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        final result = await UserService.createUser(
          authUserId: authUserId,
          email: email,
          fullName: fullName,
          phone: phone,
          userType: userType,
        );

        // Assert
        expect(result.id, equals(authUserId));
        expect(result.email, equals(email));
        expect(result.fullName, equals(fullName));
        expect(result.phone, equals(phone));
        expect(result.userType, equals(userType));
        expect(result.status, equals('active'));

        // Verify interactions
        verify(mockSupabaseClient.from('app_users')).called(greaterThan(0));
        verify(mockQueryBuilder.insert(any)).called(1);
      });

      test('should throw UserAlreadyExistsException when user already exists by ID', () async {
        // Arrange
        const authUserId = 'existing-user-id';
        const email = 'test@example.com';
        const fullName = 'Test User';
        const phone = '11999999999';
        const userType = 'passenger';

        // Mock existing user found by ID
        final existingUserData = {
          'id': authUserId,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'user_type': userType,
          'status': 'active',
        };

        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', authUserId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => existingUserData);

        // Act & Assert
        expect(
          () async => UserService.createUser(
            authUserId: authUserId,
            email: email,
            fullName: fullName,
            phone: phone,
            userType: userType,
          ),
          throwsA(isA<UserAlreadyExistsException>()),
        );
      });

      test('should throw UserAlreadyExistsException when user already exists by email', () async {
        // Arrange
        const authUserId = 'new-user-id';
        const email = 'existing@example.com';
        const fullName = 'Test User';
        const phone = '11999999999';
        const userType = 'passenger';

        // Mock user not found by ID
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', authUserId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'User not found', code: 'PGRST116')
        );

        // Mock existing user found by email
        when(mockFilterBuilder.eq('email', email)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => {
          'id': 'different-user-id',
          'email': email,
          'full_name': 'Existing User',
          'phone': '11888888888',
          'user_type': 'driver',
          'status': 'active',
        });

        // Act & Assert
        expect(
          () async => UserService.createUser(
            authUserId: authUserId,
            email: email,
            fullName: fullName,
            phone: phone,
            userType: userType,
          ),
          throwsA(isA<UserAlreadyExistsException>()),
        );
      });

      test('should throw DatabaseException when phone is required but empty', () async {
        // Arrange
        const authUserId = 'test-user-id';
        const email = 'test@example.com';
        const fullName = 'Test User';
        const userType = 'passenger';

        // Act & Assert
        expect(
          () async => UserService.createUser(
            authUserId: authUserId,
            email: email,
            fullName: fullName,
            phone: '', // Empty phone
            userType: userType,
          ),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('should throw DatabaseException when validation fails', () async {
        // Arrange
        const authUserId = 'test-user-id';
        const email = 'invalid-email'; // Invalid email format
        const fullName = 'Test User';
        const phone = '11999999999';
        const userType = 'passenger';

        // Act & Assert
        expect(
          () async => UserService.createUser(
            authUserId: authUserId,
            email: email,
            fullName: fullName,
            phone: phone,
            userType: userType,
          ),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return current user when authenticated', () async {
        // Arrange
        const userId = 'current-user-id';
        final mockUser = User(
          id: userId,
          email: 'current@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        final expectedUserData = {
          'id': userId,
          'email': 'current@example.com',
          'full_name': 'Current User',
          'phone': '11999999999',
          'user_type': 'passenger',
          'status': 'active',
        };

        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        final result = await UserService.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(userId));
        expect(result.email, equals('current@example.com'));
        expect(result.fullName, equals('Current User'));
      });

      test('should return null when no user is authenticated', () async {
        // Arrange
        when(mockGoTrueClient.currentUser).thenReturn(null);

        // Act
        final result = await UserService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('should throw DatabaseException when user data not found in app_users', () async {
        // Arrange
        const userId = 'orphaned-user-id';
        final mockUser = User(
          id: userId,
          email: 'orphaned@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );

        when(mockGoTrueClient.currentUser).thenReturn(mockUser);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'User not found', code: 'PGRST116')
        );

        // Act & Assert
        expect(
          () async => UserService.getCurrentUser(),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    group('userExists', () {
      test('should return true when user exists', () async {
        // Arrange
        const userId = 'existing-user-id';

        when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => {'id': userId});

        // Act
        final result = await UserService.userExists(userId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when user does not exist', () async {
        // Arrange
        const userId = 'non-existing-user-id';

        when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'User not found', code: 'PGRST116')
        );

        // Act
        final result = await UserService.userExists(userId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getUserById', () {
      test('should return user when found', () async {
        // Arrange
        const userId = 'test-user-id';
        final expectedUserData = {
          'id': userId,
          'email': 'test@example.com',
          'full_name': 'Test User',
          'phone': '11999999999',
          'user_type': 'passenger',
          'status': 'active',
        };

        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        final result = await UserService.getUserById(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(userId));
        expect(result.email, equals('test@example.com'));
        expect(result.fullName, equals('Test User'));
      });

      test('should return null when user not found', () async {
        // Arrange
        const userId = 'non-existing-user-id';

        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'User not found', code: 'PGRST116')
        );

        // Act
        final result = await UserService.getUserById(userId);

        // Assert
        expect(result, isNull);
      });
    });

    group('getUserByEmail', () {
      test('should return user when found by email', () async {
        // Arrange
        const email = 'test@example.com';
        final expectedUserData = {
          'id': 'test-user-id',
          'email': email,
          'full_name': 'Test User',
          'phone': '11999999999',
          'user_type': 'passenger',
          'status': 'active',
        };

        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('email', email)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        final result = await UserService.getUserByEmail(email);

        // Assert
        expect(result, isNotNull);
        expect(result!.email, equals(email));
        expect(result.fullName, equals('Test User'));
      });

      test('should return null when user not found by email', () async {
        // Arrange
        const email = 'nonexistent@example.com';

        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('email', email)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'User not found', code: 'PGRST116')
        );

        // Act
        final result = await UserService.getUserByEmail(email);

        // Assert
        expect(result, isNull);
      });
    });

    group('updateUser', () {
      test('should update user successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        final updateData = {
          'full_name': 'Updated Name',
          'phone': '11888888888',
        };

        final updatedUserData = {
          'id': userId,
          'email': 'test@example.com',
          'full_name': 'Updated Name',
          'phone': '11888888888',
          'user_type': 'passenger',
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockQueryBuilder.update(updateData)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => updatedUserData);

        // Act
        final result = await UserService.updateUser(
          userId: userId,
          fullName: updateData['full_name'],
          phone: updateData['phone'],
        );

        // Assert
        expect(result.id, equals(userId));
        expect(result.fullName, equals('Updated Name'));
        expect(result.phone, equals('11888888888'));

        // Verify interactions
        verify(mockQueryBuilder.update(updateData)).called(1);
        verify(mockFilterBuilder.eq('id', userId)).called(1);
      });

      test('should throw DatabaseException when update fails', () async {
        // Arrange
        const userId = 'non-existing-user-id';
        final updateData = {
          'full_name': 'Updated Name',
        };

        when(mockQueryBuilder.update(updateData)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(message: 'User not found', code: 'PGRST116')
        );

        // Act & Assert
        expect(
          () async => UserService.updateUser(
            userId: userId,
            fullName: updateData['full_name'],
          ),
          throwsA(isA<DatabaseException>()),
        );
      });
    });

    tearDown(() {
      SupabaseHelper.testClient = null;
    });
  });
}