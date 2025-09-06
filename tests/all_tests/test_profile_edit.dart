import 'package:flutter_test/flutter_test.dart';
import 'lib/validators/user_data_validator.dart';
import 'lib/utils/phone_validator.dart';

void main() {
  group('Profile Edit Validation Tests', () {
    test('UserDataValidator should validate full name correctly', () {
      // Test valid full name
      expect(
        () => UserDataValidator.validateAndSanitizeFullName('João Silva'),
        returnsNormally,
      );
      
      // Test empty full name
      expect(
        () => UserDataValidator.validateAndSanitizeFullName(''),
        throwsException,
      );
      
      // Test too short full name
      expect(
        () => UserDataValidator.validateAndSanitizeFullName('A'),
        throwsException,
      );
      
      print('✅ Full name validation tests passed');
    });
    
    test('PhoneValidator should validate phone numbers correctly', () {
      // Test valid phone numbers
      expect(PhoneValidator.validate('11999887766'), isNull);
      expect(PhoneValidator.validate('(11) 99988-7766'), isNull);
      
      // Test invalid phone numbers
      expect(PhoneValidator.validate('123'), isNotNull);
      expect(PhoneValidator.validate(''), isNotNull);
      expect(PhoneValidator.validate('abc'), isNotNull);
      
      print('✅ Phone validation tests passed');
    });
    
    test('UserDataValidator should validate phone correctly', () {
      // Test valid phone (optional field)
      expect(
        () => UserDataValidator.validatePhone('11999887766'),
        returnsNormally,
      );
      
      // Test null phone (should be allowed)
      expect(
        () => UserDataValidator.validatePhone(null),
        returnsNormally,
      );
      
      // Test empty phone (should be allowed)
      expect(
        () => UserDataValidator.validatePhone(''),
        returnsNormally,
      );
      
      // Test invalid phone format
      expect(
        () => UserDataValidator.validatePhone('123'),
        throwsException,
      );
      
      print('✅ UserDataValidator phone tests passed');
    });
    
    test('UserDataValidator should validate user data completely', () {
      // Test valid user data
      final validData = UserDataValidator.validateUserData(
        fullName: 'João Silva',
        email: 'joao@email.com',
        userType: 'passenger',
        phone: '11999887766',
      );
      
      expect(validData['full_name'], equals('João Silva'));
      expect(validData['email'], equals('joao@email.com'));
      expect(validData['user_type'], equals('passenger'));
      expect(validData['phone'], equals('11999887766'));
      
      print('✅ Complete user data validation passed');
    });
  });
}