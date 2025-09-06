import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

/// Serviço de monitoramento para logs estruturados e métricas
class MonitoringService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      printTime: true,
    ),
  );

  static final Map<String, int> _operationCounts = {};
  static final Map<String, List<Duration>> _operationDurations = {};

  static String? _appVersion;
  static String? _clientIp;

  /// Inicializa o serviço de monitoramento
  static Future<void> initialize() async {
    if (kDebugMode) {
      _logger.i('Monitoring service initialized in debug mode');
    }
    
    // Obter versão do app
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      _logger.i('App version: $_appVersion');
    } catch (e) {
      _logger.e('Failed to get app version', error: e);
      _appVersion = '1.0.0+1'; // fallback
    }

    // Detectar IP do cliente
    await _detectClientIp();
    
    // Configurar Sentry se não estiver em debug (desativado por enquanto)
    // if (!kDebugMode) {
    //   await SentryFlutter.init(
    //     (options) {
    //       options.dsn = 'YOUR_SENTRY_DSN_HERE';
    //       options.tracesSampleRate = 0.1;
    //       options.environment = kReleaseMode ? 'production' : 'staging';
    //     },
    //   );
    // }
  }

  /// Log estruturado para operações de zona
  static void logZoneOperation({
    required String operation,
    required String userId,
    required String driverId,
    String? zoneId,
    Map<String, dynamic>? metadata,
    Duration? duration,
    String status = 'success',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': status == 'error' ? 'ERROR' : 'INFO',
      'service': 'zone_service',
      'operation': operation,
      'user_id': userId,
      'driver_id': driverId,
      'zone_id': zoneId,
      'duration_ms': duration?.inMilliseconds,
      'status': status,
      'metadata': metadata ?? {},
      'platform': Platform.operatingSystem,
      'app_version': _appVersion ?? '1.0.0+1',
    };

    if (error != null) {
      logData['error'] = {
        'message': error.toString(),
        'type': error.runtimeType.toString(),
        if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      };
    }

    // Log local
    if (status == 'error') {
      _logger.e('Zone operation failed: $operation', error: error, stackTrace: stackTrace);
    } else {
      _logger.i('Zone operation completed: $operation');
    }

    // Enviar para Sentry em caso de erro
    if (status == 'error' && !kDebugMode) {
      // Sentry.captureException(
      //   error,
      //   stackTrace: stackTrace,
      //   withScope: (scope) {
      //     scope.setTag('operation', operation);
      //     scope.setTag('service', 'zone_service');
      //     scope.setUser(SentryUser(id: userId));
      //     scope.setExtra('zone_operation', logData);
      //   },
      // );
    }

    // Coletar métricas
    _recordMetrics(operation, status, duration);

    // Enviar para backend (opcional)
    _sendLogToBackend(logData);
  }

  /// Log para validação geográfica
  static void logGeographicValidation({
    required String address,
    required bool isValid,
    String? normalizedAddress,
    Duration? duration,
    Object? error,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': error != null ? 'ERROR' : 'INFO',
      'service': 'geographic_validation',
      'operation': 'validate_address',
      'address': address,
      'normalized_address': normalizedAddress,
      'is_valid': isValid,
      'duration_ms': duration?.inMilliseconds,
      'status': error != null ? 'error' : 'success',
    };

    if (error != null) {
      logData['error'] = {
        'message': error.toString(),
        'type': error.runtimeType.toString(),
      };
      _logger.e('Geographic validation failed', error: error);
    } else {
      _logger.i('Geographic validation completed');
    }

    _sendLogToBackend(logData);
  }

  /// Log para operações de segurança
  static void logSecurityEvent({
    required String eventType,
    required String userId,
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': 'WARN',
      'service': 'security',
      'operation': eventType,
      'user_id': userId,
      'details': details,
      'metadata': metadata ?? {},
      'client_ip': _clientIp ?? 'unknown',
      'user_agent': Platform.operatingSystem,
    };

    _logger.w('Security event: $eventType');

    // Sempre enviar eventos de segurança para Sentry
    if (!kDebugMode) {
      // Sentry.captureMessage(
      //   'Security Event: $eventType',
      //   level: SentryLevel.warning,
      //   withScope: (scope) {
      //     scope.setTag('event_type', eventType);
      //     scope.setTag('service', 'security');
      //     scope.setUser(SentryUser(id: userId));
      //     scope.setExtra('security_event', logData);
      //   },
      // );
    }

    _sendLogToBackend(logData);
  }

  /// Log para performance de queries
  static void logDatabaseQuery({
    required String query,
    required Duration duration,
    int? resultCount,
    Object? error,
  }) {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': error != null ? 'ERROR' : 'DEBUG',
      'service': 'database',
      'operation': 'query',
      'query_type': _extractQueryType(query),
      'duration_ms': duration.inMilliseconds,
      'result_count': resultCount,
      'status': error != null ? 'error' : 'success',
    };

    if (error != null) {
      logData['error'] = {
        'message': error.toString(),
        'type': error.runtimeType.toString(),
      };
      _logger.e('Database query failed', error: error);
    } else if (duration.inMilliseconds > 1000) {
      _logger.w('Slow database query detected');
    } else {
      _logger.d('Database query completed');
    }

    _sendLogToBackend(logData);
  }

  /// Registra métricas de performance
  static void _recordMetrics(String operation, String status, Duration? duration) {
    // Contador de operações
    final key = '${operation}_$status';
    _operationCounts[key] = (_operationCounts[key] ?? 0) + 1;

    // Duração das operações
    if (duration != null) {
      _operationDurations[operation] ??= [];
      _operationDurations[operation]!.add(duration);
      
      // Manter apenas as últimas 100 medições
      if (_operationDurations[operation]!.length > 100) {
        _operationDurations[operation]!.removeAt(0);
      }
    }
  }

  /// Obtém métricas coletadas
  static Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{
      'operation_counts': Map.from(_operationCounts),
      'operation_durations': {},
    };

    // Calcular estatísticas de duração
    _operationDurations.forEach((operation, durations) {
      if (durations.isNotEmpty) {
        final sortedDurations = List<Duration>.from(durations)..sort();
        final count = durations.length;
        
        metrics['operation_durations'][operation] = {
          'count': count,
          'avg_ms': durations.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / count,
          'min_ms': sortedDurations.first.inMilliseconds,
          'max_ms': sortedDurations.last.inMilliseconds,
          'p50_ms': sortedDurations[(count * 0.5).floor()].inMilliseconds,
          'p95_ms': sortedDurations[(count * 0.95).floor()].inMilliseconds,
        };
      }
    });

    return metrics;
  }

  /// Limpa métricas coletadas
  static void clearMetrics() {
    _operationCounts.clear();
    _operationDurations.clear();
  }

  /// Detecta o IP do cliente
  static Future<void> _detectClientIp() async {
    try {
      // Método 1: Usar um serviço de IP público
      final response = await Supabase.instance.client
          .rpc('get_client_ip')
          .maybeSingle();
      
      if (response != null && response['ip'] != null) {
        _clientIp = response['ip'];
        _logger.i('Client IP detected: $_clientIp');
        return;
      }
    } catch (e) {
      _logger.w('Failed to get client IP from Supabase RPC', error: e);
    }

    try {
      // Método 2: Fallback - usar um serviço externo
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse('https://api.ipify.org?format=json'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        _clientIp = data['ip'];
        _logger.i('Client IP detected via external service: $_clientIp');
      }
      httpClient.close();
    } catch (e) {
      _logger.w('Failed to get client IP from external service', error: e);
      _clientIp = 'unknown';
    }
  }

  /// Envia log para backend
  static Future<void> _sendLogToBackend(Map<String, dynamic> logData) async {
    try {
      if (kDebugMode) {
        print('LOG TO BACKEND: ${jsonEncode(logData)}');
        return; // Não enviar logs em debug mode
      }

      // Enviar para Supabase
      final supabase = Supabase.instance.client;
      
      // Preparar dados para inserção
      final logRecord = {
        ...logData,
        'created_at': DateTime.now().toIso8601String(),
        'session_id': supabase.auth.currentSession?.user.id ?? 'anonymous',
      };

      // Inserir na tabela de logs
      await supabase.from('application_logs').insert(logRecord);
      
      _logger.d('Log sent to backend successfully');
      
    } catch (e) {
      _logger.e('Falha ao enviar log para o backend', error: e);
      
      // Em caso de falha, tentar armazenar localmente para envio posterior
      try {
        await _storeLogLocally(logData);
      } catch (localError) {
        _logger.e('Failed to store log locally', error: localError);
      }
    }
  }

  /// Armazena log localmente para envio posterior
  static Future<void> _storeLogLocally(Map<String, dynamic> logData) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Tentar inserir em uma tabela de logs pendentes
      await supabase.from('pending_logs').insert({
        ...logData,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    } catch (e) {
      _logger.e('Failed to store log in pending logs table', error: e);
      // Último recurso: armazenar em SharedPreferences
      // Isso pode ser implementado se necessário
    }
  }

  /// Extrai tipo de query SQL
  static String _extractQueryType(String query) {
    final trimmed = query.trim().toUpperCase();
    if (trimmed.startsWith('SELECT')) return 'SELECT';
    if (trimmed.startsWith('INSERT')) return 'INSERT';
    if (trimmed.startsWith('UPDATE')) return 'UPDATE';
    if (trimmed.startsWith('DELETE')) return 'DELETE';
    if (trimmed.startsWith('CREATE')) return 'CREATE';
    if (trimmed.startsWith('ALTER')) return 'ALTER';
    if (trimmed.startsWith('DROP')) return 'DROP';
    return 'OTHER';
  }

  /// Health check do serviço
  static Map<String, dynamic> healthCheck() => {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'monitoring_service',
      'metrics_collected': _operationCounts.isNotEmpty,
      'sentry_enabled': !kDebugMode,
      'platform': Platform.operatingSystem,
    };

  /// Wrapper para medir duração de operações
  static Future<T> measureOperation<T>(
    String operation,
    Future<T> Function() function, {
    String? userId,
    String? driverId,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      stopwatch.stop();
      
      if (userId != null && driverId != null) {
        logZoneOperation(
          operation: operation,
          userId: userId,
          driverId: driverId,
          duration: stopwatch.elapsed,
          metadata: metadata,
        );
      }
      
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      
      if (userId != null && driverId != null) {
        logZoneOperation(
          operation: operation,
          userId: userId,
          driverId: driverId,
          duration: stopwatch.elapsed,
          metadata: metadata,
          status: 'error',
          error: error,
          stackTrace: stackTrace,
        );
      }
      
      rethrow;
    }
  }

  /// Log genérico de informação
  static void logInfo(String message, [Map<String, dynamic>? data]) {
    _logger.i(message);
  }
  
  /// Log genérico de warning
  static void logWarning(String message, [Map<String, dynamic>? data]) {
    _logger.w(message);
  }
  
  /// Log genérico de erro
  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

/// Extensão para facilitar logging em serviços
extension MonitoringExtension on Object {
  void logInfo(String message, [Map<String, dynamic>? data]) {
    MonitoringService._logger.i('$runtimeType: $message');
  }
  
  void logWarning(String message, [Map<String, dynamic>? data]) {
    MonitoringService._logger.w('$runtimeType: $message');
  }
  
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    MonitoringService._logger.e('$runtimeType: $message', error: error, stackTrace: stackTrace);
  }
}