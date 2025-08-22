import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'monitoring_service.dart';
import 'metrics_service.dart';

/// Tipos de severidade de alertas
enum AlertSeverity {
  critical,
  warning,
  info,
}

/// Tipos de alertas do sistema
enum AlertType {
  highLatency,
  errorRate,
  validationFailure,
  resourceUsage,
  securityBreach,
  dataIntegrity,
  businessMetric,
  systemHealth,
}

/// Modelo de alerta
class Alert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.metadata,
    required this.timestamp,
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'severity': severity.name,
    'title': title,
    'description': description,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'is_resolved': isResolved,
    'resolved_by': resolvedBy,
    'resolved_at': resolvedAt?.toIso8601String(),
  };

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: json['id'],
    type: AlertType.values.firstWhere((e) => e.name == json['type']),
    severity: AlertSeverity.values.firstWhere((e) => e.name == json['severity']),
    title: json['title'],
    description: json['description'],
    metadata: json['metadata'] ?? {},
    timestamp: DateTime.parse(json['timestamp']),
    isResolved: json['is_resolved'] ?? false,
    resolvedBy: json['resolved_by'],
    resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
  );
}

/// Configuração de regras de alerta
class AlertRule {
  final AlertType type;
  final AlertSeverity severity;
  final String condition;
  final double threshold;
  final Duration evaluationWindow;
  final bool isEnabled;
  final List<String> notificationChannels;

  AlertRule({
    required this.type,
    required this.severity,
    required this.condition,
    required this.threshold,
    required this.evaluationWindow,
    this.isEnabled = true,
    this.notificationChannels = const [],
  });
}

/// Serviço de alertas e notificações
class AlertService {
  static final List<Alert> _activeAlerts = [];
  static final List<AlertRule> _alertRules = [];
  static Timer? _evaluationTimer;
  static bool _isInitialized = false;

  /// Inicializa o serviço de alertas
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    // Configurar regras padrão de alerta
    _setupDefaultAlertRules();
    
    // Iniciar avaliação periódica
    _startPeriodicEvaluation();
    
    MonitoringService.logInfo('Alert service initialized');
  }

  /// Configura regras padrão de alerta
  static void _setupDefaultAlertRules() {
    _alertRules.addAll([
      // Latência alta
      AlertRule(
        type: AlertType.highLatency,
        severity: AlertSeverity.critical,
        condition: 'avg_response_time > threshold',
        threshold: 5000, // 5 segundos
        evaluationWindow: const Duration(minutes: 5),
        notificationChannels: ['email', 'slack'],
      ),
      
      // Taxa de erro alta
      AlertRule(
        type: AlertType.errorRate,
        severity: AlertSeverity.critical,
        condition: 'error_rate > threshold',
        threshold: 0.05, // 5%
        evaluationWindow: const Duration(minutes: 10),
        notificationChannels: ['email', 'slack', 'sms'],
      ),
      
      // Falhas de validação
      AlertRule(
        type: AlertType.validationFailure,
        severity: AlertSeverity.warning,
        condition: 'validation_failures > threshold',
        threshold: 10, // 10 falhas por minuto
        evaluationWindow: const Duration(minutes: 1),
        notificationChannels: ['slack'],
      ),
      
      // Uso de recursos
      AlertRule(
        type: AlertType.resourceUsage,
        severity: AlertSeverity.warning,
        condition: 'memory_usage > threshold',
        threshold: 512, // 512 MB
        evaluationWindow: const Duration(minutes: 5),
        notificationChannels: ['email'],
      ),
      
      // Violação de segurança
      AlertRule(
        type: AlertType.securityBreach,
        severity: AlertSeverity.critical,
        condition: 'security_events > threshold',
        threshold: 1, // Qualquer evento de segurança
        evaluationWindow: const Duration(minutes: 1),
        notificationChannels: ['email', 'slack', 'sms'],
      ),
      
      // Integridade de dados
      AlertRule(
        type: AlertType.dataIntegrity,
        severity: AlertSeverity.critical,
        condition: 'data_integrity_violations > threshold',
        threshold: 0, // Qualquer violação
        evaluationWindow: const Duration(minutes: 5),
        notificationChannels: ['email', 'slack'],
      ),
      
      // Métricas de negócio
      AlertRule(
        type: AlertType.businessMetric,
        severity: AlertSeverity.warning,
        condition: 'zone_creation_rate < threshold',
        threshold: 1, // Menos de 1 zona por hora
        evaluationWindow: const Duration(hours: 1),
        notificationChannels: ['email'],
      ),
    ]);
  }

  /// Inicia avaliação periódica de alertas
  static void _startPeriodicEvaluation() {
    _evaluationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _evaluateAlertRules();
    });
  }

  /// Para o serviço de alertas
  static void dispose() {
    _evaluationTimer?.cancel();
    _evaluationTimer = null;
    _isInitialized = false;
  }

  /// Avalia todas as regras de alerta
  static Future<void> _evaluateAlertRules() async {
    for (final rule in _alertRules) {
      if (!rule.isEnabled) continue;
      
      try {
        await _evaluateRule(rule);
      } catch (e) {
        MonitoringService.logError('Failed to evaluate alert rule: ${rule.type}', e);
      }
    }
  }

  /// Avalia uma regra específica de alerta
  static Future<void> _evaluateRule(AlertRule rule) async {
    final now = DateTime.now();
    final windowStart = now.subtract(rule.evaluationWindow);
    
    switch (rule.type) {
      case AlertType.highLatency:
        await _evaluateLatencyRule(rule, windowStart, now);
        break;
      case AlertType.errorRate:
        await _evaluateErrorRateRule(rule, windowStart, now);
        break;
      case AlertType.validationFailure:
        await _evaluateValidationRule(rule, windowStart, now);
        break;
      case AlertType.resourceUsage:
        await _evaluateResourceRule(rule, windowStart, now);
        break;
      case AlertType.securityBreach:
        await _evaluateSecurityRule(rule, windowStart, now);
        break;
      case AlertType.dataIntegrity:
        await _evaluateDataIntegrityRule(rule, windowStart, now);
        break;
      case AlertType.businessMetric:
        await _evaluateBusinessRule(rule, windowStart, now);
        break;
      case AlertType.systemHealth:
        await _evaluateSystemHealthRule(rule, windowStart, now);
        break;
    }
  }

  /// Avalia regra de latência
  static Future<void> _evaluateLatencyRule(AlertRule rule, DateTime start, DateTime end) async {
    final stats = MetricsService.getHistogramStats('zone_operation_duration_ms');
    final avgLatency = stats['avg'] ?? 0.0;
    
    if (avgLatency > rule.threshold) {
      await _triggerAlert(
        type: AlertType.highLatency,
        severity: rule.severity,
        title: 'High Latency Detected',
        description: 'Average response time (${avgLatency.toStringAsFixed(2)}ms) exceeds threshold (${rule.threshold}ms)',
        metadata: {
          'avg_latency_ms': avgLatency,
          'threshold_ms': rule.threshold,
          'evaluation_window': rule.evaluationWindow.inMinutes,
        },
        notificationChannels: rule.notificationChannels,
      );
    }
  }

  /// Avalia regra de taxa de erro
  static Future<void> _evaluateErrorRateRule(AlertRule rule, DateTime start, DateTime end) async {
    final totalRequests = MetricsService.getCounter('zone_operations_total');
    final totalErrors = MetricsService.getCounter('errors_total');
    
    if (totalRequests > 0) {
      final errorRate = totalErrors / totalRequests;
      
      if (errorRate > rule.threshold) {
        await _triggerAlert(
          type: AlertType.errorRate,
          severity: rule.severity,
          title: 'High Error Rate Detected',
          description: 'Error rate (${(errorRate * 100).toStringAsFixed(2)}%) exceeds threshold (${(rule.threshold * 100).toStringAsFixed(2)}%)',
          metadata: {
            'error_rate': errorRate,
            'threshold': rule.threshold,
            'total_requests': totalRequests,
            'total_errors': totalErrors,
          },
          notificationChannels: rule.notificationChannels,
        );
      }
    }
  }

  /// Avalia regra de validação
  static Future<void> _evaluateValidationRule(AlertRule rule, DateTime start, DateTime end) async {
    final validationFailures = MetricsService.getCounter('validation_failures_total');
    
    if (validationFailures > rule.threshold) {
      await _triggerAlert(
        type: AlertType.validationFailure,
        severity: rule.severity,
        title: 'High Validation Failure Rate',
        description: 'Validation failures ($validationFailures) exceed threshold (${rule.threshold})',
        metadata: {
          'validation_failures': validationFailures,
          'threshold': rule.threshold,
        },
        notificationChannels: rule.notificationChannels,
      );
    }
  }

  /// Avalia regra de recursos
  static Future<void> _evaluateResourceRule(AlertRule rule, DateTime start, DateTime end) async {
    final memoryUsage = MetricsService.getGauge('memory_usage_mb');
    
    if (memoryUsage > rule.threshold) {
      await _triggerAlert(
        type: AlertType.resourceUsage,
        severity: rule.severity,
        title: 'High Memory Usage',
        description: 'Memory usage (${memoryUsage.toStringAsFixed(2)}MB) exceeds threshold (${rule.threshold}MB)',
        metadata: {
          'memory_usage_mb': memoryUsage,
          'threshold_mb': rule.threshold,
        },
        notificationChannels: rule.notificationChannels,
      );
    }
  }

  /// Avalia regra de segurança
  static Future<void> _evaluateSecurityRule(AlertRule rule, DateTime start, DateTime end) async {
    // Implementar verificação de eventos de segurança
    // Por enquanto, simular verificação
  }

  /// Avalia regra de integridade de dados
  static Future<void> _evaluateDataIntegrityRule(AlertRule rule, DateTime start, DateTime end) async {
    // Implementar verificação de integridade
    // Por enquanto, simular verificação
  }

  /// Avalia regra de métricas de negócio
  static Future<void> _evaluateBusinessRule(AlertRule rule, DateTime start, DateTime end) async {
    final activeZones = MetricsService.getGauge('active_zones_count');
    
    if (activeZones < rule.threshold) {
      await _triggerAlert(
        type: AlertType.businessMetric,
        severity: rule.severity,
        title: 'Low Zone Activity',
        description: 'Active zones count ($activeZones) is below threshold (${rule.threshold})',
        metadata: {
          'active_zones': activeZones,
          'threshold': rule.threshold,
        },
        notificationChannels: rule.notificationChannels,
      );
    }
  }

  /// Avalia regra de saúde do sistema
  static Future<void> _evaluateSystemHealthRule(AlertRule rule, DateTime start, DateTime end) async {
    // Implementar verificação de saúde do sistema
    // Por enquanto, simular verificação
  }

  /// Dispara um alerta
  static Future<void> _triggerAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String description,
    required Map<String, dynamic> metadata,
    required List<String> notificationChannels,
  }) async {
    // Verificar se já existe um alerta ativo similar
    final existingAlert = _activeAlerts.firstWhere(
      (alert) => alert.type == type && !alert.isResolved,
      orElse: () => Alert(
        id: '',
        type: type,
        severity: severity,
        title: '',
        description: '',
        metadata: {},
        timestamp: DateTime.now(),
      ),
    );
    
    if (existingAlert.id.isNotEmpty) {
      // Alerta já existe, não duplicar
      return;
    }
    
    final alert = Alert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      severity: severity,
      title: title,
      description: description,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
    
    _activeAlerts.add(alert);
    
    // Log do alerta
    MonitoringService.logWarning('Alert triggered: $title');
    
    // Enviar notificações
    await _sendNotifications(alert, notificationChannels);
    
    // Salvar no backend
    await _saveAlertToBackend(alert);
    
    if (kDebugMode) {
      print('ALERT TRIGGERED: ${alert.toJson()}');
    }
  }

  /// Envia notificações para os canais configurados
  static Future<void> _sendNotifications(Alert alert, List<String> channels) async {
    for (final channel in channels) {
      try {
        switch (channel) {
          case 'email':
            await _sendEmailNotification(alert);
            break;
          case 'slack':
            await _sendSlackNotification(alert);
            break;
          case 'sms':
            await _sendSmsNotification(alert);
            break;
          case 'push':
            await _sendPushNotification(alert);
            break;
        }
      } catch (e) {
        MonitoringService.logError('Failed to send notification via $channel', e);
      }
    }
  }

  /// Envia notificação por email
  static Future<void> _sendEmailNotification(Alert alert) async {
    // Implementar integração com serviço de email
    if (kDebugMode) {
      print('EMAIL NOTIFICATION: ${alert.title}');
    }
  }

  /// Envia notificação para Slack
  static Future<void> _sendSlackNotification(Alert alert) async {
    // Implementar integração com Slack
    if (kDebugMode) {
      print('SLACK NOTIFICATION: ${alert.title}');
    }
  }

  /// Envia notificação por SMS
  static Future<void> _sendSmsNotification(Alert alert) async {
    // Implementar integração com serviço de SMS
    if (kDebugMode) {
      print('SMS NOTIFICATION: ${alert.title}');
    }
  }

  /// Envia notificação push
  static Future<void> _sendPushNotification(Alert alert) async {
    // Implementar notificação push
    if (kDebugMode) {
      print('PUSH NOTIFICATION: ${alert.title}');
    }
  }

  /// Salva alerta no backend
  static Future<void> _saveAlertToBackend(Alert alert) async {
    try {
      await Supabase.instance.client
          .from('system_alerts')
          .insert(alert.toJson());
    } catch (e) {
      MonitoringService.logError('Failed to save alert to backend', e);
    }
  }

  /// Resolve um alerta
  static Future<void> resolveAlert(String alertId, String resolvedBy) async {
    final alertIndex = _activeAlerts.indexWhere((alert) => alert.id == alertId);
    
    if (alertIndex != -1) {
      final resolvedAlert = Alert(
        id: _activeAlerts[alertIndex].id,
        type: _activeAlerts[alertIndex].type,
        severity: _activeAlerts[alertIndex].severity,
        title: _activeAlerts[alertIndex].title,
        description: _activeAlerts[alertIndex].description,
        metadata: _activeAlerts[alertIndex].metadata,
        timestamp: _activeAlerts[alertIndex].timestamp,
        isResolved: true,
        resolvedBy: resolvedBy,
        resolvedAt: DateTime.now(),
      );
      
      _activeAlerts[alertIndex] = resolvedAlert;
      
      // Atualizar no backend
      try {
        await Supabase.instance.client
            .from('system_alerts')
            .update({
              'is_resolved': true,
              'resolved_by': resolvedBy,
              'resolved_at': DateTime.now().toIso8601String(),
            })
            .eq('id', alertId);
      } catch (e) {
        MonitoringService.logError('Failed to update alert resolution in backend', e);
      }
      
      MonitoringService.logInfo('Alert resolved: $alertId by $resolvedBy');
    }
  }

  /// Obtém alertas ativos
  static List<Alert> getActiveAlerts() {
    return _activeAlerts.where((alert) => !alert.isResolved).toList();
  }

  /// Obtém todos os alertas
  static List<Alert> getAllAlerts() {
    return List.from(_activeAlerts);
  }

  /// Obtém alertas por severidade
  static List<Alert> getAlertsBySeverity(AlertSeverity severity) {
    return _activeAlerts.where((alert) => alert.severity == severity && !alert.isResolved).toList();
  }

  /// Obtém estatísticas de alertas
  static Map<String, dynamic> getAlertStatistics() {
    final activeAlerts = getActiveAlerts();
    final criticalAlerts = getAlertsBySeverity(AlertSeverity.critical);
    final warningAlerts = getAlertsBySeverity(AlertSeverity.warning);
    
    return {
      'total_active': activeAlerts.length,
      'critical': criticalAlerts.length,
      'warning': warningAlerts.length,
      'info': getAlertsBySeverity(AlertSeverity.info).length,
      'total_resolved': _activeAlerts.where((alert) => alert.isResolved).length,
      'alert_types': {
        for (final type in AlertType.values)
          type.name: activeAlerts.where((alert) => alert.type == type).length,
      },
    };
  }

  /// Adiciona regra de alerta personalizada
  static void addAlertRule(AlertRule rule) {
    _alertRules.add(rule);
    MonitoringService.logInfo('Alert rule added: ${rule.type}');
  }

  /// Remove regra de alerta
  static void removeAlertRule(AlertType type) {
    _alertRules.removeWhere((rule) => rule.type == type);
    MonitoringService.logInfo('Alert rule removed: $type');
  }

  /// Obtém regras de alerta
  static List<AlertRule> getAlertRules() {
    return List.from(_alertRules);
  }

  /// Limpa alertas resolvidos antigos
  static void cleanupOldAlerts({Duration? olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
    
    _activeAlerts.removeWhere((alert) => 
        alert.isResolved && 
        alert.resolvedAt != null && 
        alert.resolvedAt!.isBefore(cutoff)
    );
    
    MonitoringService.logInfo('Old resolved alerts cleaned up');
  }
}

/// Extensão para facilitar uso de alertas
extension AlertExtension on Object {
  Future<void> triggerAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    await AlertService._triggerAlert(
      type: type,
      severity: severity,
      title: title,
      description: description,
      metadata: metadata ?? {},
      notificationChannels: ['email'],
    );
  }
}