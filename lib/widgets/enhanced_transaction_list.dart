/// Lista de transações com feedback visual aprimorado
/// 
/// Este widget exibe uma lista de transações da carteira com 
/// melhorias visuais e feedback para o usuário.
library;

import 'package:flutter/material.dart';

import '../models/passenger_wallet_transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/wallet_constants.dart';

/// Lista de transações com feedback visual aprimorado
class EnhancedTransactionList extends StatelessWidget {
  const EnhancedTransactionList({
    super.key,
    required this.transactions,
    this.onTransactionTap,
    this.emptyWidget,
  });

  final List<PassengerWalletTransaction> transactions;
  final Function(PassengerWalletTransaction)? onTransactionTap;
  final Widget? emptyWidget;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return emptyWidget ?? const _DefaultEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _TransactionItem(
          transaction: transaction,
          onTap: onTransactionTap != null ? () => onTransactionTap!(transaction) : null,
        );
      },
    );
  }
}

/// Item individual de transação com feedback visual
class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.transaction,
    this.onTap,
  });

  final PassengerWalletTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCredit = transaction.isCredit;
    final status = transaction.status;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _getBorderColor(colorScheme, status),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone da transação
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(colorScheme, isCredit, status),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: _getIconColor(colorScheme, isCredit, status),
                size: AppSpacing.iconSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            
            // Informações da transação
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: AppTypography.bodyLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatTransactionDate(transaction.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (transaction.metadata != null && 
                      transaction.metadata!['reference_id'] != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      child: Text(
                        'Ref: ${transaction.metadata!['reference_id']}',
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Valor e status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: AppTypography.bodyLarge.copyWith(
                    color: _getAmountColor(colorScheme, isCredit, status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(colorScheme, status),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    transaction.status.displayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: _getStatusTextColor(colorScheme, status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Obtém a cor da borda baseada no status
  Color _getBorderColor(ColorScheme colorScheme, TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return colorScheme.outlineVariant;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return colorScheme.secondary.withValues(alpha: 0.3);
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return colorScheme.error.withValues(alpha: 0.3);
    }
  }

  /// Obtém a cor de fundo do ícone
  Color _getIconBackgroundColor(ColorScheme colorScheme, bool isCredit, TransactionStatus status) {
    if (status == TransactionStatus.failed || status == TransactionStatus.cancelled) {
      return colorScheme.errorContainer;
    }
    return isCredit ? colorScheme.primaryContainer : colorScheme.secondaryContainer;
  }

  /// Obtém a cor do ícone
  Color _getIconColor(ColorScheme colorScheme, bool isCredit, TransactionStatus status) {
    if (status == TransactionStatus.failed || status == TransactionStatus.cancelled) {
      return colorScheme.onErrorContainer;
    }
    return isCredit ? colorScheme.primary : colorScheme.secondary;
  }

  /// Obtém a cor do valor
  Color _getAmountColor(ColorScheme colorScheme, bool isCredit, TransactionStatus status) {
    if (status == TransactionStatus.failed || status == TransactionStatus.cancelled) {
      return colorScheme.onSurfaceVariant;
    }
    return isCredit ? colorScheme.primary : colorScheme.onSurface;
  }

  /// Obtém a cor de fundo do status
  Color _getStatusBackgroundColor(ColorScheme colorScheme, TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return colorScheme.primary.withValues(alpha: 0.1);
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return colorScheme.secondary.withValues(alpha: 0.1);
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return colorScheme.error.withValues(alpha: 0.1);
    }
  }

  /// Obtém a cor do texto do status
  Color _getStatusTextColor(ColorScheme colorScheme, TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return colorScheme.primary;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return colorScheme.secondary;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return colorScheme.error;
    }
  }

  /// Obtém o ícone apropriado para o tipo de transação
  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.credit:
        return Icons.add_circle_outline;
      case TransactionType.tripPayment:
        return Icons.directions_car_outlined;
      case TransactionType.refund:
        return Icons.undo_outlined;
      case TransactionType.cancellationFee:
        return Icons.cancel_outlined;
      case TransactionType.withdrawal:
        return Icons.account_balance_outlined;
    }
  }

  /// Formata a data da transação
  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Hoje, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (transactionDate == yesterday) {
      return 'Ontem, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Estado vazio padrão para a lista de transações
class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: AppSpacing.iconXl,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhuma transação encontrada',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Suas transações aparecerão aqui',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Cabeçalho da lista de transações com resumo
class TransactionListHeader extends StatelessWidget {
  const TransactionListHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}