import 'dart:developer' as developer;
import 'package:intl/intl.dart';

/// Enum para tipos de operações de chamada
enum CallOperationType {
  initiated,
  phoneAttempt,
  driverSelected,
  validationStarted,
  validationCompleted,
  error,
  callCompleted,
  callExpired,
  callRejected,
  callTimeout,
  requestCreated,
  notificationSent,
  fallbackActivated,
  driverAvailable,
  transactionSuccess,
}

/// Enum para níveis de log
enum CallLogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class DriverCallLog {
  final String id;
  final DateTime timestamp;
  final CallOperationType operationType;
  final CallLogLevel level;
  final String message;
  final String? passengerId;
  final String? driverId;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;
  final String? errorCode;

  DriverCallLog({
    required this.operationType,
    required this.level,
    required this.message,
    this.passengerId,
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
        'passengerId': passengerId,
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

class DriverCallLogger {
  static const String _tag = 'DriverCall';

  static void log(DriverCallLog log) {
    final logMessage = log.toString();
    
    switch (log.level) {
      case CallLogLevel.debug:
        developer.log(logMessage, name: _tag, level: 500);
        break;
      case CallLogLevel.info:
        developer.log(logMessage, name: _tag, level: 800);
        break;
      case CallLogLevel.warning:
        developer.log(logMessage, name: _tag, level: 900);
        break;
      case CallLogLevel.error:
        developer.log(
          logMessage,
          name: _tag,
          level: 1000,
          error: log.context,
          stackTrace: log.stackTrace,
        );
        break;
      case CallLogLevel.critical:
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

  static void _consoleLog(DriverCallLog log) {
    final color = _getColor(log.level);
    const reset = '\x1B[0m';
    final logStr = '${color}DriverCall: ${log.level.name.toUpperCase()} - ${log.message}$reset';
    print(logStr);
  }

  static String _getColor(CallLogLevel level) {
    switch (level) {
      case CallLogLevel.debug:
        return '\x1B[37m'; // White
      case CallLogLevel.info:
        return '\x1B[36m'; // Cyan
      case CallLogLevel.warning:
        return '\x1B[33m'; // Yellow
      case CallLogLevel.error:
        return '\x1B[31m'; // Red
      case CallLogLevel.critical:
        return '\x1B[35m'; // Magenta
    }
  }

  // Métodos específicos para logging de chamadas
  static void logCallInitiated({
    required String passengerId,
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.initiated,
      level: CallLogLevel.info,
      message: 'Chamada de viagem iniciada pelo passageiro',
      passengerId: passengerId,
      driverId: driverId,
      context: context,
    ));
  }

  static void logPhoneCallAttempt({
    required String passengerId,
    required String driverId,
    String? phoneNumber,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.phoneAttempt,
      level: CallLogLevel.info,
      message: 'Tentativa de ligação telefônica para o motorista',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'phoneNumber': phoneNumber,
        ...?context,
      },
    ));
  }

  static void logDriverSelected({
    required String passengerId,
    required String driverId,
    Map<String, dynamic>? driverInfo,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.driverSelected,
      level: CallLogLevel.info,
      message: 'Motorista selecionado para a viagem',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'driverInfo': driverInfo,
        ...?context,
      },
    ));
  }

  static void logValidationStarted({
    required String passengerId,
    String? driverId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.validationStarted,
      level: CallLogLevel.info,
      message: 'Iniciando validações antes de criar solicitação de viagem',
      passengerId: passengerId,
      driverId: driverId,
      context: context,
    ));
  }

  static void logValidationCompleted({
    required String passengerId,
    String? driverId,
    Map<String, dynamic>? validationResults,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.validationCompleted,
      level: CallLogLevel.info,
      message: 'Validações concluídas com sucesso',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'validationResults': validationResults,
        ...?context,
      },
    ));
  }

  static void logError({
    required String error,
    String? passengerId,
    String? driverId,
    StackTrace? stackTrace,
    String? errorCode,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.error,
      level: CallLogLevel.error,
      message: 'Erro durante processo de chamada: $error',
      passengerId: passengerId,
      driverId: driverId,
      context: context,
      stackTrace: stackTrace,
      errorCode: errorCode,
    ));
  }

  static void logWarning({
    required String message,
    String? passengerId,
    String? driverId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.error,
      level: CallLogLevel.warning,
      message: message,
      passengerId: passengerId,
      driverId: driverId,
      context: context,
    ));
  }

  static void logCallCompleted({
    required String passengerId,
    required String driverId,
    required String requestId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.callCompleted,
      level: CallLogLevel.info,
      message: 'Chamada de viagem concluída com sucesso',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'requestId': requestId,
        'status': 'completed',
        ...?context,
      },
    ));
  }

  static void logCallExpired({
    required String passengerId,
    String? driverId,
    required String requestId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.callExpired,
      level: CallLogLevel.warning,
      message: 'Chamada de viagem expirou sem resposta',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'requestId': requestId,
        'status': 'expired',
        ...?context,
      },
    ));
  }

  static void logCallRejected({
    required String passengerId,
    required String driverId,
    required String requestId,
    String? rejectionReason,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.callRejected,
      level: CallLogLevel.info,
      message: 'Chamada de viagem rejeitada pelo motorista',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'requestId': requestId,
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        ...?context,
      },
    ));
  }

  static void logCallTimeout({
    required String passengerId,
    String? driverId,
    required String requestId,
    int? timeoutSeconds,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.callTimeout,
      level: CallLogLevel.warning,
      message: 'Chamada de viagem atingiu o timeout',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'requestId': requestId,
        'status': 'timeout',
        'timeoutSeconds': timeoutSeconds,
        ...?context,
      },
    ));
  }

  // Métodos de log de sucesso adicionais
  static void logRequestCreated({
    required String passengerId,
    required String driverId,
    required String requestId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.requestCreated,
      level: CallLogLevel.info,
      message: 'Solicitação de viagem criada com sucesso',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'requestId': requestId,
        'status': 'created',
        ...?context,
      },
    ));
  }

  static void logNotificationSent({
    required String passengerId,
    required String driverId,
    required String requestId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.notificationSent,
      level: CallLogLevel.info,
      message: 'Notificação push enviada com sucesso para o motorista',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'requestId': requestId,
        'notificationType': 'push',
        ...?context,
      },
    ));
  }

  static void logFallbackActivated({
    required String passengerId,
    String? driverId,
    required String requestId,
    required String fallbackDriverId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.fallbackActivated,
      level: CallLogLevel.info,
      message: 'Sistema de fallback ativado - tentando próximo motorista',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'requestId': requestId,
        'fallbackDriverId': fallbackDriverId,
        'status': 'fallback_activated',
        ...?context,
      },
    ));
  }

  static void logDriverAvailable({
    required String passengerId,
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.driverAvailable,
      level: CallLogLevel.info,
      message: 'Motorista verificado e disponível para viagem',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'availabilityStatus': 'available',
        ...?context,
      },
    ));
  }

  static void logTransactionSuccess({
    required String passengerId,
    required String driverId,
    required String operation,
    Map<String, dynamic>? context,
  }) {
    log(DriverCallLog(
      operationType: CallOperationType.transactionSuccess,
      level: CallLogLevel.info,
      message: 'Transação concluída com sucesso',
      passengerId: passengerId,
      driverId: driverId,
      context: {
        'operation': operation,
        'transactionStatus': 'success',
        ...?context,
      },
    ));
  }
}