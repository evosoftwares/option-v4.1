import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/monitoring_service.dart';
import '../../lib/services/metrics_service.dart';
import '../../lib/services/alert_service.dart';
import '../../lib/services/health_check_service.dart';

void main() {
  group('MonitoringService Tests', () {
    setUp(() async {
      await MonitoringService.initialize();
    });

    test('should initialize monitoring service successfully', () async {
      // Act & Assert - Should not throw
      expect(() async => await MonitoringService.initialize(), returnsNormally);
    });

    test('should create monitoring service instance', () {
      // Act
      final service = MonitoringService();

      // Assert
      expect(service, isNotNull);
    });

    test('should log info message', () {
      // Act & Assert - Should not throw
      expect(() => MonitoringService.logInfo('Test info message'), returnsNormally);
    });

    test('should log warning message', () {
      // Act & Assert - Should not throw
      expect(() => MonitoringService.logWarning('Test warning message'), returnsNormally);
    });

    test('should log error message', () {
      // Act & Assert - Should not throw
      expect(() => MonitoringService.logError('Test error message'), returnsNormally);
    });
  });

  group('MetricsService Tests', () {
    setUp(() async {
      await MetricsService.initialize();
    });

    tearDown(() {
      MetricsService.dispose();
    });

    test('should initialize metrics service successfully', () async {
      // Act
      await MetricsService.initialize();

      // Assert - Should not throw
      expect(true, isTrue);
    });

    test('should increment counter correctly', () {
      // Arrange
      const metricName = 'test_counter';
      const labels = {'service': 'test'};

      // Act
      MetricsService.incrementCounter(metricName, labels: labels);
      MetricsService.incrementCounter(metricName, labels: labels, value: 5);

      // Assert
      final counterValue = MetricsService.getCounter(metricName, labels: labels);
      expect(counterValue, equals(6));
    });

    test('should set and get gauge values', () {
      // Arrange
      const metricName = 'test_gauge';
      const value = 42.5;
      const labels = {'type': 'memory'};

      // Act
      MetricsService.setGauge(metricName, value, labels: labels);

      // Assert
      final gaugeValue = MetricsService.getGauge(metricName, labels: labels);
      expect(gaugeValue, equals(value));
    });

    test('should increment and decrement gauge values', () {
      // Arrange
      const metricName = 'test_gauge_ops';
      const initialValue = 10.0;
      const incrementValue = 5.0;
      const decrementValue = 3.0;

      // Act
      MetricsService.setGauge(metricName, initialValue);
      MetricsService.incrementGauge(metricName, incrementValue);
      MetricsService.decrementGauge(metricName, decrementValue);

      // Assert
      final finalValue = MetricsService.getGauge(metricName);
      expect(finalValue, equals(12.0)); // 10 + 5 - 3
    });

    test('should observe histogram values and calculate statistics', () {
      // Arrange
      const metricName = 'test_histogram';
      const values = [10.0, 20.0, 30.0, 40.0, 50.0];

      // Act
      for (final value in values) {
        MetricsService.observeHistogram(metricName, value);
      }

      // Assert
      final stats = MetricsService.getHistogramStats(metricName);
      expect(stats['count'], equals(5.0));
      expect(stats['sum'], equals(150.0));
      expect(stats['avg'], equals(30.0));
      expect(stats['min'], equals(10.0));
      expect(stats['max'], equals(50.0));
    });

    test('should record API request metrics', () {
      // Act
      MetricsService.recordApiRequest(
        '/api/zones',
        200,
        const Duration(milliseconds: 150),
      );

      // Assert
      final counter = MetricsService.getCounter(
        'api_requests_total',
        labels: {'endpoint': '/api/zones', 'status_code': '200'},
      );
      expect(counter, equals(1));
    });

    test('should export metrics in Prometheus format', () {
      // Arrange
      MetricsService.incrementCounter('test_counter', value: 5);
      MetricsService.setGauge('test_gauge', 42.0);
      MetricsService.observeHistogram('test_histogram', 100.0);

      // Act
      final prometheusMetrics = MetricsService.exportPrometheusFormat();

      // Assert
      expect(prometheusMetrics, contains('test_counter'));
      expect(prometheusMetrics, contains('test_gauge'));
      expect(prometheusMetrics, contains('test_histogram'));
    });

    test('should export metrics in JSON format', () {
      // Arrange
      MetricsService.incrementCounter('json_counter', value: 3);
      MetricsService.setGauge('json_gauge', 25.5);

      // Act
      final jsonMetrics = MetricsService.exportJsonFormat();

      // Assert
      expect(jsonMetrics, isA<Map<String, dynamic>>());
      expect(jsonMetrics, containsPair('counters', isA<Map>()));
      expect(jsonMetrics, containsPair('gauges', isA<Map>()));
      expect(jsonMetrics, containsPair('histograms', isA<Map>()));
    });
  });

  group('AlertService Tests', () {
    setUp(() async {
      await AlertService.initialize();
    });

    test('should initialize alert service successfully', () async {
      // Act & Assert - Should not throw
      expect(() async => await AlertService.initialize(), returnsNormally);
    });

    test('should get active alerts', () {
      // Act
      final alerts = AlertService.getActiveAlerts();

      // Assert
      expect(alerts, isA<List<Alert>>());
    });

    test('should get alert statistics', () {
      // Act
      final stats = AlertService.getAlertStatistics();

      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, containsPair('total_active', isA<int>()));
      expect(stats, containsPair('critical', isA<int>()));
      expect(stats, containsPair('warning', isA<int>()));
      expect(stats, containsPair('info', isA<int>()));
    });

    test('should get all alerts', () {
      // Act
      final alerts = AlertService.getAllAlerts();

      // Assert
      expect(alerts, isA<List<Alert>>());
    });

    test('should get alerts by severity', () {
      // Act
      final criticalAlerts = AlertService.getAlertsBySeverity(AlertSeverity.critical);
      final warningAlerts = AlertService.getAlertsBySeverity(AlertSeverity.warning);

      // Assert
      expect(criticalAlerts, isA<List<Alert>>());
      expect(warningAlerts, isA<List<Alert>>());
    });

    test('should get alert rules', () {
      // Act
      final rules = AlertService.getAlertRules();

      // Assert
      expect(rules, isA<List<AlertRule>>());
      expect(rules.length, greaterThan(0)); // Should have default rules
    });

    test('should cleanup old alerts', () {
      // Act & Assert - Should not throw
      expect(() => AlertService.cleanupOldAlerts(), returnsNormally);
    });
  });

  group('HealthCheckService Tests', () {
    late HealthCheckService healthCheckService;

    setUp(() {
      healthCheckService = HealthCheckService();
    });

    test('should create health check service instance', () {
      // Act
      final service = HealthCheckService();

      // Assert
      expect(service, isNotNull);
    });

    test('should get overall system health status', () {
      // Act
      final status = healthCheckService.getOverallStatus();

      // Assert
      expect(status, isA<HealthStatus>());
    });

    test('should get health statistics', () {
      // Act
      final stats = healthCheckService.getHealthStatistics();

      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, containsPair('total_services', isA<int>()));
      expect(stats, containsPair('healthy_count', isA<int>()));
      expect(stats, containsPair('degraded_count', isA<int>()));
      expect(stats, containsPair('unhealthy_count', isA<int>()));
      expect(stats, containsPair('overall_status', isA<String>()));
    });

    test('should add custom health check config', () {
      // Arrange
      const config = HealthCheckConfig(
        serviceName: 'test_service',
        endpoint: 'https://test.example.com/health',
        timeout: Duration(seconds: 5),
      );

      // Act & Assert - Should not throw
      expect(() => healthCheckService.addHealthCheckConfig(config), returnsNormally);
    });

    test('should remove health check config', () {
      // Arrange
      const config = HealthCheckConfig(
        serviceName: 'removable_service',
        endpoint: 'https://removable.example.com/health',
      );
      healthCheckService.addHealthCheckConfig(config);

      // Act & Assert - Should not throw
      expect(() => healthCheckService.removeHealthCheckConfig('removable_service'), returnsNormally);
    });
  });

  group('Integration Tests', () {
    test('should integrate monitoring and metrics', () async {
      // Arrange
      await MonitoringService.initialize();
      await MetricsService.initialize();
      await AlertService.initialize();

      // Act - Simular uma operação que gera logs e métricas
      MonitoringService.logInfo('Zone operation started');

      MetricsService.recordApiRequest(
        '/api/zones',
        200,
        const Duration(milliseconds: 150),
      );

      // Assert
      final counter = MetricsService.getCounter(
        'api_requests_total',
        labels: {'endpoint': '/api/zones', 'status_code': '200'},
      );
      expect(counter, greaterThan(0));
      
      final alerts = AlertService.getActiveAlerts();
      expect(alerts, isA<List<Alert>>());
    });

    test('should handle error scenarios correctly', () async {
      // Arrange
      await MonitoringService.initialize();
      await AlertService.initialize();

      // Act - Simular erro na operação
      MonitoringService.logError('Database connection failed');

      MetricsService.recordApiRequest(
        '/api/database',
        500,
        const Duration(milliseconds: 5000),
      );

      // Assert
      final errorCounter = MetricsService.getCounter(
        'api_requests_total',
        labels: {'endpoint': '/api/database', 'status_code': '500'},
      );
      expect(errorCounter, greaterThan(0));
      
      final stats = AlertService.getAlertStatistics();
      expect(stats, isA<Map<String, dynamic>>());
    });
  });
}