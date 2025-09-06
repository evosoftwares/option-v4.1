import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:option/screens/auth/register_screen.dart';

void main() {
  group('RegisterScreen Widget Tests (No Mocks)', () {
    testWidgets('should render registration form correctly', (tester) async {
      // Set a larger screen size for tests
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login')),
            '/select_user_type': (context) => const Scaffold(body: Text('User Type')),
          },
        ),
      );

      // Check UI elements
      expect(find.text('Crie sua conta'), findsOneWidget);
      expect(find.text('Preencha os dados abaixo para se cadastrar'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);
      expect(find.text('Cadastrar'), findsOneWidget);
      expect(find.text('Já tem uma conta? Entrar'), findsOneWidget);

      // Check form fields
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets('should show validation errors for empty fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Try to submit without filling fields
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();

      expect(find.text('Informe seu nome'), findsOneWidget);
      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
      expect(find.text('Confirme sua senha'), findsOneWidget);
    });

    testWidgets('should validate name field properly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Test short name
      await tester.enterText(find.byType(TextFormField).at(0), 'Jo');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('O nome deve ter ao menos 3 caracteres'), findsOneWidget);
    });

    testWidgets('should detect email in name field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Test email in name field
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('Você digitou um e-mail no campo de nome. Por favor, digite apenas seu nome completo.'), findsOneWidget);
    });

    testWidgets('should detect @ symbol in name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Test name with @ symbol
      await tester.enterText(find.byType(TextFormField).at(0), 'João @ Silva');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('O nome não deve conter @ ou domínios de email. Digite apenas seu nome completo.'), findsOneWidget);
    });

    testWidgets('should validate email field properly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Test invalid email format
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid@');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('E-mail inválido. Use o formato: exemplo@email.com'), findsOneWidget);
    });

    testWidgets('should detect name in email field', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Test name in email field
      await tester.enterText(find.byType(TextFormField).at(1), 'João Silva');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('Você digitou um nome no campo de e-mail. Por favor, digite um e-mail válido.'), findsOneWidget);
    });

    testWidgets('should validate password field properly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Test short password
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('should validate password confirmation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Enter different passwords
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different123');
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();
      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets('should toggle password visibility for both fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Initially both passwords should be obscured (visibility icons)
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tap first password visibility toggle
      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();

      // First should show visibility_off, second still visibility
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap second password visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Both should show visibility_off
      expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('should navigate to login screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login Screen')),
          },
        ),
      );

      await tester.tap(find.text('Já tem uma conta? Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('should show terms and privacy notice', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      expect(
        find.text('Ao se cadastrar, você aceita nossos Termos de Uso e Política de Privacidade.'),
        findsOneWidget,
      );
    });

    testWidgets('should handle multiple validation errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Fill with invalid data for multiple fields
      await tester.enterText(find.byType(TextFormField).at(0), 'X'); // Too short
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid@'); // Bad email format
      await tester.enterText(find.byType(TextFormField).at(2), '12'); // Too short password
      await tester.enterText(find.byType(TextFormField).at(3), '34'); // Different short password

      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();

      // Should show multiple errors
      expect(find.text('O nome deve ter ao menos 3 caracteres'), findsOneWidget);
      expect(find.text('E-mail inválido. Use o formato: exemplo@email.com'), findsOneWidget);
      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsOneWidget);
      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets('should maintain form state during interactions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Enter data in all fields
      await tester.enterText(find.byType(TextFormField).at(0), 'João Silva');
      await tester.enterText(find.byType(TextFormField).at(1), 'joao@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      await tester.pump();

      // Verify all text fields have the expected values
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('joao@example.com'), findsOneWidget);
      
      // Check that form fields contain the entered text
      final nameField = tester.widget<TextFormField>(find.byType(TextFormField).at(0));
      final emailField = tester.widget<TextFormField>(find.byType(TextFormField).at(1));
      expect(nameField.controller?.text, 'João Silva');
      expect(emailField.controller?.text, 'joao@example.com');
    });

    testWidgets('should handle valid form submission attempt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );

      // Fill form with completely valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'João Silva');
      await tester.enterText(find.byType(TextFormField).at(1), 'joao@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      // Try to submit - should pass validation but fail due to no Supabase
      await tester.tap(find.text('Cadastrar'));
      await tester.pumpAndSettle();

      // No validation errors should be shown
      expect(find.text('Informe seu nome'), findsNothing);
      expect(find.text('Informe seu e-mail'), findsNothing);
      expect(find.text('Informe sua senha'), findsNothing);
      expect(find.text('Confirme sua senha'), findsNothing);
      expect(find.text('O nome deve ter ao menos 3 caracteres'), findsNothing);
      expect(find.text('E-mail inválido. Use o formato: exemplo@email.com'), findsNothing);
      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsNothing);
      expect(find.text('As senhas não coincidem'), findsNothing);
    });
  });
}