/// Sistema completo de tratamento de erros da aplicação
/// 
/// Este arquivo exporta todos os componentes do sistema de tratamento de erros:
/// - AppError: Classe base para todos os erros da aplicação
/// - ErrorLogger: Sistema de logging de erros
/// - ErrorNotifier: Sistema de notificação de erros para o usuário
/// - GlobalErrorHandler: Handler global para capturar erros não tratados
/// - Extensões úteis para facilitar o uso do sistema
/// 
/// Uso básico:
/// ```dart
/// import 'package:option/core/error_handling/error_handling.dart';
/// 
/// // Inicializar o sistema
/// void initializeErrorHandling() {
///   ErrorLoggingService.instance.initialize(
///     supabaseClient: Supabase.instance.client,
///   );
///   
///   ErrorNotificationService.instance.initialize(
///     scaffoldMessengerKey: scaffoldMessengerKey,
///   );
///   
///   GlobalErrorHandler.instance.initialize();
/// }
/// 
/// // Usar em operações assíncronas
/// Future<void> someOperation() async {
///   final result = await someAsyncOperation()
///     .withErrorHandling(
///       operationName: 'someOperation',
///       userMessage: 'Falha ao executar operação',
///     );
/// }
/// 
/// // Tratar erros manualmente
/// try {
///   await riskyOperation();
/// } catch (e) {
///   throw AppError(
///     type: AppErrorType.networkUnavailable,
///     message: e.toString(),
///     userMessage: 'Sem conexão com a internet',
///   );
/// }
/// ```

export 'app_error.dart';
export 'error_logger.dart';
export 'error_notifier.dart';
export 'global_error_handler.dart';
export 'error_extensions.dart';

// Importações necessárias para as classes utilitárias
import 'app_error.dart';
import 'error_logger.dart';
import 'error_notifier.dart';
import 'global_error_handler.dart';

/// Classe utilitária para inicialização rápida do sistema de erros
class ErrorHandlingSystem {
  static bool _initialized = false;
  
  /// Inicializa todo o sistema de tratamento de erros
  static void initialize({
    required dynamic supabaseClient, // SupabaseClient
    dynamic scaffoldMessengerKey, // GlobalKey<ScaffoldMessengerState>?
    dynamic navigatorKey, // GlobalKey<NavigatorState>?
    bool enableConsoleLogging = true,
    bool enableSupabaseLogging = true,
    bool useSnackBar = true,
    bool useDialog = false,
    bool enableErrorReporting = true,
    bool showErrorDialog = true,
    Duration errorDisplayDuration = const Duration(seconds: 5),
    List<AppErrorType> silentErrors = const [],
  }) {
    if (_initialized) {
      return;
    }
    
    // Inicializa o sistema de logging
    ErrorLoggingService.instance.initialize(
      supabaseClient: supabaseClient,
      enableConsoleLogging: enableConsoleLogging,
      enableSupabaseLogging: enableSupabaseLogging,
    );
    
    // Inicializa o sistema de notificação
    ErrorNotificationService.instance.initialize(
      scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      useSnackBar: useSnackBar,
      useDialog: useDialog,
    );
    
    // Inicializa o handler global
    GlobalErrorHandler.instance.initialize(
      config: GlobalErrorHandlerConfig(
        enableErrorReporting: enableErrorReporting,
        showErrorDialog: showErrorDialog,
        errorDisplayDuration: errorDisplayDuration,
        silentErrors: silentErrors,
      ),
    );
    
    _initialized = true;
  }
  
  /// Verifica se o sistema foi inicializado
  static bool get isInitialized => _initialized;
  
  /// Reinicializa o sistema (útil para testes)
  static void reset() {
    _initialized = false;
  }
}

/// Constantes úteis para o sistema de erros
class ErrorConstants {
  // Mensagens padrão
  static const String defaultNetworkError = 'Sem conexão com a internet. Verifique sua conexão.';
  static const String defaultServerError = 'Erro no servidor. Tente novamente em alguns minutos.';
  static const String defaultValidationError = 'Dados inválidos. Verifique as informações inseridas.';
  static const String defaultUnknownError = 'Erro inesperado. Tente novamente.';
  
  // Códigos de erro comuns
  static const String networkErrorCode = 'NETWORK_ERROR';
  static const String serverErrorCode = 'SERVER_ERROR';
  static const String validationErrorCode = 'VALIDATION_ERROR';
  static const String authErrorCode = 'AUTH_ERROR';
  
  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);
  
  // Retry
  static const int defaultMaxRetries = 3;
  static const Duration defaultRetryDelay = Duration(seconds: 1);
}

/// Utilitários para criação rápida de erros comuns
class ErrorUtils {
  /// Cria um erro de rede
  static AppError networkError({
    String? message,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: AppErrorType.networkUnavailable,
      message: message ?? 'Network error',
      userMessage: userMessage ?? ErrorConstants.defaultNetworkError,
      context: context,
      severity: ErrorSeverity.medium,
    );
  }
  
  /// Cria um erro de servidor
  static AppError serverError({
    String? message,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: AppErrorType.serverError,
      message: message ?? 'Server error',
      userMessage: userMessage ?? ErrorConstants.defaultServerError,
      context: context,
      severity: ErrorSeverity.high,
    );
  }
  
  /// Cria um erro de validação
  static AppError validationError({
    String? message,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: AppErrorType.validationFailed,
      message: message ?? 'Validation error',
      userMessage: userMessage ?? ErrorConstants.defaultValidationError,
      context: context,
      severity: ErrorSeverity.medium,
    );
  }
  
  /// Cria um erro de autenticação
  static AppError authError({
    String? message,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: AppErrorType.authenticationFailed,
      message: message ?? 'Authentication error',
      userMessage: userMessage ?? 'Falha na autenticação. Verifique suas credenciais.',
      context: context,
      severity: ErrorSeverity.high,
    );
  }
  
  /// Cria um erro de permissão
  static AppError permissionError({
    String? message,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: AppErrorType.authorizationDenied,
      message: message ?? 'Permission denied',
      userMessage: userMessage ?? 'Você não tem permissão para realizar esta ação.',
      context: context,
      severity: ErrorSeverity.medium,
    );
  }
  
  /// Verifica se um erro é recuperável (pode ser tentado novamente)
  static bool isRecoverable(AppError error) {
    switch (error.type) {
      case AppErrorType.networkUnavailable:
      case AppErrorType.connectionTimeout:
      case AppErrorType.serverError:
        return true;
      case AppErrorType.authenticationFailed:
      case AppErrorType.authorizationDenied:
      case AppErrorType.validationFailed:
      case AppErrorType.invalidInput:
        return false;
      default:
        return false;
    }
  }
  
  /// Determina se um erro deve ser reportado automaticamente
  static bool shouldReport(AppError error) {
    switch (error.severity) {
      case ErrorSeverity.low:
        return false;
      case ErrorSeverity.medium:
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        return true;
    }
  }
}