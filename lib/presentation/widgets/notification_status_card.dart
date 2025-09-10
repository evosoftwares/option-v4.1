import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum NotificationPermissionStatus {
  unknown,
  requesting,
  granted,
  denied,
  limited,
  error
}

enum OneSignalConnectionStatus {
  disconnected,
  connecting,
  connected,
  error
}

class NotificationStatusCard extends StatelessWidget {
  final NotificationPermissionStatus permissionStatus;
  final OneSignalConnectionStatus connectionStatus;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onRequestPermission;
  final bool showDetails;

  const NotificationStatusCard({
    super.key,
    required this.permissionStatus,
    required this.connectionStatus,
    this.errorMessage,
    this.onRetry,
    this.onRequestPermission,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: AppSpacing.paddingMd,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme),
            const SizedBox(height: AppSpacing.md),
            _buildPermissionStatus(context),
            const SizedBox(height: AppSpacing.sm),
            _buildConnectionStatus(context),
            if (showDetails) ...[
              const SizedBox(height: AppSpacing.md),
              _buildDetails(context),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildErrorSection(context),
            ],
            if (_shouldShowActions()) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final (icon, color, title) = _getOverallStatus();
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status das Notificações',
                style: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionStatus(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color, title, description) = _getPermissionStatusInfo();

    return _StatusRow(
      icon: icon,
      color: color,
      title: title,
      description: description,
      colorScheme: colorScheme,
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color, title, description) = _getConnectionStatusInfo();

    return _StatusRow(
      icon: icon,
      color: color,
      title: title,
      description: description,
      colorScheme: colorScheme,
    );
  }

  Widget _buildDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes',
            style: AppTypography.labelMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(
            label: 'Recebimento de notificações:',
            value: _canReceiveNotifications() ? 'Ativo' : 'Inativo',
            isPositive: _canReceiveNotifications(),
          ),
          _DetailRow(
            label: 'Som personalizado:',
            value: _hasSoundEnabled() ? 'Habilitado' : 'Padrão do sistema',
            isPositive: _hasSoundEnabled(),
          ),
          _DetailRow(
            label: 'Notificações em segundo plano:',
            value: _hasBackgroundNotifications() ? 'Funcionando' : 'Limitado',
            isPositive: _hasBackgroundNotifications(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        if (permissionStatus == NotificationPermissionStatus.denied && onRequestPermission != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: onRequestPermission,
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('Permitir Notificações'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
            ),
          ),
        if (permissionStatus == NotificationPermissionStatus.denied && onRequestPermission != null && onRetry != null)
          const SizedBox(width: AppSpacing.sm),
        if (onRetry != null && _shouldShowRetry())
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar Novamente'),
            ),
          ),
      ],
    );
  }

  // Helper methods for status information
  (IconData, Color, String) _getOverallStatus() {
    if (permissionStatus == NotificationPermissionStatus.granted && 
        connectionStatus == OneSignalConnectionStatus.connected) {
      return (Icons.check_circle, Colors.green, 'Funcionando perfeitamente');
    } else if (permissionStatus == NotificationPermissionStatus.denied) {
      return (Icons.notifications_off, Colors.orange, 'Permissão necessária');
    } else if (connectionStatus == OneSignalConnectionStatus.error || 
               permissionStatus == NotificationPermissionStatus.error) {
      return (Icons.error, Colors.red, 'Erro de conexão');
    } else {
      return (Icons.pending, Colors.blue, 'Configurando...');
    }
  }

  (IconData, Color, String, String) _getPermissionStatusInfo() {
    switch (permissionStatus) {
      case NotificationPermissionStatus.granted:
        return (Icons.check_circle, Colors.green, 'Permissão Concedida', 
                'Você pode receber todas as notificações');
      case NotificationPermissionStatus.denied:
        return (Icons.block, Colors.red, 'Permissão Negada', 
                'Toque aqui para habilitar notificações nas configurações');
      case NotificationPermissionStatus.limited:
        return (Icons.warning, Colors.orange, 'Permissão Limitada', 
                'Algumas notificações podem não aparecer');
      case NotificationPermissionStatus.requesting:
        return (Icons.hourglass_empty, Colors.blue, 'Solicitando Permissão', 
                'Aguardando sua resposta...');
      case NotificationPermissionStatus.error:
        return (Icons.error, Colors.red, 'Erro de Permissão', 
                'Não foi possível verificar as permissões');
      case NotificationPermissionStatus.unknown:
        return (Icons.help_outline, Colors.grey, 'Status Desconhecido', 
                'Verificando permissões...');
    }
  }

  (IconData, Color, String, String) _getConnectionStatusInfo() {
    switch (connectionStatus) {
      case OneSignalConnectionStatus.connected:
        return (Icons.cloud_done, Colors.green, 'Conectado', 
                'Recebendo notificações em tempo real');
      case OneSignalConnectionStatus.connecting:
        return (Icons.cloud_sync, Colors.blue, 'Conectando', 
                'Estabelecendo conexão...');
      case OneSignalConnectionStatus.disconnected:
        return (Icons.cloud_off, Colors.orange, 'Desconectado', 
                'Tentando reconectar automaticamente');
      case OneSignalConnectionStatus.error:
        return (Icons.cloud_off, Colors.red, 'Erro de Conexão', 
                'Verifique sua internet e tente novamente');
    }
  }

  bool _shouldShowActions() {
    return (permissionStatus == NotificationPermissionStatus.denied && onRequestPermission != null) ||
           (onRetry != null && _shouldShowRetry());
  }

  bool _shouldShowRetry() {
    return connectionStatus == OneSignalConnectionStatus.error ||
           permissionStatus == NotificationPermissionStatus.error;
  }

  bool _canReceiveNotifications() {
    return permissionStatus == NotificationPermissionStatus.granted &&
           connectionStatus == OneSignalConnectionStatus.connected;
  }

  bool _hasSoundEnabled() {
    return permissionStatus == NotificationPermissionStatus.granted;
  }

  bool _hasBackgroundNotifications() {
    return permissionStatus == NotificationPermissionStatus.granted &&
           connectionStatus == OneSignalConnectionStatus.connected;
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final ColorScheme colorScheme;

  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isPositive ? Colors.green : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}