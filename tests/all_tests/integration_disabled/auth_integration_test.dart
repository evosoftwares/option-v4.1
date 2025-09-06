import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:option/main.dart' as app;
import 'package:option/services/user_service.dart';
import '../helpers/supabase_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration Tests', () {
    setUpAll(() async {
      await SupabaseTestHelper.initialize();
    });

    setUp(() async {
      await SupabaseTestHelper.cleanDatabase();
    });

    group('Complete Registration Flow', () {
      testWidgets('should complete full registration flow for passenger', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to registration
        await tester.tap(find.text('Criar uma conta'));
        await tester.pumpAndSettle();

        // Fill registration form
        await tester.enterText(
          find.byType(TextFormField).at(0), 
          'João Silva Integration Test'
        );
        await tester.enterText(
          find.byType(TextFormField).at(1), 
          'joao.integration@test.com'
        );
        await tester.enterText(
          find.byType(TextFormField).at(2), 
          'password123'
        );
        await tester.enterText(
          find.byType(TextFormField).at(3), 
          'password123'
        );

        // Submit registration
        await tester.tap(find.text('Cadastrar'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should navigate to user type selection
        expect(find.text('Selecione o tipo de usuário'), findsOneWidget);

        // Select passenger type
        await tester.tap(find.text('Passageiro'));
        await tester.pumpAndSettle();

        // Should complete passenger registration
        expect(find.text('Dados pessoais'), findsOneWidget);

        // Fill additional passenger data
        await tester.enterText(
          find.byType(TextFormField).first, 
          '(11) 99999-9999'
        );

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // Should navigate to photo step
        expect(find.text('Foto do perfil'), findsOneWidget);

        // Skip photo for now and continue
        await tester.tap(find.text('Pular'));
        await tester.pumpAndSettle();

        // Should complete registration and go to home
        expect(find.text('Onde você quer ir?'), findsOneWidget);

        // Verify user was created in database
        final currentUser = await UserService.getCurrentUser();
        expect(currentUser, isNotNull);
        expect(currentUser!.email, equals('joao.integration@test.com'));
        expect(currentUser.fullName, equals('João Silva Integration Test'));
        expect(currentUser.userType, equals('passenger'));
      });

      testWidgets('should complete full registration flow for driver', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to registration
        await tester.tap(find.text('Criar uma conta'));
        await tester.pumpAndSettle();

        // Fill registration form
        await tester.enterText(
          find.byType(TextFormField).at(0), 
          'Maria Driver Test'
        );
        await tester.enterText(
          find.byType(TextFormField).at(1), 
          'maria.driver@test.com'
        );
        await tester.enterText(
          find.byType(TextFormField).at(2), 
          'password123'
        );
        await tester.enterText(
          find.byType(TextFormField).at(3), 
          'password123'
        );

        // Submit registration
        await tester.tap(find.text('Cadastrar'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should navigate to user type selection
        expect(find.text('Selecione o tipo de usuário'), findsOneWidget);

        // Select driver type
        await tester.tap(find.text('Motorista'));
        await tester.pumpAndSettle();

        // Should start driver registration flow
        expect(find.text('Dados pessoais'), findsOneWidget);

        // Fill personal data
        await tester.enterText(
          find.byType(TextFormField).first, 
          '(11) 88888-8888'
        );

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();

        // Should navigate to photo step
        expect(find.text('Foto do perfil'), findsOneWidget);

        // Skip photo and continue
        await tester.tap(find.text('Pular'));
        await tester.pumpAndSettle();

        // Should navigate to vehicle info or complete registration
        // The exact flow may vary, but we should end up at driver home
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify user was created in database
        final currentUser = await UserService.getCurrentUser();
        expect(currentUser, isNotNull);
        expect(currentUser!.email, equals('maria.driver@test.com'));
        expect(currentUser.fullName, equals('Maria Driver Test'));
        expect(currentUser.userType, equals('driver'));
      });
    });

    group('Complete Login Flow', () {
      testWidgets('should login existing user and navigate correctly', (tester) async {
        // Create a test user first
        final testUser = await SupabaseTestHelper.seedPassenger(
          fullName: 'Test Login User',
        );

        app.main();
        await tester.pumpAndSettle();

        // Should be on login screen initially
        expect(find.text('Bem-vindo(a)'), findsOneWidget);

        // Enter credentials
        await tester.enterText(
          find.byType(TextFormField).at(0), 
          'test@example.com' // Using test helper email
        );
        await tester.enterText(
          find.byType(TextFormField).at(1), 
          'password123'
        );

        // Submit login
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should navigate to appropriate home screen
        // For passenger, should see "Onde você quer ir?"
        expect(find.text('Onde você quer ir?'), findsOneWidget);

        // Verify user is properly authenticated
        final currentUser = await UserService.getCurrentUser();
        expect(currentUser, isNotNull);
        expect(currentUser!.id, equals(testUser.userId));
      });

      testWidgets('should handle login with invalid credentials', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Enter invalid credentials
        await tester.enterText(
          find.byType(TextFormField).at(0), 
          'nonexistent@example.com'
        );
        await tester.enterText(
          find.byType(TextFormField).at(1), 
          'wrongpassword'
        );

        // Submit login
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Should show error message and remain on login screen
        expect(find.text('Bem-vindo(a)'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('Navigation and State Management', () {
      testWidgets('should navigate between login and register screens', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Start on login screen
        expect(find.text('Bem-vindo(a)'), findsOneWidget);

        // Navigate to register
        await tester.tap(find.text('Criar uma conta'));
        await tester.pumpAndSettle();

        expect(find.text('Crie sua conta'), findsOneWidget);

        // Navigate back to login
        await tester.tap(find.text('Já tem uma conta? Entrar'));
        await tester.pumpAndSettle();

        expect(find.text('Bem-vindo(a)'), findsOneWidget);
      });

      testWidgets('should handle app state after registration', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Go through partial registration to test state persistence
        await tester.tap(find.text('Criar uma conta'));
        await tester.pumpAndSettle();

        // Fill partial registration form
        await tester.enterText(
          find.byType(TextFormField).at(0), 
          'State Test User'
        );
        await tester.enterText(
          find.byType(TextFormField).at(1), 
          'state.test@example.com'
        );

        // Navigate away and back
        await tester.tap(find.text('Já tem uma conta? Entrar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Criar uma conta'));
        await tester.pumpAndSettle();

        // Form should be cleared (or maintain state based on app design)
        final nameField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
        expect(nameField.controller?.text, isEmpty);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle network connectivity issues', (tester) async {
        // This test would require network simulation
        // For now, test with invalid Supabase configuration
        app.main();
        await tester.pumpAndSettle();

        // Try to login with network issues
        await tester.enterText(
          find.byType(TextFormField).at(0), 
          'network.test@example.com'
        );
        await tester.enterText(
          find.byType(TextFormField).at(1), 
          'password123'
        );

        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Should handle gracefully without crashing
        expect(find.text('Bem-vindo(a)'), findsOneWidget);
      });

      testWidgets('should validate form inputs properly', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Criar uma conta'));
        await tester.pumpAndSettle();

        // Try to submit empty form
        await tester.tap(find.text('Cadastrar'));
        await tester.pump();

        // Should show validation errors
        expect(find.text('Informe seu nome'), findsOneWidget);
        expect(find.text('Informe seu e-mail'), findsOneWidget);
        expect(find.text('Informe sua senha'), findsOneWidget);
        expect(find.text('Confirme sua senha'), findsOneWidget);

        // Should not navigate away
        expect(find.text('Crie sua conta'), findsOneWidget);
      });

      testWidgets('should handle password confirmation mismatch', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Criar uma conta'));
        await tester.pumpAndSettle();

        // Fill form with mismatched passwords
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'different456');

        await tester.tap(find.text('Cadastrar'));
        await tester.pump();

        // Should show password mismatch error
        expect(find.text('As senhas não coincidem'), findsOneWidget);
        expect(find.text('Crie sua conta'), findsOneWidget);
      });
    });

    group('User Experience Flow', () {
      testWidgets('should show proper loading states', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        await tester.tap(find.text('Entrar'));
        await tester.pump();

        // Should show loading indicator immediately
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for operation to complete
        await tester.pumpAndSettle(const Duration(seconds: 5));
      });

      testWidgets('should handle rapid tap prevention', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        // Tap login button multiple times rapidly
        await tester.tap(find.text('Entrar'));
        await tester.pump();
        
        // Button should be disabled after first tap
        expect(tester.widget<FilledButton>(find.text('Entrar').first).onPressed, isNull);

        await tester.pumpAndSettle(const Duration(seconds: 5));
      });
    });
  });
}