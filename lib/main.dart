import 'package:flutter/material.dart';
import 'package:uber_clone/theme/app_theme.dart';
import 'package:uber_clone/screens/home_screen.dart';
import 'package:uber_clone/screens/auth/login_screen.dart';
import 'package:uber_clone/screens/auth/register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uber_clone/screens/auth/user_type_screen.dart';
import 'package:uber_clone/screens/stepper/stepper_demo_screen.dart';
import 'package:uber_clone/screens/stepper/user_registration_stepper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://qlbwacmavngtonauxnte.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYndhY21hdm5ndG9uYXV4bnRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDg3MTYzMzIsImV4cCI6MjAyNDI5MjMzMn0.IPFL2f8dslKK-jU2lYGJJwHcL0ZqOVmTIiTQK5QzF2E';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber Clone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/login',
      routes: {
        '/select_user_type': (context) => const UserTypeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/stepper_demo': (context) => const StepperDemoScreen(),
        '/registration_stepper': (context) => const UserRegistrationStepper(),
      },
    );
  }
}