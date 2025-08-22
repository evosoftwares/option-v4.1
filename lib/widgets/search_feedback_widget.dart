import 'package:flutter/material.dart';
import '../services/search_status_service.dart';

/// Widget para exibir feedback visual durante a busca de motoristas
class SearchFeedbackWidget extends StatefulWidget {
  const SearchFeedbackWidget({
    super.key,
    this.showOnlyWhenActive = false,
    this.compact = false,
  });

  /// Se true, só mostra o widget quando há uma busca ativa
  final bool showOnlyWhenActive;
  
  /// Se true, usa uma versão mais compacta do widget
  final bool compact;

  @override
  State<SearchFeedbackWidget> createState() => _SearchFeedbackWidgetState();
}

class _SearchFeedbackWidgetState extends State<SearchFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  final SearchStatusService _searchService = SearchStatusService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleStateChange(SearchState state) {
    switch (state.status) {
      case SearchStatus.searching:
        _pulseController.repeat(reverse: true);
        _slideController.forward();
        break;
      case SearchStatus.success:
      case SearchStatus.error:
      case SearchStatus.noDriversFound:
        _pulseController.stop();
        _slideController.forward();
        // Auto-hide após 3 segundos para estados finais
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _slideController.reverse();
          }
        });
        break;
      case SearchStatus.idle:
        _pulseController.stop();
        _slideController.reverse();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SearchState>(
      stream: _searchService.stateStream,
      initialData: _searchService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        // Se showOnlyWhenActive é true e o estado é idle, não mostra nada
        if (widget.showOnlyWhenActive && state.status == SearchStatus.idle) {
          return const SizedBox.shrink();
        }

        _handleStateChange(state);

        return SlideTransition(
          position: _slideAnimation,
          child: _buildFeedbackCard(context, state),
        );
      },
    );
  }

  Widget _buildFeedbackCard(BuildContext context, SearchState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.status == SearchStatus.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(widget.compact ? 8 : 16),
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(colorScheme, state.status),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(colorScheme, state.status),
          SizedBox(width: widget.compact ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message ?? _getDefaultMessage(state.status),
                  style: widget.compact
                      ? textTheme.bodyMedium?.copyWith(
                          color: _getTextColor(colorScheme, state.status),
                          fontWeight: FontWeight.w500,
                        )
                      : textTheme.bodyLarge?.copyWith(
                          color: _getTextColor(colorScheme, state.status),
                          fontWeight: FontWeight.w500,
                        ),
                ),
                if (state.errorDetails != null && !widget.compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.errorDetails!,
                    style: textTheme.bodySmall?.copyWith(
                      color: _getTextColor(colorScheme, state.status)
                          .withOpacity(0.8),
                    ),
                  ),
                ],
                if (state.driversFound != null && !widget.compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${state.driversFound} motorista(s) disponível(is)',
                    style: textTheme.bodySmall?.copyWith(
                      color: _getTextColor(colorScheme, state.status)
                          .withOpacity(0.8),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme, SearchStatus status) {
    final iconColor = _getIconColor(colorScheme, status);
    final iconSize = widget.compact ? 20.0 : 24.0;

    switch (status) {
      case SearchStatus.searching:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
            );
          },
        );
      case SearchStatus.success:
        return Icon(
          Icons.check_circle,
          color: iconColor,
          size: iconSize,
        );
      case SearchStatus.error:
        return Icon(
          Icons.error,
          color: iconColor,
          size: iconSize,
        );
      case SearchStatus.noDriversFound:
        return Icon(
          Icons.search_off,
          color: iconColor,
          size: iconSize,
        );
      case SearchStatus.idle:
        return Icon(
          Icons.search,
          color: iconColor,
          size: iconSize,
        );
    }
  }

  Color _getBackgroundColor(ColorScheme colorScheme, SearchStatus status) {
    switch (status) {
      case SearchStatus.searching:
        return colorScheme.primaryContainer;
      case SearchStatus.success:
        return colorScheme.secondaryContainer;
      case SearchStatus.error:
        return colorScheme.errorContainer;
      case SearchStatus.noDriversFound:
        return colorScheme.surfaceVariant;
      case SearchStatus.idle:
        return colorScheme.surface;
    }
  }

  Color _getTextColor(ColorScheme colorScheme, SearchStatus status) {
    switch (status) {
      case SearchStatus.searching:
        return colorScheme.onPrimaryContainer;
      case SearchStatus.success:
        return colorScheme.onSecondaryContainer;
      case SearchStatus.error:
        return colorScheme.onErrorContainer;
      case SearchStatus.noDriversFound:
        return colorScheme.onSurfaceVariant;
      case SearchStatus.idle:
        return colorScheme.onSurface;
    }
  }

  Color _getIconColor(ColorScheme colorScheme, SearchStatus status) {
    switch (status) {
      case SearchStatus.searching:
        return colorScheme.primary;
      case SearchStatus.success:
        return colorScheme.secondary;
      case SearchStatus.error:
        return colorScheme.error;
      case SearchStatus.noDriversFound:
        return colorScheme.onSurfaceVariant;
      case SearchStatus.idle:
        return colorScheme.onSurface;
    }
  }

  String _getDefaultMessage(SearchStatus status) {
    switch (status) {
      case SearchStatus.searching:
        return 'Buscando motoristas...';
      case SearchStatus.success:
        return 'Motoristas encontrados!';
      case SearchStatus.error:
        return 'Erro na busca';
      case SearchStatus.noDriversFound:
        return 'Nenhum motorista encontrado';
      case SearchStatus.idle:
        return 'Pronto para buscar';
    }
  }
}