import 'package:flutter/material.dart';
import '../widgets/notification_status_card.dart';
import '../widgets/notification_permission_dialog.dart';
import '../widgets/notification_onboarding_screen.dart';
import '../widgets/notification_status_indicator.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Exemplo de integração dos componentes de UI para notificações OneSignal
/// Este arquivo demonstra como usar os widgets criados para garantir
/// perfeita compreensão do usuário sobre o status das notificações.
class NotificationUIIntegrationExample extends StatefulWidget {
  const NotificationUIIntegrationExample({super.key});

  @override
  State<NotificationUIIntegrationExample> createState() => _NotificationUIIntegrationExampleState();
}

class _NotificationUIIntegrationExampleState extends State<NotificationUIIntegrationExample> {
  NotificationPermissionStatus _permissionStatus = NotificationPermissionStatus.unknown;
  OneSignalConnectionStatus _connectionStatus = OneSignalConnectionStatus.connecting;
  bool _showBanner = true;
  bool _hasSeenOnboarding = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Integração UI OneSignal'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          // Indicador compacto na AppBar
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: NotificationStatusIndicator(
              size: NotificationIndicatorSize.compact,
              onTap: () => _showStatusDialog(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de alerta (quando necessário)
            NotificationStatusBanner(
              isVisible: _showBanner && _permissionStatus == NotificationPermissionStatus.denied,
              onAction: () => _requestPermissionDialog(),
              onDismiss: () => setState(() => _showBanner = false),
            ),

            // Seção de exemplos
            _buildSection(
              'Status Card Completo',
              'Card com informações detalhadas sobre notificações',
              NotificationStatusCard(
                permissionStatus: _permissionStatus,
                connectionStatus: _connectionStatus,
                errorMessage: _connectionStatus == OneSignalConnectionStatus.error 
                    ? 'Falha na conexão com servidor de notificações' 
                    : null,
                onRetry: () => _simulateRetry(),
                onRequestPermission: () => _requestPermissionDialog(),
                showDetails: true,
              ),
            ),

            _buildSection(
              'Indicadores de Status',
              'Diferentes tamanhos para diferentes contextos',
              Column(
                children: [
                  // Indicador pequeno
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Tela Principal'),
                      trailing: NotificationStatusIndicator(
                        size: NotificationIndicatorSize.small,
                        onTap: () => _showStatusDialog(),
                      ),
                    ),
                  ),
                  
                  // Indicador completo
                  NotificationStatusIndicator(
                    size: NotificationIndicatorSize.full,
                    onTap: () => _showStatusDialog(),
                    margin: const EdgeInsets.all(AppSpacing.md),
                  ),
                ],
              ),
            ),

            _buildSection(
              'Ações Disponíveis',
              'Botões para testar diferentes fluxos',
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showOnboarding(),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Onboarding'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _requestPermissionDialog(),
                          icon: const Icon(Icons.notifications),
                          label: const Text('Permissão'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _togglePermissionStatus(),
                          icon: Icon(
                            _permissionStatus == NotificationPermissionStatus.granted
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                          ),
                          label: const Text('Toggle Permissão'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleConnectionStatus(),
                          icon: Icon(
                            _connectionStatus == OneSignalConnectionStatus.connected
                                ? Icons.wifi
                                : Icons.wifi_off,
                          ),
                          label: const Text('Toggle Conexão'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _buildSection(
              'Status Atual',
              'Informações detalhadas do estado atual',
              Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusRow(
                        'Permissão:',
                        _getPermissionStatusText(),
                        _getPermissionStatusColor(),
                      ),
                      const Divider(),
                      _buildStatusRow(
                        'Conexão:',
                        _getConnectionStatusText(),
                        _getConnectionStatusColor(),
                      ),
                      const Divider(),
                      _buildStatusRow(
                        'Onboarding:',
                        _hasSeenOnboarding ? 'Concluído' : 'Pendente',
                        _hasSeenOnboarding ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, Widget content) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          content,
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de ação
  Future<void> _showOnboarding() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationOnboardingScreen(
          isRequired: false,
        ),
      ),
    );
    
    if (result == true) {
      setState(() {
        _hasSeenOnboarding = true;
        _permissionStatus = NotificationPermissionStatus.granted;
      });
    }
  }

  Future<void> _requestPermissionDialog() async {
    final result = await NotificationPermissionDialog.show(
      context,
      reason: _permissionStatus == NotificationPermissionStatus.denied
          ? NotificationPermissionReason.denied
          : NotificationPermissionReason.firstTime,
    );
    
    if (result == true) {
      setState(() {
        _permissionStatus = NotificationPermissionStatus.granted;
      });
    } else if (result == false) {
      setState(() {
        _permissionStatus = NotificationPermissionStatus.denied;
      });
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status das Notificações'),
        content: NotificationStatusCard(
          permissionStatus: _permissionStatus,
          connectionStatus: _connectionStatus,
          showDetails: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _simulateRetry() {
    setState(() {
      _connectionStatus = OneSignalConnectionStatus.connecting;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _connectionStatus = OneSignalConnectionStatus.connected;
        });
      }
    });
  }

  void _togglePermissionStatus() {
    setState(() {
      _permissionStatus = _permissionStatus == NotificationPermissionStatus.granted
          ? NotificationPermissionStatus.denied
          : NotificationPermissionStatus.granted;
    });
  }

  void _toggleConnectionStatus() {
    setState(() {
      _connectionStatus = _connectionStatus == OneSignalConnectionStatus.connected
          ? OneSignalConnectionStatus.error
          : OneSignalConnectionStatus.connected;
    });
  }

  // Métodos auxiliares para exibição de status
  String _getPermissionStatusText() {
    switch (_permissionStatus) {
      case NotificationPermissionStatus.granted:
        return 'Concedida';
      case NotificationPermissionStatus.denied:
        return 'Negada';
      case NotificationPermissionStatus.limited:
        return 'Limitada';
      case NotificationPermissionStatus.requesting:
        return 'Solicitando';
      case NotificationPermissionStatus.error:
        return 'Erro';
      case NotificationPermissionStatus.unknown:
        return 'Desconhecida';
    }
  }

  Color _getPermissionStatusColor() {
    switch (_permissionStatus) {
      case NotificationPermissionStatus.granted:
        return Colors.green;
      case NotificationPermissionStatus.denied:
      case NotificationPermissionStatus.limited:
        return Colors.orange;
      case NotificationPermissionStatus.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getConnectionStatusText() {
    switch (_connectionStatus) {
      case OneSignalConnectionStatus.connected:
        return 'Conectado';
      case OneSignalConnectionStatus.connecting:
        return 'Conectando';
      case OneSignalConnectionStatus.disconnected:
        return 'Desconectado';
      case OneSignalConnectionStatus.error:
        return 'Erro';
    }
  }

  Color _getConnectionStatusColor() {
    switch (_connectionStatus) {
      case OneSignalConnectionStatus.connected:
        return Colors.green;
      case OneSignalConnectionStatus.connecting:
        return Colors.blue;
      case OneSignalConnectionStatus.disconnected:
        return Colors.orange;
      case OneSignalConnectionStatus.error:
        return Colors.red;
    }
  }
}

/// Exemplo de como integrar no AppBar principal
class MainScreenWithNotificationIndicator extends StatelessWidget {
  const MainScreenWithNotificationIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Option'),
        actions: [
          // Indicador pequeno que não ocupa muito espaço
          NotificationStatusIndicator(
            size: NotificationIndicatorSize.small,
            showPulse: true,
            onTap: () => _handleNotificationTap(context),
            margin: const EdgeInsets.only(right: AppSpacing.sm),
          ),
        ],
      ),
      body: const Center(
        child: Text('Conteúdo principal da tela'),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context) {
    // Lógica para lidar com toque no indicador
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingLg,
        child: const NotificationStatusCard(
          permissionStatus: NotificationPermissionStatus.granted,
          connectionStatus: OneSignalConnectionStatus.connected,
          showDetails: true,
        ),
      ),
    );
  }
}