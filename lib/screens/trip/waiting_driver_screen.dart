import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../models/supabase/trip_request.dart';
import '../../services/trip_service.dart';
import '../../widgets/logo_branding.dart';

class WaitingDriverScreen extends StatefulWidget {
  static const String routeName = '/waiting-driver';

  const WaitingDriverScreen({
    super.key,
    required this.tripRequestId,
  });

  final String tripRequestId;

  static WaitingDriverScreen fromArgs(Object? args) {
    final map = args as Map<String, dynamic>;
    return WaitingDriverScreen(
      tripRequestId: map['tripRequestId'] as String,
    );
  }

  @override
  State<WaitingDriverScreen> createState() => _WaitingDriverScreenState();
}

class _WaitingDriverScreenState extends State<WaitingDriverScreen>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late final TripService _tripService;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  
  TripRequest? _tripRequest;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tripService = TripService(_supabase);
    
    // Configurar animação de pulso
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _loadTripRequest();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadTripRequest() async {
    try {
      final tripRequest = await _tripService.getTripRequest(widget.tripRequestId);
      if (mounted) {
        setState(() {
          _tripRequest = tripRequest;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _cancelTrip() async {
    try {
      await _tripService.updateTripRequestStatus(
        id: widget.tripRequestId,
        status: 'cancelled',
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar viagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(title: 'Aguardando motorista'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _loadTripRequest)
              : _tripRequest != null
                  ? _WaitingContent(
                      tripRequest: _tripRequest!,
                      pulseAnimation: _pulseAnimation,
                      onCancel: _cancelTrip,
                    )
                  : const Center(child: Text('Solicitação não encontrada')),
    );
  }
}

class _WaitingContent extends StatelessWidget {
  const _WaitingContent({
    required this.tripRequest,
    required this.pulseAnimation,
    required this.onCancel,
  });

  final TripRequest tripRequest;
  final Animation<double> pulseAnimation;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone animado
                AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car,
                          size: 60,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // Título
                Text(
                  'Procurando motorista...',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Descrição
                Text(
                  'Estamos encontrando o melhor motorista para você. Isso pode levar alguns minutos.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Informações da viagem
                _TripInfoCard(tripRequest: tripRequest),
              ],
            ),
          ),
          
          // Botão cancelar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.error),
                foregroundColor: colorScheme.error,
              ),
              child: const Text('Cancelar viagem'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.tripRequest});

  final TripRequest tripRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhes da viagem',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Origem
          _InfoRow(
            icon: Icons.radio_button_checked,
            iconColor: colorScheme.primary,
            title: 'Origem',
            subtitle: tripRequest.originAddress,
          ),
          const SizedBox(height: 12),
          
          // Destino
          _InfoRow(
            icon: Icons.location_on,
            iconColor: colorScheme.error,
            title: 'Destino',
            subtitle: tripRequest.destinationAddress,
          ),
          const SizedBox(height: 12),
          
          // Categoria
          _InfoRow(
            icon: Icons.directions_car,
            iconColor: colorScheme.secondary,
            title: 'Categoria',
            subtitle: tripRequest.vehicleCategory.toUpperCase(),
          ),
          const SizedBox(height: 12),
          
          // Preço estimado
          _InfoRow(
            icon: Icons.attach_money,
            iconColor: colorScheme.tertiary,
            title: 'Preço estimado',
            subtitle: 'R\$ ${tripRequest.estimatedFare.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar solicitação',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}