import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:option/screens/auth/register_screen.dart';
import 'package:option/utils/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
])
import 'register_screen_test.mocks.dart';

void main() {
  group('RegisterScreen Widget Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();

      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      SupabaseHelper.testClient = mockSupabaseClient;
    });

    tearDown(() {
      SupabaseHelper.testClient = null;
    });

    testWidgets('should render all form fields and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
          routes: {
            '/login': (context) => const Scaffold(),
            '/select_user_type': (context) => const Scaffold(),
          },
        ),
      );

      // Check if form fields are present
      expect(find.byType(TextFormField), findsNWidgets(4)); // Name, email, password, confirm
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);

      // Check if buttons are present
      expect(find.text('Cadastrar'), findsOneWidget);
      expect(find.text('Já tem uma conta? Entrar'), findsOneWidget);

      // Check if headers are present
      expect(find.text('Crie sua conta'), findsOneWidget);
      expect(find.text('Preencha os dados abaixo para se cadastrar'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Tap register button without filling fields
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();

      // Check validation messages
      expect(find.text('Informe seu nome'), findsOneWidget);
      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
      expect(find.text('Confirme sua senha'), findsOneWidget);
    });

    testWidgets('should validate name field properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Test short name
      await tester.enterText(find.byType(TextFormField).first, 'Jo');
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
      expect(find.text('O nome deve ter ao menos 3 caracteres'), findsOneWidget);

      // Test email in name field
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
      expect(find.text('Você digitou um e-mail no campo de nome. Por favor, digite apenas seu nome completo.'), findsOneWidget);

      // Test name with @ symbol
      await tester.enterText(find.byType(TextFormField).first, 'João @ Silva');
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
      expect(find.text('O nome não deve conter @ ou domínios de email. Digite apenas seu nome completo.'), findsOneWidget);
    });

    testWidgets('should validate email field properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Test invalid email
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
      expect(find.text('E-mail inválido. Use o formato: exemplo@email.com'), findsOneWidget);

      // Test name in email field
      await tester.enterText(find.byType(TextFormField).at(1), 'João Silva');
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
      expect(find.text('Você digitou um nome no campo de e-mail. Por favor, digite um e-mail válido.'), findsOneWidget);
    });

    testWidgets('should validate password fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Test short password
      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsOneWidget);

      // Test password confirmation mismatch
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'different123');
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();
      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Test password field visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));

      // Test confirm password field visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(1));
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

      // Tap "Já tem uma conta? Entrar" button
      await tester.tap(find.text('Já tem uma conta? Entrar'));
      await tester.pumpAndSettle();

      // Should navigate to login screen
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('should show loading indicator during registration', (tester) async {
      // Mock successful registration
      when(mockGoTrueClient.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => AuthResponse(
        user: User(
          id: 'new-user-id',
          email: 'test@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
        session: Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: User(
            id: 'new-user-id',
            email: 'test@example.com',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: const RegisterScreen(),
          routes: {
            '/select_user_type': (context) => const Scaffold(),
          },
        ),
      );

      // Fill valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      // Tap register button
      await tester.tap(find.text('Cadastrar'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cadastrar'), findsNothing);
    });

    group('Registration Flow Tests', () {
      testWidgets('should handle successful registration with session', (tester) async {
        // Mock successful registration with session
        when(mockGoTrueClient.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => AuthResponse(
          user: User(
            id: 'new-user-id',
            email: 'test@example.com',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: User(
              id: 'new-user-id',
              email: 'test@example.com',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: const RegisterScreen(),
            routes: {
              '/select_user_type': (context) => const Scaffold(body: Text('Select User Type')),
            },
          ),
        );

        // Fill valid data
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        // Tap register button
        await tester.tap(find.text('Cadastrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Should navigate to user type selection
        expect(find.text('Select User Type'), findsOneWidget);
      });

      testWidgets('should handle registration requiring email confirmation', (tester) async {
        // Mock registration without session (email confirmation required)
        when(mockGoTrueClient.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => AuthResponse(
          user: User(
            id: 'new-user-id',
            email: 'test@example.com',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: const RegisterScreen(),
            routes: {
              '/login': (context) => const Scaffold(body: Text('Login Screen')),
            },
          ),
        );

        // Fill valid data
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        // Tap register button
        await tester.tap(find.text('Cadastrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Should show confirmation message and navigate to login
        expect(find.text('Verifique seu e-mail para confirmar a conta.'), findsOneWidget);
        expect(find.text('Login Screen'), findsOneWidget);
      });

      testWidgets('should handle authentication errors', (tester) async {
        // Mock authentication error
        when(mockGoTrueClient.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Email already exists'));

        await tester.pumpWidget(
          const MaterialApp(
            home: RegisterScreen(),
          ),
        );

        // Fill data
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'existing@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        // Tap register button
        await tester.tap(find.text('Cadastrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.text('Erro de autenticação: Email already exists'), findsOneWidget);
      });

      testWidgets('should handle generic errors', (tester) async {
        // Mock generic error
        when(mockGoTrueClient.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Network error'));

        await tester.pumpWidget(
          const MaterialApp(
            home: RegisterScreen(),
          ),
        );

        // Fill data
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        // Tap register button
        await tester.tap(find.text('Cadastrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Should show generic error message
        expect(find.text('Erro ao criar conta: Exception: Network error'), findsOneWidget);
      });

      testWidgets('should handle SupabaseHelper unavailable', (tester) async {
        // Set client to null to simulate unavailability
        SupabaseHelper.testClient = null;

        await tester.pumpWidget(
          const MaterialApp(
            home: RegisterScreen(),
          ),
        );

        // Fill valid data
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');

        // Tap register button
        await tester.tap(find.text('Cadastrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Should show service unavailable message
        expect(find.text('Serviço indisponível. Tente novamente.'), findsOneWidget);
      });
    });

    group('Form Validation Integration', () {
      testWidgets('should validate all fields together', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: RegisterScreen(),
          ),
        );

        // Fill valid name and email, invalid passwords
        await tester.enterText(find.byType(TextFormField).at(0), 'Valid Name');
        await tester.enterText(find.byType(TextFormField).at(1), 'valid@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), '123'); // Short password
        await tester.enterText(find.byType(TextFormField).at(3), '456'); // Different short password

        await tester.tap(find.text('Cadastrar'));
        await tester.pump();

        // Should show password validation errors
        expect(find.text('A senha deve ter ao menos 6 caracteres'), findsOneWidget);
        expect(find.text('As senhas não coincidem'), findsOneWidget);
      });

      testWidgets('should prevent submission with invalid data', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: RegisterScreen(),
          ),
        );

        // Try to submit with empty form
        await tester.tap(find.text('Cadastrar'));
        await tester.pump();

        // Loading indicator should not appear
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Validation errors should be shown
        expect(find.text('Informe seu nome'), findsOneWidget);
        expect(find.text('Informe seu e-mail'), findsOneWidget);
        expect(find.text('Informe sua senha'), findsOneWidget);
        expect(find.text('Confirme sua senha'), findsOneWidget);
      });
    });
  });
}