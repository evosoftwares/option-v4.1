import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'monitoring_service.dart';
import 'metrics_service.dart';

/// Enum para status de health check
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
  unknown,
}

/// Modelo para resultado de health check
class HealthCheckResult {
  final String serviceName;
  final HealthStatus status;
  final Duration responseTime;
  final String? errorMessage;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  HealthCheckResult({
    required this.serviceName,
    required this.status,
    required this.responseTime,
    this.errorMessage,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'service_name': serviceName,
        'status': status.name,
        'response_time_ms': responseTime.inMilliseconds,
        'error_message': errorMessage,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    return HealthCheckResult(
      serviceName: json['service_name'],
      status: HealthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => HealthStatus.unknown,
      ),
      responseTime: Duration(milliseconds: json['response_time_ms']),
      errorMessage: json['error_message'],
      metadata: json['metadata'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Configuração para health check de um serviço
class HealthCheckConfig {
  final String serviceName;
  final String endpoint;
  final Duration timeout;
  final Duration interval;
  final Map<String, String> headers;
  final int expectedStatusCode;
  final String? expectedResponsePattern;
  final bool enabled;

  const HealthCheckConfig({
    required this.serviceName,
    required this.endpoint,
    this.timeout = const Duration(seconds: 10),
    this.interval = const Duration(minutes: 1),
    this.headers = const {},
    this.expectedStatusCode = 200,
    this.expectedResponsePattern,
    this.enabled = true,
  });
}

/// Serviço para monitoramento de health checks
class HealthCheckService {
  static final HealthCheckService _instance = HealthCheckService._internal();
  factory HealthCheckService() => _instance;
  HealthCheckService._internal();

  final Dio _dio = Dio();
  final Map<String, Timer> _timers = {};
  final Map<String, HealthCheckResult> _lastResults = {};
  final List<HealthCheckConfig> _configs = [];
  bool _isInitialized = false;

  /// Configurações padrão para serviços externos
  static const List<HealthCheckConfig> defaultConfigs = [
    HealthCheckConfig(
      serviceName: 'supabase_api',
      endpoint: 'https://your-project.supabase.co/rest/v1/',
      timeout: Duration(seconds: 5),
      interval: Duration(minutes: 2),
      headers: {'apikey': 'your-anon-key'},
    ),
    HealthCheckConfig(
      serviceName: 'google_maps_api',
      endpoint: 'https://maps.googleapis.com/maps/api/geocode/json?address=test&key=YOUR_API_KEY',
      timeout: Duration(seconds: 10),
      interval: Duration(minutes: 5),
    ),
    HealthCheckConfig(
      serviceName: 'payment_gateway',
      endpoint: 'https://api.stripe.com/v1/charges',
      timeout: Duration(seconds: 15),
      interval: Duration(minutes: 3),
      headers: {'Authorization': 'Bearer YOUR_SECRET_KEY'},
    ),
    HealthCheckConfig(
      serviceName: 'notification_service',
      endpoint: 'https://fcm.googleapis.com/fcm/send',
      timeout: Duration(seconds: 8),
      interval: Duration(minutes: 2),
      headers: {'Authorization': 'key=YOUR_SERVER_KEY'},
    ),
  ];

  /// Inicializa o serviço de health check
  Future<void> initialize({
    List<HealthCheckConfig>? customConfigs,
  }) async {
    if (_isInitialized) return;

    try {
      // Adiciona configurações padrão e customizadas
      _configs.addAll(defaultConfigs);
      if (customConfigs != null) {
        _configs.addAll(customConfigs);
      }

      // Configura o Dio
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);

      // Inicia health checks periódicos
      _startPeriodicHealthChecks();

      _isInitialized = true;
      MonitoringService.logInfo('HealthCheckService inicializado com ${_configs.length} serviços');
    } catch (e) {
      MonitoringService.logError('Erro ao inicializar HealthCheckService: $e');
      rethrow;
    }
  }

  /// Inicia health checks periódicos para todos os serviços
  void _startPeriodicHealthChecks() {
    for (final config in _configs) {
      if (!config.enabled) continue;

      _timers[config.serviceName] = Timer.periodic(
        config.interval,
        (_) => _performHealthCheck(config),
      );

      // Executa o primeiro check imediatamente
      _performHealthCheck(config);
    }
  }

  /// Executa health check para um serviço específico
  Future<HealthCheckResult> _performHealthCheck(HealthCheckConfig config) async {
    final stopwatch = Stopwatch()..start();
    HealthCheckResult result;

    try {
      final response = await _dio.get(
        config.endpoint,
        options: Options(
          headers: config.headers,
          sendTimeout: config.timeout,
          receiveTimeout: config.timeout,
        ),
      );

      stopwatch.stop();

      // Verifica status code
      final isStatusOk = response.statusCode == config.expectedStatusCode;
      
      // Verifica padrão de resposta se especificado
      bool isResponseOk = true;
      if (config.expectedResponsePattern != null) {
        final responseBody = response.data.toString();
        isResponseOk = responseBody.contains(config.expectedResponsePattern!);
      }

      final status = (isStatusOk && isResponseOk) 
          ? HealthStatus.healthy 
          : HealthStatus.degraded;

      result = HealthCheckResult(
        serviceName: config.serviceName,
        status: status,
        responseTime: stopwatch.elapsed,
        metadata: {
          'status_code': response.statusCode,
          'response_size': response.data.toString().length,
          'endpoint': config.endpoint,
        },
      );
    } catch (e) {
      stopwatch.stop();
      
      result = HealthCheckResult(
        serviceName: config.serviceName,
        status: HealthStatus.unhealthy,
        responseTime: stopwatch.elapsed,
        errorMessage: e.toString(),
        metadata: {
          'endpoint': config.endpoint,
          'error_type': e.runtimeType.toString(),
        },
      );
    }

    // Armazena resultado e registra métricas
    _lastResults[config.serviceName] = result;
    await _recordHealthCheckMetrics(result);
    await _logHealthCheckResult(result);

    return result;
  }

  /// Registra métricas do health check
  Future<void> _recordHealthCheckMetrics(HealthCheckResult result) async {
    try {
      // Métrica de status (0=unhealthy, 1=degraded, 2=healthy)
      final statusValue = switch (result.status) {
        HealthStatus.healthy => 2.0,
        HealthStatus.degraded => 1.0,
        HealthStatus.unhealthy => 0.0,
        HealthStatus.unknown => -1.0,
      };
      
      MetricsService.setGauge(
        'health_check_status',
        statusValue,
        labels: {'service': result.serviceName},
      );
      
      // Métrica de tempo de resposta
      MetricsService.observeHistogram(
        'health_check_response_time',
        result.responseTime.inMilliseconds.toDouble(),
        labels: {'service': result.serviceName},
      );
      
      // Contador de checks
      MetricsService.incrementCounter(
        'health_check_total',
        labels: {'service': result.serviceName, 'status': result.status.name},
      );
    } catch (e) {
      MonitoringService.logError('Erro ao registrar métricas de health check: $e');
    }
  }

  /// Registra resultado do health check nos logs
  Future<void> _logHealthCheckResult(HealthCheckResult result) async {
    try {
      final logData = {
        'service_name': result.serviceName,
        'status': result.status.name,
        'response_time_ms': result.responseTime.inMilliseconds,
        'error_message': result.errorMessage,
        'metadata': result.metadata,
      };

      if (result.status == HealthStatus.unhealthy) {
        MonitoringService.logError(
          'Health check falhou para ${result.serviceName}: ${result.errorMessage}',
        );
      } else {
        MonitoringService.logInfo(
          'Health check para ${result.serviceName}: ${result.status.name}',
        );
      }
    } catch (e) {
      print('Erro ao registrar log de health check: $e');
    }
  }

  /// Executa health check manual para um serviço
  Future<HealthCheckResult> checkService(String serviceName) async {
    final config = _configs.firstWhere(
      (c) => c.serviceName == serviceName,
      orElse: () => throw ArgumentError('Serviço $serviceName não encontrado'),
    );
    
    return await _performHealthCheck(config);
  }

  /// Executa health check para todos os serviços
  Future<List<HealthCheckResult>> checkAllServices() async {
    final results = <HealthCheckResult>[];
    
    for (final config in _configs) {
      if (config.enabled) {
        final result = await _performHealthCheck(config);
        results.add(result);
      }
    }
    
    return results;
  }

  /// Obtém o último resultado de health check para um serviço
  HealthCheckResult? getLastResult(String serviceName) {
    return _lastResults[serviceName];
  }

  /// Obtém todos os últimos resultados
  Map<String, HealthCheckResult> getAllLastResults() {
    return Map.from(_lastResults);
  }

  /// Obtém status geral do sistema
  HealthStatus getOverallStatus() {
    if (_lastResults.isEmpty) return HealthStatus.unknown;
    
    final statuses = _lastResults.values.map((r) => r.status).toList();
    
    if (statuses.any((s) => s == HealthStatus.unhealthy)) {
      return HealthStatus.unhealthy;
    }
    
    if (statuses.any((s) => s == HealthStatus.degraded)) {
      return HealthStatus.degraded;
    }
    
    if (statuses.every((s) => s == HealthStatus.healthy)) {
      return HealthStatus.healthy;
    }
    
    return HealthStatus.unknown;
  }

  /// Obtém estatísticas de health check
  Map<String, dynamic> getHealthStatistics() {
    final results = _lastResults.values.toList();
    
    if (results.isEmpty) {
      return {
        'total_services': 0,
        'healthy_count': 0,
        'degraded_count': 0,
        'unhealthy_count': 0,
        'average_response_time_ms': 0,
        'overall_status': HealthStatus.unknown.name,
      };
    }
    
    final healthyCount = results.where((r) => r.status == HealthStatus.healthy).length;
    final degradedCount = results.where((r) => r.status == HealthStatus.degraded).length;
    final unhealthyCount = results.where((r) => r.status == HealthStatus.unhealthy).length;
    
    final avgResponseTime = results
        .map((r) => r.responseTime.inMilliseconds)
        .reduce((a, b) => a + b) / results.length;
    
    return {
      'total_services': results.length,
      'healthy_count': healthyCount,
      'degraded_count': degradedCount,
      'unhealthy_count': unhealthyCount,
      'average_response_time_ms': avgResponseTime.round(),
      'overall_status': getOverallStatus().name,
      'last_check': results.map((r) => r.timestamp).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String(),
    };
  }

  /// Adiciona configuração de health check customizada
  void addHealthCheckConfig(HealthCheckConfig config) {
    _configs.add(config);
    
    if (_isInitialized && config.enabled) {
      _timers[config.serviceName] = Timer.periodic(
        config.interval,
        (_) => _performHealthCheck(config),
      );
      
      // Executa o primeiro check
      _performHealthCheck(config);
    }
  }

  /// Remove configuração de health check
  void removeHealthCheckConfig(String serviceName) {
    _configs.removeWhere((c) => c.serviceName == serviceName);
    _timers[serviceName]?.cancel();
    _timers.remove(serviceName);
    _lastResults.remove(serviceName);
  }

  /// Para todos os health checks
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _lastResults.clear();
    _isInitialized = false;
  }
}

/// Extensão para facilitar uso do HealthCheckService
extension HealthCheckExtension on Object {
  /// Executa health check para um serviço
  Future<HealthCheckResult> checkServiceHealth(String serviceName) {
    return HealthCheckService().checkService(serviceName);
  }
  
  /// Obtém status geral do sistema
  HealthStatus getSystemHealth() {
    return HealthCheckService().getOverallStatus();
  }
}