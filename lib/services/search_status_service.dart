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

  const SearchState({
    required this.status,
    this.message,
    this.errorDetails,
    this.driversFound,
  });
  final SearchStatus status;
  final String? message;
  final String? errorDetails;
  final int? driversFound;

  SearchState copyWith({
    SearchStatus? status,
    String? message,
    String? errorDetails,
    int? driversFound,
  }) => SearchState(
      status: status ?? this.status,
      message: message ?? this.message,
      errorDetails: errorDetails ?? this.errorDetails,
      driversFound: driversFound ?? this.driversFound,
    );

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
  int get hashCode => status.hashCode ^
        message.hashCode ^
        errorDetails.hashCode ^
        driversFound.hashCode;
}

/// Serviço para gerenciar o estado da busca de motoristas
class SearchStatusService {
  factory SearchStatusService() => _instance;
  SearchStatusService._internal();
  static final SearchStatusService _instance = SearchStatusService._internal();

  final StreamController<SearchState> _stateController =
      StreamController<SearchState>.broadcast();

  SearchState _currentState = const SearchState(status: SearchStatus.idle);

  /// Stream para ouvir mudanças no estado da busca
  Stream<SearchState> get stateStream => _stateController.stream;

  /// Estado atual da busca
  SearchState get currentState => _currentState;

  /// Atualiza o estado da busca
  void updateState(SearchState newState) {
    print('🔄 [SEARCH_STATUS] Estado atualizado: ${_currentState.status} -> ${newState.status}');
    print('📝 [SEARCH_STATUS] Mensagem: ${newState.message}');
    if (newState.errorDetails != null) {
      print('🚨 [SEARCH_STATUS] Detalhes do erro: ${newState.errorDetails}');
    }
    if (newState.driversFound != null) {
      print('📊 [SEARCH_STATUS] Motoristas encontrados: ${newState.driversFound}');
    }
    
    _currentState = newState;
    _stateController.add(newState);
    print('📡 [SEARCH_STATUS] Estado transmitido para listeners');
  }

  /// Inicia a busca por motoristas
  void startSearch({String? message}) {
    print('🔍 [SEARCH_STATUS] Iniciando busca por motoristas');
    updateState(SearchState(
      status: SearchStatus.searching,
      message: message ?? 'Buscando motoristas disponíveis...',
    ),);
  }

  /// Marca a busca como bem-sucedida
  void markSuccess({required int driversFound, String? message}) {
    print('✅ [SEARCH_STATUS] Busca bem-sucedida - $driversFound motoristas encontrados');
    updateState(SearchState(
      status: SearchStatus.success,
      driversFound: driversFound,
      message: message ?? _getSuccessMessage(driversFound),
    ),);
  }

  /// Marca que nenhum motorista foi encontrado
  void markNoDriversFound({String? message}) {
    print('⚠️ [SEARCH_STATUS] Nenhum motorista encontrado');
    updateState(SearchState(
      status: SearchStatus.noDriversFound,
      message: message ?? 'Nenhum motorista disponível no momento',
    ),);
  }

  /// Marca erro na busca
  void markError({required String message, String? errorDetails}) {
    print('❌ [SEARCH_STATUS] Erro na busca: $message');
    if (errorDetails != null) {
      print('📍 [SEARCH_STATUS] Detalhes do erro: $errorDetails');
    }
    updateState(SearchState(
      status: SearchStatus.error,
      message: message,
      errorDetails: errorDetails,
    ),);
  }

  /// Reseta o estado para idle
  void reset() {
    print('🔄 [SEARCH_STATUS] Resetando estado para idle');
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