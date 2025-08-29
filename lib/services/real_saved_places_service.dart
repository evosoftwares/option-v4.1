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

class DatabaseException extends SavedPlacesException {
  DatabaseException(super.message, {super.originalError}) 
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
      
      final response = await _supabase
          .from(_tableName)
          .insert(location.toInsertJson())
          .select()
          .single();

      AppLogger.info('RealSavedPlacesService: Local favorito adicionado com sucesso');
      return FavoriteLocation.fromJson(response);
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao adicionar local: ${e.message}');
      throw DatabaseException('Erro ao salvar local favorito: ${e.message}', originalError: e);
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
      throw DatabaseException('Erro ao buscar locais favoritos: ${e.message}', originalError: e);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao buscar locais: $e');
      throw NetworkException('Erro de conexão ao buscar locais favoritos', originalError: e);
    }
  }

  /// Remove um local favorito
  Future<void> removePlace(String placeId) async {
    try {
      if (placeId.isEmpty) {
        throw ValidationException('ID do local é obrigatório');
      }

      AppLogger.info('RealSavedPlacesService: Removendo local favorito $placeId');
      
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', placeId);

      AppLogger.info('RealSavedPlacesService: Local favorito removido com sucesso');
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao remover local: ${e.message}');
      throw DatabaseException('Erro ao remover local favorito: ${e.message}', originalError: e);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao remover local: $e');
      throw NetworkException('Erro de conexão ao remover local favorito', originalError: e);
    }
  }

  /// Atualiza um local favorito
  Future<FavoriteLocation> updatePlace(FavoriteLocation location) async {
    try {
      if (location.id == null || location.id!.isEmpty) {
        throw ValidationException('ID do local é obrigatório para atualização');
      }
      if (location.name.isEmpty) {
        throw ValidationException('Nome do local é obrigatório');
      }
      if (location.address.isEmpty) {
        throw ValidationException('Endereço do local é obrigatório');
      }

      AppLogger.info('RealSavedPlacesService: Atualizando local favorito ${location.id}');
      
      final updateData = {
        'label': location.name, // Mapeia 'name' do modelo para 'label' do banco
        'address': location.address,
        'category': location.type.name, // Mapeia 'type' do modelo para 'category' do banco
        'latitude': location.latitude,
        'longitude': location.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', location.id!)
          .select()
          .single();

      AppLogger.info('RealSavedPlacesService: Local favorito atualizado com sucesso');
      return FavoriteLocation.fromJson(response);
    } on PostgrestException catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro de banco ao atualizar local: ${e.message}');
      throw DatabaseException('Erro ao atualizar local favorito: ${e.message}', originalError: e);
    } on ValidationException {
      rethrow;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro inesperado ao atualizar local: $e');
      throw NetworkException('Erro de conexão ao atualizar local favorito', originalError: e);
    }
  }

  /// Verifica se o usuário tem locais favoritos
  Future<bool> hasPlaces(String userId) async {
    try {
      final places = await getPlaces(userId);
      return places.isNotEmpty;
    } catch (e) {
      AppLogger.error('RealSavedPlacesService: Erro ao verificar locais favoritos: $e');
      return false;
    }
  }

  /// Adiciona múltiplos locais favoritos em batch
  Future<List<FavoriteLocation>> addMultiplePlaces(List<FavoriteLocation> locations) async {
    try {
      AppLogger.info('RealSavedPlacesService: Adicionando ${locations.length} locais favoritos em batch');
      
      final placesToInsert = locations.map((location) => location.toInsertJson()).toList();

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