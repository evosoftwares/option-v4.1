import 'package:flutter_test/flutter_test.dart';

import 'package:option/validators/user_data_validator.dart';
import 'package:option/exceptions/validation_exception.dart';

void main() {
  group('User Registration Validation Tests', () {
    group('UserDataValidator', () {
      test('should validate correct user data', () {
        // Act
        final result = UserDataValidator.validateUserData(
          fullName: 'João Silva',
          email: 'joao@example.com',
          userType: 'passenger',
          phone: '+5511999999999',
        );

        // Assert
        expect(result['full_name'], equals('João Silva'));
        expect(result['email'], equals('joao@example.com'));
        expect(result['user_type'], equals('passenger'));
        expect(result['phone'], equals('+5511999999999'));
      });

      test('should throw ValidationException for invalid email', () {
        expect(
          () => UserDataValidator.validateUserData(
            fullName: 'João Silva',
            email: 'invalid-email',
            userType: 'passenger',
            phone: '+5511999999999',
          ),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message', contains('Email'))),
        );
      });

      test('should throw ValidationException for empty name', () {
        expect(
          () => UserDataValidator.validateUserData(
            fullName: '',
            email: 'joao@example.com',
            userType: 'passenger',
            phone: '+5511999999999',
          ),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message', contains('nome'))),
        );
      });

      test('should throw ValidationException for invalid phone', () {
        expect(
          () => UserDataValidator.validateUserData(
            fullName: 'João Silva',
            email: 'joao@example.com',
            userType: 'passenger',
            phone: 'invalid-phone',
          ),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message', contains('Telefone deve ter'))),
        );
      });

      test('should throw ValidationException for invalid user type', () {
        expect(
          () => UserDataValidator.validateUserData(
            fullName: 'João Silva',
            email: 'joao@example.com',
            userType: 'invalid-type',
            phone: '+5511999999999',
          ),
          throwsA(isA<ValidationException>()
              .having((e) => e.message, 'message', contains('Tipo de usuário inválido'))),
        );
      });

      test('should accept driver user type', () {
        final result = UserDataValidator.validateUserData(
          fullName: 'João Motorista',
          email: 'joao.motorista@example.com',
          userType: 'driver',
          phone: '+5511999999999',
        );

        expect(result['user_type'], equals('driver'));
      });

      test('should trim whitespace from inputs', () {
        final result = UserDataValidator.validateUserData(
          fullName: '  João Silva  ',
          email: '  joao@example.com  ',
          userType: 'passenger',
          phone: '  +5511999999999  ',
        );

        expect(result['full_name'], equals('João Silva'));
        expect(result['email'], equals('joao@example.com'));
        expect(result['phone'], equals('+5511999999999'));
      });

      test('should validate Brazilian phone numbers', () {
        final validPhones = [
          '+5511999999999',
          '+55(11)99999-9999',
          '(11)99999-9999',
          '11999999999',
          '11 99999-9999',
        ];

        for (final phone in validPhones) {
          expect(
            () => UserDataValidator.validateUserData(
              fullName: 'Test User',
              email: 'test@example.com',
              userType: 'passenger',
              phone: phone,
            ),
            returnsNormally,
            reason: 'Phone $phone should be valid',
          );
        }
      });

      test('should reject invalid Brazilian phone numbers', () {
        final invalidPhones = [
          '123456789',
          'not-a-phone',
          '+55119999999999', // Too many digits
        ];

        for (final phone in invalidPhones) {
          expect(
            () => UserDataValidator.validateUserData(
              fullName: 'Test User',
              email: 'test@example.com',
              userType: 'passenger',
              phone: phone,
            ),
            throwsA(isA<ValidationException>()),
            reason: 'Phone $phone should be invalid',
          );
        }
      });

      test('should validate email formats', () {
        final validEmails = [
          'user@example.com',
          'test.user@example.com.br',
          'user+tag@example.co.uk',
          'user123@example-domain.com',
        ];

        for (final email in validEmails) {
          expect(
            () => UserDataValidator.validateUserData(
              fullName: 'Test User',
              email: email,
              userType: 'passenger',
              phone: '+5511999999999',
            ),
            returnsNormally,
            reason: 'Email $email should be valid',
          );
        }
      });

      test('should reject invalid email formats', () {
        final invalidEmails = [
          'invalid-email',
          '@example.com',
          'user@',
          'user@.com',
          '',
          'user space@example.com',
        ];

        for (final email in invalidEmails) {
          expect(
            () => UserDataValidator.validateUserData(
              fullName: 'Test User',
              email: email,
              userType: 'passenger',
              phone: '+5511999999999',
            ),
            throwsA(isA<ValidationException>()),
            reason: 'Email $email should be invalid',
          );
        }
      });

      test('should handle null photoUrl', () {
        final result = UserDataValidator.validateUserData(
          fullName: 'Test User',
          email: 'test@example.com',
          userType: 'passenger',
          phone: '+5511999999999',
          photoUrl: null,
        );

        expect(result['photo_url'], isNull);
      });

      test('should validate photoUrl when provided', () {
        final result = UserDataValidator.validateUserData(
          fullName: 'Test User',
          email: 'test@example.com',
          userType: 'passenger',
          phone: '+5511999999999',
          photoUrl: 'https://example.com/photo.jpg',
        );

        expect(result['photo_url'], equals('https://example.com/photo.jpg'));
      });
    });
  });
}