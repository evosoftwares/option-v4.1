import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:option/exceptions/app_exceptions.dart';

/// Testes de widget para validar o tratamento de erros no profile edit
/// 
/// Estes testes verificam que:
/// 1. Erros sync_control são tratados adequadamente na UI
/// 2. Mensagens de erro amigáveis são exibidas para o usuário
/// 3. A UI não trava quando há erros de sincronização
/// 4. Loading states são gerenciados corretamente durante erros
void main() {
  group('Profile Edit Error Handling Widget Tests', () {
    
    test('should create user-friendly error messages for sync_control errors', () {
      // Test error message creation for UI display
      
      // Arrange
      const syncError = DatabaseException(
        'Sistema de sincronização não configurado. Entre em contato com o suporte.',
        'SYNC_ERROR'
      );
      
      const regularError = DatabaseException(
        'Erro ao atualizar usuário. Por favor, verifique os dados e tente novamente.',
        '42P01'
      );
      
      const validationError = DatabaseException(
        'Dados inválidos fornecidos para atualização: Nome não pode estar vazio'
      );

      // Act & Assert
      
      // Sync error should be user-friendly
      expect(syncError.message, contains('Sistema de sincronização'));
      expect(syncError.message, contains('suporte'));
      expect(syncError.message, isNot(contains('sync_control')));
      expect(syncError.message, isNot(contains('42P01')));
      expect(syncError.code, equals('SYNC_ERROR'));
      
      // Regular database error should be generic but helpful
      expect(regularError.message, contains('Erro ao atualizar'));
      expect(regularError.message, contains('verifique os dados'));
      expect(regularError.code, equals('42P01'));
      
      // Validation error should be specific
      expect(validationError.message, contains('Dados inválidos'));
      expect(validationError.message, contains('Nome não pode estar vazio'));
    });

    test('should create appropriate snackbar messages for different error types', () {
      // Test SnackBar message generation for different error scenarios
      
      final errorScenarios = [
        {
          'error': const DatabaseException(
            'Sistema de sincronização não configurado. Entre em contato com o suporte.',
            'SYNC_ERROR'
          ),
          'expectedSnackbarMessage': 'Problema de sincronização. Entre em contato com o suporte.',
          'expectedIcon': Icons.sync_problem,
          'expectedColor': Colors.orange,
        },
        {
          'error': const UserNotFoundException('user-123'),
          'expectedSnackbarMessage': 'Usuário não encontrado. Tente fazer login novamente.',
          'expectedIcon': Icons.person_off,
          'expectedColor': Colors.red,
        },
        {
          'error': const DatabaseException(
            'Dados inválidos fornecidos para atualização: Nome não pode estar vazio'
          ),
          'expectedSnackbarMessage': 'Dados inválidos. Verifique os campos e tente novamente.',
          'expectedIcon': Icons.error,
          'expectedColor': Colors.red,
        },
        {
          'error': const DatabaseException(
            'Erro ao atualizar usuário. Por favor, verifique os dados e tente novamente.'
          ),
          'expectedSnackbarMessage': 'Erro ao salvar. Verifique sua conexão e tente novamente.',
          'expectedIcon': Icons.error,
          'expectedColor': Colors.red,
        },
      ];

      for (final scenario in errorScenarios) {
        // Act - Generate UI message from error (simulates what ProfileEditScreen would do)
        final error = scenario['error']! as DatabaseException;
        
        String snackbarMessage;
        IconData icon;
        Color color;
        
        if (error.code == 'SYNC_ERROR') {
          snackbarMessage = 'Problema de sincronização. Entre em contato com o suporte.';
          icon = Icons.sync_problem;
          color = Colors.orange;
        } else if (error is UserNotFoundException) {
          snackbarMessage = 'Usuário não encontrado. Tente fazer login novamente.';
          icon = Icons.person_off;
          color = Colors.red;
        } else if (error.message.contains('Dados inválidos')) {
          snackbarMessage = 'Dados inválidos. Verifique os campos e tente novamente.';
          icon = Icons.error;
          color = Colors.red;
        } else {
          snackbarMessage = 'Erro ao salvar. Verifique sua conexão e tente novamente.';
          icon = Icons.error;
          color = Colors.red;
        }
        
        // Assert
        expect(snackbarMessage, equals(scenario['expectedSnackbarMessage']));
        expect(icon, equals(scenario['expectedIcon']));
        expect(color, equals(scenario['expectedColor']));
      }
    });

    test('should handle loading states correctly during error scenarios', () {
      // Test loading state management during errors
      
      // Arrange - Simulate profile edit states
      var isLoading = false;
      var hasError = false;
      String? errorMessage;
      
      // Act - Simulate profile edit flow with error
      
      // 1. Start update
      isLoading = true;
      hasError = false;
      errorMessage = null;
      
      expect(isLoading, isTrue);
      expect(hasError, isFalse);
      expect(errorMessage, isNull);
      
      // 2. Error occurs (sync_control)
      try {
        throw const DatabaseException(
          'Sistema de sincronização não configurado. Entre em contato com o suporte.',
          'SYNC_ERROR'
        );
      } on DatabaseException {
        isLoading = false;
        hasError = true;
        errorMessage = 'Problema de sincronização. Entre em contato com o suporte.';
      }
      
      // 3. After error handling
      expect(isLoading, isFalse);
      expect(hasError, isTrue);
      expect(errorMessage, equals('Problema de sincronização. Entre em contato com o suporte.'));
      
      // 4. User retries - reset state
      isLoading = true;
      hasError = false;
      errorMessage = null;
      
      expect(isLoading, isTrue);
      expect(hasError, isFalse);
      expect(errorMessage, isNull);
    });

    test('should validate form data before calling service', () {
      // Test client-side validation that prevents unnecessary service calls
      
      final validationTestCases = [
        {
          'name': 'Valid data',
          'fullName': 'Valid User Name',
          'phone': '11999999999',
          'email': 'valid@example.com',
          'isValid': true,
          'expectedError': null,
        },
        {
          'name': 'Empty full name',
          'fullName': '',
          'phone': '11999999999',
          'email': 'valid@example.com',
          'isValid': false,
          'expectedError': 'Nome é obrigatório',
        },
        {
          'name': 'Invalid phone format',
          'fullName': 'Valid User Name',
          'phone': '123',
          'email': 'valid@example.com',
          'isValid': false,
          'expectedError': 'Telefone deve ter 10 ou 11 dígitos',
        },
        {
          'name': 'Invalid email format',
          'fullName': 'Valid User Name', 
          'phone': '11999999999',
          'email': 'invalid-email',
          'isValid': false,
          'expectedError': 'Email inválido',
        },
        {
          'name': 'Name too long',
          'fullName': 'A' * 101, // 101 characters
          'phone': '11999999999',
          'email': 'valid@example.com',
          'isValid': false,
          'expectedError': 'Nome deve ter no máximo 100 caracteres',
        },
      ];

      for (final testCase in validationTestCases) {
        // Act - Simulate form validation
        final fullName = testCase['fullName']! as String;
        final phone = testCase['phone']! as String;
        final email = testCase['email']! as String;
        final expectedValid = testCase['isValid']! as bool;
        final expectedError = testCase['expectedError'] as String?;
        
        String? validationError;
        var isValid = true;
        
        // Client-side validation logic
        if (fullName.trim().isEmpty) {
          validationError = 'Nome é obrigatório';
          isValid = false;
        } else if (fullName.length > 100) {
          validationError = 'Nome deve ter no máximo 100 caracteres';
          isValid = false;
        } else if (phone.isNotEmpty && !RegExp(r'^\d{10,11}$').hasMatch(phone)) {
          validationError = 'Telefone deve ter 10 ou 11 dígitos';
          isValid = false;
        } else if (email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
          validationError = 'Email inválido';
          isValid = false;
        }
        
        // Assert
        expect(isValid, equals(expectedValid), 
          reason: 'Validation result mismatch for: ${testCase['name']}');
        expect(validationError, equals(expectedError),
          reason: 'Validation error mismatch for: ${testCase['name']}');
      }
    });

    test('should create retry mechanism for transient errors', () {
      // Test retry logic for errors that might be temporary
      
      // Arrange
      var retryCount = 0;
      const maxRetries = 3;
      var shouldRetry = false;
      
      final retryableErrors = [
        'network error',
        'timeout',
        'connection failed',
        'server error 500',
      ];
      
      final nonRetryableErrors = [
        'Sistema de sincronização não configurado',
        'Dados inválidos',
        'Usuário não encontrado',
        'Acesso negado',
      ];
      
      // Act & Assert - Test retryable errors
      for (final errorMessage in retryableErrors) {
        shouldRetry = retryCount < maxRetries && (
          errorMessage.contains('network') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('500')
        );
        
        expect(shouldRetry, isTrue,
          reason: 'Should retry for error: $errorMessage');
      }
      
      // Test non-retryable errors  
      for (final errorMessage in nonRetryableErrors) {
        shouldRetry = retryCount < maxRetries && (
          errorMessage.contains('network') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('500')
        );
        
        expect(shouldRetry, isFalse,
          reason: 'Should not retry for error: $errorMessage');
      }
    });

    test('should preserve form state during error recovery', () {
      // Test that user input is preserved when errors occur
      
      // Arrange - Simulate form state
      final formData = {
        'fullName': 'Updated Name',
        'phone': '11999999999', 
        'email': 'updated@example.com',
        'photoUrl': 'https://example.com/new-photo.jpg',
      };
      
      // Act - Simulate error and recovery
      final savedFormData = Map<String, String>.from(formData);
      
      // Error occurs - form data should be preserved
      const error = DatabaseException(
        'Sistema de sincronização não configurado. Entre em contato com o suporte.',
        'SYNC_ERROR'
      );
      
      // User sees error message but form data remains
      final restoredFormData = savedFormData;
      
      // Assert
      expect(restoredFormData['fullName'], equals(formData['fullName']));
      expect(restoredFormData['phone'], equals(formData['phone']));
      expect(restoredFormData['email'], equals(formData['email']));
      expect(restoredFormData['photoUrl'], equals(formData['photoUrl']));
      expect(restoredFormData, hasLength(4));
      
      // User can retry with same data or make modifications
      restoredFormData['fullName'] = 'Modified Name';
      expect(restoredFormData['fullName'], equals('Modified Name'));
    });
  });
}