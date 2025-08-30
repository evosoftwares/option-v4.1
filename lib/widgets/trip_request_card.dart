import 'package:flutter/material.dart';
import '../models/supabase/trip_request.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Widget card para exibir solicitações de viagem direcionadas para motoristas
/// Segue Material Design 3 e padrões do sistema Uber
class TripRequestCard extends StatelessWidget {
  const TripRequestCard({
    super.key,
    required this.request,
    required this.remainingSeconds,
    required this.onAccept,
    required this.onDecline,
  });

  final TripRequest request;
  final int remainingSeconds;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final isUrgent = remainingSeconds <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 3,
      shadowColor: AppColors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: isUrgent 
            ? const BorderSide(color: AppColors.error, width: 2)
            : BorderSide.none,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: isUrgent 
              ? LinearGradient(
                  colors: [
                    AppColors.error.withOpacity(0.05),
                    AppColors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, minutes, seconds, isUrgent),
              const SizedBox(height: AppSpacing.lg),
              _buildRouteInfo(context),
              const SizedBox(height: AppSpacing.lg),
              _buildTripDetails(context),
              if (_hasSpecialRequirements) ...[
                const SizedBox(height: AppSpacing.md),
                _buildSpecialRequirements(context),
              ],
              const SizedBox(height: AppSpacing.xl),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int minutes, int seconds, bool isUrgent) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Timer countdown
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppColors.error.withOpacity(0.1)
                : AppColors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: isUrgent 
                ? Border.all(color: AppColors.error)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUrgent ? Icons.warning : Icons.timer,
                size: AppSpacing.lg - AppSpacing.xs,
                color: isUrgent ? AppColors.error : AppColors.blue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: AppTypography.bold,
                  color: isUrgent ? AppColors.error : AppColors.blue,
                ),
              ),
            ],
          ),
        ),
        
        // Vehicle category
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Text(
            request.vehicleCategory.toUpperCase(),
            style: AppTypography.labelMedium.copyWith(
              fontWeight: AppTypography.semiBold,
              color: AppColors.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );

  Widget _buildRouteInfo(BuildContext context) => Column(
      children: [
        // Origem
        Row(
          children: [
            Container(
              width: AppSpacing.xs * 3,
              height: AppSpacing.xs * 3,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Origem',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    request.originAddress,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.medium,
                      color: AppColors.lightOnSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Linha conectora
        Container(
          margin: const EdgeInsets.only(
            left: 6, 
            top: AppSpacing.sm, 
            bottom: AppSpacing.sm,
          ),
          width: 2,
          height: AppSpacing.lg,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.blue,
                AppColors.error,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        // Destino
        Row(
          children: [
            Container(
              width: AppSpacing.xs * 3,
              height: AppSpacing.xs * 3,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destino',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.lightOnSurfaceVariant,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    request.destinationAddress,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.medium,
                      color: AppColors.lightOnSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

  Widget _buildTripDetails(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailChip(
              icon: Icons.straighten,
              label: '${request.estimatedDistanceKm.toStringAsFixed(1)} km',
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildDetailChip(
              icon: Icons.access_time,
              label: '${request.estimatedDurationMinutes} min',
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildDetailChip(
              icon: Icons.attach_money,
              label: 'R\$ ${request.estimatedFare.toStringAsFixed(2)}',
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) => Column(
      children: [
        Icon(
          icon,
          size: AppSpacing.lg,
          color: color,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: AppTypography.semiBold,
            color: AppColors.lightOnSurface,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

  bool get _hasSpecialRequirements => request.needsPet || 
           request.needsGrocery || 
           request.needsAc;

  Widget _buildSpecialRequirements(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos especiais',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: AppTypography.semiBold,
              color: AppColors.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (request.needsPet)
                _buildRequirementChip(
                  icon: Icons.pets,
                  label: 'Pet',
                ),
              if (request.needsGrocery)
                Row(
                  children: const [
                    Icon(Icons.local_grocery_store, size: 16),
                    SizedBox(width: 4),
                    Text('Espaço para compras'),
                  ],
                ),
              if (request.needsAc)
                _buildRequirementChip(
                  icon: Icons.ac_unit,
                  label: 'Ar Condicionado',
                ),
            ],
          ),
        ],
      ),
    );

  Widget _buildRequirementChip({
    required IconData icon,
    required String label,
  }) => Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.onTertiaryContainer.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSpacing.md,
            color: AppColors.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: AppTypography.medium,
              color: AppColors.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );

  Widget _buildActionButtons(BuildContext context) => Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              'Recusar',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              elevation: 2,
            ),
            child: Text(
              'Aceitar Viagem',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ),
      ],
    );
}