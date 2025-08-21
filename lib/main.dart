import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'controllers/stepper_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/user_type_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stepper/stepper_demo_screen.dart';
import 'screens/stepper/user_registration_stepper.dart';
import 'theme/app_theme.dart';
import 'screens/profile/profile_edit_screen.dart';
import 'screens/menu/driver_menu_screen.dart';
import 'screens/menu/user_menu_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/trip/trip_options_screen.dart';
import 'screens/trip/driver_selection_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/trips/trip_history_screen.dart';
import 'screens/saved_places_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = AppConfig.supabaseUrl;
  const supabaseAnonKey = AppConfig.supabaseAnonKey;

  print('🔧 Iniciando aplicativo...');
  print('🌐 Supabase URL: ${supabaseUrl.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');
  print('🔑 Supabase Key: ${supabaseAnonKey.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      print('✅ Supabase inicializado com sucesso!');
    } catch (e) {
      print('❌ Erro ao inicializar Supabase: $e');
    }
  } else {
    print('⚠️ Supabase não inicializado - variáveis de ambiente ausentes');
    print('📋 Certifique-se de que SUPABASE_URL e SUPABASE_ANON_KEY estão configuradas');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<StepperController>(
      create: (_) => StepperController(),
      child: MaterialApp(
        title: 'Option',
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
          '/driver_home': (context) => const DriverHomeScreen(),
          '/user_menu': (context) => const UserMenuScreen(),
          '/wallet': (context) => const WalletScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/trip_history': (context) => const TripHistoryScreen(),
          '/saved_places': (context) => const SavedPlacesScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case TripOptionsScreen.routeName:
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => TripOptionsScreen.fromArgs(args),
                settings: settings,
              );
            case DriverSelectionScreen.routeName:
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => DriverSelectionScreen.fromArgs(args),
                settings: settings,
              );
          }
          return null;
        },
      ),
    );
}