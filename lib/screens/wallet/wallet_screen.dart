/// Tela principal da carteira digital do passageiro
/// 
/// Esta tela permite ao usuário:
/// - Visualizar saldo disponível, pendente e total ganho
/// - Consultar histórico de transações
/// - Solicitar saques via PIX com validação robusta
/// - Recarregar a carteira
/// 
/// Implementa funcionalidades de segurança como:
/// - Rate limiting para saques
/// - Validação de chaves PIX
/// - Logs de auditoria
/// - Detecção de atividades suspeitas
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../models/passenger_wallet.dart';
import '../../models/passenger_wallet_transaction.dart';
import '../../models/payment_method.dart';
import '../../models/user.dart' as app_user;
import '../../services/passenger_payment_service.dart';
import '../../services/user_service.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/logo_branding.dart';
import '../../utils/pix_validator.dart';
import '../../exceptions/wallet_exceptions.dart';
import '../../utils/money_formatter.dart';
import '../../utils/wallet_constants.dart';
import '../../widgets/paginated_transaction_list.dart';
import '../../services/transaction_cache_service.dart';

/// Widget principal da tela de carteira
/// 
/// Gerencia o estado da carteira e coordena as operações
/// financeiras do passageiro.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

/// Estado da tela de carteira
/// 
/// Controla o ciclo de vida da tela e gerencia
/// as interações do usuário com a carteira.
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
  final TransactionCacheService _cacheService = TransactionCacheService();
  Future<String?>? _passengerIdFuture;
  Future<PassengerWallet?>? _walletFuture;
  Future<List<PaymentMethod>>? _paymentMethodsFuture;

  @override
  void initState() {
    super.initState();
    _paymentService = PassengerPaymentService(walletService: widget.walletService);
    _cacheService.initialize();
    _passengerIdFuture = widget.walletService.getPassengerIdForUser(widget.user.id);
    _passengerIdFuture!.then((passengerId) {
      if (passengerId != null && mounted) {
        setState(() {
          _walletFuture = _getOrCreateWallet(passengerId);
          _paymentMethodsFuture = widget.walletService.getPaymentMethods(widget.user.id);
        });
      }
    }).catchError((error) {
      if (mounted) {
        // Handle error silently or show error state
        debugPrint('Error loading passenger data: $error');
      }
    });
  }
  
  @override
  void dispose() {
    _cacheService.dispose();
    super.dispose();
  }

  Future<PassengerWallet?> _getOrCreateWallet(String passengerId) async {
    var wallet = await widget.walletService.getPassengerWallet(passengerId);
    wallet ??= await widget.walletService.createPassengerWallet(passengerId, widget.user.id);
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
          return const _ErrorState(message: 'Perfil de passageiro não encontrado. Tente fazer logout e login novamente.');
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
                    availableBalance: wallet?.availableBalance ?? WalletConstants.defaultBalance,
        pendingBalance: wallet?.pendingBalance ?? WalletConstants.defaultBalance,
        totalSpent: wallet?.totalSpent ?? WalletConstants.defaultBalance,
            
                    onAddCredit: () => _onAddCredit(passengerId),
                    onViewPaymentMethods: _onViewPaymentMethods,
                    onWithdraw: () => _onWithdraw(passengerId),
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
              SizedBox(
                height: 400, // Altura fixa para a lista paginada
                child: PaginatedTransactionList(
                  passengerId: passengerId,
                  transactionLoader: ({required passengerId, required page, required limit}) => 
                      widget.walletService.getPassengerWalletTransactions(passengerId, page: page, limit: limit),
                  itemBuilder: (context, transaction, index) => _PassengerTransactionTile(
                    transaction: transaction,
                  ),
                  emptyWidget: const _InfoCard(
                    title: 'Nenhuma transação',
                    message: 'Suas transações aparecerão aqui assim que você começar a usar a carteira.',
                    icon: Icons.receipt_long_outlined,
                  ),
                  loadingWidget: const _TransactionsLoadingSkeleton(),
                ),
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
      _paymentMethodsFuture = widget.walletService.getPaymentMethods(widget.user.id);
    });
    // Invalidate cache to force refresh of transactions
     _cacheService.invalidateUserCache(passengerId);
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

    if (result ?? false) {
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

  Future<void> _onWithdraw(String passengerId) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WithdrawBottomSheet(
        passengerId: passengerId,
        availableBalance: widget.walletService.getPassengerWallet(passengerId).then((wallet) => wallet?.availableBalance ?? WalletConstants.zeroBalance),
      ),
    );

    if (result ?? false) {
      await _refreshData(passengerId);
    }
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
          return _ErrorState(
            message: 'Configurando perfil de motorista',
            showRetryButton: true,
            retryButtonText: 'Atualizar',
            onRetry: () {
              setState(() {
                _driverIdFuture = widget.walletService.getDriverIdForUser(widget.user.id);
                _driverIdFuture!.then((driverId) {
                  if (driverId != null) {
                    setState(() {
                      _walletFuture = widget.walletService.getDriverWallet(driverId);
                      _txFuture = widget.walletService.getWalletTransactions(driverId);
                    });
                    widget.walletService.ensureAsaasCustomerForUser(widget.user);
                  }
                });
              });
            },
          );
        }
        return ListView(
          padding: AppSpacing.paddingLg,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: _walletFuture,
              builder: (context, wSnap) {
                final wallet = wSnap.data;
                final available = (wallet?['available_balance'] ?? WalletConstants.minimumPositiveAmount).toString();
      final pending = (wallet?['pending_balance'] ?? WalletConstants.minimumPositiveAmount).toString();
      final total = (wallet?['total_earned'] ?? WalletConstants.minimumPositiveAmount).toString();
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
            decoration: const InputDecoration(labelText: r'Valor (R$)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: cs.primary)),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
                if (parsed != null && parsed > WalletConstants.minimumPositiveAmount) {
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
    final amount = (tx['amount'] ?? WalletConstants.minimumPositiveAmount).toString();
    final desc = (tx['description'] ?? '').toString();
    final createdAt = (tx['created_at'] ?? '').toString();

    final isCredit = type.toLowerCase() == 'credit' || (double.tryParse(amount) ?? WalletConstants.minimumPositiveAmount) > WalletConstants.minimumPositiveAmount;
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
  const _ErrorState({
    required this.message,
    this.onRetry,
    this.showRetryButton = false,
    this.retryButtonText = 'Tentar Novamente',
  });
  
  final String message;
  final VoidCallback? onRetry;
  final bool showRetryButton;
  final String retryButtonText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              message.contains('Configurando') ? Icons.settings : Icons.error_outline,
              size: 64,
              color: message.contains('Configurando') ? cs.primary : cs.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: message.contains('Configurando') ? cs.primary : cs.error
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message.contains('Configurando') 
                ? 'Seu perfil de motorista está sendo configurado automaticamente. Isso pode levar alguns segundos.'
                : 'Verifique sua conexão ou entre em contato com o suporte se o problema persistir.',
              style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && onRetry != null) ...[
               const SizedBox(height: AppSpacing.lg),
               ElevatedButton(
                 onPressed: onRetry,
                 child: Text(retryButtonText),
               ),
             ]
          ],
        ),
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

    required this.onAddCredit,
    required this.onViewPaymentMethods,
    required this.onWithdraw,
  });

  final double availableBalance;
  final double pendingBalance;
  final double totalSpent;

  final VoidCallback onAddCredit;
  final VoidCallback onViewPaymentMethods;
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
          Text('${WalletConstants.currencySymbol} ${availableBalance.toStringAsFixed(WalletConstants.decimalPlaces)}', style: AppTypography.displaySmall.copyWith(color: cs.onPrimaryContainer)),
          const SizedBox(height: AppSpacing.md),
          _StatChip(
            label: 'Total gasto',
            value: '${WalletConstants.currencySymbol} ${totalSpent.toStringAsFixed(WalletConstants.decimalPlaces)}',
            background: cs.secondaryContainer,
            foreground: cs.onSecondaryContainer,
          ),

          if (pendingBalance > WalletConstants.defaultBalance) ...[
            const SizedBox(height: AppSpacing.md),
            _StatChip(
              label: 'Pendente',
              value: '${WalletConstants.currencySymbol} ${pendingBalance.toStringAsFixed(WalletConstants.decimalPlaces)}',
              background: cs.surfaceContainerHighest,
              foreground: cs.onSurface,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddCredit,
              style: FilledButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar crédito'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onWithdraw,
              style: OutlinedButton.styleFrom(foregroundColor: cs.onPrimaryContainer),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Sacar'),
            ),
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
                  maxLines: WalletConstants.singleLine,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: WalletConstants.verticalSpacing2),
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
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.cancellationFee:
        return Icons.cancel_outlined;
      case TransactionType.withdrawal:
        return Icons.account_balance;
    }
  }

  Color _getStatusColor(TransactionStatus status, ColorScheme cs) {
    switch (status) {
      case TransactionStatus.completed:
        return cs.tertiary.withOpacity(WalletConstants.backgroundOpacity);
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return cs.secondary.withOpacity(WalletConstants.backgroundOpacity);
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return cs.error.withOpacity(WalletConstants.backgroundOpacity);
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
    final yesterday = today.subtract(const Duration(days: WalletConstants.yesterdayOffset));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return '${WalletConstants.todayPrefix}${date.hour}:${date.minute.toString().padLeft(WalletConstants.timePadLength, WalletConstants.timePadChar)}';
    } else if (transactionDate == yesterday) {
      return '${WalletConstants.yesterdayPrefix}${date.hour}:${date.minute.toString().padLeft(WalletConstants.timePadLength, WalletConstants.timePadChar)}';
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
              labelText: r'Valor (R$)',
              hintText: WalletConstants.defaultAmountHint,
              prefixText: r'R$ ',
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
              minimumSize: const Size.fromHeight(WalletConstants.buttonMinHeight),
            ),
            child: _isLoading
                ? const SizedBox(width: WalletConstants.progressIndicatorSize, height: WalletConstants.progressIndicatorSize, child: CircularProgressIndicator(strokeWidth: WalletConstants.progressIndicatorStroke))
                : const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddCredit() async {
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= WalletConstants.defaultBalance) {
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
        description: 'Recarga de carteira - ${WalletConstants.currencySymbol} ${amount.toStringAsFixed(WalletConstants.decimalPlaces)}',
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
    switch (_selectedMethod) {
      case PaymentMethodType.pix:
        showDialog(
          context: context,
          builder: (context) => _PixPaymentDialog(paymentData: paymentData),
        );
        break;
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        showDialog(
          context: context,
          builder: (context) => _CardPaymentDialog(
            paymentData: paymentData,
            isCredit: _selectedMethod == PaymentMethodType.creditCard,
          ),
        );
        break;
      case PaymentMethodType.wallet:
        // Wallet payment não precisa de detalhes adicionais
        break;
      case PaymentMethodType.cash:
        // Cash payment não aplicável para recarga de carteira
        break;
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
          isEnabled: true,
        ),
        _PaymentMethodTile(
          type: PaymentMethodType.creditCard,
          isSelected: selectedMethod == PaymentMethodType.creditCard,
          onTap: () => onChanged(PaymentMethodType.creditCard),
          icon: Icons.credit_card,
          title: 'Cartão de Crédito',
          subtitle: 'Pagamento parcelado disponível',
          cs: cs,
          isEnabled: true,
        ),
        _PaymentMethodTile(
          type: PaymentMethodType.debitCard,
          isSelected: selectedMethod == PaymentMethodType.debitCard,
          onTap: () => onChanged(PaymentMethodType.debitCard),
          icon: Icons.credit_card_outlined,
          title: 'Cartão de Débito',
          subtitle: 'Débito direto da conta',
          cs: cs,
          isEnabled: true,
        ),
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
    required this.isEnabled,
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
  Widget build(BuildContext context) => GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? WalletConstants.selectedBorderWidth : WalletConstants.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEnabled ? (isSelected ? cs.primary : cs.onSurfaceVariant) : cs.onSurfaceVariant.withOpacity(WalletConstants.disabledOpacity),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isEnabled ? (isSelected ? cs.onPrimaryContainer : cs.onSurface) : cs.onSurface.withOpacity(WalletConstants.disabledOpacity),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isEnabled ? (isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant) : cs.onSurfaceVariant.withOpacity(WalletConstants.disabledOpacity),
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

class _PixPaymentDialog extends StatelessWidget {
  const _PixPaymentDialog({required this.paymentData});
  final Map<String, dynamic> paymentData;

  Widget _buildQrCodeImage(String? qrCodeData) {
    if (qrCodeData == null || qrCodeData.isEmpty) {
      return Container(
        width: WalletConstants.qrCodeSize,
        height: WalletConstants.qrCodeSize,
        decoration: BoxDecoration(
          color: Colors.grey[WalletConstants.greyColorIndex],
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(
          child: Text('QR Code não disponível'),
        ),
      );
    }

    try {
      // Remove o prefixo data:image se presente
      var base64String = qrCodeData;
      if (qrCodeData.startsWith('data:image')) {
        base64String = qrCodeData.split(WalletConstants.qrCodeDataSeparator)[WalletConstants.qrCodeDataIndex];
      }
      
      final bytes = base64Decode(base64String);
      return Container(
        width: WalletConstants.qrCodeSize,
          height: WalletConstants.qrCodeSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: Colors.grey[WalletConstants.greyColorIndex]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: WalletConstants.qrCodeSize,
          height: WalletConstants.qrCodeSize,
        decoration: BoxDecoration(
          color: Colors.grey[WalletConstants.greyColorIndex],
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(
          child: Text('Erro ao carregar QR Code'),
        ),
      );
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado para a área de transferência'),
        duration: WalletConstants.qrCodeDisplayDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final qrCode = paymentData['qr_code'] as String?;
    final pixCopyPaste = paymentData['pix_copy_paste'] as String?;
    final amount = paymentData['amount']?.toString() ?? WalletConstants.defaultAmountHint;
    
    return AlertDialog(
      backgroundColor: cs.surface,
      title: Text('Pagamento PIX', style: AppTypography.titleMedium.copyWith(color: cs.onSurface)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Valor: R\$ $amount',
              style: AppTypography.titleMedium.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // QR Code
            _buildQrCodeImage(qrCode),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Escaneie o QR Code acima ou use o código PIX abaixo',
              style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // PIX Copia e Cola
            if (pixCopyPaste != null && pixCopyPaste.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: cs.outline.withOpacity(WalletConstants.borderOpacity)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código PIX (Copia e Cola):',
                      style: AppTypography.labelMedium.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      pixCopyPaste,
                      style: AppTypography.bodySmall.copyWith(
                        color: cs.onSurface,
                        fontFamily: 'monospace',
                      ),
                      maxLines: WalletConstants.maxDescriptionLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(context, pixCopyPaste),
                        icon: const Icon(Icons.copy, size: WalletConstants.smallIconSize),
                        label: const Text('Copiar Código'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'Código PIX não disponível',
                  style: AppTypography.bodySmall.copyWith(color: cs.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
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

class _CardPaymentDialog extends StatelessWidget {
  const _CardPaymentDialog({
    required this.paymentData,
    required this.isCredit,
  });
  
  final Map<String, dynamic> paymentData;
  final bool isCredit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardType = isCredit ? 'Crédito' : 'Débito';
    
    return AlertDialog(
      backgroundColor: cs.surface,
      title: Text('Pagamento com Cartão de $cardType', style: AppTypography.titleMedium.copyWith(color: cs.onSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCredit ? Icons.credit_card : Icons.credit_card_outlined, 
            size: WalletConstants.iconSize,
            color: cs.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Você será redirecionado para inserir os dados do seu cartão de $cardType',
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
              isCredit 
                ? 'Pagamento seguro com parcelamento disponível'
                : 'Débito direto e seguro da sua conta',
              style: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Implementar integração com gateway de pagamento
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Integração com cartão de $cardType em desenvolvimento'),
              ),
            );
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class _WithdrawBottomSheet extends StatefulWidget {
  const _WithdrawBottomSheet({
    required this.passengerId,
    required this.availableBalance,
  });

  final String passengerId;
  final Future<double> availableBalance;

  @override
  State<_WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<_WithdrawBottomSheet> {
  final _amountController = TextEditingController();
  final _pixKeyController = TextEditingController();
  bool _isLoading = false;
  double _currentBalance = WalletConstants.defaultBalance;

  @override
  void initState() {
    super.initState();
    widget.availableBalance.then((balance) {
      if (mounted) {
        setState(() => _currentBalance = balance);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pixKeyController.dispose();
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
              Text('Sacar dinheiro', style: AppTypography.titleLarge.copyWith(color: cs.onSurface)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${WalletConstants.balancePrefix}${WalletConstants.currencySymbol} ${_currentBalance.toStringAsFixed(WalletConstants.decimalPlaces)}',
                  style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              DecimalInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor a sacar',
              hintText: WalletConstants.defaultAmountHint,
              prefixText: r'R$ ',
              helperText: 'Use vírgula para separar os centavos',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _pixKeyController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Chave PIX',
              hintText: 'Digite sua chave PIX (CPF, e-mail, telefone ou chave aleatória)',
              prefixIcon: Icon(Icons.pix),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _isLoading ? null : _onWithdraw,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              minimumSize: const Size.fromHeight(WalletConstants.buttonMinHeight),
            ),
            child: _isLoading
                ? const SizedBox(width: WalletConstants.progressIndicatorSize, height: WalletConstants.progressIndicatorSize, child: CircularProgressIndicator(strokeWidth: WalletConstants.progressIndicatorStroke))
                : const Text('Solicitar saque'),
          ),
        ],
      ),
    );
  }

  Future<void> _onWithdraw() async {
    final amountText = _amountController.text.trim();
    final amount = MoneyFormatter.parseToDouble(amountText);
    final pixKey = _pixKeyController.text.trim();

    // Validação usando MoneyFormatter
    if (!MoneyFormatter.isValidAmount(amount, min: WalletConstants.minWithdrawalAmount, max: _currentBalance)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MoneyFormatter.getAmountErrorMessage(amount, min: WalletConstants.minWithdrawalAmount, max: _currentBalance))),
      );
      return;
    }

    if (amount! > _currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor solicitado maior que o saldo disponível')),
      );
      return;
    }

    // Validação robusta da chave PIX
    if (!PixValidator.isValidPixKey(pixKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PixValidator.getValidationErrorMessage(pixKey))),
      );
      return;
    }

    // Mostrar dialog de confirmação
    final confirmed = await _showWithdrawalConfirmationDialog(amount, pixKey);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final walletService = WalletService();
      await walletService.requestPassengerWithdrawal(
        passengerId: widget.passengerId,
        amount: amount,
        pixKey: pixKey,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saque de ${WalletConstants.currencySymbol} ${amount.toStringAsFixed(WalletConstants.decimalPlaces)} solicitado com sucesso!\nProcessamento em até ${WalletConstants.withdrawalProcessingTime.inHours} horas úteis.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        var backgroundColor = Theme.of(context).colorScheme.error;
        
        if (e is WalletException) {
          errorMessage = WalletErrorHandler.getUserFriendlyMessage(e);
          
          // Cores diferentes para diferentes tipos de erro
          switch (e.type) {
            case WalletErrorType.insufficientBalance:
              backgroundColor = Colors.orange;
              break;
            case WalletErrorType.invalidAmount:
            case WalletErrorType.invalidPixKey:
              backgroundColor = Colors.amber;
              break;
            default:
              backgroundColor = Theme.of(context).colorScheme.error;
          }
        } else {
          errorMessage = 'Erro inesperado ao processar saque. Tente novamente.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: WalletConstants.snackBarDuration,
            action: e is WalletException && WalletErrorHandler.canRetry(e)
                ? SnackBarAction(
                    label: 'Tentar novamente',
                    textColor: Colors.white,
                    onPressed: _onWithdraw,
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Mostra dialog de confirmação do saque com resumo da transação
  Future<bool> _showWithdrawalConfirmationDialog(double amount, String pixKey) async {
    final pixKeyType = PixValidator.getPixKeyType(pixKey);
    final formattedPixKey = PixValidator.formatPixKey(pixKey);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Saque'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirme os dados do seu saque:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: WalletConstants.verticalSpacing16),
            _buildConfirmationRow('Valor:', '${WalletConstants.currencySymbol} ${amount.toStringAsFixed(WalletConstants.decimalPlaces)}'),
            const SizedBox(height: WalletConstants.verticalSpacing8),
            _buildConfirmationRow('Tipo da chave:', pixKeyType.displayName),
            const SizedBox(height: WalletConstants.verticalSpacing8),
            _buildConfirmationRow('Chave PIX:', formattedPixKey),
            const SizedBox(height: WalletConstants.verticalSpacing16),
            Container(
              padding: const EdgeInsets.all(WalletConstants.containerPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(WalletConstants.borderRadius),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Informações importantes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: WalletConstants.smallSpacing),
                  Text(WalletConstants.processingTimeInfo),
                  Text('• Verifique se a chave PIX está correta'),
                  Text('• Esta operação não pode ser cancelada'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Confirmar Saque'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Widget helper para linhas de confirmação
  Widget _buildConfirmationRow(String label, String value) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: WalletConstants.shimmerSmallWidth,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
      ],
    );
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
          Container(height: WalletConstants.shimmerContainerHeight, width: WalletConstants.shimmerContainerWidth, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerMediumOpacity)),
          const SizedBox(height: AppSpacing.sm),
          Container(height: WalletConstants.shimmerLargeHeight, width: WalletConstants.shimmerLargeWidth, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerMediumOpacity)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: Container(height: WalletConstants.shimmerMediumHeight, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerLightOpacity))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Container(height: WalletConstants.shimmerMediumHeight, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerLightOpacity))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(height: WalletConstants.shimmerButtonHeight, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerLightOpacity)),
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
      children: List.generate(WalletConstants.shimmerListCount, (index) => Container(
        height: AppSpacing.listItemHeight,
        margin: const EdgeInsets.only(bottom: AppSpacing.itemSpacing),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(width: WalletConstants.shimmerIconSize, height: WalletConstants.shimmerIconSize, decoration: BoxDecoration(shape: BoxShape.circle, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerMediumOpacity))),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: WalletConstants.shimmerContainerHeight, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerMediumOpacity)),
                  const SizedBox(height: WalletConstants.verticalSpacing4),
                  Container(height: WalletConstants.shimmerSmallHeight, width: WalletConstants.shimmerMediumWidth, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerLightOpacity)),
                ],
              ),
            ),
            Container(height: WalletConstants.shimmerContainerHeight, width: WalletConstants.shimmerSmallWidth, color: cs.onSurfaceVariant.withOpacity(WalletConstants.shimmerMediumOpacity)),
          ],
        ),
      ),),
    );
  }
}