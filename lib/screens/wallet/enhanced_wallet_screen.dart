/// Tela completa da carteira com feedback visual aprimorado
/// 
/// Esta tela implementa a interface completa da carteira com
/// todos os feedbacks visuais e interações necessárias.
library;

import 'package:flutter/material.dart';

import '../exceptions/wallet_exceptions.dart';
import '../models/passenger_wallet.dart';
import '../models/passenger_wallet_transaction.dart';
import '../models/user.dart' as app_user;
import '../services/passenger_payment_service.dart';
import '../services/user_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/wallet_constants.dart';
import '../widgets/wallet_dashboard.dart';
import '../widgets/wallet_feedback_widgets.dart';
import 'enhanced_transaction_list.dart';

/// Tela principal da carteira com feedback visual aprimorado
class EnhancedWalletScreen extends StatefulWidget {
  const EnhancedWalletScreen({super.key});

  @override
  State<EnhancedWalletScreen> createState() => _EnhancedWalletScreenState();
}

class _EnhancedWalletScreenState extends State<EnhancedWalletScreen> {
  late final WalletService _walletService;
  late final PassengerPaymentService _paymentService;
  
  app_user.User? _currentUser;
  PassengerWallet? _wallet;
  List<PassengerWalletTransaction> _transactions = [];
  
  bool _isLoading = true;
  bool _isProcessing = false;
  WalletOperationFeedback? _feedbackWidget;

  @override
  void initState() {
    super.initState();
    _walletService = WalletService();
    _paymentService = PassengerPaymentService(walletService: _walletService);
    _loadWalletData();
  }

  /// Carrega os dados da carteira
  Future<void> _loadWalletData() async {
    try {
      setState(() => _isLoading = true);
      
      final user = await UserService.getCurrentUser();
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }
      
      _currentUser = user;
      
      // Verifica se é passageiro
      if (user.userType.toLowerCase() != 'passenger') {
        throw Exception('Apenas passageiros podem acessar esta carteira');
      }
      
      // Obtém o ID do passageiro
      final passengerId = await _walletService.getPassengerIdForUser(user.id);
      if (passengerId == null) {
        throw Exception('Não foi possível obter o ID do passageiro');
      }
      
      // Obtém ou cria a carteira
      var wallet = await _walletService.getPassengerWallet(passengerId);
      if (wallet == null) {
        wallet = await _walletService.createPassengerWallet(passengerId, user.id);
      }
      
      _wallet = wallet;
      
      // Obtém transações recentes
      final transactions = await _walletService.getPassengerWalletTransactions(
        passengerId,
        limit: 10,
      );
      
      _transactions = transactions;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _feedbackWidget = WalletOperationFeedback(
          type: WalletOperationType.error,
          title: 'Erro ao carregar carteira',
          message: 'Não foi possível carregar os dados da sua carteira. Tente novamente mais tarde.',
          onRetry: _loadWalletData,
          onClose: () => setState(() => _feedbackWidget = null),
        );
      });
    }
  }

  /// Adiciona crédito à carteira
  Future<void> _addCredit() async {
    if (_currentUser == null || _wallet == null) return;
    
    // TODO: Implementar interface de adição de crédito
    // Esta função seria chamada quando o usuário clica em "Adicionar Crédito"
    
    // Exemplo de como mostrar feedback:
    setState(() {
      _feedbackWidget = WalletOperationFeedback(
        type: WalletOperationType.info,
        title: 'Adicionar crédito',
        message: 'Funcionalidade de adição de crédito será implementada em breve.',
        onClose: () => setState(() => _feedbackWidget = null),
      );
    });
    
    // Remove o feedback após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackWidget = null);
      }
    });
  }

  /// Solicita um saque
  Future<void> _requestWithdrawal() async {
    if (_currentUser == null || _wallet == null) return;
    
    // TODO: Implementar interface de saque
    // Esta função seria chamada quando o usuário clica em "Sacar"
    
    // Exemplo de como mostrar feedback:
    setState(() {
      _feedbackWidget = WalletOperationFeedback(
        type: WalletOperationType.info,
        title: 'Saque',
        message: 'Funcionalidade de saque será implementada em breve.',
        onClose: () => setState(() => _feedbackWidget = null),
      );
    });
    
    // Remove o feedback após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackWidget = null);
      }
    });
  }

  /// Manipula o clique em uma transação
  void _onTransactionTap(PassengerWalletTransaction transaction) {
    // TODO: Implementar detalhes da transação
    setState(() {
      _feedbackWidget = WalletOperationFeedback(
        type: WalletOperationType.info,
        title: 'Detalhes da transação',
        message: 'Transação: ${transaction.description}\n'
                 'Valor: ${transaction.formattedAmount}\n'
                 'Data: ${transaction.createdAt}',
        onClose: () => setState(() => _feedbackWidget = null),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Minha Carteira',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadWalletData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Conteúdo principal
          WalletDashboard(
            wallet: _wallet,
            recentTransactions: _transactions,
            onAddCredit: _addCredit,
            onWithdraw: _requestWithdrawal,
            onTransactionTap: _onTransactionTap,
            isLoading: _isLoading,
          ),
          
          // Feedback overlay
          if (_feedbackWidget != null)
            Positioned(
              top: AppSpacing.md,
              left: 0,
              right: 0,
              child: _feedbackWidget!,
            ),
          
          // Indicador de progresso
          if (_isProcessing)
            const Positioned(
              top: AppSpacing.md,
              left: 0,
              right: 0,
              child: WalletProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

/// Diálogo de adição de crédito
class AddCreditDialog extends StatefulWidget {
  const AddCreditDialog({
    super.key,
    required this.user,
    required this.passengerId,
    required this.walletService,
    required this.paymentService,
  });

  final app_user.User user;
  final String passengerId;
  final WalletService walletService;
  final PassengerPaymentService paymentService;

  @override
  State<AddCreditDialog> createState() => _AddCreditDialogState();
}

class _AddCreditDialogState extends State<AddCreditDialog> {
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _onAddCredit() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText.replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      _showFeedback(
        WalletOperationType.error,
        'Valor inválido',
        'Por favor, insira um valor válido maior que zero.',
      );
      return;
    }

    if (amount < WalletConstants.minCreditAmount) {
      _showFeedback(
        WalletOperationType.error,
        'Valor mínimo',
        'O valor mínimo para adição de crédito é ${WalletConstants.currencySymbol}${WalletConstants.minCreditAmount.toStringAsFixed(2)}.',
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // TODO: Implementar lógica real de pagamento
      // Esta é uma simulação da operação
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Simula sucesso ou erro aleatório
      if (amount > 1000) {
        throw WalletException(
          type: WalletErrorType.networkError,
          details: 'Erro de conexão com o servidor de pagamento',
        );
      }
      
      // Sucesso - mostra confirmação
      if (mounted) {
        Navigator.pop(context, true);
        
        // Mostra notificação de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crédito de ${WalletConstants.currencySymbol}${amount.toStringAsFixed(2)} adicionado com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message;
        if (e is WalletException) {
          message = WalletErrorHandler.getUserFriendlyMessage(e);
        } else {
          message = 'Erro ao processar pagamento. Tente novamente.';
        }
        
        _showFeedback(
          WalletOperationType.error,
          'Erro no pagamento',
          message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showFeedback(WalletOperationType type, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _getSnackbarColor(type),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getSnackbarColor(WalletOperationType type) {
    switch (type) {
      case WalletOperationType.success:
        return Theme.of(context).colorScheme.primary;
      case WalletOperationType.error:
        return Theme.of(context).colorScheme.error;
      case WalletOperationType.warning:
        return Theme.of(context).colorScheme.secondary;
      case WalletOperationType.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Text(
        'Adicionar Crédito',
        style: AppTypography.titleLarge.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isProcessing)
            const WalletProgressIndicator(message: 'Processando pagamento...')
          else ...[
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: 'R\$ ',
                hintText: '0,00',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formas de pagamento disponíveis:',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Row(
                    children: [
                      Icon(Icons.pix, color: Colors.blue),
                      SizedBox(width: AppSpacing.sm),
                      Text('PIX'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.blue),
                      SizedBox(width: AppSpacing.sm),
                      Text('Cartão de Crédito'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.blue),
                      SizedBox(width: AppSpacing.sm),
                      Text('Transferência Bancária'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _onAddCredit,
          child: _isProcessing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adicionar'),
        ),
      ],
    );
  }
}