import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../models/payment_method.dart';
import '../../services/payment_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/logo_branding.dart';
import '../../widgets/feedback/index.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _addPaymentMethod() async {
    final result = await showDialog<PaymentMethod?>(
      context: context,
      builder: (context) => const _AddPaymentMethodDialog(),
    );

    if (result != null) {
      try {
        await PaymentService.addPaymentMethod(result);
        setState(() {}); // Refresh the FutureBuilder
        
        if (!mounted) return;
        SnackBarUtils.showSuccess(context, 'Método de pagamento adicionado com sucesso');
      } catch (e) {
        if (!mounted) return;
        SnackBarUtils.showError(context, 'Erro ao adicionar método: $e');
      }
    }
  }

  Future<void> _removePaymentMethod(PaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar remoção'),
        content: Text('Tem certeza que deseja remover o método ${method.displayName}?'),
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

    if (confirm ?? false) {
      try {
        await PaymentService.removePaymentMethod(method.id);
        setState(() {}); // Refresh the FutureBuilder
        
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
      appBar: StandardAppBar(
        title: 'Métodos de Pagamento',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPaymentMethod,
          ),
        ],
      ),
      body: FutureBuilder<List<PaymentMethod>>(
        future: PaymentService.getPaymentMethods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
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
                    'Erro ao carregar métodos de pagamento',
                    style: AppTypography.titleMedium.copyWith(color: cs.error),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    snapshot.error.toString(),
                    style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    onPressed: () => setState(() {}), // Rebuild to retry
                    text: 'Tentar novamente',
                    type: AppButtonType.primary,
                  ),
                ],
              ),
            );
          }

          final paymentMethods = snapshot.data ?? [];
          
          if (paymentMethods.isEmpty) {
            return Center(
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
                    'Adicione um método PIX ou configure sua carteira para facilitar seus pagamentos',
                    style: AppTypography.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    onPressed: _addPaymentMethod,
                    text: 'Adicionar método',
                    type: AppButtonType.primary,
                    icon: Icons.add,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: AppSpacing.paddingLg,
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentMethods[index];
              return _PaymentMethodCard(
                method: method,
                onRemove: () => _removePaymentMethod(method),
              );
            },
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
        case PaymentMethodType.creditCard:
          return Icons.credit_card;
        case PaymentMethodType.debitCard:
          return Icons.payment;
        case PaymentMethodType.cash:
          return Icons.money;
      }
    }

    String getSubtitle() {
      switch (method.type) {
        case PaymentMethodType.wallet:
          return r'Saldo: R$ 0,00'; // TODO: Implementar saldo real
        case PaymentMethodType.pix:
          return method.pixData?.displayName ?? 'Chave PIX não configurada';
        case PaymentMethodType.creditCard:
          return 'Cartão de Crédito';
        case PaymentMethodType.debitCard:
          return 'Cartão de Débito';
        case PaymentMethodType.cash:
          return 'Dinheiro';
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
  final _formKey = GlobalKey<FormState>();
  
  // Formatadores de máscara
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp('[0-9]')},
  );
  
  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp('[0-9]')},
  );

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
      ),);
      return;
    }

    if (_selectedType == PaymentMethodType.pix) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final pixKey = _pixKeyController.text.trim();
      
      // Para CPF e telefone, salva apenas os números
      final keyValue = _selectedPixKeyType == PixKeyType.cpf || 
                      _selectedPixKeyType == PixKeyType.phone
          ? pixKey.replaceAll(RegExp('[^0-9]'), '')
          : pixKey;

      Navigator.of(context).pop(PaymentMethod(
        id: '',
        userId: '',
        type: _selectedType,
        isDefault: false,
        isActive: true,
        pixData: PixData(
          keyType: _selectedPixKeyType,
          keyValue: keyValue,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),);
      return;
    }

    // Para cartões de crédito/débito e dinheiro, apenas criar o método básico
    if (_selectedType == PaymentMethodType.creditCard || 
        _selectedType == PaymentMethodType.debitCard ||
        _selectedType == PaymentMethodType.cash) {
      Navigator.of(context).pop(PaymentMethod(
        id: '',
        userId: '',
        type: _selectedType,
        isDefault: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),);
    }
  }

  String _getPixKeyHint() {
    switch (_selectedPixKeyType) {
      case PixKeyType.cpf:
        return '000.000.000-00';
      case PixKeyType.email:
        return 'exemplo@email.com';
      case PixKeyType.phone:
        return '(11) 99999-9999';
      case PixKeyType.randomKey:
        return 'Ex: 123e4567-e12b-12d1-a456-426655440000';
    }
  }

  IconData _getPixKeyIcon() {
    switch (_selectedPixKeyType) {
      case PixKeyType.cpf:
        return Icons.badge; // Documento de identificação
      case PixKeyType.email:
        return Icons.email;
      case PixKeyType.phone:
        return Icons.phone;
      case PixKeyType.randomKey:
        return Icons.vpn_key; // Chave mais específica
    }
  }

  TextInputType _getKeyboardType() {
    switch (_selectedPixKeyType) {
      case PixKeyType.cpf:
      case PixKeyType.phone:
        return TextInputType.number;
      case PixKeyType.email:
        return TextInputType.emailAddress;
      case PixKeyType.randomKey:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (_selectedPixKeyType) {
      case PixKeyType.cpf:
        return [_cpfMask];
      case PixKeyType.phone:
        return [_phoneMask];
      case PixKeyType.email:
        return [FilteringTextInputFormatter.deny(RegExp(' '))];
      case PixKeyType.randomKey:
        return [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]'))];
    }
  }

  bool _isValidPixKey(String key, PixKeyType type) {
    switch (type) {
      case PixKeyType.cpf:
        // Remove caracteres especiais e verifica se tem 11 dígitos
        final numbers = key.replaceAll(RegExp('[^0-9]'), '');
        return numbers.length == 11 && _isValidCPF(numbers);
      case PixKeyType.email:
        return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(key);
      case PixKeyType.phone:
        // Remove caracteres especiais e verifica se tem 11 dígitos (celular brasileiro)
        final numbers = key.replaceAll(RegExp('[^0-9]'), '');
        return numbers.length == 11 && 
               numbers.length >= 3 && 
               ['9'].contains(numbers[2]); // 3º dígito deve ser 9 para celulares
      case PixKeyType.randomKey:
        // Chave aleatória deve ter pelo menos 32 caracteres
        return key.length >= 32;
    }
  }

  bool _isValidCPF(String cpf) {
    if (cpf.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    
    // Validação dos dígitos verificadores
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    var digit1 = 11 - (sum % 11);
    if (digit1 >= 10) digit1 = 0;
    
    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    var digit2 = 11 - (sum % 11);
    if (digit2 >= 10) digit2 = 0;
    
    return int.parse(cpf[9]) == digit1 && int.parse(cpf[10]) == digit2;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
      title: const Text('Adicionar Método de Pagamento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PaymentMethodType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PaymentMethodType.pix, child: Text('PIX')),
                  DropdownMenuItem(value: PaymentMethodType.wallet, child: Text('Carteira')),
                  DropdownMenuItem(value: PaymentMethodType.creditCard, child: Text('Cartão de Crédito')),
                  DropdownMenuItem(value: PaymentMethodType.debitCard, child: Text('Cartão de Débito')),
                  DropdownMenuItem(value: PaymentMethodType.cash, child: Text('Dinheiro')),
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
                initialValue: _selectedPixKeyType,
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
                  hintText: _getPixKeyHint(),
                  prefixIcon: Icon(_getPixKeyIcon()),
                ),
                keyboardType: _getKeyboardType(),
                inputFormatters: _getInputFormatters(),
                textCapitalization: _selectedPixKeyType == PixKeyType.email 
                    ? TextCapitalization.none 
                    : TextCapitalization.characters,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Campo obrigatório';
                  }
                  if (!_isValidPixKey(value!.trim(), _selectedPixKeyType)) {
                    return '${_selectedPixKeyType.displayName} inválido';
                  }
                  return null;
                },
              ),
            ], // Fecha o array "if"
          ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(
          onPressed: _save,
          text: 'Adicionar',
          type: AppButtonType.primary,
        ),
      ],
    );
}