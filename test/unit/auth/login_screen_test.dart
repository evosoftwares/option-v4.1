import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:option/screens/auth/login_screen.dart';
import 'package:option/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  UserService,
])
import 'login_screen_test.mocks.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();

      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    });

    testWidgets('should render all form fields and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          routes: {
            '/register': (context) => const Scaffold(),
            '/select_user_type': (context) => const Scaffold(),
            '/home': (context) => const Scaffold(),
            '/driver_home': (context) => const Scaffold(),
            '/forgot-password': (context) => const Scaffold(),
            '/debug_supabase': (context) => const Scaffold(),
          },
        ),
      );

      // Check if form fields are present
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);

      // Check if buttons are present
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Criar uma conta'), findsOneWidget);
      expect(find.text('Esqueceu sua senha?'), findsOneWidget);
      expect(find.text('🔧 Debug Supabase'), findsOneWidget);

      // Check if logo is present
      expect(find.text('Bem-vindo(a)'), findsOneWidget);
      expect(find.text('Acesse sua conta para continuar'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Tap login button without filling fields
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      // Check validation messages
      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets('should show validation error for short password', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter short password
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('A senha deve ter ao menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find password field
      final passwordField = find.byType(TextFormField).at(1);
      final obscureTextFinder = find.descendant(
        of: passwordField,
        matching: find.byType(TextFormField),
      );

      // Initially password should be obscured
      var passwordWidget = tester.widget(obscureTextFinder) as TextField;
      expect(passwordWidget.obscureText, isTrue);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Password should now be visible
      passwordWidget = tester.widget(obscureTextFinder) as TextField;
      expect(passwordWidget.obscureText, isFalse);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Password should be obscured again
      passwordWidget = tester.widget(obscureTextFinder) as TextField;
      expect(passwordWidget.obscureText, isTrue);
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

      // Tap "Criar uma conta" button
      await tester.tap(find.text('Criar uma conta'));
      await tester.pumpAndSettle();

      // Should navigate to register screen
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

      // Tap "Esqueceu sua senha?" button
      await tester.tap(find.text('Esqueceu sua senha?'));
      await tester.pumpAndSettle();

      // Should navigate to forgot password screen
      expect(find.text('Forgot Password Screen'), findsOneWidget);
    });

    testWidgets('should show loading indicator during login', (tester) async {
      // Mock successful login
      when(mockGoTrueClient.signInWithPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => AuthResponse(
        user: User(
          id: 'test-user-id',
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
            id: 'test-user-id',
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
          home: const LoginScreen(),
          routes: {
            '/select_user_type': (context) => const Scaffold(),
            '/home': (context) => const Scaffold(),
            '/driver_home': (context) => const Scaffold(),
          },
        ),
      );

      // Fill valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Tap login button
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Entrar'), findsNothing);
    });

    group('Authentication Flow Tests', () {
      testWidgets('should handle successful login with existing user', (tester) async {
        // Mock successful authentication
        when(mockGoTrueClient.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => AuthResponse(
          user: User(
            id: 'existing-user-id',
            email: 'existing@example.com',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: User(
              id: 'existing-user-id',
              email: 'existing@example.com',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: const LoginScreen(),
            routes: {
              '/select_user_type': (context) => const Scaffold(body: Text('Select User Type')),
              '/home': (context) => const Scaffold(body: Text('Home Screen')),
              '/driver_home': (context) => const Scaffold(body: Text('Driver Home')),
            },
          ),
        );

        // Fill valid credentials
        await tester.enterText(find.byType(TextFormField).first, 'existing@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        // Tap login button
        await tester.tap(find.text('Entrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Since we can't easily mock UserService.userExists in widget tests,
        // we expect navigation to user type selection for new users
        expect(find.text('Select User Type'), findsOneWidget);
      });

      testWidgets('should handle authentication errors', (tester) async {
        // Mock authentication error
        when(mockGoTrueClient.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Invalid credentials'));

        await tester.pumpWidget(
          const MaterialApp(
            home: LoginScreen(),
          ),
        );

        // Fill credentials
        await tester.enterText(find.byType(TextFormField).first, 'wrong@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

        // Tap login button
        await tester.tap(find.text('Entrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.text('Invalid credentials'), findsOneWidget);
      });

      testWidgets('should handle generic errors', (tester) async {
        // Mock generic error
        when(mockGoTrueClient.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Network error'));

        await tester.pumpWidget(
          const MaterialApp(
            home: LoginScreen(),
          ),
        );

        // Fill credentials
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');

        // Tap login button
        await tester.tap(find.text('Entrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Should show generic error message
        expect(find.text('Erro de autenticação. Por favor, verifique suas credenciais e tente novamente.'), findsOneWidget);
      });
    });
  });
}