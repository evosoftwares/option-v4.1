import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/trip_service.dart';
import '../../services/user_service.dart';
import '../../widgets/logo_branding.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final TripService _tripService = TripService(Supabase.instance.client);
  List<TripHistoryModel> _trips = [];
  bool _isLoading = true;
  String? _userId;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _initializeTrips();
  }

  Future<void> _initializeTrips() async {
    try {
      final user = await UserService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _userId = user.id;
          _userType = user.userType;
        });
        
        await _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar viagens: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTrips() async {
    if (_userId == null || _userType == null) return;

    try {
      List<TripHistoryModel> trips;
      
      if (_userType == 'driver') {
        trips = await _tripService.getTripHistory(driverId: _userId);
      } else {
        trips = await _tripService.getTripHistory(passengerId: _userId);
      }

      if (mounted) {
        setState(() {
          _trips = trips;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar viagens: $e')),
        );
      }
    }
  }

  String _getEmptyStateTitle() => _userType == 'driver' 
        ? 'Nenhuma viagem realizada'
        : 'Nenhuma viagem solicitada';

  String _getEmptyStateMessage() => _userType == 'driver'
        ? 'Você ainda não realizou nenhuma viagem.\nFique online para receber solicitações!'
        : 'Você ainda não solicitou nenhuma viagem.\nQue tal começar sua primeira jornada?';

  Future<void> _navigateToMenu() async {
    final user = await UserService.getCurrentUser();
    if (!mounted) {
      return;
    }
    
    if (user != null) {
      if (user.userType == 'driver') {
        await Navigator.pushNamed(context, '/driver_menu');
      } else {
        await Navigator.pushNamed(context, '/user_menu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: const StandardAppBar(
        title: 'Histórico de Viagens',
        showMenuIcon: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? _buildEmptyState(colorScheme)
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    padding: AppSpacing.paddingMd,
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      return _TripHistoryTile(
                        trip: trip,
                        isForDriver: _userType == 'driver',
                        onTap: () => _showTripDetails(trip),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) => Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _getEmptyStateTitle(),
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _getEmptyStateMessage(),
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );

  void _showTripDetails(TripHistoryModel trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TripDetailsBottomSheet(
        trip: trip,
        isForDriver: _userType == 'driver',
      ),
    );
  }
}

class _TripHistoryTile extends StatelessWidget {

  const _TripHistoryTile({
    required this.trip,
    required this.isForDriver,
    required this.onTap,
  });
  final TripHistoryModel trip;
  final bool isForDriver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = trip.status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status, colorScheme),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Date and status
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          trip.formattedDate,
                          style: AppTypography.labelMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(trip.status, colorScheme).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            trip.statusDisplayText,
                            style: AppTypography.labelSmall.copyWith(
                              color: _getStatusColor(trip.status, colorScheme),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Other user info
                  if (trip.otherUserName != null) ...[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: trip.otherUserPhotoUrl != null
                          ? NetworkImage(trip.otherUserPhotoUrl!)
                          : null,
                      child: trip.otherUserPhotoUrl == null
                          ? Icon(
                              Icons.person,
                              size: 20,
                              color: colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Route info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.radio_button_checked,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                trip.shortOriginAddress,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 1,
                          height: 16,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                trip.shortDestinationAddress,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Price and details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isCompleted) ...[
                        Text(
                          'R\$ ${trip.totalFare.toStringAsFixed(2)}',
                          style: AppTypography.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (trip.actualDistanceKm != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${trip.actualDistanceKm!.toStringAsFixed(1)} km',
                            style: AppTypography.labelSmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                      if (trip.otherUserName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          trip.otherUserName!,
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return colorScheme.error;
      case 'ongoing':
        return Colors.orange;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}

class _TripDetailsBottomSheet extends StatelessWidget {

  const _TripDetailsBottomSheet({
    required this.trip,
    required this.isForDriver,
  });
  final TripHistoryModel trip;
  final bool isForDriver;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detalhes da Viagem',
                        style: AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Trip code
                if (trip.tripCode != null) ...[
                  _DetailRow(
                    label: 'Código da viagem',
                    value: trip.tripCode!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Status
                _DetailRow(
                  label: 'Status',
                  value: trip.statusDisplayText,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Date
                _DetailRow(
                  label: 'Data',
                  value: '${trip.requestedAt.day}/${trip.requestedAt.month}/${trip.requestedAt.year} às ${trip.requestedAt.hour}:${trip.requestedAt.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Distance
                if (trip.actualDistanceKm != null) ...[
                  _DetailRow(
                    label: 'Distância',
                    value: '${trip.actualDistanceKm!.toStringAsFixed(1)} km',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Price
                _DetailRow(
                  label: 'Valor',
                  value: 'R\$ ${trip.totalFare.toStringAsFixed(2)}',
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Other user
                if (trip.otherUserName != null) ...[
                  _DetailRow(
                    label: isForDriver ? 'Passageiro' : 'Motorista',
                    value: trip.otherUserName!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Addresses
                const Text(
                  'Trajeto',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                _AddressRow(
                  icon: Icons.radio_button_checked,
                  iconColor: colorScheme.primary,
                  label: 'Origem',
                  address: trip.originAddress,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                _AddressRow(
                  icon: Icons.location_on,
                  iconColor: colorScheme.error,
                  label: 'Destino',
                  address: trip.destinationAddress,
                ),
                
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {

  const _DetailRow({
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                address,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}