import 'package:flutter/foundation.dart';
import 'zone_error_report.dart';
import '../../exceptions/app_exceptions.dart';

/// Exemplo de uso da classe ZoneErrorReport
/// Demonstra como integrar o sistema de relatórios de erros ao código existente
class ZoneErrorReportExample {
  
  /// Exemplo de uso com o serviço de zonas excluídas
  static void demonstrateUsage() {
    final errorReport = ZoneErrorReport();
    
    // Exemplo 1: Adicionando um erro de banco de dados
    try {
      // Simula uma operação que falha
      throw const DatabaseException('Erro de conexão com o banco de dados', 'DB_CONNECTION_ERROR');
    } catch (e, stackTrace) {
      errorReport.addError(
        operation: 'fetch_excluded_zones',
        driverId: 'driver_123',
        error: e,
        stackTrace: stackTrace,
        context: {
          'database_host': 'localhost',
          'database_port': 5432,
          'retry_count': 3,
        },
      );
    }
    
    // Exemplo 2: Adicionando uma exceção de validação específica
    errorReport.addValidationException(
      operation: 'validate_zone_coordinates',
      driverId: 'driver_456',
      exception: const ValidationException('Coordenadas inválidas fornecidas', 'INVALID_COORDINATES'),
      zoneData: {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'radius': -100, // Raio inválido (negativo)
      },
    );
    
    // Exemplo 3: Adicionando um erro genérico
    errorReport.addError(
      operation: 'update_excluded_zone',
      driverId: 'driver_789',
      error: 'Timeout ao atualizar zona excluída',
      context: {
        'timeout_duration': 30,
        'zone_id': 'zone_abc123',
        'attempt_number': 2,
      },
    );
    
    // Gerando relatórios
    debugPrint('=== RESUMO DE ERROS ===');
    final summary = errorReport.getErrorSummary();
    debugPrint('Total de erros: ${summary['total_errors']}');
    debugPrint('Drivers afetados: ${summary['drivers_affected']}');
    
    debugPrint('\n=== RELATÓRIO POR DRIVER ===');
    final driverReport = errorReport.getDriverReport('driver_123');
    debugPrint('Erros do driver_123: ${driverReport['total_errors']}');
    
    debugPrint('\n=== RELATÓRIO POR OPERAÇÃO ===');
    final operationReport = errorReport.getOperationReport('fetch_excluded_zones');
    debugPrint('Erros em fetch_excluded_zones: ${operationReport['total_errors']}');
    debugPrint('Taxa de sucesso estimada: ${operationReport['success_rate']}%');
    
    debugPrint('\n=== RELATÓRIO LEGÍVEL ===');
    debugPrint(errorReport.generateReadableReport());
    
    debugPrint('\n=== RELATÓRIO JSON ===');
    debugPrint(errorReport.exportToJson());
  }
  
  /// Exemplo de integração com o ZoneExclusionLogger existente
  static void demonstrateIntegrationWithLogger() {
    final errorReport = ZoneErrorReport();
    
    // Simula o contexto do ZoneExclusionLogger
    final context = {
      'driverId': 'driver_integration_test',
      'operation': 'sync_excluded_zones',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    try {
      // Simula um erro que poderia ocorrer no ZoneExclusionLogger
      throw Exception('Falha ao sincronizar zonas do servidor');
    } catch (e, stackTrace) {
      // Loga no sistema existente e adiciona ao relatório
      errorReport.addError(
        operation: context['operation'] as String,
        driverId: context['driverId'] as String,
        error: e,
        stackTrace: stackTrace,
        context: context,
      );
      
      debugPrint('Erro registrado no ZoneErrorReport: $e');
    }
    
    // Gera relatório específico para debugging
    final report = errorReport.generateReadableReport();
    debugPrint('Relatório de integração gerado:\n$report');
  }
  
  /// Exemplo de uso em produção com coleta periódica
  static void demonstrateProductionUsage() {
    final errorReport = ZoneErrorReport();
    
    // Simula múltiplos erros ao longo do tempo
    final errors = [
      {
        'operation': 'load_excluded_zones',
        'driverId': 'drv_001',
        'error': 'Zona não encontrada no banco de dados',
        'context': {'zone_id': 'zone_missing_123'},
      },
      {
        'operation': 'validate_zone_bounds',
        'driverId': 'drv_002',
        'error': 'Área da zona excede limite permitido',
        'context': {'area_km2': 150, 'max_allowed': 100},
      },
      {
        'operation': 'save_excluded_zone',
        'driverId': 'drv_003',
        'error': 'Conflito com zona existente',
        'context': {'overlapping_zones': ['zone_a', 'zone_b']},
      },
    ];
    
    // Adiciona todos os erros ao relatório
    for (final errorData in errors) {
      errorReport.addError(
        operation: errorData['operation'] as String,
        driverId: errorData['driverId'] as String,
        error: errorData['error'] as String,
        context: errorData['context'] as Map<String, dynamic>,
      );
    }
    
    // Análise de produção
    debugPrint('=== ANÁLISE DE PRODUÇÃO ===');
    
    // Verifica se há erros críticos
    if (errorReport.hasErrors) {
      debugPrint('⚠️  Foram detectados ${errorReport.errorCount} erros');
      
      // Obtém os erros mais recentes para análise imediata
      final recentErrors = errorReport.getRecentErrors(3);
      debugPrint('Últimos 3 erros:');
      for (final error in recentErrors) {
        debugPrint('- ${error.operation}: ${error.error}');
      }
      
      // Gera um relatório JSON para envio ao servidor de monitoramento
      final jsonReport = errorReport.exportToJson();
      debugPrint('Relatório JSON gerado (${jsonReport.length} caracteres)');
      
      // Em produção, aqui você poderia:
      // 1. Enviar o relatório para um serviço de monitoramento
      // 2. Salvar em arquivo local para análise posterior
      // 3. Disparar alertas para a equipe de desenvolvimento
      // 4. Limpar o relatório após o envio
    }
  }
  
  /// Demonstra como limpar o relatório após análise
  static void demonstrateCleanup() {
    final errorReport = ZoneErrorReport();
    
    // Adiciona alguns erros
    errorReport.addError(
      operation: 'test_operation',
      driverId: 'test_driver',
      error: 'Erro de teste',
    );
    
    debugPrint('Erros antes da limpeza: ${errorReport.errorCount}');
    
    // Limpa o relatório
    errorReport.clear();
    
    debugPrint('Erros após limpeza: ${errorReport.errorCount}');
    debugPrint('Relatório está vazio: ${!errorReport.hasErrors}');
  }
}