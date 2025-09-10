import 'dart:convert';
import 'package:intl/intl.dart';
import '../../exceptions/app_exceptions.dart';

/// Classe para consolidar e reportar erros relacionados a zonas excluídas
/// Fornece análise detalhada e relatórios sobre problemas no sistema de zonas
class ZoneErrorReport {
  final List<ZoneErrorEntry> _errors = [];
  final DateTime _createdAt = DateTime.now();
  
  /// Adiciona um erro ao relatório
  void addError({
    required String operation,
    required String driverId,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? zoneData,
  }) {
    _errors.add(ZoneErrorEntry(
      timestamp: DateTime.now(),
      operation: operation,
      driverId: driverId,
      error: error,
      stackTrace: stackTrace,
      context: context ?? {},
      zoneData: zoneData,
    ));
  }

  /// Adiciona uma exceção do tipo DatabaseException
  void addDatabaseException({
    required String operation,
    required String driverId,
    required DatabaseException exception,
    Map<String, dynamic>? context,
  }) {
    addError(
      operation: operation,
      driverId: driverId,
      error: exception.message,
      context: {
        'error_code': exception.code,
        'is_database_error': true,
        ...?context,
      },
    );
  }

  /// Adiciona uma exceção do tipo ValidationException
  void addValidationException({
    required String operation,
    required String driverId,
    required ValidationException exception,
    Map<String, dynamic>? zoneData,
  }) {
    addError(
      operation: operation,
      driverId: driverId,
      error: exception.message,
      context: {
        'is_validation_error': true,
        'validation_type': 'zone_validation',
      },
      zoneData: zoneData != null ? jsonEncode(zoneData) : null,
    );
  }

  /// Gera um resumo dos erros por tipo
  Map<String, dynamic> getErrorSummary() {
    if (_errors.isEmpty) {
      return {
        'total_errors': 0,
        'error_types': {},
        'operations': {},
        'drivers_affected': 0,
      };
    }

    final errorTypes = <String, int>{};
    final operations = <String, int>{};
    final driversAffected = <String>{};

    for (final error in _errors) {
      // Conta por tipo de erro
      final errorType = _getErrorType(error.error);
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;

      // Conta por operação
      operations[error.operation] = (operations[error.operation] ?? 0) + 1;

      // Registra drivers afetados
      driversAffected.add(error.driverId);
    }

    return {
      'total_errors': _errors.length,
      'error_types': errorTypes,
      'operations': operations,
      'drivers_affected': driversAffected.length,
      'most_common_error': _getMostCommonError(errorTypes),
      'most_problematic_operation': _getMostProblematicOperation(operations),
    };
  }

  /// Gera um relatório detalhado por driver
  Map<String, dynamic> getDriverReport(String driverId) {
    final driverErrors = _errors.where((e) => e.driverId == driverId).toList();
    
    if (driverErrors.isEmpty) {
      return {
        'driver_id': driverId,
        'total_errors': 0,
        'error_history': [],
      };
    }

    final errorTypes = <String, int>{};
    final operations = <String, int>{};

    for (final error in driverErrors) {
      final errorType = _getErrorType(error.error);
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
      operations[error.operation] = (operations[error.operation] ?? 0) + 1;
    }

    return {
      'driver_id': driverId,
      'total_errors': driverErrors.length,
      'error_types': errorTypes,
      'operations': operations,
      'error_history': driverErrors.map((e) => e.toJson()).toList(),
      'first_error': driverErrors.first.timestamp.toIso8601String(),
      'last_error': driverErrors.last.timestamp.toIso8601String(),
    };
  }

  /// Gera um relatório de erros por operação
  Map<String, dynamic> getOperationReport(String operation) {
    final operationErrors = _errors.where((e) => e.operation == operation).toList();
    
    if (operationErrors.isEmpty) {
      return {
        'operation': operation,
        'total_errors': 0,
        'success_rate': 100.0,
      };
    }

    final errorTypes = <String, int>{};
    final driversAffected = <String>{};

    for (final error in operationErrors) {
      final errorType = _getErrorType(error.error);
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
      driversAffected.add(error.driverId);
    }

    // Assume uma taxa de sucesso baseada no número de erros (estimativa)
    // Em produção, isso deveria ser baseado em dados reais de uso
    final estimatedTotalOperations = operationErrors.length * 10; // Estimativa conservadora
    final successRate = ((estimatedTotalOperations - operationErrors.length) / estimatedTotalOperations) * 100;

    return {
      'operation': operation,
      'total_errors': operationErrors.length,
      'error_types': errorTypes,
      'drivers_affected': driversAffected.length,
      'success_rate': successRate.clamp(0.0, 100.0),
      'error_frequency': _calculateErrorFrequency(operationErrors),
    };
  }

  /// Exporta o relatório completo em formato JSON
  String exportToJson() {
    final report = {
      'report_id': 'zone_error_report_${_createdAt.millisecondsSinceEpoch}',
      'generated_at': _createdAt.toIso8601String(),
      'summary': getErrorSummary(),
      'all_errors': _errors.map((e) => e.toJson()).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(report);
  }

  /// Gera um relatório em formato legível
  String generateReadableReport() {
    final buffer = StringBuffer();
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    
    buffer.writeln('=== RELATÓRIO DE ERROS DE ZONAS EXCLUÍDAS ===');
    buffer.writeln('Gerado em: ${formatter.format(_createdAt)}');
    buffer.writeln('');
    
    final summary = getErrorSummary();
    
    buffer.writeln('RESUMO:');
    buffer.writeln('- Total de erros: ${summary['total_errors']}');
    buffer.writeln('- Drivers afetados: ${summary['drivers_affected']}');
    buffer.writeln('');
    
    if (summary['error_types'].isNotEmpty) {
      buffer.writeln('TIPOS DE ERRO:');
      (summary['error_types'] as Map<String, dynamic>).forEach((type, count) {
        buffer.writeln('- $type: $count ocorrências');
      });
      buffer.writeln('');
    }
    
    if (summary['operations'].isNotEmpty) {
      buffer.writeln('OPERAÇÕES MAIS PROBLEMÁTICAS:');
      (summary['operations'] as Map<String, dynamic>).forEach((op, count) {
        buffer.writeln('- $op: $count erros');
      });
      buffer.writeln('');
    }
    
    if (_errors.isNotEmpty) {
      buffer.writeln('ÚLTIMOS 5 ERROS:');
      final recentErrors = _errors.take(5).toList();
      for (final error in recentErrors) {
        buffer.writeln('- ${formatter.format(error.timestamp)} | ${error.operation} | Driver: ${error.driverId}');
        buffer.writeln('  Erro: ${error.error}');
        if (error.context.isNotEmpty) {
          buffer.writeln('  Contexto: ${error.context}');
        }
      }
    }
    
    return buffer.toString();
  }

  /// Limpa todos os erros do relatório
  void clear() {
    _errors.clear();
  }

  /// Verifica se há erros no relatório
  bool get hasErrors => _errors.isNotEmpty;

  /// Retorna o número total de erros
  int get errorCount => _errors.length;

  /// Retorna os erros mais recentes (últimos N)
  List<ZoneErrorEntry> getRecentErrors([int count = 10]) {
    final sortedErrors = List<ZoneErrorEntry>.from(_errors)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedErrors.take(count).toList();
  }

  /// Métodos auxiliares estáticos para facilitar o uso
  static ZoneErrorReport createReport() {
    return ZoneErrorReport();
  }

  static void logDatabaseError({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    required String error,
    String? errorCode,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: error,
      stackTrace: stackTrace,
      context: {
        'error_code': errorCode,
        'is_database_error': true,
        ...?context,
      },
    );
  }

  static void logValidationError({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    required String error,
    Map<String, dynamic>? zoneData,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: error,
      context: {
        'is_validation_error': true,
        'validation_type': 'zone_validation',
        ...?context,
      },
      zoneData: zoneData != null ? jsonEncode(zoneData) : null,
    );
  }

  static void logPermissionError({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: 'Permissão negada',
      context: {
        'is_permission_error': true,
        ...?context,
      },
    );
  }

  static void logNetworkError({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    required String error,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: error,
      context: {
        'is_network_error': true,
        ...?context,
      },
    );
  }

  static void logUnexpectedError({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    required String error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: error,
      stackTrace: stackTrace,
      context: {
        'is_unexpected_error': true,
        ...?context,
      },
    );
  }

  static void logLimitExceeded({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: 'Limite de zonas excedido',
      context: {
        'is_limit_error': true,
        ...?context,
      },
    );
  }

  static void logDuplicateZone({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: 'Tentativa de adicionar zona duplicada',
      context: {
        'is_duplicate_error': true,
        ...?context,
      },
    );
  }

  static void logConstraintViolation({
    required ZoneErrorReport report,
    required String operation,
    required String driverId,
    Map<String, dynamic>? context,
  }) {
    report.addError(
      operation: operation,
      driverId: driverId,
      error: 'Violação de restrição de banco de dados',
      context: {
        'is_constraint_error': true,
        ...?context,
      },
    );
  }

  // Métodos privados auxiliares
  
  String _getErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('database') || errorString.contains('conexão')) {
      return 'database_error';
    } else if (errorString.contains('validação') || errorString.contains('validation')) {
      return 'validation_error';
    } else if (errorString.contains('limite') || errorString.contains('limit')) {
      return 'limit_error';
    } else if (errorString.contains('permissão') || errorString.contains('permission')) {
      return 'permission_error';
    } else {
      return 'unknown_error';
    }
  }

  String _getMostCommonError(Map<String, int> errorTypes) {
    if (errorTypes.isEmpty) return 'none';
    
    String mostCommon = errorTypes.keys.first;
    int maxCount = errorTypes.values.first;
    
    errorTypes.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = type;
      }
    });
    
    return mostCommon;
  }

  String _getMostProblematicOperation(Map<String, int> operations) {
    if (operations.isEmpty) return 'none';
    
    String mostProblematic = operations.keys.first;
    int maxCount = operations.values.first;
    
    operations.forEach((op, count) {
      if (count > maxCount) {
        maxCount = count;
        mostProblematic = op;
      }
    });
    
    return mostProblematic;
  }

  Map<String, dynamic> _calculateErrorFrequency(List<ZoneErrorEntry> errors) {
    if (errors.isEmpty) return {};
    
    final timeSpans = <int>[];
    for (int i = 1; i < errors.length; i++) {
      final diff = errors[i].timestamp.difference(errors[i-1].timestamp).inMinutes;
      timeSpans.add(diff);
    }
    
    if (timeSpans.isEmpty) return {'average_minutes_between_errors': 0};
    
    final average = timeSpans.reduce((a, b) => a + b) / timeSpans.length;
    
    return {
      'average_minutes_between_errors': average.round(),
      'total_time_span_minutes': errors.last.timestamp.difference(errors.first.timestamp).inMinutes,
    };
  }
}

/// Classe que representa uma entrada de erro individual
class ZoneErrorEntry {
  final DateTime timestamp;
  final String operation;
  final String driverId;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic> context;
  final String? zoneData;

  ZoneErrorEntry({
    required this.timestamp,
    required this.operation,
    required this.driverId,
    required this.error,
    this.stackTrace,
    required this.context,
    this.zoneData,
  });

  /// Converte a entrada de erro para JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'operation': operation,
      'driver_id': driverId,
      'error': error.toString(),
      'stack_trace': stackTrace?.toString(),
      'context': context,
      'zone_data': zoneData,
    };
  }
}