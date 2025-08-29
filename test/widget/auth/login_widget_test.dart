import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:option/screens/auth/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests (No Mocks)', () {
    testWidgets('should render login form correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/register': (context) => const Scaffold(body: Text('Register')),
            '/forgot-password': (context) => const Scaffold(body: Text('Forgot Password')),
            '/debug_supabase': (context) => const Scaffold(body: Text('Debug')),
          },
        ),
      );

      // Check UI elements
      expect(find.text('Bem-vindo(a)'), findsOneWidget);
      expect(find.text('Acesse sua conta para continuar'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Criar uma conta'), findsOneWidget);
      expect(find.text('Esqueceu sua senha?'), findsOneWidget);
      expect(find.text('🔧 Debug Supabase'), findsOneWidget);

      // Check form fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Try to submit without filling fields
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
    });

    testWidgets('should validate email format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets('should validate password length', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Enter short password
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Initially password should be obscured (visibility icon)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Tap to show password
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now should show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Back to visibility icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
    });

    testWidgets('should navigate to register screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/register': (context) => const Scaffold(body: Text('Register Screen')),
          },
        ),
      );

      await tester.tap(find.text('Criar uma conta'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('should navigate to forgot password screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/forgot-password': (context) => const Scaffold(body: Text('Forgot Password Screen')),
          },
        ),
      );

      await tester.tap(find.text('Esqueceu sua senha?'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password Screen'), findsOneWidget);
    });

    testWidgets('should navigate to debug screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/debug_supabase': (context) => const Scaffold(body: Text('Debug Screen')),
          },
        ),
      );

      await tester.tap(find.text('🔧 Debug Supabase'));
      await tester.pumpAndSettle();

      expect(find.text('Debug Screen'), findsOneWidget);
    });

    testWidgets('should handle form validation properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Fill with valid email but invalid password
      await tester.enterText(find.byType(TextFormField).first, 'valid@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), '12'); // Too short

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      // Should only show password error
      expect(find.text('Informe seu e-mail'), findsNothing);
      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('should enable/disable login button correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      final loginButton = find.byType(FilledButton);
      
      // Button should be enabled initially
      expect(tester.widget<FilledButton>(loginButton).onPressed, isNotNull);

      // Fill form with valid data
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      
      // Button should still be enabled
      expect(tester.widget<FilledButton>(loginButton).onPressed, isNotNull);
    });

    testWidgets('should maintain form state during interactions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Enter some text
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Toggle password visibility
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Text should still be there
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('should handle keyboard actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );

      // Fill fields
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Submit via keyboard (Enter key simulation via onFieldSubmitted)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Form validation should have run
      expect(find.text('E-mail inválido'), findsNothing);
      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsNothing);
    });
  });
}