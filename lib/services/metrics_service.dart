import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'monitoring_service.dart';

/// Serviço para coleta e exposição de métricas do sistema
class MetricsService {
  static final Map<String, int> _counters = {};
  static final Map<String, double> _gauges = {};
  static final Map<String, List<double>> _histograms = {};
  static final Map<String, DateTime> _lastUpdated = {};
  
  static Timer? _metricsTimer;
  static bool _isInitialized = false;

  /// Inicializa o serviço de métricas
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    // Inicializar métricas básicas
    _initializeBasicMetrics();
    
    // Iniciar coleta periódica de métricas
    _startPeriodicCollection();
    
    MonitoringService.logInfo('Metrics service initialized');
  }

  /// Inicializa métricas básicas do sistema
  static void _initializeBasicMetrics() {
    // Contadores
    _counters['zone_operations_total'] = 0;
    _counters['api_requests_total'] = 0;
    _counters['errors_total'] = 0;
    _counters['validation_failures_total'] = 0;
    
    // Gauges
    _gauges['active_zones_count'] = 0;
    _gauges['active_drivers_count'] = 0;
    _gauges['memory_usage_mb'] = 0;
    _gauges['cpu_usage_percent'] = 0;
    
    // Histogramas
    _histograms['zone_operation_duration_ms'] = [];
    _histograms['api_response_time_ms'] = [];
    _histograms['database_query_duration_ms'] = [];
  }

  /// Inicia coleta periódica de métricas
  static void _startPeriodicCollection() {
    _metricsTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _collectSystemMetrics();
      _sendMetricsToBackend();
    });
  }

  /// Para a coleta de métricas
  static void dispose() {
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _isInitialized = false;
  }

  // =====================================================
  // CONTADORES
  // =====================================================

  /// Incrementa um contador
  static void incrementCounter(String name, {Map<String, String>? labels, int value = 1}) {
    final key = _buildMetricKey(name, labels);
    _counters[key] = (_counters[key] ?? 0) + value;
    _lastUpdated[key] = DateTime.now();
    
    if (kDebugMode) {
      print('METRIC: Counter $key incremented by $value to ${_counters[key]}');
    }
  }

  /// Obtém valor de um contador
  static int getCounter(String name, {Map<String, String>? labels}) {
    final key = _buildMetricKey(name, labels);
    return _counters[key] ?? 0;
  }

  // =====================================================
  // GAUGES
  // =====================================================

  /// Define valor de um gauge
  static void setGauge(String name, double value, {Map<String, String>? labels}) {
    final key = _buildMetricKey(name, labels);
    _gauges[key] = value;
    _lastUpdated[key] = DateTime.now();
    
    if (kDebugMode) {
      print('METRIC: Gauge $key set to $value');
    }
  }

  /// Incrementa um gauge
  static void incrementGauge(String name, double value, {Map<String, String>? labels}) {
    final key = _buildMetricKey(name, labels);
    _gauges[key] = (_gauges[key] ?? 0) + value;
    _lastUpdated[key] = DateTime.now();
  }

  /// Decrementa um gauge
  static void decrementGauge(String name, double value, {Map<String, String>? labels}) {
    final key = _buildMetricKey(name, labels);
    _gauges[key] = (_gauges[key] ?? 0) - value;
    _lastUpdated[key] = DateTime.now();
  }

  /// Obtém valor de um gauge
  static double getGauge(String name, {Map<String, String>? labels}) {
    final key = _buildMetricKey(name, labels);
    return _gauges[key] ?? 0.0;
  }

  // =====================================================
  // HISTOGRAMAS
  // =====================================================

  /// Observa um valor em um histograma
  static void observeHistogram(String name, double value, {Map<String, String>? labels}) {
    final key = _buildMetricKey(name, labels);
    _histograms[key] ??= [];
    _histograms[key]!.add(value);
    _lastUpdated[key] = DateTime.now();
    
    // Manter apenas as últimas 1000 observações
    if (_histograms[key]!.length > 1000) {
      _histograms[key]!.removeAt(0);
    }
    
    if (kDebugMode) {
      print('METRIC: Histogram $key observed value $value');
    }
  }

  /// Obtém estatísticas de um histograma
  static Map<String, double> getHistogramStats(String name, {Map<String, String>? labels}) {
    final key = _buildMetricKey(name, labels);
    final values = _histograms[key] ?? [];
    
    if (values.isEmpty) {
      return {
        'count': 0,
        'sum': 0,
        'avg': 0,
        'min': 0,
        'max': 0,
        'p50': 0,
        'p95': 0,
        'p99': 0,
      };
    }
    
    final sortedValues = List<double>.from(values)..sort();
    final count = values.length;
    final sum = values.reduce((a, b) => a + b);
    
    return {
      'count': count.toDouble(),
      'sum': sum,
      'avg': sum / count,
      'min': sortedValues.first,
      'max': sortedValues.last,
      'p50': _percentile(sortedValues, 0.5),
      'p95': _percentile(sortedValues, 0.95),
      'p99': _percentile(sortedValues, 0.99),
    };
  }

  // =====================================================
  // MÉTRICAS ESPECÍFICAS DO NEGÓCIO
  // =====================================================

  /// Registra operação de zona
  static void recordZoneOperation(String operation, String status, Duration duration) {
    incrementCounter('zone_operations_total', labels: {
      'operation': operation,
      'status': status,
    });
    
    observeHistogram('zone_operation_duration_ms', duration.inMilliseconds.toDouble(), labels: {
      'operation': operation,
    });
    
    if (status == 'error') {
      incrementCounter('errors_total', labels: {
        'service': 'zone_service',
        'operation': operation,
      });
    }
  }

  /// Registra requisição de API
  static void recordApiRequest(String endpoint, int statusCode, Duration duration) {
    incrementCounter('api_requests_total', labels: {
      'endpoint': endpoint,
      'status_code': statusCode.toString(),
    });
    
    observeHistogram('api_response_time_ms', duration.inMilliseconds.toDouble(), labels: {
      'endpoint': endpoint,
    });
    
    if (statusCode >= 400) {
      incrementCounter('errors_total', labels: {
        'service': 'api',
        'endpoint': endpoint,
      });
    }
  }

  /// Registra query de banco de dados
  static void recordDatabaseQuery(String queryType, Duration duration, {bool hasError = false}) {
    observeHistogram('database_query_duration_ms', duration.inMilliseconds.toDouble(), labels: {
      'query_type': queryType,
    });
    
    if (hasError) {
      incrementCounter('errors_total', labels: {
        'service': 'database',
        'query_type': queryType,
      });
    }
  }

  /// Registra falha de validação
  static void recordValidationFailure(String validationType, String reason) {
    incrementCounter('validation_failures_total', labels: {
      'type': validationType,
      'reason': reason,
    });
  }

  // =====================================================
  // COLETA DE MÉTRICAS DO SISTEMA
  // =====================================================

  /// Coleta métricas do sistema
  static Future<void> _collectSystemMetrics() async {
    try {
      // Coletar métricas de memória (aproximação)
      final memoryUsage = _getMemoryUsage();
      setGauge('memory_usage_mb', memoryUsage);
      
      // Coletar contagem de zonas ativas
      final activeZones = await _getActiveZonesCount();
      setGauge('active_zones_count', activeZones.toDouble());
      
      // Coletar contagem de motoristas ativos
      final activeDrivers = await _getActiveDriversCount();
      setGauge('active_drivers_count', activeDrivers.toDouble());
      
    } catch (e) {
      MonitoringService.logError('Failed to collect system metrics', e);
    }
  }

  /// Obtém uso aproximado de memória
  static double _getMemoryUsage() {
    // Esta é uma aproximação - em produção seria melhor usar ferramentas específicas
    return ProcessInfo.currentRss / (1024 * 1024); // MB
  }

  /// Obtém contagem de zonas ativas
  static Future<int> _getActiveZonesCount() async {
    try {
      final response = await Supabase.instance.client
          .from('driver_operation_zones')
          .select('id')
          .eq('is_active', true)
          .count();
      
      return response.count;
    } catch (e) {
      return 0;
    }
  }

  /// Obtém contagem de motoristas ativos
  static Future<int> _getActiveDriversCount() async {
    try {
      final response = await Supabase.instance.client
          .from('driver_operation_zones')
          .select('driver_id')
          .eq('is_active', true);
      
      final uniqueDrivers = <String>{};
      for (final row in response) {
        uniqueDrivers.add(row['driver_id'].toString());
      }
      
      return uniqueDrivers.length;
    } catch (e) {
      return 0;
    }
  }

  // =====================================================
  // EXPORTAÇÃO DE MÉTRICAS
  // =====================================================

  /// Exporta métricas no formato Prometheus
  static String exportPrometheusFormat() {
    final buffer = StringBuffer();
    
    // Exportar contadores
    _counters.forEach((key, value) {
      final metricName = _extractMetricName(key);
      final labels = _extractLabels(key);
      buffer.writeln('# TYPE $metricName counter');
      buffer.writeln('$metricName$labels $value');
    });
    
    // Exportar gauges
    _gauges.forEach((key, value) {
      final metricName = _extractMetricName(key);
      final labels = _extractLabels(key);
      buffer.writeln('# TYPE $metricName gauge');
      buffer.writeln('$metricName$labels $value');
    });
    
    // Exportar histogramas
    _histograms.forEach((key, values) {
      if (values.isNotEmpty) {
        final metricName = _extractMetricName(key);
        final labels = _extractLabels(key);
        final stats = getHistogramStats(_extractMetricName(key), labels: _parseLabels(labels));
        
        buffer.writeln('# TYPE $metricName histogram');
        buffer.writeln('${metricName}_count$labels ${stats['count']!.toInt()}');
        buffer.writeln('${metricName}_sum$labels ${stats['sum']}');
        
        // Buckets padrão
        final buckets = [0.1, 0.5, 1.0, 2.5, 5.0, 10.0, double.infinity];
        for (final bucket in buckets) {
          final count = values.where((v) => v <= bucket).length;
          final bucketLabel = bucket == double.infinity ? '+Inf' : bucket.toString();
          buffer.writeln('${metricName}_bucket${_addLabelToBucket(labels, 'le', bucketLabel)} $count');
        }
      }
    });
    
    return buffer.toString();
  }

  /// Exporta métricas em formato JSON
  static Map<String, dynamic> exportJsonFormat() {
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'counters': {},
      'gauges': {},
      'histograms': {},
    };
    
    // Contadores
    _counters.forEach((key, value) {
      result['counters'][key] = {
        'value': value,
        'last_updated': _lastUpdated[key]?.toIso8601String(),
      };
    });
    
    // Gauges
    _gauges.forEach((key, value) {
      result['gauges'][key] = {
        'value': value,
        'last_updated': _lastUpdated[key]?.toIso8601String(),
      };
    });
    
    // Histogramas
    _histograms.forEach((key, values) {
      if (values.isNotEmpty) {
        result['histograms'][key] = {
          'stats': getHistogramStats(_extractMetricName(key)),
          'last_updated': _lastUpdated[key]?.toIso8601String(),
        };
      }
    });
    
    return result;
  }

  /// Envia métricas para backend
  static Future<void> _sendMetricsToBackend() async {
    try {
      final metrics = exportJsonFormat();
      
      // Enviar para Supabase (implementação futura)
      // await Supabase.instance.client
      //     .from('system_metrics')
      //     .insert({
      //       'metric_data': metrics,
      //       'timestamp': DateTime.now().toIso8601String(),
      //     });
      
      if (kDebugMode) {
        print('METRICS SENT TO BACKEND: ${jsonEncode(metrics)}');
      }
      
    } catch (e) {
      MonitoringService.logError('Failed to send metrics to backend', e);
    }
  }

  // =====================================================
  // UTILITÁRIOS
  // =====================================================

  /// Constrói chave de métrica com labels
  static String _buildMetricKey(String name, Map<String, String>? labels) {
    if (labels == null || labels.isEmpty) {
      return name;
    }
    
    final labelPairs = labels.entries
        .map((e) => '${e.key}="${e.value}"')
        .join(',');
    
    return '$name{$labelPairs}';
  }

  /// Extrai nome da métrica da chave
  static String _extractMetricName(String key) {
    final index = key.indexOf('{');
    return index == -1 ? key : key.substring(0, index);
  }

  /// Extrai labels da chave
  static String _extractLabels(String key) {
    final index = key.indexOf('{');
    return index == -1 ? '' : key.substring(index);
  }

  /// Converte string de labels para Map
  static Map<String, String>? _parseLabels(String labelsStr) {
    if (labelsStr.isEmpty) return null;
    
    final labels = <String, String>{};
    final content = labelsStr.substring(1, labelsStr.length - 1); // Remove { }
    
    for (final pair in content.split(',')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim().replaceAll('"', '');
        labels[key] = value;
      }
    }
    
    return labels.isEmpty ? null : labels;
  }

  /// Adiciona label a bucket de histograma
  static String _addLabelToBucket(String existingLabels, String key, String value) {
    if (existingLabels.isEmpty) {
      return '{$key="$value"}';
    }
    
    final content = existingLabels.substring(1, existingLabels.length - 1);
    return '{$content,$key="$value"}';
  }

  /// Calcula percentil
  static double _percentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0.0;
    
    final index = (sortedValues.length - 1) * percentile;
    final lower = index.floor();
    final upper = index.ceil();
    
    if (lower == upper) {
      return sortedValues[lower];
    }
    
    final weight = index - lower;
    return sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight;
  }

  /// Limpa todas as métricas
  static void clearAllMetrics() {
    _counters.clear();
    _gauges.clear();
    _histograms.clear();
    _lastUpdated.clear();
    
    _initializeBasicMetrics();
    MonitoringService.logInfo('All metrics cleared and reinitialized');
  }

  /// Obtém resumo das métricas
  static Map<String, dynamic> getMetricsSummary() {
    return {
      'counters_count': _counters.length,
      'gauges_count': _gauges.length,
      'histograms_count': _histograms.length,
      'total_histogram_observations': _histograms.values
          .map((values) => values.length)
          .fold(0, (sum, count) => sum + count),
      'last_collection': _lastUpdated.values
          .fold<DateTime?>(null, (latest, time) => 
              latest == null || time.isAfter(latest) ? time : latest)
          ?.toIso8601String(),
    };
  }
}

/// Extensão para facilitar uso de métricas
extension MetricsExtension on Object {
  void recordOperation(String operation, Duration duration, {bool hasError = false}) {
    MetricsService.recordZoneOperation(
      operation,
      hasError ? 'error' : 'success',
      duration,
    );
  }
}