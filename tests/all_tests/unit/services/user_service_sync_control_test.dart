import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:option/exceptions/app_exceptions.dart';
import 'package:option/models/user.dart';
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
import 'user_service_sync_control_test.mocks.dart';

void main() {
  group('UserService - Sync Control Error Handling', () {
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
      when(mockSupabaseClient.from('app_users')).thenReturn(mockQueryBuilder);
    });

    tearDown(() {
      SupabaseHelper.testClient = null;
    });

    group('updateUser - sync_control error handling', () {
      test('should handle sync_control table missing error gracefully', () async {
        // Arrange
        const userId = 'test-user-id';
        const updatedName = 'Updated Name';
        
        final updateData = {
          'full_name': updatedName,
          'updated_at': anything,
        };

        // Mock the sync_control error (42P01 - relation does not exist)
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(
            message: 'relation "sync_control" does not exist',
            code: '42P01',
          ),
        );

        // Act & Assert
        expect(
          () async => UserService.updateUser(
            userId: userId,
            fullName: updatedName,
          ),
          throwsA(
            allOf(
              isA<DatabaseException>(),
              predicate((e) =>
                e.message.contains('Sistema de sincronização não configurado') &&
                e.code == 'SYNC_ERROR'),
            ),
          ),
        );

        // Verify the correct methods were called
        verify(mockSupabaseClient.from('app_users')).called(1);
        verify(mockQueryBuilder.update(argThat(containsPair('full_name', updatedName)))).called(1);
      });

      test('should handle sync_control error with different message variations', () async {
        // Arrange
        const userId = 'test-user-id';
        const updatedPhone = '11999999999';

        // Test different sync_control error messages
        final errorMessages = [
          'relation "sync_control" does not exist',
          'table "sync_control" does not exist',
          'ERROR: relation "sync_control" does not exist',
          'sync_control table not found',
        ];

        for (final errorMessage in errorMessages) {
          // Reset mocks for each iteration
          reset(mockQueryBuilder);
          reset(mockFilterBuilder);
          
          when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
          when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
          when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
          when(mockFilterBuilder.single()).thenThrow(
            PostgrestException(
              message: errorMessage,
              code: '42P01',
            ),
          );

          // Act & Assert
          expect(
            () async => UserService.updateUser(
              userId: userId,
              phone: updatedPhone,
            ),
            throwsA(
              allOf(
                isA<DatabaseException>(),
                predicate((e) =>
                  e.message.contains('Sistema de sincronização não configurado') &&
                  e.code == 'SYNC_ERROR'),
              ),
            ),
            reason: 'Should handle error message: $errorMessage',
          );
        }
      });

      test('should handle other 42P01 errors that are not sync_control related', () async {
        // Arrange
        const userId = 'test-user-id';
        const updatedName = 'Updated Name';

        // Mock a different 42P01 error (not sync_control related)
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(
            message: 'relation "some_other_table" does not exist',
            code: '42P01',
          ),
        );

        // Act & Assert
        expect(
          () async => UserService.updateUser(
            userId: userId,
            fullName: updatedName,
          ),
          throwsA(
            allOf(
              isA<DatabaseException>(),
              predicate((e) =>
                e.message.contains('Erro ao atualizar usuário') &&
                e.code == '42P01'),
            ),
          ),
        );
      });

      test('should successfully update user when no sync_control error occurs', () async {
        // Arrange
        const userId = 'test-user-id';
        const updatedName = 'Updated Name';
        const updatedPhone = '11888888888';
        
        final expectedUserData = {
          'id': userId,
          'email': 'test@example.com',
          'full_name': updatedName,
          'phone': updatedPhone,
          'user_type': 'passenger',
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        final result = await UserService.updateUser(
          userId: userId,
          fullName: updatedName,
          phone: updatedPhone,
        );

        // Assert
        expect(result, isA<User>());
        expect(result.id, equals(userId));
        expect(result.fullName, equals(updatedName));
        expect(result.phone, equals(updatedPhone));
        expect(result.email, equals('test@example.com'));

        // Verify interactions
        verify(mockSupabaseClient.from('app_users')).called(1);
        verify(mockQueryBuilder.update(argThat(allOf(
          containsPair('full_name', updatedName),
          containsPair('phone', updatedPhone),
          hasLength(greaterThan(2)), // Should include updated_at
        )))).called(1);
        verify(mockFilterBuilder.eq('id', userId)).called(1);
        verify(mockFilterBuilder.select()).called(1);
        verify(mockFilterBuilder.single()).called(1);
      });

      test('should handle user not found error (PGRST116)', () async {
        // Arrange
        const userId = 'non-existing-user-id';
        const updatedName = 'Updated Name';

        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(
            message: 'No rows returned',
            code: 'PGRST116',
          ),
        );

        // Act & Assert
        expect(
          () async => UserService.updateUser(
            userId: userId,
            fullName: updatedName,
          ),
          throwsA(isA<UserNotFoundException>()),
        );
      });

      test('should validate input data before update', () async {
        // Arrange - Test invalid input data
        const userId = 'test-user-id';
        
        // Test cases for invalid data that should throw ValidationException -> DatabaseException
        final invalidInputs = [
          {
            'description': 'empty full name',
            'fullName': '',
            'phone': null,
          },
          {
            'description': 'invalid phone format',
            'fullName': 'Valid Name',
            'phone': 'invalid-phone',
          },
          {
            'description': 'invalid user type',
            'fullName': 'Valid Name',
            'phone': '11999999999',
            'userType': 'invalid_type',
          },
        ];

        for (final testCase in invalidInputs) {
          // Act & Assert
          expect(
            () async => UserService.updateUser(
              userId: userId,
              fullName: testCase['fullName'],
              phone: testCase['phone'],
              userType: testCase['userType'],
            ),
            throwsA(
              allOf(
                isA<DatabaseException>(),
                predicate((e) =>
                  e.message.contains('Dados inválidos fornecidos para atualização')),
              ),
            ),
            reason: 'Should reject ${testCase['description']}',
          );
        }
      });

      test('should include updated_at timestamp in all updates', () async {
        // Arrange
        const userId = 'test-user-id';
        const updatedName = 'Updated Name';
        
        final expectedUserData = {
          'id': userId,
          'email': 'test@example.com',
          'full_name': updatedName,
          'phone': '11999999999',
          'user_type': 'passenger',
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        await UserService.updateUser(
          userId: userId,
          fullName: updatedName,
        );

        // Assert - Verify that updated_at was included in the update data
        verify(mockQueryBuilder.update(argThat(
          allOf(
            containsPair('full_name', updatedName),
            predicate<Map<String, dynamic>>((data) => 
              data.containsKey('updated_at') && 
              data['updated_at'] is String &&
              data['updated_at'].isNotEmpty),
          ),
        ))).called(1);
      });
    });

    group('updateUserType - sync_control error handling', () {
      test('should handle sync_control error in updateUserType', () async {
        // Arrange
        const userId = 'test-user-id';
        const newUserType = 'driver';

        // Mock the sync_control error
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(
          const PostgrestException(
            message: 'relation "sync_control" does not exist',
            code: '42P01',
          ),
        );

        // Act & Assert
        expect(
          () async => UserService.updateUserType(userId, newUserType),
          throwsA(
            allOf(
              isA<DatabaseException>(),
              predicate((e) =>
                e.message.contains('Erro ao atualizar tipo de usuário') &&
                e.code == '42P01'),
            ),
          ),
        );
      });

      test('should successfully update user type when no sync_control error', () async {
        // Arrange
        const userId = 'test-user-id';
        const newUserType = 'driver';
        
        final expectedUserData = {
          'id': userId,
          'email': 'test@example.com',
          'full_name': 'Test User',
          'phone': '11999999999',
          'user_type': newUserType,
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', userId)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => expectedUserData);

        // Act
        final result = await UserService.updateUserType(userId, newUserType);

        // Assert
        expect(result, isA<User>());
        expect(result.userType, equals(newUserType));

        // Verify the update included both user_type and updated_at
        verify(mockQueryBuilder.update(argThat(allOf(
          containsPair('user_type', newUserType),
          containsKey('updated_at'),
        )))).called(1);
      });
    });
  });
}