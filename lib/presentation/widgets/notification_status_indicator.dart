import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../services/onesignal_service.dart';

enum NotificationIndicatorSize {
  compact,  // Apenas ícone
  small,    // Ícone + status
  full,     // Ícone + status + ação
}

class NotificationStatusIndicator extends StatefulWidget {
  final NotificationIndicatorSize size;
  final VoidCallback? onTap;
  final bool showPulse;
  final EdgeInsetsGeometry? margin;

  const NotificationStatusIndicator({
    super.key,
    this.size = NotificationIndicatorSize.small,
    this.onTap,
    this.showPulse = true,
    this.margin,
  });

  @override
  State<NotificationStatusIndicator> createState() => _NotificationStatusIndicatorState();
}

class _NotificationStatusIndicatorState extends State<NotificationStatusIndicator>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  Timer? _statusCheckTimer;
  bool _isConnected = false;
  bool _hasPermission = false;
  bool _isInitializing = true;
  String _lastStatusCheck = '';

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _startStatusCheck();
    
    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusCheck() {
    _checkStatus();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkStatus(),
    );
  }

  Future<void> _checkStatus() async {
    try {
      // Verificar se OneSignal está inicializado
      final service = OneSignalService();
      
      setState(() {
        _isInitializing = true;
      });
      
      // Simular verificação de status
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Aqui você integraria com os métodos reais do OneSignalService
      // Por enquanto, vamos simular o status
      final now = DateTime.now();
      
      setState(() {
        _isConnected = true; // service.isConnected
        _hasPermission = true; // service.hasPermission
        _isInitializing = false;
        _lastStatusCheck = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
      
      _updateAnimation();
      
    } catch (e) {
      setState(() {
        _isConnected = false;
        _hasPermission = false;
        _isInitializing = false;
      });
    }
  }

  void _updateAnimation() {
    if (_isInitializing) {
      _rotationController.repeat();
      _pulseController.stop();
    } else if (_isConnected && _hasPermission) {
      _rotationController.stop();
      _rotationController.reset();
      if (widget.showPulse) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _rotationController.stop();
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget indicator = _buildIndicator(colorScheme);
    
    if (widget.onTap != null) {
      indicator = InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: indicator,
      );
    }

    return Container(
      margin: widget.margin,
      child: indicator,
    );
  }

  Widget _buildIndicator(ColorScheme colorScheme) {
    switch (widget.size) {
      case NotificationIndicatorSize.compact:
        return _buildCompactIndicator(colorScheme);
      case NotificationIndicatorSize.small:
        return _buildSmallIndicator(colorScheme);
      case NotificationIndicatorSize.full:
        return _buildFullIndicator(colorScheme);
    }
  }

  Widget _buildCompactIndicator(ColorScheme colorScheme) {
    final (icon, color) = _getStatusIconAndColor(colorScheme);
    
    return AnimatedBuilder(
      animation: _isInitializing ? _rotationController : _pulseController,
      builder: (context, child) {
        if (_isInitializing) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Icon(
              Icons.sync,
              color: colorScheme.primary,
              size: 20,
            ),
          );
        }
        
        return Transform.scale(
          scale: widget.showPulse && _isConnected && _hasPermission 
            ? _pulseAnimation.value 
            : 1.0,
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildSmallIndicator(ColorScheme colorScheme) {
    final (icon, color) = _getStatusIconAndColor(colorScheme);
    final statusText = _getStatusText();
    
    return AnimatedBuilder(
      animation: _isInitializing ? _rotationController : _pulseController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isInitializing)
              Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Icon(
                  Icons.sync,
                  color: colorScheme.primary,
                  size: 16,
                ),
              )
            else
              Transform.scale(
                scale: widget.showPulse && _isConnected && _hasPermission 
                  ? _pulseAnimation.value 
                  : 1.0,
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              statusText,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFullIndicator(ColorScheme colorScheme) {
    final (icon, color) = _getStatusIconAndColor(colorScheme);
    final statusText = _getStatusText();
    final description = _getStatusDescription();
    
    return AnimatedBuilder(
      animation: _isInitializing ? _rotationController : _pulseController,
      builder: (context, child) {
        return Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              if (_isInitializing)
                Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Icon(
                    Icons.sync,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                )
              else
                Transform.scale(
                  scale: widget.showPulse && _isConnected && _hasPermission 
                    ? _pulseAnimation.value 
                    : 1.0,
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: AppTypography.labelMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
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
              if (_shouldShowAction())
                Icon(
                  Icons.settings,
                  color: colorScheme.onSurfaceVariant,
                  size: 16,
                ),
            ],
          ),
        );
      },
    );
  }

  (IconData, Color) _getStatusIconAndColor(ColorScheme colorScheme) {
    if (_isInitializing) {
      return (Icons.sync, colorScheme.primary);
    } else if (_isConnected && _hasPermission) {
      return (Icons.notifications_active, Colors.green);
    } else if (!_hasPermission) {
      return (Icons.notifications_off, Colors.orange);
    } else {
      return (Icons.notifications_none, colorScheme.error);
    }
  }

  String _getStatusText() {
    if (_isInitializing) {
      return 'Verificando...';
    } else if (_isConnected && _hasPermission) {
      return 'Notificações Ativas';
    } else if (!_hasPermission) {
      return 'Permissão Necessária';
    } else {
      return 'Desconectado';
    }
  }

  String _getStatusDescription() {
    if (_isInitializing) {
      return 'Verificando status das notificações';
    } else if (_isConnected && _hasPermission) {
      return 'Última verificação: $_lastStatusCheck';
    } else if (!_hasPermission) {
      return 'Toque para habilitar notificações';
    } else {
      return 'Problemas de conectividade detectados';
    }
  }

  bool _shouldShowAction() {
    return !_isConnected || !_hasPermission;
  }
}

// Widget auxiliar para mostrar o status em banners
class NotificationStatusBanner extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const NotificationStatusBanner({
    super.key,
    required this.isVisible,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: AppSpacing.paddingMd,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notification_important,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificações Desabilitadas',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Você pode estar perdendo informações importantes',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                'Ativar',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: Colors.orange.shade600,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}