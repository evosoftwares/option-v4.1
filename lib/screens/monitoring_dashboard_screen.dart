import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import '../services/monitoring_service.dart';
import '../services/metrics_service.dart';
import '../services/alert_service.dart';

/// Tela do dashboard de monitoramento
class MonitoringDashboardScreen extends StatefulWidget {
  const MonitoringDashboardScreen({super.key});

  @override
  State<MonitoringDashboardScreen> createState() => _MonitoringDashboardScreenState();
}

class _MonitoringDashboardScreenState extends State<MonitoringDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  
  // Estado das métricas
  Map<String, dynamic> _systemMetrics = {};
  Map<String, dynamic> _alertStats = {};
  List<Alert> _activeAlerts = [];
  List<Map<String, dynamic>> _recentLogs = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Inicializa os serviços de monitoramento
  Future<void> _initializeServices() async {
    try {
      await MonitoringService.initialize();
      await MetricsService.initialize();
      await AlertService.initialize();
      await _refreshData();
    } catch (e) {
      setState(() {
        _error = 'Erro ao inicializar serviços: $e';
        _isLoading = false;
      });
    }
  }

  /// Inicia atualização automática
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshData();
    });
  }

  /// Atualiza dados do dashboard
  Future<void> _refreshData() async {
    try {
      final metrics = MetricsService.exportJsonFormat();
      final alertStats = AlertService.getAlertStatistics();
      final activeAlerts = AlertService.getActiveAlerts();
      
      setState(() {
        _systemMetrics = metrics;
        _alertStats = alertStats;
        _activeAlerts = activeAlerts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao atualizar dados: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Monitoramento'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Atualizar dados',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_metrics',
                child: Text('Exportar Métricas'),
              ),
              const PopupMenuItem(
                value: 'clear_alerts',
                child: Text('Limpar Alertas Resolvidos'),
              ),
              const PopupMenuItem(
                value: 'system_health',
                child: Text('Verificar Saúde do Sistema'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Visão Geral'),
            Tab(icon: Icon(Icons.show_chart), text: 'Métricas'),
            Tab(icon: Icon(Icons.warning), text: 'Alertas'),
            Tab(icon: Icon(Icons.list_alt), text: 'Logs'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMetricsTab(),
                    _buildAlertsTab(),
                    _buildLogsTab(),
                  ],
                ),
    );
  }

  /// Widget de erro
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro no Dashboard',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  /// Tab de visão geral
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatusCard(),
          const SizedBox(height: 16),
          _buildQuickStatsGrid(),
          const SizedBox(height: 16),
          _buildRecentAlertsCard(),
          const SizedBox(height: 16),
          _buildPerformanceChart(),
        ],
      ),
    );
  }

  /// Card de status do sistema
  Widget _buildSystemStatusCard() {
    final isHealthy = _activeAlerts.where((a) => a.severity == AlertSeverity.critical).isEmpty;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.error,
              size: 48,
              color: isHealthy ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status do Sistema',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    isHealthy ? 'Sistema Operacional' : 'Alertas Críticos Ativos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isHealthy ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Última atualização: ${DateTime.now().toString().substring(0, 19)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid de estatísticas rápidas
  Widget _buildQuickStatsGrid() {
    final gauges = _systemMetrics['gauges'] as Map<String, dynamic>? ?? {};
    final counters = _systemMetrics['counters'] as Map<String, dynamic>? ?? {};
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildStatCard(
          'Zonas Ativas',
          _getMetricValue(gauges, 'active_zones_count').toInt().toString(),
          Icons.location_on,
          Colors.blue,
        ),
        _buildStatCard(
          'Motoristas Ativos',
          _getMetricValue(gauges, 'active_drivers_count').toInt().toString(),
          Icons.drive_eta,
          Colors.green,
        ),
        _buildStatCard(
          'Operações Totais',
          _getMetricValue(counters, 'zone_operations_total').toInt().toString(),
          Icons.analytics,
          Colors.orange,
        ),
        _buildStatCard(
          'Alertas Ativos',
          _alertStats['total_active']?.toString() ?? '0',
          Icons.warning,
          _alertStats['critical'] > 0 ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  /// Card de estatística individual
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Card de alertas recentes
  Widget _buildRecentAlertsCard() {
    final recentAlerts = _activeAlerts.take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alertas Recentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (recentAlerts.isEmpty)
              const Text('Nenhum alerta ativo')
            else
              ...recentAlerts.map((alert) => _buildAlertListItem(alert)),
          ],
        ),
      ),
    );
  }

  /// Gráfico de performance
  Widget _buildPerformanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance do Sistema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Gráfico de Performance\n(Implementação futura)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab de métricas
  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsSection('Contadores', _systemMetrics['counters'] ?? {}),
          const SizedBox(height: 16),
          _buildMetricsSection('Gauges', _systemMetrics['gauges'] ?? {}),
          const SizedBox(height: 16),
          _buildHistogramSection('Histogramas', _systemMetrics['histograms'] ?? {}),
        ],
      ),
    );
  }

  /// Seção de métricas
  Widget _buildMetricsSection(String title, Map<String, dynamic> metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (metrics.isEmpty)
              const Text('Nenhuma métrica disponível')
            else
              ...metrics.entries.map((entry) => _buildMetricItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  /// Item de métrica individual
  Widget _buildMetricItem(String name, dynamic value) {
    String displayValue;
    if (value is Map && value.containsKey('value')) {
      displayValue = value['value'].toString();
    } else {
      displayValue = value.toString();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            displayValue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de histogramas
  Widget _buildHistogramSection(String title, Map<String, dynamic> histograms) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (histograms.isEmpty)
              const Text('Nenhum histograma disponível')
            else
              ...histograms.entries.map((entry) => _buildHistogramItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  /// Item de histograma
  Widget _buildHistogramItem(String name, dynamic value) {
    if (value is! Map || !value.containsKey('stats')) {
      return const SizedBox.shrink();
    }
    
    final stats = value['stats'] as Map<String, dynamic>;
    
    return ExpansionTile(
      title: Text(name),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatRow('Contagem', stats['count']?.toInt().toString() ?? '0'),
              _buildStatRow('Média', '${stats['avg']?.toStringAsFixed(2) ?? '0'} ms'),
              _buildStatRow('Mínimo', '${stats['min']?.toStringAsFixed(2) ?? '0'} ms'),
              _buildStatRow('Máximo', '${stats['max']?.toStringAsFixed(2) ?? '0'} ms'),
              _buildStatRow('P50', '${stats['p50']?.toStringAsFixed(2) ?? '0'} ms'),
              _buildStatRow('P95', '${stats['p95']?.toStringAsFixed(2) ?? '0'} ms'),
              _buildStatRow('P99', '${stats['p99']?.toStringAsFixed(2) ?? '0'} ms'),
            ],
          ),
        ),
      ],
    );
  }

  /// Linha de estatística
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Tab de alertas
  Widget _buildAlertsTab() {
    return Column(
      children: [
        _buildAlertsSummary(),
        Expanded(
          child: _activeAlerts.isEmpty
              ? const Center(child: Text('Nenhum alerta ativo'))
              : ListView.builder(
                  itemCount: _activeAlerts.length,
                  itemBuilder: (context, index) {
                    return _buildAlertCard(_activeAlerts[index]);
                  },
                ),
        ),
      ],
    );
  }

  /// Resumo de alertas
  Widget _buildAlertsSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAlertSummaryItem(
            'Críticos',
            _alertStats['critical']?.toString() ?? '0',
            Colors.red,
          ),
          _buildAlertSummaryItem(
            'Avisos',
            _alertStats['warning']?.toString() ?? '0',
            Colors.orange,
          ),
          _buildAlertSummaryItem(
            'Informações',
            _alertStats['info']?.toString() ?? '0',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  /// Item do resumo de alertas
  Widget _buildAlertSummaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }

  /// Card de alerta
  Widget _buildAlertCard(Alert alert) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          _getAlertIcon(alert.severity),
          color: _getAlertColor(alert.severity),
        ),
        title: Text(alert.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.description),
            Text(
              alert.timestamp.toString().substring(0, 19),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAlertAction(value, alert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'resolve',
              child: Text('Resolver'),
            ),
            const PopupMenuItem(
              value: 'details',
              child: Text('Detalhes'),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  /// Item de alerta na lista
  Widget _buildAlertListItem(Alert alert) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getAlertIcon(alert.severity),
            size: 16,
            color: _getAlertColor(alert.severity),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            alert.timestamp.toString().substring(11, 16),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Tab de logs
  Widget _buildLogsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Filtrar logs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // Implementar filtro de logs
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportLogs,
                tooltip: 'Exportar logs',
              ),
            ],
          ),
        ),
        Expanded(
          child: _recentLogs.isEmpty
              ? const Center(child: Text('Nenhum log disponível'))
              : ListView.builder(
                  itemCount: _recentLogs.length,
                  itemBuilder: (context, index) {
                    return _buildLogItem(_recentLogs[index]);
                  },
                ),
        ),
      ],
    );
  }

  /// Item de log
  Widget _buildLogItem(Map<String, dynamic> log) {
    final level = log['level'] ?? 'INFO';
    final timestamp = log['timestamp'] ?? DateTime.now().toIso8601String();
    final message = log['message'] ?? 'Log sem mensagem';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        leading: Icon(
          _getLogIcon(level),
          color: _getLogColor(level),
          size: 16,
        ),
        title: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        subtitle: Text(
          timestamp.substring(0, 19),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        dense: true,
      ),
    );
  }

  /// Manipula ações do menu
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_metrics':
        _exportMetrics();
        break;
      case 'clear_alerts':
        _clearResolvedAlerts();
        break;
      case 'system_health':
        _checkSystemHealth();
        break;
    }
  }

  /// Manipula ações de alerta
  void _handleAlertAction(String action, Alert alert) {
    switch (action) {
      case 'resolve':
        _resolveAlert(alert);
        break;
      case 'details':
        _showAlertDetails(alert);
        break;
    }
  }

  /// Resolve um alerta
  Future<void> _resolveAlert(Alert alert) async {
    try {
      await AlertService.resolveAlert(alert.id, 'dashboard_user');
      await _refreshData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta resolvido com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao resolver alerta: $e')),
        );
      }
    }
  }

  /// Mostra detalhes do alerta
  void _showAlertDetails(Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${alert.type.name}'),
            Text('Severidade: ${alert.severity.name}'),
            Text('Descrição: ${alert.description}'),
            Text('Timestamp: ${alert.timestamp}'),
            if (alert.metadata.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Metadados:'),
              Text(jsonEncode(alert.metadata)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          if (!alert.isResolved)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resolveAlert(alert);
              },
              child: const Text('Resolver'),
            ),
        ],
      ),
    );
  }

  /// Exporta métricas
  void _exportMetrics() {
    final metricsJson = jsonEncode(_systemMetrics);
    Clipboard.setData(ClipboardData(text: metricsJson));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Métricas copiadas para a área de transferência')),
    );
  }

  /// Limpa alertas resolvidos
  void _clearResolvedAlerts() {
    AlertService.cleanupOldAlerts();
    _refreshData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alertas resolvidos limpos')),
    );
  }

  /// Verifica saúde do sistema
  void _checkSystemHealth() {
    // Implementar verificação de saúde
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verificação de saúde iniciada')),
    );
  }

  /// Exporta logs
  void _exportLogs() {
    final logsJson = jsonEncode(_recentLogs);
    Clipboard.setData(ClipboardData(text: logsJson));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copiados para a área de transferência')),
    );
  }

  /// Obtém valor de métrica
  double _getMetricValue(Map<String, dynamic> metrics, String key) {
    final metric = metrics[key];
    if (metric is Map && metric.containsKey('value')) {
      return (metric['value'] as num).toDouble();
    }
    return 0.0;
  }

  /// Obtém ícone do alerta
  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.info:
        return Icons.info;
    }
  }

  /// Obtém cor do alerta
  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  /// Obtém ícone do log
  IconData _getLogIcon(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Icons.error;
      case 'WARN':
      case 'WARNING':
        return Icons.warning;
      case 'INFO':
        return Icons.info;
      case 'DEBUG':
        return Icons.bug_report;
      default:
        return Icons.circle;
    }
  }

  /// Obtém cor do log
  Color _getLogColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARN':
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      case 'DEBUG':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}