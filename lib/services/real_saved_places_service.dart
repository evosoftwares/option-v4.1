import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/favorite_location.dart';
import '../services/app_logger.dart';

/// Exceções específicas para o serviço de locais salvos
class SavedPlacesException implements Exception {

  SavedPlacesException(this.message, {this.code, this.originalError});
  final String message;
  final String? code;
  final dynamic originalError;

  @override
  String toString() => 'SavedPlacesException: $message';
}

class NetworkException extends SavedPlacesException {
  NetworkException(super.message, {super.originalError}) 
      : super(code: 'NETWORK_ERROR');
}

class SavedPlacesDatabaseException extends SavedPlacesException {
  SavedPlacesDatabaseException(super.message, {super.originalError}) 
      : super(code: 'DATABASE_ERROR');
}

class ValidationException extends SavedPlacesException {
  ValidationException(super.message, {super.originalError}) 
      : super(code: 'VALIDATION_ERROR');
}

class RealSavedPlacesService {
  static const String _tableName = 'saved_places';
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Adiciona um novo local favorito para o usuário
  Future<FavoriteLocation> addPlace(FavoriteLocation location) async {
    try {
      // Validação básica
      if (location.userId.isEmpty) {
        throw ValidationException('ID do usuário é obrigatório');
      }
      if (location.name.isEmpty) {
        throw ValidationException('Nome do local é obrigatório');
      }
      if (location.address.isEmpty) {
        throw ValidationException('Endereço do local é obrigatório');
      }

      AppLogger.info('RealSavedPlacesService: Adicionando local favorito para usuário ${location.userId}');
      
      // Criar dados para inserção usando user_id diretamente
      final insertData = {
        'user_id': location.userId,
        'label': location.name,
        'address': location.address,
        'category': location.type.name,
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
      
      final response = await _supabase
          .from(_tableName)
          .insert(insertData)
          .select()
          .single();

      AppLogger.info('RealSavedPlacesService: Local favorito adicionado com sucesso');
      return FavoriteLocation.fromJson(response);
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao adicionar local: ${e.message}');
      throw SavedPlacesDatabaseException('Erro ao salvar local favorito: ${e.message}', originalError: e);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao adicionar local: $e');
      throw NetworkException('Erro de conexão ao adicionar local favorito', originalError: e);
    }
  }

  /// Busca todos os locais favoritos do usuário
  Future<List<FavoriteLocation>> getPlaces(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ValidationException('ID do usuário é obrigatório');
      }

      AppLogger.info('RealSavedPlacesService: Buscando locais favoritos para usuário $userId');
      
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final places = (response as List)
          .map((json) => FavoriteLocation.fromJson(json))
          .toList();

      AppLogger.info('RealSavedPlacesService: ${places.length} locais favoritos encontrados');
      return places;
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao buscar locais: ${e.message}');
      throw SavedPlacesDatabaseException('Erro ao buscar locais favoritos: ${e.message}', originalError: e);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao buscar locais: $e');
      throw NetworkException('Erro de conexão ao buscar locais favoritos', originalError: e);
    }
  }

  /// Remove um local favorito
  Future<bool> removePlace(String userId, String placeId) async {
    try {
      if (userId.isEmpty || placeId.isEmpty) {
        throw ValidationException('ID do usuário e ID do local são obrigatórios');
      }

      AppLogger.info('RealSavedPlacesService: Removendo local favorito $placeId do usuário $userId');
      
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', placeId)
          .eq('user_id', userId);

      AppLogger.info('RealSavedPlacesService: Local favorito removido com sucesso');
      return true;
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao remover local: ${e.message}');
      throw SavedPlacesDatabaseException('Erro ao remover local favorito: ${e.message}', originalError: e);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao remover local: $e');
      throw NetworkException('Erro de conexão ao remover local favorito', originalError: e);
    }
  }

  /// Atualiza um local favorito existente
  Future<FavoriteLocation?> updatePlace(String userId, String placeId, FavoriteLocation updatedLocation) async {
    try {
      if (userId.isEmpty || placeId.isEmpty) {
        throw ValidationException('ID do usuário e ID do local são obrigatórios');
      }

      AppLogger.info('RealSavedPlacesService: Atualizando local favorito $placeId do usuário $userId');
      
      final updateData = {
        'label': updatedLocation.name,
        'address': updatedLocation.address,
        'category': updatedLocation.type.name,
        'latitude': updatedLocation.latitude,
        'longitude': updatedLocation.longitude,
      };
      
      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', placeId)
          .eq('user_id', userId)
          .select()
          .single();

      AppLogger.info('RealSavedPlacesService: Local favorito atualizado com sucesso');
      return FavoriteLocation.fromJson(response);
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao atualizar local: ${e.message}');
      throw SavedPlacesDatabaseException('Erro ao atualizar local favorito: ${e.message}', originalError: e);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao atualizar local: $e');
      throw NetworkException('Erro de conexão ao atualizar local favorito', originalError: e);
    }
  }

  /// Verifica se o usuário tem locais favoritos salvos
  Future<bool> hasPlaces(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ValidationException('ID do usuário é obrigatório');
      }

      AppLogger.info('RealSavedPlacesService: Verificando se usuário $userId tem locais favoritos');
      
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      final hasPlaces = (response as List).isNotEmpty;
      AppLogger.info('RealSavedPlacesService: Usuário ${hasPlaces ? 'tem' : 'não tem'} locais favoritos');
      return hasPlaces;
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao verificar locais: ${e.message}');
      return false;
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao verificar locais: $e');
      return false;
    }
  }

  /// Adiciona múltiplos locais favoritos em batch
  Future<List<FavoriteLocation>> addMultiplePlaces(List<FavoriteLocation> locations) async {
    try {
      if (locations.isEmpty) {
        return [];
      }
      
      AppLogger.info('RealSavedPlacesService: Adicionando ${locations.length} locais favoritos em batch');
      
      // Criar dados para inserção usando user_id diretamente
      final placesToInsert = locations.map((location) => {
        'user_id': location.userId,
        'label': location.name,
        'address': location.address,
        'category': location.type.name,
        'latitude': location.latitude,
        'longitude': location.longitude,
      }).toList();

      final response = await _supabase
          .from(_tableName)
          .insert(placesToInsert)
          .select();

      final savedPlaces = (response as List)
          .map((json) => FavoriteLocation.fromJson(json))
          .toList();

      AppLogger.info('RealSavedPlacesService: ${savedPlaces.length} locais favoritos adicionados em batch');
      return savedPlaces;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro ao adicionar locais favoritos em batch: $e');
      return [];
    }
  }
  
}