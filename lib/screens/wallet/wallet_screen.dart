import 'package:flutter/material.dart';
import 'package:uber_clone/theme/app_typography.dart';
import 'package:uber_clone/theme/app_spacing.dart';
import 'package:uber_clone/services/user_service.dart';
import 'package:uber_clone/services/wallet_service.dart';
import 'package:uber_clone/models/user.dart' as app_user;

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
      appBar: AppBar(
        title: const Text('Carteira'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
      ),
      body: FutureBuilder<app_user.User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) {
            return _ErrorState(message: 'Você precisa estar logado para ver a carteira.');
          }

          final isDriver = user.userType.toLowerCase() == 'driver';
          if (!isDriver) {
            return _PassengerWalletPlaceholder(user: user);
          }

          return _DriverWalletContent(user: user, walletService: _walletService);
        },
      ),
    );
  }
}

class _PassengerWalletPlaceholder extends StatelessWidget {
  final app_user.User user;
  const _PassengerWalletPlaceholder({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        _InfoCard(
          title: 'Carteira indisponível',
          message: 'Por enquanto, a carteira está disponível apenas para motoristas. Em breve você poderá gerenciar seus pagamentos aqui.',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gerenciamento de pagamentos em breve', style: AppTypography.bodyMedium.copyWith(color: cs.onInverseSurface))),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
          child: const Text('Gerenciar pagamentos'),
        ),
      ],
    );
  }
}

class _DriverWalletContent extends StatefulWidget {
  final app_user.User user;
  final WalletService walletService;
  const _DriverWalletContent({required this.user, required this.walletService});

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
          return _ErrorState(message: 'Não encontramos seu perfil de motorista.');
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
                  return _InfoCard(
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
      builder: (context) {
        return AlertDialog(
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
        );
      },
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
  final String available;
  final String pending;
  final String total;
  final VoidCallback onWithdraw;
  const _BalanceCard({required this.available, required this.pending, required this.total, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant, width: AppSpacing.borderThin),
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
          )
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color foreground;
  const _StatChip({required this.label, required this.value, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionTile({required this.tx});

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
        border: Border.all(color: cs.outlineVariant, width: AppSpacing.borderThin),
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
            (isCredit ? '+ R\$ ' : '- R\$ ') + amount,
            style: AppTypography.bodyMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  const _InfoCard({required this.title, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: cs.outlineVariant, width: AppSpacing.borderThin),
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
          )
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

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