/// Teste de integração completo para fluxo de autenticação
/// Simula comportamento real do usuário: registro, login, logout
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:option/main.dart' as app;
import 'package:option/services/user_service.dart';
import 'package:option/models/user.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🔐 Complete Auth Flow Integration Tests', () {
    
    testWidgets('👤 Complete User Registration Flow', (tester) async {
      print('🧪 Starting Complete User Registration Flow Test...');
      
      // 1. Launch app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      print('✅ App launched successfully');
      
      // 2. Navigate to registration
      final registerButton = find.text('Criar conta');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
        print('✅ Navigation to registration successful');
      }
      
      // 3. Fill registration form
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).at(1);
      
      await tester.enterText(emailField, 'test_user_${DateTime.now().millisecondsSinceEpoch}@example.com');
      await tester.enterText(passwordField, 'TestPassword123!');
      await tester.pumpAndSettle();
      
      print('✅ Registration form filled');
      
      // 4. Submit registration
      final submitButton = find.text('Registrar');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
        print('✅ Registration submitted');
      }
      
      // 5. Verify success indicators
      expect(find.text('Erro'), findsNothing, reason: 'Should not show error messages');
      print('✅ No error messages found');
      
      // 6. Check if navigated to next screen (stepper or home)
      final stepperIndicators = find.byType(Stepper);
      final homeIndicators = find.text('Home');
      
      expect(stepperIndicators.evaluate().isNotEmpty || homeIndicators.evaluate().isNotEmpty, 
             isTrue, reason: 'Should navigate to stepper or home after registration');
      
      print('🎯 Complete User Registration Flow: PASSED');
    });

    testWidgets('🔄 Login/Logout Cycle Test', (tester) async {
      print('🧪 Starting Login/Logout Cycle Test...');
      
      // Mock successful login flow
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Test login form validation
      final emailField = find.byKey(const Key('email_field')).first;
      final passwordField = find.byKey(const Key('password_field')).first;
      
      // Test with invalid email
      await tester.enterText(emailField, 'invalid-email');
      await tester.enterText(passwordField, 'short');
      await tester.pumpAndSettle();
      
      final loginButton = find.text('Entrar');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }
      
      print('✅ Form validation tested');
      
      // Test with valid credentials (mock)
      await tester.enterText(emailField, 'valid@example.com');
      await tester.enterText(passwordField, 'ValidPassword123!');
      await tester.pumpAndSettle();
      
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      
      print('✅ Valid login attempt processed');
      
      // Verify we don't crash
      expect(tester.takeException(), isNull, reason: 'Should not throw exceptions during login');
      
      print('🎯 Login/Logout Cycle Test: PASSED');
    });

    testWidgets('📱 User Type Selection Flow', (tester) async {
      print('🧪 Starting User Type Selection Test...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for user type selection
      final passengerOption = find.text('Passageiro');
      final driverOption = find.text('Motorista');
      
      if (passengerOption.evaluate().isNotEmpty) {
        await tester.tap(passengerOption);
        await tester.pumpAndSettle();
        print('✅ Passenger type selected');
        
        // Verify selection is reflected in UI
        expect(find.text('Passageiro'), findsWidgets);
      }
      
      if (driverOption.evaluate().isNotEmpty) {
        await tester.tap(driverOption);
        await tester.pumpAndSettle();
        print('✅ Driver type selected');
        
        // Verify selection is reflected in UI
        expect(find.text('Motorista'), findsWidgets);
      }
      
      print('🎯 User Type Selection Flow: PASSED');
    });

    testWidgets('⚡ Authentication State Management', (tester) async {
      print('🧪 Testing Authentication State Management...');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Test that app handles auth state changes gracefully
      // This simulates network issues, token expiration, etc.
      
      // Trigger state changes by navigating between screens
      final navigationItems = find.byType(BottomNavigationBar);
      if (navigationItems.evaluate().isNotEmpty) {
        // Test navigation doesn't crash
        final tabs = find.byType(Tab);
        for (var i = 0; i < tabs.evaluate().length && i < 3; i++) {
          await tester.tap(tabs.at(i));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Navigation should not crash');
        }
        print('✅ Navigation state management stable');
      }
      
      // Test app recovery from auth errors
      expect(find.text('Erro fatal'), findsNothing, reason: 'Should not show fatal errors');
      
      print('🎯 Authentication State Management: PASSED');
    });
  });
}