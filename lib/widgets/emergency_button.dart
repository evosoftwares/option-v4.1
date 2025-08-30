import 'package:flutter/material.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Widget de botão de emergência
class EmergencyButton extends StatefulWidget {
  const EmergencyButton({super.key});

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Animação pulsante contínua
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _triggerEmergency() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Mostrar diálogo de confirmação
      final confirmed = await _showConfirmationDialog();
      
      if (confirmed ?? false) {
        // Disparar emergência
        await EmergencyService.triggerEmergency(
          description: 'Emergência acionada pelo usuário',
        );

        if (mounted) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmationDialog() async => showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.warning,
              color: AppColors.error,
              size: AppSpacing.lg,
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Confirmar Emergência'),
          ],
        ),
        content: const Text(
          'Você está prestes a acionar o botão de emergência. '
          'Isso irá notificar seus contatos de emergência e as autoridades. '
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Confirmar Emergência'),
          ),
        ],
      ),
    );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: AppSpacing.lg,
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Emergência Acionada'),
          ],
        ),
        content: const Text(
          'Sua emergência foi registrada com sucesso. '
          'Seus contatos de emergência foram notificados.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.error,
              color: AppColors.error,
              size: AppSpacing.lg,
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Erro'),
          ],
        ),
        content: Text(
          'Erro ao acionar emergência: $error',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: _triggerEmergency,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.error.withOpacity(0.8),
                    AppColors.error,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: _isPressed ? AppSpacing.sm : AppSpacing.md,
                    spreadRadius: _isPressed ? 2 : AppSpacing.xs,
                  ),
                ],
                border: Border.all(
                  color: AppColors.white,
                  width: 3,
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emergency,
                          color: AppColors.white,
                          size: AppSpacing.iconXl,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'SOS',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
    );
}

/// Widget compacto de botão de emergência para uso em menus
class CompactEmergencyButton extends StatelessWidget {
  const CompactEmergencyButton({super.key});

  Future<void> _triggerEmergency(BuildContext context) async {
    try {
      await EmergencyService.triggerEmergency(
        description: 'Emergência acionada pelo usuário',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergência acionada com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao acionar emergência: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _triggerEmergency(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emergency,
                  color: AppColors.white,
                  size: AppSpacing.lg,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Emergência',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}