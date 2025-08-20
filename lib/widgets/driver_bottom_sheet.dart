import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/driver_status.dart';
import '../controllers/driver_status_controller.dart';

class DriverBottomSheet extends StatefulWidget {
  final DriverStatusController statusController;
  final double minHeight;
  final double maxHeight;

  const DriverBottomSheet({
    super.key,
    required this.statusController,
    this.minHeight = 140,
    this.maxHeight = 300,
  });

  @override
  State<DriverBottomSheet> createState() => _DriverBottomSheetState();
}

class _DriverBottomSheetState extends State<DriverBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    widget.statusController.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    widget.statusController.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    final isOnline = widget.statusController.isOnline;
    
    if (isOnline && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isOnline) {
      _pulseController.stop();
      _pulseController.reset();
    }
    
    setState(() {});
  }

  void _onGoButtonPressed() async {
    HapticFeedback.mediumImpact();
    
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    await widget.statusController.toggleOnlineStatus();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = widget.statusController.status;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? widget.maxHeight : widget.minHeight,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: _toggleExpansion,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    if (!_isExpanded) _buildCollapsedContent(context, status),
                    if (_isExpanded) _buildExpandedContent(context, status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context, DriverStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status.statusDisplayText,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (status.isOnline)
                Text(
                  widget.statusController.onlineTimeText,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildGoButton(context, status),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, DriverStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.statusDisplayText,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (status.isOnline)
                    Text(
                      widget.statusController.onlineTimeText,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildGoButton(context, status),
          ],
        ),
        if (status.isOnline) ...[
          const SizedBox(height: 24),
          _buildStatsSection(context, status),
        ],
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, DriverStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '${status.tripsCompleted}',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'viagens',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 32,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  status.earningsDisplayText,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ganhos',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoButton(BuildContext context, DriverStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color buttonColor;
    Color textColor;
    String buttonText;

    if (status.isTransitioning) {
      buttonColor = colorScheme.surfaceVariant;
      textColor = colorScheme.onSurfaceVariant;
      buttonText = '...';
    } else if (status.isOnline) {
      buttonColor = colorScheme.error;
      textColor = colorScheme.onError;
      buttonText = 'PARAR';
    } else {
      buttonColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      buttonText = 'IR';
    }

    Widget button = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: buttonColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          buttonText,
          style: textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (status.isOnline) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: button,
          );
        },
      );
    }

    button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: button,
        );
      },
    );

    return GestureDetector(
      onTap: status.isTransitioning ? null : _onGoButtonPressed,
      child: button,
    );
  }
}