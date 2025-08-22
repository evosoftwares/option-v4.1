import 'package:flutter/material.dart';
import '../../models/payment_method.dart';
import '../../services/payment_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final methods = await PaymentService.getPaymentMethods();
      
      setState(() {
        _paymentMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addPaymentMethod() async {
    final result = await showDialog<PaymentMethod?>(
      context: context,
      builder: (context) => const _AddPaymentMethodDialog(),
    );

    if (result != null) {
      try {
        await PaymentService.addPaymentMethod(result);
        _loadPaymentMethods();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Método de pagamento adicionado com sucesso'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar método: $e'),
          ),
        );
      }
    }
  }

  Future<void> _removePaymentMethod(PaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover método'),
        content: Text('Deseja remover ${method.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PaymentService.removePaymentMethod(method.id);
        _loadPaymentMethods();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Método removido com sucesso'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover método: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Métodos de Pagamento'),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPaymentMethod,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: cs.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Erro ao carregar métodos',
                        style: AppTypography.titleMedium.copyWith(color: cs.error),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _error!,
                        style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: _loadPaymentMethods,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _paymentMethods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card_off,
                            size: 64,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Nenhum método cadastrado',
                            style: AppTypography.titleMedium.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Adicione um método PIX para facilitar seus pagamentos',
                            style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: _addPaymentMethod,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar método'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: AppSpacing.paddingLg,
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        return _PaymentMethodCard(
                          method: method,
                          onRemove: () => _removePaymentMethod(method),
                        );
                      },
                    ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.onRemove,
  });

  final PaymentMethod method;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    IconData getIcon() {
      switch (method.type) {
        case PaymentMethodType.wallet:
          return Icons.account_balance_wallet;
        case PaymentMethodType.pix:
          return Icons.pix;
      }
    }

    String getSubtitle() {
      switch (method.type) {
        case PaymentMethodType.wallet:
          return 'Carteira Option';
        case PaymentMethodType.pix:
          return method.pixData?.displayName ?? 'PIX';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            getIcon(),
            color: cs.onPrimaryContainer,
          ),
        ),
        title: Text(
          method.displayName,
          style: AppTypography.bodyLarge.copyWith(color: cs.onSurface),
        ),
        subtitle: Text(
          getSubtitle(),
          style: AppTypography.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: method.isDefault
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Padrão',
                  style: AppTypography.labelSmall.copyWith(color: cs.onPrimary),
                ),
              )
            : IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error),
                onPressed: onRemove,
              ),
      ),
    );
  }
}

class _AddPaymentMethodDialog extends StatefulWidget {
  const _AddPaymentMethodDialog();

  @override
  State<_AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<_AddPaymentMethodDialog> {
  PaymentMethodType _selectedType = PaymentMethodType.pix;
  PixKeyType _selectedPixKeyType = PixKeyType.cpf;
  final _pixKeyController = TextEditingController();

  @override
  void dispose() {
    _pixKeyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedType == PaymentMethodType.wallet) {
      Navigator.of(context).pop(PaymentMethod(
        id: '',
        userId: '',
        type: _selectedType,
        isDefault: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      return;
    }

    if (_selectedType == PaymentMethodType.pix) {
      final pixKey = _pixKeyController.text.trim();
      
      if (pixKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha a chave PIX')),
        );
        return;
      }

      Navigator.of(context).pop(PaymentMethod(
        id: '',
        userId: '',
        type: _selectedType,
        isDefault: false,
        isActive: true,
        pixData: PixData(
          keyType: _selectedPixKeyType,
          keyValue: pixKey,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Método'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<PaymentMethodType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: PaymentMethodType.pix, child: Text('PIX')),
                DropdownMenuItem(value: PaymentMethodType.wallet, child: Text('Carteira')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            if (_selectedType == PaymentMethodType.pix) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<PixKeyType>(
                value: _selectedPixKeyType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de chave PIX',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PixKeyType.cpf, child: Text('CPF')),
                  DropdownMenuItem(value: PixKeyType.email, child: Text('E-mail')),
                  DropdownMenuItem(value: PixKeyType.phone, child: Text('Telefone')),
                  DropdownMenuItem(value: PixKeyType.randomKey, child: Text('Chave Aleatória')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPixKeyType = value!;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _pixKeyController,
                decoration: InputDecoration(
                  labelText: 'Chave ${_selectedPixKeyType.displayName}',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: _selectedPixKeyType == PixKeyType.email
                    ? TextInputType.emailAddress
                    : _selectedPixKeyType == PixKeyType.phone
                        ? TextInputType.phone
                        : TextInputType.text,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}