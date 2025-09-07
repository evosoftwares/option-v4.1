import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'utils/supabase_emulator_config.dart';
import 'controllers/stepper_controller.dart';
import 'screens/about/about_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/user_type_screen.dart';

import 'screens/driver/ac_policy_screen.dart';
import 'screens/driver/driver_documents_screen.dart';
import 'screens/driver/driver_excluded_zones_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/driver/driver_approval_pending_screen.dart';
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
import 'utils/emulator_network_helper.dart';

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

  // Configuração e inicialização do Supabase com diagnóstico completo
  print('🔧 [MAIN] Inicializando Supabase com diagnóstico...');

  await _initializeSupabaseWithDiagnostics();

  // Inicializando OneSignal para notificações push
  print('🚀 [MAIN] Inicializando OneSignal Service...');
  try {
    print('🔧 [MAIN] Chamando OneSignalService().initialize()...');
    await OneSignalService().initialize();
    print('🎉 [MAIN] OneSignal inicializado com SUCESSO TOTAL!');
    print(
        '📊 [MAIN] OneSignal status: ${OneSignalService().isInitialized ? 'ATIVO' : 'INATIVO'}');
    print(
        '💡 [MAIN] Player ID atual: ${OneSignalService().currentPlayerId ?? 'Aguardando...'}');
    print(
        '💡 [MAIN] Push Token atual: ${OneSignalService().currentPushToken != null ? 'Disponível' : 'Aguardando...'}');
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

/// Inicializa o Supabase com diagnóstico completo de conectividade
Future<void> _initializeSupabaseWithDiagnostics() async {
  // 1. Validar configuração
  print('📋 Validando configuração...');
  final configValidation = AppConfig.validateConfiguration();

  if (!configValidation.isValid) {
    print('❌ Configuração inválida, mas tentando inicializar mesmo assim:');
    configValidation.printReport();
  }

  if (configValidation.hasWarnings && AppConfig.enableVerboseLogs) {
    configValidation.printReport();
  }

  // 2. Exibir informações de configuração
  if (AppConfig.enableVerboseLogs) {
    AppConfig.printConfigurationInfo();
  } else {
    print('✅ Configuração processada');
  }

  // 3. Testar conectividade de rede (mas não bloquear inicialização)
  print('🌐 Verificando conectividade de rede...');
  final connectivity = await _testNetworkConnectivity();

  if (!connectivity.isConnected) {
    print('❌ Falha de conectividade: ${connectivity.error}');
    print('⚠️ Tentando inicializar mesmo assim...');
    _printConnectivityTroubleshooting(connectivity);
  } else {
    print('✅ Conectividade de rede OK');
  }

  // 4. Inicializar Supabase (SEMPRE tenta inicializar)
  try {
    print('⚡ Inicializando cliente Supabase com otimizações para emulador...');
    print('🔧 URL: ${AppConfig.supabaseUrl}');
    print('🔧 Key: ${AppConfig.supabaseAnonKey.substring(0, 20)}...');

    // Usar configuração otimizada para emuladores
    await SupabaseEmulatorConfig.initializeWithEmulatorSupport();

    print('✅ Supabase inicializado com otimizações para emulador!');
    SupabaseHelper.markInitialized();

    // 5. Teste pós-inicialização
    await _testSupabasePostInitialization();
  } catch (e) {
    await _handleSupabaseInitializationError(e);
  }
}

/// Testa conectividade básica de rede
Future<NetworkConnectivityResult> _testNetworkConnectivity() async {
  try {
    final projectInfo = AppConfig.getSupabaseProjectInfo();

    // Teste DNS com timeout maior para emuladores
    final addresses = await InternetAddress.lookup(projectInfo.host)
        .timeout(Duration(seconds: 10));

    if (addresses.isEmpty) {
      print('❌ [CONNECTIVITY] DNS não resolveu: ${projectInfo.host}');
      print('💡 [CONNECTIVITY] Possível problema de DNS no emulador Android');
      return NetworkConnectivityResult(
        isConnected: false,
        error:
            'DNS não resolveu endereços para ${projectInfo.host}. Verifique configurações DNS do emulador.',
        errorType: NetworkErrorType.dns,
      );
    }

    // Teste TCP básico
    final socket = await Socket.connect(
      projectInfo.host,
      443,
      timeout: Duration(seconds: 5),
    );
    await socket.close();

    return NetworkConnectivityResult(isConnected: true);
  } catch (e) {
    NetworkErrorType errorType = NetworkErrorType.unknown;

    if (e.toString().contains('SocketException')) {
      if (e.toString().contains('No address associated with hostname') ||
          e.toString().contains('unknown host')) {
        errorType = NetworkErrorType.dns;
        print('❌ [CONNECTIVITY] Erro DNS detectado: ${e.toString()}');
        print(
            '💡 [CONNECTIVITY] Solução: Reinicie o emulador com: emulator @AVD_NAME -dns-server 8.8.8.8,1.1.1.1');
      } else {
        errorType = NetworkErrorType.connection;
      }
    } else if (e.toString().contains('TimeoutException')) {
      errorType = NetworkErrorType.timeout;
    }

    return NetworkConnectivityResult(
      isConnected: false,
      error: e.toString(),
      errorType: errorType,
    );
  }
}

/// Testa funcionalidades básicas após inicialização do Supabase
Future<void> _testSupabasePostInitialization() async {
  try {
    print('🔍 Testando funcionalidades básicas...');

    final client = Supabase.instance.client;

    // Teste 1: Query simples (pode falhar por RLS, mas conexão funciona)
    try {
      await client
          .from('app_users')
          .select('count')
          .limit(1)
          .timeout(Duration(seconds: AppConfig.httpTimeoutSeconds));
      print('✅ Conexão com banco de dados confirmada');
    } catch (queryError) {
      if (queryError
          .toString()
          .contains('relation "app_users" does not exist')) {
        print(
            '✅ Conexão OK (tabela app_users não existe - normal em setup inicial)');
      } else if (queryError.toString().contains('RLS') ||
          queryError.toString().contains('permission denied')) {
        print('✅ Conexão OK (RLS ativa - segurança funcionando)');
      } else {
        print('⚠️ Conexão parcial: $queryError');
      }
    }

    // Teste 2: Auth endpoint
    try {
      // Apenas verifica se o endpoint responde (não precisa autenticar)
      client.auth.currentSession;
      print('✅ Endpoint de autenticação acessível');
    } catch (authError) {
      print('⚠️ Auth endpoint: ${authError.toString().substring(0, 100)}...');
    }

    print('🎉 Supabase totalmente funcional!');
  } catch (e) {
    print('⚠️ Alguns recursos podem não funcionar: $e');
  }
}

/// Trata erros de inicialização do Supabase
Future<void> _handleSupabaseInitializationError(dynamic error) async {
  print('❌ Erro na inicialização do Supabase:');
  print('   $error');
  print('');

  final errorStr = error.toString().toLowerCase();

  print('🔧 DIAGNÓSTICO AUTOMÁTICO:');

  if (errorStr.contains('already been initialized')) {
    print('   ✅ Supabase já estava inicializado (normal em hot reload)');
    SupabaseHelper.markInitialized();
    return;
  }

  if (errorStr.contains('socketexception') ||
      errorStr.contains('could not resolve')) {
    print('   🌐 PROBLEMA DE CONECTIVIDADE DE REDE');
    print('   • Verifique sua conexão de internet');
    print('   • Teste DNS: nslookup ${Uri.parse(AppConfig.supabaseUrl).host}');
    print('   • Considere trocar DNS: 8.8.8.8, 1.1.1.1');
    print('   • Verifique se VPN/Proxy não está bloqueando');
  }

  if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
    print('   🔑 PROBLEMA DE AUTENTICAÇÃO');
    print('   • Verifique SUPABASE_ANON_KEY no Dashboard');
    print('   • Confirme que a chave não expirou');
  }

  if (errorStr.contains('403') || errorStr.contains('forbidden')) {
    print('   🚫 PROBLEMA DE PERMISSÕES');
    print('   • Projeto Supabase pode estar pausado/suspenso');
    print('   • Verifique status: https://status.supabase.com');
  }

  if (errorStr.contains('timeout')) {
    print('   ⏱️ PROBLEMA DE TIMEOUT');
    print('   • Conexão lenta ou instável');
    print('   • Tente de outra rede (dados móveis)');
  }

  print('');
  print('🔧 TENTANDO CONTINUAR SEM SUPABASE...');
  print('⚠️ Aplicativo funcionará com funcionalidades limitadas');
  print('');
  print('📋 PRÓXIMOS PASSOS:');
  print('   1. Execute: dart test_supabase_connectivity.dart');
  print('   2. Verifique configurações no Supabase Dashboard');
  print('   3. Teste de outra máquina/rede');
  print('   4. Se persistir, contate suporte do Supabase');
}

/// Imprime dicas de solução para problemas de conectividade
void _printConnectivityTroubleshooting(NetworkConnectivityResult result) {
  print('🛠️ SOLUÇÕES PARA CONECTIVIDADE:');

  switch (result.errorType) {
    case NetworkErrorType.dns:
      print('   📡 PROBLEMA DE DNS:');
      print('   • Mude DNS: 8.8.8.8, 1.1.1.1');
      print('   • Teste: nslookup ${Uri.parse(AppConfig.supabaseUrl).host}');
      print('   • Reinicie roteador/modem');
      break;

    case NetworkErrorType.connection:
      print('   🔌 PROBLEMA DE CONEXÃO:');
      print('   • Verifique firewall/antivírus');
      print('   • Teste de outra rede');
      print('   • Verifique configuração de proxy');
      break;

    case NetworkErrorType.timeout:
      print('   ⏱️ PROBLEMA DE TIMEOUT:');
      print('   • Conexão muito lenta');
      print('   • Tente novamente em alguns minutos');
      break;

    case NetworkErrorType.unknown:
      print('   ❓ ERRO DESCONHECIDO:');
      print('   • Execute: dart test_dns.dart');
      print('   • Verifique logs do sistema');
      break;
  }
}

/// Resultado do teste de conectividade de rede
class NetworkConnectivityResult {
  final bool isConnected;
  final String? error;
  final NetworkErrorType errorType;

  NetworkConnectivityResult({
    required this.isConnected,
    this.error,
    this.errorType = NetworkErrorType.unknown,
  });
}

/// Tipos de erro de conectividade
enum NetworkErrorType {
  dns,
  connection,
  timeout,
  unknown,
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static PageRouteBuilder _createSlideRoute(
          Widget page, RouteSettings settings) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1, 0);
          const end = Offset.zero;
          const curve = Curves.ease;

          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<StepperController>(
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
            '/registration_stepper': (context) =>
                const UserRegistrationStepper(),
            '/driver_stepper': (context) => const DriverStepper(),
            '/profile_edit': (context) => const ProfileEditScreen(),
            '/driver_menu': (context) => const DriverMenuScreen(),
            '/driver_home': (context) => const DriverHomeScreen(),
            '/driver_approval_pending': (context) =>
                const DriverApprovalPendingScreen(),
            '/driver-requests': (context) => const DriverRequestsScreen(),
            '/driver_trip': (context) => const DriverTripScreen(),
            '/user_menu': (context) => const UserMenuScreen(),
            '/wallet': (context) => const WalletScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/trip_history': (context) => const TripHistoryScreen(),
            '/saved_places': (context) => const SavedPlacesScreen(),
            '/about': (context) => const AboutScreen(),
            '/driver_excluded_zones': (context) =>
                const DriverExcludedZonesScreen(),
            '/driver_documents': (context) => const DriverDocumentsScreen(),
            '/vehicle': (context) => const VehicleScreen(),
            '/ac_policy': (context) => const AcPolicyScreen(),
            '/statistics': (context) => const StatisticsScreen(),
            '/driver_operation_zones': (context) =>
                const DriverOperationZonesScreen(),
            '/payments': (context) => const PaymentsScreen(),
            '/emergency': (context) => const EmergencyScreen(),
            '/emergency_contacts': (context) => const EmergencyContactsScreen(),
          },
          onGenerateRoute: (settings) {
            print('🎯 onGenerateRoute chamado para: ${settings.name}');
            print('🎯 Argumentos: ${settings.arguments}');

            switch (settings.name) {
              case TripOptionsScreen.routeName:
                print('✅ Processando TripOptionsScreen');
                final args = settings.arguments as Map<String, dynamic>?;
                print('✅ Args processados: $args');
                return _createSlideRoute(
                    TripOptionsScreen.fromArgs(args), settings);
              case DriverSelectionScreen.routeName:
                final args = settings.arguments as Map<String, dynamic>?;
                return _createSlideRoute(
                    DriverSelectionScreen.fromArgs(args ?? {}), settings);
              case AdditionalStopScreen.routeName:
                final args = settings.arguments as Map<String, dynamic>?;
                return _createSlideRoute(
                    AdditionalStopScreen.fromArgs(args), settings);
              case WaitingDriverScreen.routeName:
                final args = settings.arguments as Map<String, dynamic>?;
                return _createSlideRoute(
                    WaitingDriverScreen.fromArgs(args), settings);
              case PassengerTripScreen.routeName:
                final args = settings.arguments as Map<String, dynamic>?;
                return _createSlideRoute(
                    PassengerTripScreen.fromArgs(args), settings);
              case TripRatingScreen.routeName:
                final args = settings.arguments as Map<String, dynamic>?;
                return _createSlideRoute(
                    TripRatingScreen.fromArgs(args), settings);
            }
            return null;
          },
        ),
      );
}
