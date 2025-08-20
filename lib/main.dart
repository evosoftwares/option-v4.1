import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uber_clone/controllers/stepper_controller.dart';
import 'package:uber_clone/screens/auth/login_screen.dart';
import 'package:uber_clone/screens/auth/register_screen.dart';
import 'package:uber_clone/screens/auth/user_type_screen.dart';
import 'package:uber_clone/screens/auth/forgot_password_screen.dart';
import 'package:uber_clone/screens/home_screen.dart';
import 'package:uber_clone/screens/stepper/stepper_demo_screen.dart';
import 'package:uber_clone/screens/stepper/user_registration_stepper.dart';
import 'package:uber_clone/theme/app_theme.dart';
import 'package:uber_clone/screens/profile/profile_edit_screen.dart';
import 'package:uber_clone/screens/menu/driver_menu_screen.dart';
import 'package:uber_clone/screens/menu/user_menu_screen.dart';
import 'package:uber_clone/screens/wallet/wallet_screen.dart';

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
    return ChangeNotifierProvider(
      create: (_) => StepperController(),
      child: MaterialApp(
        title: 'OPTION',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/login',
        routes: {
          '/select_user_type': (context) => const UserTypeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/stepper_demo': (context) => const StepperDemoScreen(),
          '/registration_stepper': (context) => const UserRegistrationStepper(),
          '/profile_edit': (context) => const ProfileEditScreen(),
          '/driver_menu': (context) => const DriverMenuScreen(),
          '/user_menu': (context) => const UserMenuScreen(),
          '/wallet': (context) => const WalletScreen(),
        },
      ),
    );
  }
}