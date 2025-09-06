import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'controllers/stepper_controller.dart';
import 'screens/about/about_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/user_type_screen.dart';
import 'screens/debug/supabase_debug_screen.dart';
import 'screens/driver/ac_policy_screen.dart';
import 'screens/driver/driver_documents_screen.dart';
import 'screens/driver/driver_excluded_zones_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/driver_operation_zones_screen.dart';
import 'screens/driver/driver_requests_screen.dart';
import 'screens/driver/driver_trip_screen.dart';

import 'screens/driver/statistics_screen.dart';
import 'screens/driver/vehicle_screen.dart';
import 'screens/emergency/emergency_contacts_screen.dart';
import 'screens/emergency/emergency_screen.dart';
import 'screens/menu/driver_menu_screen.dart';
import 'screens/menu/user_menu_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/passenger/passenger_home_screen.dart';
import 'screens/passenger/passenger_trip_screen.dart';
import 'screens/payments/payments_screen.dart';
import 'screens/profile/profile_edit_screen.dart';
import 'screens/rating/trip_rating_screen.dart';
import 'screens/saved_places_screen.dart';
import 'screens/stepper/driver_stepper.dart';
import 'screens/stepper/stepper_demo_screen.dart';
import 'screens/stepper/user_registration_stepper.dart';
import 'screens/trip/additional_stop_screen.dart';
import 'screens/trip/driver_selection_screen.dart';
import 'screens/trip/trip_options_screen.dart';
import 'screens/trip/waiting_driver_screen.dart';
import 'screens/trips/trip_history_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'services/onesignal_service.dart';
import 'theme/app_theme.dart';
import 'utils/supabase_helper.dart';
import 'debug/test_notification_screen.dart';

// Global navigator key for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializando Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado com sucesso!');
  } catch (e) {
    print('❌ Erro ao inicializar Firebase: $e');
  }

  const supabaseUrl = AppConfig.supabaseUrl;
  const supabaseAnonKey = AppConfig.supabaseAnonKey;

  print('🔧 Iniciando aplicativo...');
  print('🌐 Supabase URL: ${supabaseUrl.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');
  print('🔑 Supabase Key: ${supabaseAnonKey.isNotEmpty ? "✅ Configurada" : "❌ Vazia"}');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      print('✅ Supabase inicializado com sucesso!');
      SupabaseHelper.markInitialized();
    } catch (e) {
      print('❌ Erro ao inicializar Supabase: $e');
    }
  } else {
    print('⚠️ Supabase não inicializado - variáveis de ambiente ausentes');
    print('📋 Certifique-se de que SUPABASE_URL e SUPABASE_ANON_KEY estão configuradas');
  }

  // Inicializando OneSignal para notificações push
  print('🚀 [MAIN] Inicializando OneSignal Service...');
  try {
    print('🔧 [MAIN] Chamando OneSignalService().initialize()...');
    await OneSignalService().initialize();
    print('🎉 [MAIN] OneSignal inicializado com SUCESSO TOTAL!');
    print('📊 [MAIN] OneSignal status: ${OneSignalService().isInitialized ? 'ATIVO' : 'INATIVO'}');
    print('💡 [MAIN] Player ID atual: ${OneSignalService().currentPlayerId ?? 'Aguardando...'}');
    print('💡 [MAIN] Push Token atual: ${OneSignalService().currentPushToken != null ? 'Disponível' : 'Aguardando...'}');
  } catch (e, stackTrace) {
    print('💥 [MAIN] ERRO CRÍTICO ao inicializar OneSignal: $e');
    print('📍 [MAIN] Stack trace: $stackTrace');
    print('⚠️ [MAIN] Aplicativo continuará sem notificações push');
  }

  runApp(const MyApp());
}

class CustomSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1, 0);
    const end = Offset.zero;
    const curve = Curves.ease;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static PageRouteBuilder _createSlideRoute(Widget page, RouteSettings settings) => PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1, 0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<StepperController>(
      create: (_) => StepperController(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Option',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CustomSlidePageTransitionsBuilder(),
              TargetPlatform.iOS: CustomSlidePageTransitionsBuilder(),
            },
          ),
        ),
        darkTheme: AppTheme.darkTheme.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CustomSlidePageTransitionsBuilder(),
              TargetPlatform.iOS: CustomSlidePageTransitionsBuilder(),
            },
          ),
        ),
        themeMode: ThemeMode.light,
        initialRoute: '/login',
        routes: {
          '/select_user_type': (context) => const UserTypeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const PassengerHomeScreen(),
          '/stepper_demo': (context) => const StepperDemoScreen(),
          '/registration_stepper': (context) => const UserRegistrationStepper(),
          '/driver_stepper': (context) => const DriverStepper(),
          '/profile_edit': (context) => const ProfileEditScreen(),
          '/driver_menu': (context) => const DriverMenuScreen(),
          '/driver_home': (context) => const DriverHomeScreen(),
          '/driver-requests': (context) => const DriverRequestsScreen(),
          '/driver_trip': (context) => const DriverTripScreen(),
          '/user_menu': (context) => const UserMenuScreen(),
          '/wallet': (context) => const WalletScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/trip_history': (context) => const TripHistoryScreen(),
          '/saved_places': (context) => const SavedPlacesScreen(),
          '/about': (context) => const AboutScreen(),
          '/driver_excluded_zones': (context) => const DriverExcludedZonesScreen(),

          '/driver_documents': (context) => const DriverDocumentsScreen(),
          '/vehicle': (context) => const VehicleScreen(),
          '/ac_policy': (context) => const AcPolicyScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/driver_operation_zones': (context) => const DriverOperationZonesScreen(),
          '/payments': (context) => const PaymentsScreen(),
          '/emergency': (context) => const EmergencyScreen(),
          '/emergency_contacts': (context) => const EmergencyContactsScreen(),
          '/debug_supabase': (context) => const SupabaseDebugScreen(),
          '/test_notification': (context) => const TestNotificationScreen(),
        },
        onGenerateRoute: (settings) {
          print('🎯 onGenerateRoute chamado para: ${settings.name}');
          print('🎯 Argumentos: ${settings.arguments}');
          
          switch (settings.name) {
            case TripOptionsScreen.routeName:
              print('✅ Processando TripOptionsScreen');
              final args = settings.arguments as Map<String, dynamic>?;
              print('✅ Args processados: $args');
              return _createSlideRoute(TripOptionsScreen.fromArgs(args), settings);
            case DriverSelectionScreen.routeName:
              final args = settings.arguments as Map<String, dynamic>?;
              return _createSlideRoute(DriverSelectionScreen.fromArgs(args ?? {}), settings);
            case AdditionalStopScreen.routeName:
              final args = settings.arguments as Map<String, dynamic>?;
              return _createSlideRoute(AdditionalStopScreen.fromArgs(args), settings);
            case WaitingDriverScreen.routeName:
              final args = settings.arguments as Map<String, dynamic>?;
              return _createSlideRoute(WaitingDriverScreen.fromArgs(args), settings);
            case PassengerTripScreen.routeName:
              final args = settings.arguments as Map<String, dynamic>?;
              return _createSlideRoute(PassengerTripScreen.fromArgs(args), settings);
            case TripRatingScreen.routeName:
              final args = settings.arguments as Map<String, dynamic>?;
              return _createSlideRoute(TripRatingScreen.fromArgs(args), settings);
          }
          return null;
        },
      ),
    );
}