import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';

/// Tipos de indicador de carregamento
enum AppLoadingType {
  circular,
  linear,
  dots,
  skeleton,
}

/// Tamanhos de indicador de carregamento
enum AppLoadingSize {
  small,
  medium,
  large,
}

/// Widget de indicador de carregamento padronizado
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.type = AppLoadingType.circular,
    this.size = AppLoadingSize.medium,
    this.message,
    this.color,
    this.backgroundColor,
    this.showMessage = true,
  });

  final AppLoadingType type;
  final AppLoadingSize size;
  final String? message;
  final Color? color;
  final Color? backgroundColor;
  final bool showMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;

    return ColoredBox(
      color: effectiveBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLoadingIndicator(effectiveColor),
            if (showMessage && message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    switch (type) {
      case AppLoadingType.circular:
        return _buildCircularIndicator(color);
      case AppLoadingType.linear:
        return _buildLinearIndicator(color);
      case AppLoadingType.dots:
        return _buildDotsIndicator(color);
      case AppLoadingType.skeleton:
        return _buildSkeletonIndicator(color);
    }
  }

  Widget _buildCircularIndicator(Color color) {
    final indicatorSize = _getIndicatorSize();
    final strokeWidth = _getStrokeWidth();

    return SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildLinearIndicator(Color color) {
    final width = _getLinearWidth();
    final height = _getLinearHeight();

    return SizedBox(
      width: width,
      height: height,
      child: LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: color.withOpacity(0.2),
      ),
    );
  }

  Widget _buildDotsIndicator(Color color) => _DotsLoadingIndicator(
      color: color,
      size: size,
    );

  Widget _buildSkeletonIndicator(Color color) => _SkeletonLoadingIndicator(
      color: color,
      size: size,
    );

  double _getIndicatorSize() {
    switch (size) {
      case AppLoadingSize.small:
        return AppSpacing.iconSm;
      case AppLoadingSize.medium:
        return AppSpacing.iconMd;
      case AppLoadingSize.large:
        return AppSpacing.iconLg;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case AppLoadingSize.small:
        return 2;
      case AppLoadingSize.medium:
        return 3;
      case AppLoadingSize.large:
        return 4;
    }
  }

  double _getLinearWidth() {
    switch (size) {
      case AppLoadingSize.small:
        return 100;
      case AppLoadingSize.medium:
        return 200;
      case AppLoadingSize.large:
        return 300;
    }
  }

  double _getLinearHeight() {
    switch (size) {
      case AppLoadingSize.small:
        return 2;
      case AppLoadingSize.medium:
        return 4;
      case AppLoadingSize.large:
        return 6;
    }
  }
}

/// Indicador de carregamento com pontos animados
class _DotsLoadingIndicator extends StatefulWidget {
  const _DotsLoadingIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final AppLoadingSize size;

  @override
  State<_DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<_DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers
        .map((controller) => Tween<double>(
              begin: 0,
              end: 1,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            )))
        .toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = _getDotSize();
    final spacing = _getDotSpacing();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) => Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Opacity(
                opacity: 0.3 + (0.7 * _animations[index].value),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ),
      ),
    );
  }

  double _getDotSize() {
    switch (widget.size) {
      case AppLoadingSize.small:
        return 6;
      case AppLoadingSize.medium:
        return 8;
      case AppLoadingSize.large:
        return 12;
    }
  }

  double _getDotSpacing() {
    switch (widget.size) {
      case AppLoadingSize.small:
        return 4;
      case AppLoadingSize.medium:
        return 6;
      case AppLoadingSize.large:
        return 8;
    }
  }
}

/// Indicador de carregamento skeleton
class _SkeletonLoadingIndicator extends StatefulWidget {
  const _SkeletonLoadingIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final AppLoadingSize size;

  @override
  State<_SkeletonLoadingIndicator> createState() =>
      _SkeletonLoadingIndicatorState();
}

class _SkeletonLoadingIndicatorState extends State<_SkeletonLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = _getSkeletonWidth();
    final height = _getSkeletonHeight();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                widget.color.withOpacity(0.1),
                widget.color.withOpacity(0.3),
                widget.color.withOpacity(0.1),
              ],
            ),
          ),
        ),
    );
  }

  double _getSkeletonWidth() {
    switch (widget.size) {
      case AppLoadingSize.small:
        return 80;
      case AppLoadingSize.medium:
        return 120;
      case AppLoadingSize.large:
        return 200;
    }
  }

  double _getSkeletonHeight() {
    switch (widget.size) {
      case AppLoadingSize.small:
        return 12;
      case AppLoadingSize.medium:
        return 16;
      case AppLoadingSize.large:
        return 24;
    }
  }
}

/// Overlay de carregamento em tela cheia
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    this.message,
    this.type = AppLoadingType.circular,
    this.size = AppLoadingSize.medium,
    this.backgroundColor,
    this.opacity = 0.8,
  });

  final String? message;
  final AppLoadingType type;
  final AppLoadingSize size;
  final Color? backgroundColor;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.surface.withOpacity(opacity);

    return Material(
      color: effectiveBackgroundColor,
      child: AppLoading(
        type: type,
        size: size,
        message: message,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

/// Utilitários para indicadores de carregamento
abstract class AppLoadingUtils {
  /// Exibe um overlay de carregamento
  static void showOverlay(
    BuildContext context, {
    String? message,
    AppLoadingType type = AppLoadingType.circular,
    AppLoadingSize size = AppLoadingSize.medium,
    Color? backgroundColor,
    double opacity = 0.8,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => AppLoadingOverlay(
        message: message,
        type: type,
        size: size,
        backgroundColor: backgroundColor,
        opacity: opacity,
      ),
    );
  }

  /// Remove o overlay de carregamento
  static void hideOverlay(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Widget de carregamento circular pequeno para botões
  static Widget buttonLoading({
    Color? color,
    double? size,
  }) => SizedBox(
      width: size ?? AppSpacing.iconSm,
      height: size ?? AppSpacing.iconSm,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.white,
        ),
      ),
    );

  /// Widget de carregamento para listas
  static Widget listLoading({
    String? message,
    AppLoadingSize size = AppLoadingSize.medium,
  }) => AppLoading(
      type: AppLoadingType.circular,
      size: size,
      message: message ?? 'Carregando...',
      backgroundColor: Colors.transparent,
    );

  /// Widget de carregamento skeleton para listas
  static Widget skeletonList({
    int itemCount = 5,
    AppLoadingSize size = AppLoadingSize.medium,
  }) => ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppLoading(
          type: AppLoadingType.skeleton,
          size: size,
          showMessage: false,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
}