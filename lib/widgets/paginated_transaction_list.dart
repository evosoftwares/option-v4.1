/// Widget de lista paginada para transações com lazy loading
/// 
/// Implementa carregamento sob demanda (lazy loading) com cache inteligente
/// para otimizar a performance e reduzir o uso de dados.
/// 
/// Funcionalidades:
/// - Paginação automática ao rolar para o final
/// - Cache em memória com TTL
/// - Pull-to-refresh
/// - Estados de loading, erro e vazio
/// - Prevenção de múltiplas requisições simultâneas
library;

import 'package:flutter/material.dart';
import '../models/passenger_wallet_transaction.dart';
import '../services/transaction_cache_service.dart';
import '../services/wallet_service.dart';
import '../utils/wallet_constants.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Callback para carregar mais transações
typedef TransactionLoader = Future<List<PassengerWalletTransaction>> Function({
  required String passengerId,
  required int page,
  required int limit,
});

/// Widget builder para cada item da transação
typedef TransactionItemBuilder = Widget Function(
  BuildContext context,
  PassengerWalletTransaction transaction,
  int index,
);

/// Widget de lista paginada para transações
class PaginatedTransactionList extends StatefulWidget {
  const PaginatedTransactionList({
    super.key,
    required this.passengerId,
    required this.transactionLoader,
    required this.itemBuilder,
    this.emptyWidget,
    this.errorBuilder,
    this.loadingWidget,
    this.pageSize = WalletConstants.transactionPageSize,
    this.preloadThreshold = 3,
    this.enableCache = true,
    this.enablePullToRefresh = true,
  });
  
  /// ID do passageiro
  final String passengerId;
  
  /// Função para carregar transações
  final TransactionLoader transactionLoader;
  
  /// Builder para cada item da lista
  final TransactionItemBuilder itemBuilder;
  
  /// Widget exibido quando a lista está vazia
  final Widget? emptyWidget;
  
  /// Builder para widget de erro
  final Widget Function(BuildContext context, String error)? errorBuilder;
  
  /// Widget de loading personalizado
  final Widget? loadingWidget;
  
  /// Tamanho da página
  final int pageSize;
  
  /// Número de itens antes do final para iniciar pré-carregamento
  final int preloadThreshold;
  
  /// Habilita cache
  final bool enableCache;
  
  /// Habilita pull-to-refresh
  final bool enablePullToRefresh;
  
  @override
  State<PaginatedTransactionList> createState() => _PaginatedTransactionListState();
}

class _PaginatedTransactionListState extends State<PaginatedTransactionList> {
  final ScrollController _scrollController = ScrollController();
  final TransactionCacheService _cacheService = TransactionCacheService();
  
  List<PassengerWalletTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _error;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.enableCache) {
      _cacheService.initialize();
    }
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(PaginatedTransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recarrega se o passageiro mudou
    if (oldWidget.passengerId != widget.passengerId) {
      _reset();
      _loadInitialData();
    }
  }
  
  /// Listener do scroll para detectar quando carregar mais dados
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll - (widget.preloadThreshold * 100); // Aproximadamente 3 itens
    
    if (currentScroll >= threshold && !_isLoadingMore && _hasMoreData) {
      _loadMoreData();
    }
  }
  
  /// Carrega dados iniciais
  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final transactions = await _loadPage(0);
      
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _currentPage = 0;
          _hasMoreData = transactions.length >= widget.pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  /// Carrega mais dados (próxima página)
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final nextPage = _currentPage + 1;
      final newTransactions = await _loadPage(nextPage);
      
      if (mounted) {
        setState(() {
          _transactions.addAll(newTransactions);
          _currentPage = nextPage;
          _hasMoreData = newTransactions.length >= widget.pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        
        // Mostra erro sem interromper a lista existente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar mais transações: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Tentar novamente',
              onPressed: _loadMoreData,
            ),
          ),
        );
      }
    }
  }
  
  /// Carrega uma página específica
  Future<List<PassengerWalletTransaction>> _loadPage(int page) async {
    // Verifica cache primeiro
    if (widget.enableCache) {
      final cached = _cacheService.getCachedTransactions(
        passengerId: widget.passengerId,
        page: page,
        limit: widget.pageSize,
      );
      
      if (cached != null) {
        return cached;
      }
    }
    
    // Carrega do servidor
    final transactions = await widget.transactionLoader(
      passengerId: widget.passengerId,
      page: page,
      limit: widget.pageSize,
    );
    
    // Armazena no cache
    if (widget.enableCache) {
      _cacheService.cacheTransactions(
        passengerId: widget.passengerId,
        page: page,
        limit: widget.pageSize,
        transactions: transactions,
        totalCount: transactions.length,
      );
    }
    
    return transactions;
  }
  
  /// Redefine o estado da lista
  void _reset() {
    _transactions.clear();
    _currentPage = 0;
    _hasMoreData = true;
    _error = null;
    
    // Invalida cache para este usuário
    if (widget.enableCache) {
      _cacheService.invalidateUserCache(widget.passengerId);
    }
  }
  
  /// Refresh manual da lista
  Future<void> _onRefresh() async {
    _reset();
    await _loadInitialData();
  }
  
  @override
  Widget build(BuildContext context) {
    // Estado de loading inicial
    if (_isLoading && _transactions.isEmpty) {
      return widget.loadingWidget ?? _buildDefaultLoading();
    }
    
    // Estado de erro
    if (_error != null && _transactions.isEmpty) {
      return widget.errorBuilder?.call(context, _error!) ?? _buildDefaultError();
    }
    
    // Estado vazio
    if (_transactions.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmpty();
    }
    
    // Lista com dados
    Widget listView = ListView.builder(
      controller: _scrollController,
      itemCount: _transactions.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // Item de loading no final
        if (index >= _transactions.length) {
          return _buildLoadingMoreIndicator();
        }
        
        // Item normal
        return widget.itemBuilder(context, _transactions[index], index);
      },
    );
    
    // Adiciona pull-to-refresh se habilitado
    if (widget.enablePullToRefresh) {
      listView = RefreshIndicator(
        onRefresh: _onRefresh,
        child: listView,
      );
    }
    
    return listView;
  }
  
  /// Widget de loading padrão
  Widget _buildDefaultLoading() => const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Carregando transações...'),
        ],
      ),
    );
  
  /// Widget de erro padrão
  Widget _buildDefaultError() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Erro ao carregar transações',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error ?? 'Erro desconhecido',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  
  /// Widget vazio padrão
  Widget _buildDefaultEmpty() => const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Nenhuma transação',
            style: AppTypography.titleMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Suas transações aparecerão aqui assim que você começar a usar a carteira.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  
  /// Indicador de carregamento de mais itens
  Widget _buildLoadingMoreIndicator() => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const SizedBox.shrink(),
    );
}