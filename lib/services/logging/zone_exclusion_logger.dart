import 'dart:developer' as developer;
import 'package:intl/intl.dart';

/// Enum for zone operation types
enum ZoneOperationType {
  add,
  remove,
  validate,
  validation,
  database,
  permission,
  network,
  query,
}

/// Enum for log levels
enum ZoneLogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class ZoneExclusionLog {
  final String id;
  final DateTime timestamp;
  final ZoneOperationType operationType;
  final ZoneLogLevel level;
  final String message;
  final String? driverId;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;
  final String? errorCode;

  ZoneExclusionLog({
    required this.operationType,
    required this.level,
    required this.message,
    this.driverId,
    this.context,
    this.stackTrace,
    this.errorCode,
    String? id,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'operationType': operationType.toString(),
        'level': level.toString(),
        'message': message,
        'driverId': driverId,
        'context': context,
        'errorCode': errorCode,
        'stackTrace': stackTrace?.toString(),
      };

  @override
  String toString() {
    final timeStr = DateFormat('HH:mm:ss.SSS').format(timestamp);
    return '[$timeStr] ${level.name.toUpperCase()} ${operationType.name.toUpperCase()}: $message';
  }
}

class ZoneExclusionLogger {
  static const String _tag = 'ZoneExclusion';

  static void log(ZoneExclusionLog log) {
    final logMessage = log.toString();
    
    switch (log.level) {
      case ZoneLogLevel.debug:
        developer.log(logMessage, name: _tag, level: 500);
        break;
      case ZoneLogLevel.info:
        developer.log(logMessage, name: _tag, level: 800);
        break;
      case ZoneLogLevel.warning:
        developer.log(logMessage, name: _tag, level: 900);
        break;
      case ZoneLogLevel.error:
        developer.log(
          logMessage,
          name: _tag,
          level: 1000,
          error: log.context,
          stackTrace: log.stackTrace,
        );
        break;
      case ZoneLogLevel.critical:
        developer.log(
          logMessage,
          name: _tag,
          level: 1200,
          error: log.context,
          stackTrace: log.stackTrace,
        );
        break;
    }

    // Também loga no console para desenvolvimento
    _consoleLog(log);
  }

  static void _consoleLog(ZoneExclusionLog log) {
    final color = _getColor(log.level);
    const reset = '\x1B[0m';
    final logStr = '${color}ZoneExclusion: ${log.level.name.toUpperCase()} - ${log.message}$reset';
    print(logStr);
  }

  static String _getColor(ZoneLogLevel level) {
    switch (level) {
      case ZoneLogLevel.debug:
        return '\x1B[37m'; // White
      case ZoneLogLevel.info:
        return '\x1B[36m'; // Cyan
      case ZoneLogLevel.warning:
        return '\x1B[33m'; // Yellow
      case ZoneLogLevel.error:
        return '\x1B[31m'; // Red
      case ZoneLogLevel.critical:
        return '\x1B[35m'; // Magenta
    }
  }

  // Métodos auxiliares para tipos específicos de operações
  static void logAddStart({required String driverId, Map<String, dynamic>? context}) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.add,
      level: ZoneLogLevel.info,
      message: 'Iniciando adição de zona de exclusão',
      driverId: driverId,
      context: context,
    ));
  }

  static void logAddSuccess({
    required String driverId,
    required String neighborhood,
    required String city,
    required String state,
    String? zoneId,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.add,
      level: ZoneLogLevel.info,
      message: 'Zona de exclusão adicionada com sucesso',
      driverId: driverId,
      context: {
        'neighborhood': neighborhood,
        'city': city,
        'state': state,
        'zoneId': zoneId,
      },
    ));
  }

  static void logAddError({
    required String driverId,
    required String error,
    StackTrace? stackTrace,
    String? errorCode,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.add,
      level: ZoneLogLevel.error,
      message: 'Erro ao adicionar zona de exclusão: $error',
      driverId: driverId,
      context: context,
      stackTrace: stackTrace,
      errorCode: errorCode,
    ));
  }

  static void logRemoveStart({
    required String driverId,
    required String zoneId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.remove,
      level: ZoneLogLevel.info,
      message: 'Iniciando remoção de zona de exclusão',
      driverId: driverId,
      context: {'zoneId': zoneId, ...?context},
    ));
  }

  static void logRemoveSuccess({
    required String driverId,
    required String zoneId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.remove,
      level: ZoneLogLevel.info,
      message: 'Zona de exclusão removida com sucesso',
      driverId: driverId,
      context: {'zoneId': zoneId, ...?context},
    ));
  }

  static void logRemoveError({
    required String driverId,
    required String zoneId,
    required String error,
    StackTrace? stackTrace,
    String? errorCode,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.remove,
      level: ZoneLogLevel.error,
      message: 'Erro ao remover zona de exclusão: $error',
      driverId: driverId,
      context: {'zoneId': zoneId, ...?context},
      stackTrace: stackTrace,
      errorCode: errorCode,
    ));
  }

  static void logValidationError({
    required String driverId,
    required String field,
    required String error,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.warning,
      message: 'Erro de validação no campo $field: $error',
      driverId: driverId,
      context: {'field': field, 'error': error, ...?context},
    ));
  }

  static void logDatabaseError({
    required String driverId,
    required String operation,
    required String error,
    String? errorCode,
    String? code,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.database,
      level: ZoneLogLevel.error,
      message: 'Erro de banco de dados durante $operation: $error',
      driverId: driverId,
      context: context,
      stackTrace: stackTrace,
      errorCode: errorCode ?? code,
    ));
  }

  static void logPermissionError({
    required String driverId,
    required String operation,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.permission,
      level: ZoneLogLevel.error,
      message: 'Permissão negada para $operation',
      driverId: driverId,
      context: context,
    ));
  }

  static void logNetworkError({
    required String driverId,
    required String operation,
    required String error,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.network,
      level: ZoneLogLevel.error,
      message: 'Erro de rede durante $operation: $error',
      driverId: driverId,
      context: context,
    ));
  }

  static void logQueryError({
    required String driverId,
    required String query,
    required String error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.query,
      level: ZoneLogLevel.error,
      message: 'Erro na query: $query',
      driverId: driverId,
      context: {'query': query, ...?context},
      stackTrace: stackTrace,
    ));
  }

  // Métodos adicionais para tipos específicos de operações
  static void logQueryStart({
    required String driverId,
    required String query,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.query,
      level: ZoneLogLevel.info,
      message: 'Iniciando query: $query',
      driverId: driverId,
      context: context,
    ));
  }

  static void logQuerySuccess({
    required String driverId,
    required String query,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.query,
      level: ZoneLogLevel.info,
      message: 'Query executada com sucesso: $query',
      driverId: driverId,
      context: context,
    ));
  }

  static void logUnexpectedError({
    required String driverId,
    required String operation,
    required String error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.database,
      level: ZoneLogLevel.critical,
      message: 'Erro inesperado durante $operation: $error',
      driverId: driverId,
      context: context,
      stackTrace: stackTrace,
    ));
  }

  static void logValidationStart({
    required String driverId,
    String? field,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.info,
      message: 'Iniciando validação de dados${field != null ? ' para $field' : ''}',
      driverId: driverId,
      context: {'field': field, ...?context},
    ));
  }

  static void logValidationSuccess({
    required String driverId,
    String? field,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.info,
      message: 'Validação de dados concluída com sucesso${field != null ? ' para $field' : ''}',
      driverId: driverId,
      context: {'field': field, ...?context},
    ));
  }

  static void logLimitCheck({
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.info,
      message: 'Verificando limite de zonas',
      driverId: driverId,
      context: context,
    ));
  }

  static void logCurrentCount({
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.query,
      level: ZoneLogLevel.info,
      message: 'Contagem atual de zonas obtida',
      driverId: driverId,
      context: context,
    ));
  }

  static void logLimitExceeded({
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.warning,
      message: 'Limite de zonas excedido',
      driverId: driverId,
      context: context,
    ));
  }

  static void logDatabaseOperation({
    required String driverId,
    required String operation,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.database,
      level: ZoneLogLevel.info,
      message: 'Executando operação de banco: $operation',
      driverId: driverId,
      context: context,
    ));
  }

  static void logDuplicateZone({
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.warning,
      message: 'Tentativa de adicionar zona duplicada',
      driverId: driverId,
      context: context,
    ));
  }

  static void logCustomValidationError({
    required String driverId,
    required String error,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.error,
      message: 'Erro de validação customizada: $error',
      driverId: driverId,
      context: context,
    ));
  }

  static void logConstraintViolation({
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.error,
      message: 'Violação de restrição de banco de dados',
      driverId: driverId,
      context: context,
    ));
  }

  static void logRemovalValidation({
    required String driverId,
    required String zoneId,
    Map<String, dynamic>? zoneData,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.validate,
      level: ZoneLogLevel.info,
      message: 'Validando remoção de zona',
      driverId: driverId,
      context: {'zoneId': zoneId, 'zoneData': zoneData},
    ));
  }

  static void logRemovalStart({
    String? driverId,
    String? zoneId,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.remove,
      level: ZoneLogLevel.info,
      message: 'Iniciando remoção de zona de exclusão',
      driverId: driverId ?? 'unknown',
      context: {'zoneId': zoneId, ...?context},
    ));
  }

  static void logRemovalSuccess({
    required String driverId,
    required String zoneId,
    Map<String, dynamic>? zoneData,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.remove,
      level: ZoneLogLevel.info,
      message: 'Zona de exclusão removida com sucesso',
      driverId: driverId,
      context: {'zoneId': zoneId, 'zoneData': zoneData},
    ));
  }

  static void logRemovalError({
    required String driverId,
    required String zoneId,
    required String error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    log(ZoneExclusionLog(
      operationType: ZoneOperationType.remove,
      level: ZoneLogLevel.error,
      message: 'Erro ao remover zona de exclusão: $error',
      driverId: driverId,
      context: {'zoneId': zoneId, ...?context},
      stackTrace: stackTrace,
    ));
  }
}