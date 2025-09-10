import 'dart:async';
import 'package:flutter/material.dart';

class SafeListView<T> extends StatefulWidget {
  const SafeListView({
    super.key,
    required this.future,
    required this.itemBuilder,
    this.onRefresh,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.timeout = const Duration(seconds: 30),
    this.padding,
    this.separatorBuilder,
  });

  final Future<List<T>> future;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onRefresh;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorWidget;
  final Duration timeout;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  @override
  State<SafeListView<T>> createState() => _SafeListViewState<T>();
}

class _SafeListViewState<T> extends State<SafeListView<T>> {
  late Future<List<T>> _future;
  Timer? _timeoutTimer;
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    _future = _getFutureWithTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<List<T>> _getFutureWithTimeout() async {
    _hasTimedOut = false;
    _timeoutTimer?.cancel();
    
    // Start timeout timer
    _timeoutTimer = Timer(widget.timeout, () {
      if (mounted) {
        setState(() {
          _hasTimedOut = true;
        });
      }
    });

    try {
      final result = await widget.future;
      _timeoutTimer?.cancel();
      return result;
    } catch (e) {
      _timeoutTimer?.cancel();
      rethrow;
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
    if (mounted) {
      setState(() {
        _future = _getFutureWithTimeout();
      });
    }
  }

  Widget _buildDefaultEmpty() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum item encontrado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Puxe para baixo para atualizar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

  Widget _buildDefaultError(String error) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleRefresh,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );

  Widget _buildDefaultLoading() => const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando...'),
        ],
      ),
    );

  @override
  Widget build(BuildContext context) {
    if (_hasTimedOut) {
      return widget.errorWidget?.call('Timeout: A operação demorou mais que o esperado') ??
          _buildDefaultError('Timeout: A operação demorou mais que o esperado');
    }

    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ?? _buildDefaultLoading();
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          return widget.errorWidget?.call(error) ?? _buildDefaultError(error);
        }

        final items = snapshot.data ?? [];
        
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: widget.padding,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: widget.emptyWidget ?? _buildDefaultEmpty(),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: widget.separatorBuilder != null
              ? ListView.separated(
                  padding: widget.padding,
                  itemCount: items.length,
                  separatorBuilder: widget.separatorBuilder!,
                  itemBuilder: (context, index) => widget.itemBuilder(context, items[index], index),
                )
              : ListView.builder(
                  padding: widget.padding,
                  itemCount: items.length,
                  itemBuilder: (context, index) => widget.itemBuilder(context, items[index], index),
                ),
        );
      },
    );
  }
}