import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum NotificationPermissionReason {
  firstTime,
  denied,
  essential,
  benefit,
}

class NotificationPermissionDialog extends StatelessWidget {
  final NotificationPermissionReason reason;
  final VoidCallback onAllow;
  final VoidCallback onDeny;
  final VoidCallback? onSettings;
  final String? customMessage;

  const NotificationPermissionDialog({
    super.key,
    required this.reason,
    required this.onAllow,
    required this.onDeny,
    this.onSettings,
    this.customMessage,
  });

  static Future<bool?> show(
    BuildContext context, {
    required NotificationPermissionReason reason,
    String? customMessage,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NotificationPermissionDialog(
        reason: reason,
        customMessage: customMessage,
        onAllow: () => Navigator.of(context).pop(true),
        onDeny: () => Navigator.of(context).pop(false),
        onSettings: () => Navigator.of(context).pop(null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          color: colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colorScheme),
            _buildContent(context),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final (icon, color, title) = _getHeaderInfo();
    
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customMessage ?? _getMainMessage(),
            style: AppTypography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBenefitsList(colorScheme),
          if (reason == NotificationPermissionReason.denied) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDeniedInstructions(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsList(ColorScheme colorScheme) {
    final benefits = _getBenefits();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Com as notificações você recebe:',
          style: AppTypography.titleSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...benefits.map((benefit) => _BenefitItem(
          icon: benefit.$1,
          text: benefit.$2,
          colorScheme: colorScheme,
        )),
      ],
    );
  }

  Widget _buildDeniedInstructions(ColorScheme colorScheme) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Para habilitar manualmente:',
                style: AppTypography.labelMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '1. Vá em Configurações do dispositivo\n'
            '2. Encontre "Option" na lista de apps\n'
            '3. Toque em "Notificações"\n'
            '4. Ative "Permitir notificações"',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        children: [
          Row(
            children: [
              if (reason == NotificationPermissionReason.denied && onSettings != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSettings,
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Abrir Configurações'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (reason == NotificationPermissionReason.denied && onSettings != null)
                const SizedBox(width: AppSpacing.sm),
              if (reason != NotificationPermissionReason.denied)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAllow,
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: Text(_getAllowButtonText()),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          if (reason != NotificationPermissionReason.essential) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onDeny,
              child: Text(
                _getDenyButtonText(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods
  (IconData, Color, String) _getHeaderInfo() {
    switch (reason) {
      case NotificationPermissionReason.firstTime:
        return (Icons.notifications, Colors.blue, 'Receba Notificações');
      case NotificationPermissionReason.denied:
        return (Icons.notifications_off, Colors.orange, 'Notificações Desabilitadas');
      case NotificationPermissionReason.essential:
        return (Icons.notification_important, Colors.red, 'Notificações Essenciais');
      case NotificationPermissionReason.benefit:
        return (Icons.notifications_active, Colors.green, 'Melhore sua Experiência');
    }
  }

  String _getMainMessage() {
    switch (reason) {
      case NotificationPermissionReason.firstTime:
        return 'Para uma melhor experiência no Option, permita que enviemos notificações importantes sobre suas viagens.';
      case NotificationPermissionReason.denied:
        return 'As notificações estão desabilitadas. Você pode estar perdendo informações importantes sobre suas viagens.';
      case NotificationPermissionReason.essential:
        return 'As notificações são essenciais para o funcionamento do aplicativo. Sem elas, você não receberá avisos sobre viagens e motoristas.';
      case NotificationPermissionReason.benefit:
        return 'Ative as notificações para receber informações em tempo real e ter uma experiência completa no Option.';
    }
  }

  List<(IconData, String)> _getBenefits() {
    return [
      (Icons.directions_car, 'Avisos quando o motorista chegou'),
      (Icons.message, 'Mensagens do motorista ou passageiro'),
      (Icons.route, 'Status da viagem em tempo real'),
      (Icons.payment, 'Confirmações de pagamento'),
      (Icons.local_offer, 'Ofertas especiais personalizadas'),
    ];
  }

  String _getAllowButtonText() {
    switch (reason) {
      case NotificationPermissionReason.firstTime:
        return 'Permitir Notificações';
      case NotificationPermissionReason.denied:
        return 'Tentar Novamente';
      case NotificationPermissionReason.essential:
        return 'Ativar Agora';
      case NotificationPermissionReason.benefit:
        return 'Ativar Notificações';
    }
  }

  String _getDenyButtonText() {
    switch (reason) {
      case NotificationPermissionReason.firstTime:
        return 'Agora não';
      case NotificationPermissionReason.denied:
        return 'Continuar sem notificações';
      case NotificationPermissionReason.essential:
        return 'Entendi os riscos';
      case NotificationPermissionReason.benefit:
        return 'Talvez depois';
    }
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;

  const _BenefitItem({
    required this.icon,
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}