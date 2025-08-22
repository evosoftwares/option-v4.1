import 'dart:async';

/// Estados possíveis durante a busca de motoristas
enum SearchStatus {
  idle,
  searching,
  success,
  error,
  noDriversFound,
}

/// Modelo para representar o estado atual da busca
class SearchState {
  final SearchStatus status;
  final String? message;
  final String? errorDetails;
  final int? driversFound;

  const SearchState({
    required this.status,
    this.message,
    this.errorDetails,
    this.driversFound,
  });

  SearchState copyWith({
    SearchStatus? status,
    String? message,
    String? errorDetails,
    int? driversFound,
  }) {
    return SearchState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorDetails: errorDetails ?? this.errorDetails,
      driversFound: driversFound ?? this.driversFound,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchState &&
        other.status == status &&
        other.message == message &&
        other.errorDetails == errorDetails &&
        other.driversFound == driversFound;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        message.hashCode ^
        errorDetails.hashCode ^
        driversFound.hashCode;
  }
}

/// Serviço para gerenciar o estado da busca de motoristas
class SearchStatusService {
  static final SearchStatusService _instance = SearchStatusService._internal();
  factory SearchStatusService() => _instance;
  SearchStatusService._internal();

  final StreamController<SearchState> _stateController =
      StreamController<SearchState>.broadcast();

  SearchState _currentState = const SearchState(status: SearchStatus.idle);

  /// Stream para ouvir mudanças no estado da busca
  Stream<SearchState> get stateStream => _stateController.stream;

  /// Estado atual da busca
  SearchState get currentState => _currentState;

  /// Atualiza o estado da busca
  void updateState(SearchState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Inicia a busca por motoristas
  void startSearch({String? message}) {
    updateState(SearchState(
      status: SearchStatus.searching,
      message: message ?? 'Buscando motoristas disponíveis...',
    ));
  }

  /// Marca a busca como bem-sucedida
  void markSuccess({required int driversFound, String? message}) {
    updateState(SearchState(
      status: SearchStatus.success,
      driversFound: driversFound,
      message: message ?? _getSuccessMessage(driversFound),
    ));
  }

  /// Marca que nenhum motorista foi encontrado
  void markNoDriversFound({String? message}) {
    updateState(SearchState(
      status: SearchStatus.noDriversFound,
      message: message ?? 'Nenhum motorista disponível no momento',
    ));
  }

  /// Marca erro na busca
  void markError({required String message, String? errorDetails}) {
    updateState(SearchState(
      status: SearchStatus.error,
      message: message,
      errorDetails: errorDetails,
    ));
  }

  /// Reseta o estado para idle
  void reset() {
    updateState(const SearchState(status: SearchStatus.idle));
  }

  /// Gera mensagem de sucesso baseada no número de motoristas encontrados
  String _getSuccessMessage(int driversFound) {
    if (driversFound == 1) {
      return '1 motorista encontrado';
    } else {
      return '$driversFound motoristas encontrados';
    }
  }

  /// Libera recursos
  void dispose() {
    _stateController.close();
  }
}