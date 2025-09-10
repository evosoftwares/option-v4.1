import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'zone_exclusion_logger.dart';
import 'zone_error_report.dart';
import '../../exceptions/app_exceptions.dart';

/// Integração entre ZoneExclusionLogger e ZoneErrorReport
/// Fornece uma interface unificada para logging e relatórios de erros
class ZoneExclusionLoggerWithReporting {
  final ZoneExclusionLogger _logger;
  final ZoneErrorReport _errorReport;
  
  ZoneExclusionLoggerWithReporting({
    ZoneExclusionLogger? logger,
    ZoneErrorReport? errorReport,
  }) : _logger = logger ?? ZoneExclusionLogger(),
       _errorReport = errorReport ?? ZoneErrorReport();
  
  /// Logger existente com funcionalidade adicional de relatórios
  ZoneExclusionLogger get logger => _logger;
  
  /// Relatório de erros consolidado
  ZoneErrorReport get errorReport => _errorReport;
  
  /// Loga uma operação bem-sucedida e limpa erros antigos se necessário
  void logSuccess({
    required String operation,
    required String driverId,
    Map<String, dynamic>? metadata,
  }) {
    // Usa o método apropriado baseado na operação
    switch (operation.toLowerCase()) {
      case 'add':
        ZoneExclusionLogger.logAddSuccess(
          driverId: driverId,
          neighborhood: metadata?['neighborhood'] ?? 'unknown',
          city: metadata?['city'] ?? 'unknown',
          state: metadata?['state'] ?? 'unknown',
          zoneId: metadata?['zoneId'],
        );
        break;
      case 'remove':
        ZoneExclusionLogger.logRemoveSuccess(
          driverId: driverId,
          zoneId: metadata?['zoneId'] ?? 'unknown',
          context: metadata,
        );
        break;
      case 'validation':
        ZoneExclusionLogger.logValidationSuccess(
          driverId: driverId,
          field: metadata?['field'],
          context: metadata,
        );
        break;
      case 'query':
        ZoneExclusionLogger.logQuerySuccess(
          driverId: driverId,
          query: metadata?['query'] ?? operation,
          context: metadata,
        );
        break;
      default:
        ZoneExclusionLogger.log(
          ZoneExclusionLog(
            operationType: ZoneOperationType.database,
            level: ZoneLogLevel.info,
            message: 'Operação bem-sucedida: $operation',
            driverId: driverId,
            context: metadata,
          ),
        );
    }
    
    // Opcional: limpar erros antigos do mesmo tipo se a operação for bem-sucedida
    _cleanupOldErrorsIfNeeded(operation, driverId);
  }
  
  /// Loga um erro e o adiciona ao relatório de erros
  void logError({
    required String operation,
    required String driverId,
    required String error,
    String? errorCode,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    // Loga usando o método estático apropriado
    ZoneExclusionLogger.logDatabaseError(
      operation: operation,
      driverId: driverId,
      error: error,
      context: {
        'error_code': errorCode,
        ...?metadata,
      },
    );
    
    // Adiciona ao relatório de erros usando o método estático
    ZoneErrorReport.logDatabaseError(
      report: _errorReport,
      operation: operation,
      driverId: driverId,
      error: error,
      errorCode: errorCode,
      stackTrace: stackTrace,
      context: metadata,
    );
  }
  
  /// Loga uma operação crítica
  void logCritical({
    required String operation,
    required String driverId,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    // Loga como erro crítico usando o logger
    ZoneExclusionLogger.logDatabaseError(
      operation: operation,
      driverId: driverId,
      error: message,
      context: {
        'level': 'critical',
        ...?metadata,
      },
    );
    
    // Adiciona ao relatório com prioridade crítica
    ZoneErrorReport.logUnexpectedError(
      report: _errorReport,
      operation: operation,
      driverId: driverId,
      error: message,
      context: {
        'is_critical': true,
        ...?metadata,
      },
    );
  }
  
  /// Loga uma exceção de validação específica
  void logValidationError({
    required String operation,
    required String driverId,
    required ValidationException exception,
    Map<String, dynamic>? zoneData,
    Map<String, dynamic>? metadata,
  }) {
    // Loga a validação com erro usando o logger
    ZoneExclusionLogger.logValidationError(
      driverId: driverId,
      field: metadata?['field'] ?? 'unknown',
      error: exception.message,
      context: {
        'operation': operation,
        'error_code': exception.code,
        'zone_data': zoneData,
        ...?metadata,
      },
    );
    
    // Adiciona ao relatório de erros
    _errorReport.addValidationException(
      operation: operation,
      driverId: driverId,
      exception: exception,
      zoneData: zoneData,
    );
  }
  
  /// Gera um relatório consolidado combinando logs e erros
  Map<String, dynamic> generateReport() {
    final errorSummary = _errorReport.getErrorSummary();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'error_summary': errorSummary,
      'combined_analysis': _calculateSystemHealth({}, errorSummary),
      'recommendations': _generateRecommendations({}, errorSummary),
    };
  }
  
  /// Exporta todos os logs e relatórios em formato JSON
  String exportCompleteReport() {
    final report = generateReport();
    final errorReportJson = _errorReport.exportToJson();
    
    return jsonEncode({
      'report': report,
      'detailed_errors': jsonDecode(errorReportJson),
      'export_timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Limpa logs antigos e erros resolvidos
  void cleanup({
    bool clearLogs = false,
    bool clearErrors = false,
    Duration? maxAge,
  }) {
    if (clearLogs) {
      // O ZoneExclusionLogger não tem método de limpeza direto,
      // mas poderia ser implementado se necessário
    }
    
    if (clearErrors) {
      _errorReport.clear();
    }
    
    // Opcional: implementar limpeza baseada em idade
    if (maxAge != null) {
      _cleanupByAge(maxAge);
    }
  }
  
  /// Verifica se há problemas críticos que requerem atenção imediata
  bool hasCriticalIssues() {
    final errorSummary = _errorReport.getErrorSummary();
    final totalErrors = errorSummary['total_errors'] as int;
    
    // Define critérios para problemas críticos
    if (totalErrors > 10) return true;
    
    final errorTypes = errorSummary['error_types'] as Map<String, dynamic>;
    if (errorTypes['database_error'] != null && errorTypes['database_error'] > 5) {
      return true;
    }
    
    return false;
  }
  
  /// Dispara alertas se houver problemas críticos
  void checkAndAlert() {
    if (hasCriticalIssues()) {
      final report = generateReport();
      
      // Em produção, aqui você poderia:
      // 1. Enviar notificação push
      // 2. Enviar email para a equipe
      // 3. Disparar webhook para sistema de monitoramento
      // 4. Registrar em serviço externo (Sentry, etc.)
      
      if (kDebugMode) {
        debugPrint('🚨 ALERTA: Problemas críticos detectados!');
        debugPrint('Relatório: ${jsonEncode(report)}');
      }
    }
  }
  
  // Métodos privados auxiliares
  
  void _cleanupOldErrorsIfNeeded(String operation, String driverId) {
    // Implementação opcional: limpar erros antigos da mesma operação
    // se ela for bem-sucedida agora
  }
  
  Map<String, dynamic> _calculateSystemHealth(
    Map<String, dynamic> loggerStats,
    Map<String, dynamic> errorSummary,
  ) {
    final totalOperations = loggerStats['total_operations'] as int;
    final totalErrors = errorSummary['total_errors'] as int;
    
    double successRate = 0.0;
    if (totalOperations > 0) {
      successRate = ((totalOperations - totalErrors) / totalOperations) * 100;
    }
    
    String healthStatus;
    if (successRate >= 95) {
      healthStatus = 'excellent';
    } else if (successRate >= 85) {
      healthStatus = 'good';
    } else if (successRate >= 70) {
      healthStatus = 'warning';
    } else {
      healthStatus = 'critical';
    }
    
    return {
      'success_rate': successRate,
      'health_status': healthStatus,
      'total_operations': totalOperations,
      'total_errors': totalErrors,
    };
  }
  
  List<String> _generateRecommendations(
    Map<String, dynamic> loggerStats,
    Map<String, dynamic> errorSummary,
  ) {
    final recommendations = <String>[];
    
    final errorTypes = errorSummary['error_types'] as Map<String, dynamic>;
    final totalErrors = errorSummary['total_errors'] as int;
    
    if (errorTypes['database_error'] != null && errorTypes['database_error'] > 3) {
      recommendations.add('Verificar conexão com banco de dados');
      recommendations.add('Implementar retry mechanism para operações de banco');
    }
    
    if (errorTypes['validation_error'] != null && errorTypes['validation_error'] > 5) {
      recommendations.add('Revisar validação de dados de entrada');
      recommendations.add('Melhorar feedback para usuários sobre erros de validação');
    }
    
    if (totalErrors > 10) {
      recommendations.add('Investigar padrão de erros recorrentes');
      recommendations.add('Considerar implementação de circuit breaker');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Sistema funcionando normalmente');
    }
    
    return recommendations;
  }
  
  void _cleanupByAge(Duration maxAge) {
    // Implementação futura: limpar erros mais antigos que maxAge
    // Isso requereria modificar a classe ZoneErrorReport para suportar
    // remoção seletiva de erros
  }
}

/// Classe auxiliar para facilitar o uso singleton
class ZoneExclusionLoggerWithReportingSingleton {
  static ZoneExclusionLoggerWithReporting? _instance;
  
  static ZoneExclusionLoggerWithReporting get instance {
    _instance ??= ZoneExclusionLoggerWithReporting();
    return _instance!;
  }
  
  static void reset() {
    _instance = null;
  }
}