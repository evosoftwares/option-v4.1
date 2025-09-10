import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import '../domain/services/user_preferences_service.dart';

class PerformanceMetrics {

  const PerformanceMetrics({
    required this.timestamp,
    required this.event,
    required this.data,
    this.duration,
    this.error,
  });
  final DateTime timestamp;
  final String event;
  final Map<String, dynamic> data;
  final Duration? duration;
  final String? error;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'event': event,
    'data': data,
    'duration_ms': duration?.inMilliseconds,
    'error': error,
    'platform': Platform.operatingSystem,
    'is_release': kReleaseMode,
  };
}

class ShellAppMonitor {
  factory ShellAppMonitor() => _instance;
  ShellAppMonitor._internal();
  static final ShellAppMonitor _instance = ShellAppMonitor._internal();

  final List<PerformanceMetrics> _metrics = [];
  final StreamController<PerformanceMetrics> _metricsController = 
      StreamController<PerformanceMetrics>.broadcast();
  
  Timer? _reportTimer;
  final Dio _dio = Dio();
  bool _isInitialized = false;
  
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    dev.log('📊 Inicializando Performance Monitor...', name: 'Monitor');
    
    await _loadStoredMetrics();
    _startPeriodicReporting();
    
    recordEvent('shell_app_start', {
      'app_version': '4.1.0',
      'shell_mode': true,
      'optimization_level': 'ultra',
    });
    
    _isInitialized = true;
    dev.log('✅ Performance Monitor inicializado', name: 'Monitor');
  }

  void recordEvent(String event, Map<String, dynamic> data, {Duration? duration, String? error}) {
    final metrics = PerformanceMetrics(
      timestamp: DateTime.now(),
      event: event,
      data: data,
      duration: duration,
      error: error,
    );
    
    _metrics.add(metrics);
    _metricsController.add(metrics);
    
    // Log para debug
    if (!kReleaseMode) {
      final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      final errorStr = error != null ? ' [ERROR: $error]' : '';
      dev.log('📈 $event$durationStr$errorStr', name: 'Monitor');
    }
    
    // Salvar periodicamente
    if (_metrics.length % 10 == 0) {
      _saveMetrics();
    }
  }

  Future<void> recordModuleLoad(String moduleId, Duration loadTime, bool success) async {
    recordEvent('module_load', {
      'module_id': moduleId,
      'success': success,
      'load_time_ms': loadTime.inMilliseconds,
      'memory_usage': await _getMemoryUsage(),
    }, duration: loadTime, error: success ? null : 'Load failed');
  }

  Future<void> recordAssetLoad(String assetKey, String source, Duration loadTime, bool success) async {
    recordEvent('asset_load', {
      'asset_key': assetKey,
      'source': source, // 'local' ou 'cdn'
      'success': success,
      'load_time_ms': loadTime.inMilliseconds,
    }, duration: loadTime, error: success ? null : 'Asset load failed');
  }

  Future<void> recordUserInteraction(String screen, String action, Map<String, dynamic>? context) async {
    recordEvent('user_interaction', {
      'screen': screen,
      'action': action,
      'context': context ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> recordAIPredicton(Map<String, double> predictions, int correctPredictions) async {
    recordEvent('ai_prediction', {
      'total_predictions': predictions.length,
      'correct_predictions': correctPredictions,
      'accuracy': correctPredictions / predictions.length,
      'predictions': predictions,
    });
  }

  Future<void> recordError(String context, String error, StackTrace? stackTrace) async {
    recordEvent('error', {
      'context': context,
      'error_message': error,
      'stack_trace': stackTrace?.toString(),
      'platform': Platform.operatingSystem,
    }, error: error);
  }

  Map<String, dynamic> getPerformanceSummary() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(days: 1));
    
    final recentMetrics = _metrics
        .where((m) => m.timestamp.isAfter(last24h))
        .toList();
    
    final moduleLoads = recentMetrics
        .where((m) => m.event == 'module_load')
        .toList();
    
    final assetLoads = recentMetrics
        .where((m) => m.event == 'asset_load')
        .toList();
    
    final errors = recentMetrics
        .where((m) => m.error != null)
        .toList();
    
    return {
      'shell_app_performance': {
        'total_events_24h': recentMetrics.length,
        'module_loads': {
          'count': moduleLoads.length,
          'success_rate': _calculateSuccessRate(moduleLoads),
          'avg_load_time_ms': _calculateAverageLoadTime(moduleLoads),
        },
        'asset_loads': {
          'count': assetLoads.length,
          'success_rate': _calculateSuccessRate(assetLoads),
          'avg_load_time_ms': _calculateAverageLoadTime(assetLoads),
          'cdn_usage': _calculateCdnUsage(assetLoads),
        },
        'errors': {
          'count': errors.length,
          'error_rate': errors.length / recentMetrics.length,
          'most_common': _getMostCommonErrors(errors),
        },
        'optimization_metrics': {
          'shell_app_enabled': true,
          'lazy_loading_efficiency': _calculateLazyLoadingEfficiency(),
          'ai_prediction_accuracy': _calculateAIPredictionAccuracy(),
        },
      },
      'timestamp': now.toIso8601String(),
    };
  }

  double _calculateSuccessRate(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) return 1;
    
    final successful = metrics.where((m) => m.data['success'] == true).length;
    return successful / metrics.length;
  }

  double _calculateAverageLoadTime(List<PerformanceMetrics> metrics) {
    if (metrics.isEmpty) return 0;
    
    final loadTimes = metrics
        .where((m) => m.data['load_time_ms'] != null)
        .map((m) => m.data['load_time_ms'] as int)
        .toList();
    
    if (loadTimes.isEmpty) return 0;
    
    return loadTimes.reduce((a, b) => a + b) / loadTimes.length;
  }

  double _calculateCdnUsage(List<PerformanceMetrics> assetLoads) {
    if (assetLoads.isEmpty) return 0;
    
    final cdnLoads = assetLoads
        .where((m) => m.data['source'] == 'cdn')
        .length;
    
    return cdnLoads / assetLoads.length;
  }

  double _calculateLazyLoadingEfficiency() {
    final moduleLoads = _metrics
        .where((m) => m.event == 'module_load')
        .toList();
    
    if (moduleLoads.isEmpty) return 1;
    
    final fastLoads = moduleLoads
        .where((m) => (m.data['load_time_ms'] as int?) != null && 
                     (m.data['load_time_ms'] as int) < 1000)
        .length;
    
    return fastLoads / moduleLoads.length;
  }

  double _calculateAIPredictionAccuracy() {
    final predictions = _metrics
        .where((m) => m.event == 'ai_prediction')
        .toList();
    
    if (predictions.isEmpty) return 0;
    
    final accuracies = predictions
        .map((m) => m.data['accuracy'] as double? ?? 0.0)
        .toList();
    
    return accuracies.reduce((a, b) => a + b) / accuracies.length;
  }

  List<Map<String, dynamic>> _getMostCommonErrors(List<PerformanceMetrics> errors) {
    final errorCounts = <String, int>{};
    
    for (final error in errors) {
      final errorMsg = error.error ?? 'Unknown error';
      errorCounts[errorMsg] = (errorCounts[errorMsg] ?? 0) + 1;
    }
    
    final sortedErrors = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedErrors.take(5)
        .map((entry) => {
          'error': entry.key,
          'count': entry.value,
        })
        .toList();
  }

  void _startPeriodicReporting() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _sendMetricsReport(),
    );
    
    dev.log('⏰ Relatórios periódicos iniciados (15min)', name: 'Monitor');
  }

  Future<void> _sendMetricsReport() async {
    try {
      if (_metrics.isEmpty) return;
      
      final summary = getPerformanceSummary();
      
      // Em produção, enviaria para serviço de analytics
      dev.log('📊 Relatório de performance: ${summary['shell_app_performance']['total_events_24h']} eventos', 
          name: 'Monitor');
      
      // Limpar métricas antigas (manter apenas 1000 mais recentes)
      if (_metrics.length > 1000) {
        _metrics.removeRange(0, _metrics.length - 1000);
      }
      
    } catch (e) {
      dev.log('❌ Erro ao enviar relatório: $e', name: 'Monitor');
    }
  }

  Future<void> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentMetrics = _metrics.take(100).toList();
      final jsonData = recentMetrics.map((m) => m.toJson()).toList();
      
      await prefs.setString('performance_metrics', jsonData.toString());
    } catch (e) {
      dev.log('⚠️ Erro ao salvar métricas: $e', name: 'Monitor');
    }
  }

  Future<void> _loadStoredMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('performance_metrics');
      
      if (storedData != null) {
        // Em implementação real, faria parse dos dados JSON
        dev.log('📂 Métricas carregadas do armazenamento', name: 'Monitor');
      }
    } catch (e) {
      dev.log('⚠️ Erro ao carregar métricas: $e', name: 'Monitor');
    }
  }

  Future<int> _getMemoryUsage() async {
    try {
      // Em implementação real, usaria plugin específico para memória
      return 0; // Placeholder
    } catch (e) {
      return 0;
    }
  }

  void dispose() {
    _reportTimer?.cancel();
    _metricsController.close();
    _dio.close();
    dev.log('🧹 Performance Monitor disposed', name: 'Monitor');
  }
}

class AnalyticsReporter {
  static String get _endpoint => '${AppConfig.supabaseUrl}/functions/v1/analytics';

  static Future<bool> _hasAnalyticsConsent() async {
    try {
      return await UserPreferencesService().getAnalyticsConsent();
    } catch (e) {
      dev.log('⚠️ Erro ao verificar consentimento de analytics: $e', name: 'Analytics');
      return false; // Default to not sending if we can't determine consent
    }
  }

  static Future<void> sendShellAppMetrics(Map<String, dynamic> metrics) async {
    // Check if user has given consent for analytics
    final hasConsent = await _hasAnalyticsConsent();
    if (!hasConsent) {
      dev.log('⏭️  Analytics desativados pelo usuário - métricas não enviadas', name: 'Analytics');
      return;
    }

    try {
      final dio = Dio();
      
      await dio.post(
        _endpoint,
        data: {
          'type': 'shell_app_metrics',
          'data': metrics,
          'app_version': '4.1.0',
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      dev.log('📤 Métricas enviadas com sucesso', name: 'Analytics');
    } catch (e) {
      dev.log('❌ Erro ao enviar métricas: $e', name: 'Analytics');
    }
  }
  
  static Future<void> reportOptimizationImpact({
    required double downloadReduction,
    required double loadTimeImprovement,
    required int modulesLazyLoaded,
    required double aiAccuracy,
  }) async {
    final impactData = {
      'optimization_impact': {
        'download_reduction_percent': downloadReduction,
        'load_time_improvement_percent': loadTimeImprovement,
        'modules_lazy_loaded': modulesLazyLoaded,
        'ai_prediction_accuracy': aiAccuracy,
        'shell_app_version': '1.0',
      }
    };
    
    await sendShellAppMetrics(impactData);
  }
}