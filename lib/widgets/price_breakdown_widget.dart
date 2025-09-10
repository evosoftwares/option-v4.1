import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// Widget para exibir o breakdown detalhado do preço da viagem
/// Segue padrões de transparência exigidos pelas app stores
class PriceBreakdownWidget extends StatelessWidget {
  const PriceBreakdownWidget({
    super.key,
    required this.totalPrice,
    required this.distanceComponent,
    required this.timeComponent,
    required this.additionalFees,
    this.zoneMultiplier = 1.0,
    this.baseFare,
    this.showTotal = true,
    this.compact = false,
    this.platformCommission,
    this.driverEarnings,
    this.showCommissionBreakdown = false,
  });

  /// Preço total da viagem
  final double totalPrice;

  /// Componente de distância (R$ por km)
  final double distanceComponent;

  /// Componente de tempo (R$ por minuto)
  final double timeComponent;

  /// Taxas adicionais (pet, grocery, condo, stop)
  final double additionalFees;

  /// Multiplicador de zona (se aplicável)
  final double zoneMultiplier;

  /// Tarifa base (opcional - para casos onde é diferente da soma dos componentes)
  final double? baseFare;

  /// Se deve mostrar o total no final
  final bool showTotal;

  /// Modo compacto para espaços menores
  final bool compact;
  
  /// Comissão da plataforma (opcional)
  final double? platformCommission;
  
  /// Ganhos do motorista (opcional)
  final double? driverEarnings;
  
  /// Se deve mostrar breakdown de comissão
  final bool showCommissionBreakdown;

  @override
  Widget build(BuildContext context) {
    final effectiveBaseFare = baseFare ?? (distanceComponent + timeComponent);
    final hasZoneMultiplier = zoneMultiplier != 1.0;

    return AppCard(
      padding: compact ? AppSpacing.paddingMd : AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Detalhamento do Preço',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: AppTypography.semiBold,
              color: AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Componente de Distância
          _buildPriceLine(
            label: 'Distância',
            value: distanceComponent,
            icon: Icons.straighten,
          ),

          // Componente de Tempo
          _buildPriceLine(
            label: 'Tempo',
            value: timeComponent,
            icon: Icons.access_time,
          ),

          // Taxas Adicionais (se houver)
          if (additionalFees > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildPriceLine(
              label: 'Taxas Adicionais',
              value: additionalFees,
              icon: Icons.attach_money,
            ),
          ],

          // Multiplicador de Zona (se aplicável)
          if (hasZoneMultiplier) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildMultiplierLine(),
          ],

          // Linha divisória antes do total
          if (showTotal) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
          ],

          // Breakdown da Comissão (se solicitado)
          if (showCommissionBreakdown && platformCommission != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            
            // Título da seção de comissão
            Text(
              'Distribuição do Valor',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: AppTypography.semiBold,
                color: AppColors.lightOnSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Ganhos do motorista
            if (driverEarnings != null)
              _buildPriceLine(
                label: 'Motorista',
                value: driverEarnings!,
                icon: Icons.drive_eta,
              ),
            
            // Comissão da plataforma
            _buildPriceLine(
              label: 'Taxa da Plataforma',
              value: platformCommission!,
              icon: Icons.business,
            ),
          ],
          
          // Preço Total
          if (showTotal) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.lightOnSurface,
                  ),
                ),
                Text(
                  'R\$ ${totalPrice.toStringAsFixed(2)}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: AppTypography.bold,
                    color: AppColors.lightPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceLine({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  icon,
                  size: compact ? AppSpacing.md : AppSpacing.lg,
                  color: AppColors.lightOnSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: compact
                        ? AppTypography.bodySmall.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          )
                        : AppTypography.bodyMedium.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: compact
                ? AppTypography.bodySmall.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.lightOnSurface,
                  )
                : AppTypography.bodyMedium.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.lightOnSurface,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: compact ? AppSpacing.md : AppSpacing.lg,
                  color: AppColors.lightOnSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Multiplicador de Zona',
                    style: compact
                        ? AppTypography.bodySmall.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          )
                        : AppTypography.bodyMedium.copyWith(
                            color: AppColors.lightOnSurfaceVariant,
                          ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${zoneMultiplier.toStringAsFixed(1)}x',
            style: compact
                ? AppTypography.bodySmall.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.warning,
                  )
                : AppTypography.bodyMedium.copyWith(
                    fontWeight: AppTypography.medium,
                    color: AppColors.warning,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Versão simplificada para exibição rápida em cards
class CompactPriceBreakdown extends StatelessWidget {
  const CompactPriceBreakdown({
    super.key,
    required this.totalPrice,
    required this.distanceComponent,
    required this.timeComponent,
    required this.additionalFees,
  });

  final double totalPrice;
  final double distanceComponent;
  final double timeComponent;
  final double additionalFees;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Clique para ver detalhes do preço',
      child: InkWell(
        onTap: () {
          _showDetailedBreakdown(context);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.lightOutlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                size: AppSpacing.md,
                color: AppColors.lightOnSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'R\$ ${totalPrice.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: AppTypography.semiBold,
                  color: AppColors.lightOnSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedBreakdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalhamento do Preço'),
          content: PriceBreakdownWidget(
            totalPrice: totalPrice,
            distanceComponent: distanceComponent,
            timeComponent: timeComponent,
            additionalFees: additionalFees,
            compact: false,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}