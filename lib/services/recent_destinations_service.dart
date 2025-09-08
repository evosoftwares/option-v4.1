import '../models/favorite_location.dart';

/// Serviço de destinos recentes DESABILITADO para evitar cache
class RecentDestinationsService {
  
  RecentDestinationsService._internal();
  static const String _key = 'recent_destinations';
  static const int _maxRecentItems = 10;
  
  static RecentDestinationsService? _instance;
  
  static RecentDestinationsService get instance {
    _instance ??= RecentDestinationsService._internal();
    return _instance!;
  }

  /// Cache desabilitado - sempre retorna lista vazia
  Future<List<FavoriteLocation>> getRecentDestinations() async {
    return [];
  }

  /// Cache desabilitado - método no-op
  Future<void> addRecentDestination(FavoriteLocation destination) async {
    // Cache desabilitado - não salva destinos recentes
  }

  /// Cache desabilitado - método no-op
  Future<void> removeRecentDestination(String id) async {
    // Cache desabilitado - não remove destinos recentes
  }

  /// Cache desabilitado - método no-op
  Future<void> clearRecentDestinations() async {
    // Cache desabilitado - não limpa destinos recentes
  }
}