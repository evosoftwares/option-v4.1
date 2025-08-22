import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../services/user_service.dart';
import '../../services/wallet_service.dart';
import '../../services/passenger_payment_service.dart';
import '../../models/user.dart' as app_user;
import '../../models/passenger_wallet.dart';
import '../../models/passenger_wallet_transaction.dart';
import '../../models/payment_method.dart';
import '../../widgets/logo_branding.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletService _walletService;
  Future<app_user.User?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _walletService = WalletService();
    _userFuture = UserService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const StandardAppBar(title: 'Carteira'),
      body: FutureBuilder<app_user.User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            return const _ErrorState(message: 'Você precisa estar logado para ver a carteira.');
          }

          final isDriver = user.userType.toLowerCase() == 'driver';
          if (!isDriver) {
            return _PassengerWalletContent(user: user, walletService: _walletService);
          }

          return _DriverWalletContent(user: user, walletService: _walletService);
        },
      ),
    );
  }
}

class _PassengerWalletContent extends StatefulWidget {
  const _PassengerWalletContent({required this.user, required this.walletService});
  final app_user.User user;
  final WalletService walletService;

  @override
  State<_PassengerWalletContent> createState() => _PassengerWalletContentState();
}

class _PassengerWalletContentState extends State<_PassengerWalletContent> {
  late final PassengerPaymentService _paymentService;
  Future<String?>? _passengerIdFuture;
  Future<PassengerWallet?>? _walletFuture;
  Future<List<PassengerWalletTransaction>>? _transactionsFuture;
  Future<List<PaymentMethod>>? _paymentMethodsFuture;

  @override
  void initState() {
    super.initState();
    _paymentService = PassengerPaymentService(walletService: widget.walletService);
    _passengerIdFuture = widget.walletService.getPassengerIdForUser(widget.user.id);
    _passengerIdFuture!.then((passengerId) {
      if (passengerId != null) {
        setState(() {
          _walletFuture = _getOrCreateWallet(passengerId);
          _transactionsFuture = widget.walletService.getPassengerWalletTransactions(passengerId);
          _paymentMethodsFuture = widget.walletService.getPaymentMethods(widget.user.id);
        });
      }
    });
  }

  Future<PassengerWallet?> _getOrCreateWallet(String passengerId) async {
    var wallet = await widget.walletService.getPassengerWallet(passengerId);
    if (wallet == null) {
      wallet = await widget.walletService.createPassengerWallet(passengerId, widget.user.id);
    }
    return wallet;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<String?>(
      future: _passengerIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final passengerId = snap.data;
        if (passengerId == null) {
          return const _ErrorState(message: 'Não encontramos seu perfil de passageiro.');
        }
        return RefreshIndicator(
          onRefresh: () => _refreshData(passengerId),
          child: ListView(
            padding: AppSpacing.paddingLg,
            children: [
              FutureBuilder<PassengerWallet?>(
                future: _walletFuture,
                builder: (context, wSnap) {
                  if (wSnap.connectionState == ConnectionState.waiting) {
                    return const _WalletBalanceLoadingSkeleton();
                  }
                  final wallet = wSnap.data;
                  return _PassengerBalanceCard(
                    availableBalance: wallet?.availableBalance ?? 0.0,
                    pendingBalance: wallet?.pendingBalance ?? 0.0,
                    totalSpent: wallet?.totalSpent ?? 0.0,
                    totalCashback: wallet?.totalCashback ?? 0.0,
                    onAddCredit: () => _onAddCredit(passengerId),
                    onViewPaymentMethods: () => _onViewPaymentMethods(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transações', style: AppTypography.titleMedium.copyWith(color: cs.onSurfaceVariant)),
                  TextButton.icon(
                    onPressed: () => _refreshData(passengerId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FutureBuilder<List<PassengerWalletTransaction>>(
                future: _transactionsFuture,
                builder: (context, tSnap) {
                  if (tSnap.connectionState == ConnectionState.waiting) {
                    return const _TransactionsLoadingSkeleton();
                  }
                  final transactions = tSnap.data ?? const [];
                  if (transactions.isEmpty) {
                    return const _InfoCard(
                      title: 'Nenhuma transação',
                      message: 'Suas transações aparecerão aqui assim que você começar a usar a carteira.',
                      icon: Icons.receipt_long_outlined,
                    );
                  }
                  return Column(
                    children: transactions.map((tx) => _PassengerTransactionTile(transaction: tx)).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refreshData(String passengerId) async {
    setState(() {
      _walletFuture = widget.walletService.getPassengerWallet(passengerId);
      _transactionsFuture = widget.walletService.getPassengerWalletTransactions(passengerId);
      _paymentMethodsFuture = widget.walletService.getPaymentMethods(widget.user.id);
    });
  }

  Future<void> _onAddCredit(String passengerId) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddCreditBottomSheet(
        user: widget.user,
        passengerId: passengerId,
        paymentService: _paymentService,
      ),
    );

    if (result == true) {
      await _refreshData(passengerId);
    }
  }

  void _onViewPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gerenciamento de métodos de pagamento em breve'),
      ),
    );
  }
}

class _DriverWalletContent extends StatefulWidget {
  const _DriverWalletContent({required this.user, required this.walletService});
  final app_user.User user;
  final WalletService walletService;

  @override
  State<_DriverWalletContent> createState() => _DriverWalletContentState();
}

class _DriverWalletContentState extends State<_DriverWalletContent> {
  Future<String?>? _driverIdFuture;
  Future<Map<String, dynamic>?>? _walletFuture;
  Future<List<Map<String, dynamic>>>? _txFuture;

  @override
  void initState() {
    super.initState();
    _driverIdFuture = widget.walletService.getDriverIdForUser(widget.user.id);
    _driverIdFuture!.then((driverId) {
      if (driverId != null) {
        setState(() {
          _walletFuture = widget.walletService.getDriverWallet(driverId);
          _txFuture = widget.walletService.getWalletTransactions(driverId);
        });
        // Pré-garante cadastro no Asaas (não bloqueia UI)
        widget.walletService.ensureAsaasCustomerForUser(widget.user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<String?>(
      future: _driverIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final driverId = snap.data;
        if (driverId == null) {
          return const _ErrorState(message: 'Não encontramos seu perfil de motorista.');
        }
        return ListView(
          padding: AppSpacing.paddingLg,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _walletFuture,
              builder: (context, wSnap) {
                final wallet = wSnap.data;
                final available = (wallet?['available_balance'] ?? 0).toString();
                final pending = (wallet?['pending_balance'] ?? 0).toString();
                final total = (wallet?['total_earned'] ?? 0).toString();
                return _BalanceCard(
                  available: available,
                  pending: pending,
                  total: total,
                  onWithdraw: () => _onWithdraw(driverId),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sectionSpacing),
            Text('Transações', style: AppTypography.titleMedium.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _txFuture,
              builder: (context, tSnap) {
                if (tSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final txs = tSnap.data ?? const [];
                if (txs.isEmpty) {
                  return const _InfoCard(
                    title: 'Nenhuma transação',
                    message: 'Suas transações aparecerão aqui assim que você começar a ganhar.',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return Column(
                  children: txs.map((tx) => _TransactionTile(tx: tx)).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onWithdraw(String driverId) async {
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
          backgroundColor: cs.surface,
          title: Text('Solicitar saque', style: AppTypography.titleMedium.copyWith(color: cs.onSurface)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Valor (R\$)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: cs.primary)),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
                if (parsed != null && parsed > 0) {
                  Navigator.pop<double>(context, parsed);
                }
              },
              style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
              child: const Text('Confirmar'),
            ),
          ],
        ),
    );

    if (amount != null) {
      try {
        await widget.walletService.requestWithdrawal(driverId: driverId, amount: amount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saque solicitado com sucesso', style: AppTypography.bodyMedium.copyWith(color: cs.onInverseSurface))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao solicitar saque. Por favor, tente novamente mais tarde.', style: AppTypography.bodyMedium.copyWith(color: cs.onInverseSurface))),
          );
        }
      }
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.available, required this.pending, required this.total, required this.onWithdraw});
  final String available;
  final String pending;
  final String total;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo disponível', style: AppTypography.bodyMedium.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.xs),
          Text('R\$ $available', style: AppTypography.displaySmall.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Pendente',
                  value: 'R\$ $pending',
                  background: cs.secondaryContainer,
                  foreground: cs.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatChip(
                  label: 'Total ganho',
                  value: 'R\$ $total',
                  background: cs.tertiaryContainer,
                  foreground: cs.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onWithdraw,
              style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
              icon: const Icon(Icons.attach_money),
              label: const Text('Solicitar saque'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.background, required this.foreground});
  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySmall.copyWith(color: foreground))),
          Text(value, style: AppTypography.bodyMedium.copyWith(color: foreground, fontWeight: FontWeight.w600)),
        ],
      ),
    );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final type = (tx['type'] ?? '').toString();
    final amount = (tx['amount'] ?? 0).toString();
    final desc = (tx['description'] ?? '').toString();
    final createdAt = (tx['created_at'] ?? '').toString();

    final isCredit = type.toLowerCase() == 'credit' || (double.tryParse(amount) ?? 0) > 0;
    final icon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;
    final color = isCredit ? cs.tertiary : cs.secondary;
    final onColor = isCredit ? cs.onTertiary : cs.onSecondary;

    return Container(
      height: AppSpacing.listItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: onColor,
            child: Icon(icon),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc.isEmpty ? 'Transação' : desc, style: AppTypography.bodyLarge.copyWith(color: cs.onSurface)),
                Text(createdAt, style: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            (isCredit ? r'+ R$ ' : r'- R$ ') + amount,
            style: AppTypography.bodyMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.message, required this.icon});
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: cs.primaryContainer, foregroundColor: cs.onPrimaryContainer, child: Icon(icon)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium.copyWith(color: cs.onSurface)),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Text(message, style: AppTypography.bodyLarge.copyWith(color: cs.error)),
      ),
    );
  }
}

// ========== PASSENGER WALLET WIDGETS ==========

class _PassengerBalanceCard extends StatelessWidget {
  const _PassengerBalanceCard({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalSpent,
    required this.totalCashback,
    required this.onAddCredit,
    required this.onViewPaymentMethods,
  });

  final double availableBalance;
  final double pendingBalance;
  final double totalSpent;
  final double totalCashback;
  final VoidCallback onAddCredit;
  final VoidCallback onViewPaymentMethods;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo disponível', style: AppTypography.bodyMedium.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.xs),
          Text('R\$ ${availableBalance.toStringAsFixed(2)}', style: AppTypography.displaySmall.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Total gasto',
                  value: 'R\$ ${totalSpent.toStringAsFixed(2)}',
                  background: cs.secondaryContainer,
                  foreground: cs.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatChip(
                  label: 'Cashback',
                  value: 'R\$ ${totalCashback.toStringAsFixed(2)}',
                  background: cs.tertiaryContainer,
                  foreground: cs.onTertiaryContainer,
                ),
              ),
            ],
          ),
          if (pendingBalance > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _StatChip(
              label: 'Pendente',
              value: 'R\$ ${pendingBalance.toStringAsFixed(2)}',
              background: cs.surfaceContainerHighest,
              foreground: cs.onSurface,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddCredit,
                  style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar crédito'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onViewPaymentMethods,
                style: OutlinedButton.styleFrom(foregroundColor: cs.onPrimaryContainer),
                icon: const Icon(Icons.payment),
                label: const Text('Métodos'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassengerTransactionTile extends StatelessWidget {
  const _PassengerTransactionTile({required this.transaction});
  final PassengerWalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCredit = transaction.isCredit;
    final icon = _getTransactionIcon(transaction.type);
    final color = isCredit ? cs.tertiary : cs.secondary;
    final onColor = isCredit ? cs.onTertiary : cs.onSecondary;

    return Container(
      height: AppSpacing.listItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: onColor,
            child: Icon(icon),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTypography.bodyLarge.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatTransactionDate(transaction.createdAt),
                  style: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount,
                style: AppTypography.bodyMedium.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transaction.status, cs),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  transaction.status.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: _getStatusTextColor(transaction.status, cs),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.credit:
        return Icons.add_circle_outline;
      case TransactionType.tripPayment:
        return Icons.directions_car;
      case TransactionType.cashback:
        return Icons.monetization_on;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.cancellationFee:
        return Icons.cancel_outlined;
    }
  }

  Color _getStatusColor(TransactionStatus status, ColorScheme cs) {
    switch (status) {
      case TransactionStatus.completed:
        return cs.tertiary.withOpacity(0.1);
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return cs.secondary.withOpacity(0.1);
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return cs.error.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor(TransactionStatus status, ColorScheme cs) {
    switch (status) {
      case TransactionStatus.completed:
        return cs.tertiary;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return cs.secondary;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return cs.error;
    }
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Hoje ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (transactionDate == yesterday) {
      return 'Ontem ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _AddCreditBottomSheet extends StatefulWidget {
  const _AddCreditBottomSheet({
    required this.user,
    required this.passengerId,
    required this.paymentService,
  });

  final app_user.User user;
  final String passengerId;
  final PassengerPaymentService paymentService;

  @override
  State<_AddCreditBottomSheet> createState() => _AddCreditBottomSheetState();
}

class _AddCreditBottomSheetState extends State<_AddCreditBottomSheet> {
  final _amountController = TextEditingController();
  PaymentMethodType _selectedMethod = PaymentMethodType.pix;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Adicionar crédito', style: AppTypography.titleLarge.copyWith(color: cs.onSurface)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              hintText: '0,00',
              prefixText: 'R\$ ',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Método de pagamento', style: AppTypography.titleMedium.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          _PaymentMethodSelector(
            selectedMethod: _selectedMethod,
            onChanged: (method) => setState(() => _selectedMethod = method),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _isLoading ? null : _onAddCredit,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddCredit() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um valor válido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final paymentData = await widget.paymentService.createCreditPayment(
        passengerId: widget.passengerId,
        user: widget.user,
        amount: amount,
        paymentMethod: _selectedMethod,
        description: 'Recarga de carteira - R\$ ${amount.toStringAsFixed(2)}',
      );

      if (mounted) {
        Navigator.pop(context, true);
        // Show payment details or QR code
        _showPaymentDetails(paymentData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar pagamento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPaymentDetails(Map<String, dynamic> paymentData) {
    if (_selectedMethod == PaymentMethodType.pix) {
      showDialog(
        context: context,
        builder: (context) => _PixPaymentDialog(paymentData: paymentData),
      );
    }
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selectedMethod,
    required this.onChanged,
  });

  final PaymentMethodType selectedMethod;
  final ValueChanged<PaymentMethodType> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _PaymentMethodTile(
          type: PaymentMethodType.pix,
          isSelected: selectedMethod == PaymentMethodType.pix,
          onTap: () => onChanged(PaymentMethodType.pix),
          icon: Icons.pix,
          title: 'PIX',
          subtitle: 'Transferência instantânea',
          cs: cs,
        ),
        // Cartão de crédito removido - não suportado pela estratégia de pagamentos digitais
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
    this.isEnabled = true,
  });

  final PaymentMethodType type;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEnabled ? (isSelected ? cs.primary : cs.onSurfaceVariant) : cs.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isEnabled ? (isSelected ? cs.onPrimaryContainer : cs.onSurface) : cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isEnabled ? (isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant) : cs.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _PixPaymentDialog extends StatelessWidget {
  const _PixPaymentDialog({required this.paymentData});
  final Map<String, dynamic> paymentData;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surface,
      title: Text('Pagamento PIX', style: AppTypography.titleMedium.copyWith(color: cs.onSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pix, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Use o código PIX abaixo ou escaneie o QR Code para efetuar o pagamento',
            style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              'PIX Copia e Cola: Em breve',
              style: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

// Loading Skeletons
class _WalletBalanceLoadingSkeleton extends StatelessWidget {
  const _WalletBalanceLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 16, width: 120, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 32, width: 200, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: Container(height: 60, color: cs.onSurfaceVariant.withOpacity(0.2))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Container(height: 60, color: cs.onSurfaceVariant.withOpacity(0.2))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(height: 48, color: cs.onSurfaceVariant.withOpacity(0.2)),
        ],
      ),
    );
  }
}

class _TransactionsLoadingSkeleton extends StatelessWidget {
  const _TransactionsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(3, (index) => Container(
        height: AppSpacing.listItemHeight,
        margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: cs.onSurfaceVariant.withOpacity(0.3))),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 16, color: cs.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 4),
                  Container(height: 12, width: 100, color: cs.onSurfaceVariant.withOpacity(0.2)),
                ],
              ),
            ),
            Container(height: 16, width: 80, color: cs.onSurfaceVariant.withOpacity(0.3)),
          ],
        ),
      )),
    );
  }
}