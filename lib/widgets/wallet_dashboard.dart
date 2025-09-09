/// Dashboard da carteira com feedback visual completo
/// 
/// Este widget exibe um dashboard completo da carteira com 
/// todos os elementos visuais e feedback necessários.
library;

import 'package:flutter/material.dart';

import '../models/passenger_wallet.dart';
import '../models/passenger_wallet_transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/wallet_constants.dart';
import 'enhanced_transaction_list.dart';
import 'wallet_feedback_widgets.dart';

/// Dashboard completo da carteira
class WalletDashboard extends StatelessWidget {
  const WalletDashboard({
    super.key,
    required this.wallet,
    required this.recentTransactions,
    this.onAddCredit,
    this.onWithdraw,
    this.onTransactionTap,
    this.isLoading = false,
  });

  final PassengerWallet? wallet;
  final List<PassengerWalletTransaction> recentTransactions;
  final VoidCallback? onAddCredit;
  final VoidCallback? onWithdraw;
  final Function(PassengerWalletTransaction)? onTransactionTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        if (isLoading)
          const _WalletDashboardLoadingSkeleton()
        else ...[
          _BalanceCard(
            wallet: wallet,
            onAddCredit: onAddCredit,
            onWithdraw: onWithdraw,
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          const TransactionListHeader(
            title: 'Transações Recentes',
            subtitle: 'Últimas movimentações da sua carteira',
          ),
          const SizedBox(height: AppSpacing.md),
          EnhancedTransactionList(
            transactions: recentTransactions,
            onTransactionTap: onTransactionTap,
          ),
        ],
      ],
    );
  }
}

/// Cartão de saldo com feedback visual
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.wallet,
    this.onAddCredit,
    this.onWithdraw,
  });

  final PassengerWallet? wallet;
  final VoidCallback? onAddCredit;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableBalance = wallet?.availableBalance ?? 0.0;
    final totalSpent = wallet?.totalSpent ?? 0.0;
    final pendingBalance = wallet?.pendingBalance ?? 0.0;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Disponível',
                style: AppTypography.bodyLarge.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: colorScheme.onPrimaryContainer,
                size: AppSpacing.iconMd,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${WalletConstants.currencySymbol}${availableBalance.toStringAsFixed(WalletConstants.decimalPlaces)}',
            style: AppTypography.displayMedium.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Estatísticas
          Row(
            children: [
              _StatChip(
                label: 'Total Gasto',
                value: '${WalletConstants.currencySymbol}${totalSpent.toStringAsFixed(WalletConstants.decimalPlaces)}',
                backgroundColor: colorScheme.secondaryContainer,
                textColor: colorScheme.onSecondaryContainer,
                icon: Icons.shopping_cart_outlined,
              ),
              const SizedBox(width: AppSpacing.md),
              if (pendingBalance > 0)
                _StatChip(
                  label: 'Pendente',
                  value: '${WalletConstants.currencySymbol}${pendingBalance.toStringAsFixed(WalletConstants.decimalPlaces)}',
                  backgroundColor: colorScheme.tertiaryContainer,
                  textColor: colorScheme.onTertiaryContainer,
                  icon: Icons.hourglass_empty_outlined,
                ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Botões de ação
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddCredit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: AppSpacing.paddingMd,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Crédito'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onWithdraw,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onPrimaryContainer,
                    padding: AppSpacing.paddingMd,
                    side: BorderSide(color: colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Sacar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip de estatística com ícone
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      color: textColor,
                    ),
                  ),
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de carregamento para o dashboard
class _WalletDashboardLoadingSkeleton extends StatelessWidget {
  const _WalletDashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        // Cartão de saldo
        Container(
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                width: 120,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 36,
                width: 200,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: AppSpacing.listItemHeight,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      height: AppSpacing.listItemHeight,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: AppSpacing.buttonHeight,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.sectionSpacing),
        
        // Cabeçalho de transações
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 24,
              width: 150,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            Container(
              height: 16,
              width: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Lista de transações
        ...List.generate(3, (index) => const _TransactionSkeleton()),
      ],
    );
  }
}

/// Esqueleto de carregamento para item de transação
class _TransactionSkeleton extends StatelessWidget {
  const _TransactionSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconLg,
            height: AppSpacing.iconLg,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 14,
                  width: 80,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          Container(
            height: 16,
            width: 60,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}