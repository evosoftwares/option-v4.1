import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_location.dart';
import '../services/favorite_locations_service.dart';

class SavedPlacesController extends ChangeNotifier {
  List<SavedPlace> _savedPlaces = [];
  bool _isLoading = false;
  String? _error;
  
  List<SavedPlace> get savedPlaces => _savedPlaces;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPlaces => _savedPlaces.isNotEmpty;
  
  /// Obtém o ID do usuário atual
  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  
  /// Carrega todos os locais salvos do usuário
  Future<void> loadSavedPlaces() async {
    final userId = _currentUserId;
    if (userId == null) {
      _setError('Usuário não autenticado');
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      _savedPlaces = await FavoriteLocationsService.getFavoriteLocations(userId);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar locais salvos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Adiciona um novo local salvo
  Future<bool> addSavedPlace({
    required String label,
    required String address,
    required double latitude,
    required double longitude,
    required LocationType category,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      _setError('Usuário não autenticado');
      return false;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      await FavoriteLocationsService.addFavoriteLocation(
        userId: userId,
        label: label,
        address: address,
        latitude: latitude,
        longitude: longitude,
        category: category,
      );
      
      // Recarrega a lista após adicionar
      await loadSavedPlaces();
      return true;
    } catch (e) {
      _setError('Erro ao adicionar local: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Atualiza um local salvo existente
  Future<bool> updateSavedPlace({
    required String id,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
    required LocationType category,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      await FavoriteLocationsService.updateFavoriteLocation(
        locationId: id,
        label: label,
        address: address,
        latitude: latitude,
        longitude: longitude,
        category: category,
      );
      
      // Recarrega a lista após atualizar
      await loadSavedPlaces();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar local: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Remove um local salvo
  Future<bool> removeSavedPlace(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      await FavoriteLocationsService.deleteFavoriteLocation(id);
      
      // Remove da lista local imediatamente para melhor UX
      _savedPlaces.removeWhere((place) => place.id == id);
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Erro ao remover local: ${e.toString()}');
      // Recarrega a lista em caso de erro para manter consistência
      await loadSavedPlaces();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Busca um local específico por ID
  SavedPlace? getSavedPlaceById(String id) {
    try {
      return _savedPlaces.firstWhere((place) => place.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Converte SavedPlace para FavoriteLocation (para compatibilidade)
  FavoriteLocation savedPlaceToFavoriteLocation(SavedPlace savedPlace) => FavoriteLocation(
      id: savedPlace.id,
      name: savedPlace.label,
      address: savedPlace.address,
      type: LocationType.favorite,
      latitude: savedPlace.latitude,
      longitude: savedPlace.longitude,
      userId: savedPlace.userId,
    );
  
  /// Limpa todos os dados e redefine o estado
  void reset() {
    _savedPlaces.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
  
  /// Limpa mensagens de erro
  void clearError() {
    _clearError();
  }
  
  // Métodos privados para gerenciar estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}