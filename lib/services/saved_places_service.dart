import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_logger.dart';

/// Serviço para gerenciar locais favoritos dos usuários
/// Este serviço usa a tabela dedicada saved_places
class SavedPlacesService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'saved_places';

  /// Salva múltiplos locais favoritos para um usuário
  static Future<void> savePlaces(String userId, List<Map<String, dynamic>> places) async {
    try {
      AppLogger.info('Salvando ${places.length} locais favoritos para usuário $userId');
      
      // Primeiro limpar locais existentes
      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', userId);
      
      // Inserir novos locais se houver
      if (places.isNotEmpty) {
        final placesToInsert = places.map((place) => {
          'user_id': userId,
          'label': place['label'] ?? place['name'],
          'address': place['address'],
          'latitude': place['latitude'],
          'longitude': place['longitude'],
          'category': place['category'] ?? place['type'] ?? 'other',
        }).toList();
        
        await _supabase
            .from(_tableName)
            .insert(placesToInsert);
      }
      
      AppLogger.info('Locais favoritos salvos com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao salvar locais favoritos', error: e);
      throw Exception('Erro ao salvar locais favoritos: $e');
    }
  }

  /// Recupera os locais favoritos de um usuário
  /// Retorna uma lista vazia se o usuário não tiver locais salvos
  static Future<List<Map<String, dynamic>>> getPlaces(String userId) async {
    try {
      AppLogger.info('Recuperando locais favoritos para usuário $userId');
      
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final places = (response as List).map((place) => {
        'id': place['id'],
        'label': place['label'],
        'name': place['label'], // Compatibilidade
        'address': place['address'],
        'latitude': place['latitude'],
        'longitude': place['longitude'],
        'category': place['category'],
        'type': place['category'], // Compatibilidade
        'created_at': place['created_at'],
        'updated_at': place['updated_at'],
      }).toList();
      
      AppLogger.info('${places.length} locais favoritos recuperados');
      return places;
    } catch (e) {
      AppLogger.error('Erro ao recuperar locais favoritos', error: e);
      throw Exception('Erro ao recuperar locais favoritos: $e');
    }
  }

  /// Remove todos os locais favoritos de um usuário
  static Future<void> deletePlaces(String userId) async {
    try {
      AppLogger.info('Removendo todos os locais favoritos para usuário $userId');
      
      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', userId);
      
      AppLogger.info('Locais favoritos removidos com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao remover locais favoritos', error: e);
      throw Exception('Erro ao remover locais favoritos: $e');
    }
  }

  /// Adiciona um novo local favorito
  static Future<Map<String, dynamic>> addPlace(String userId, Map<String, dynamic> place) async {
    try {
      final placeData = {
        'user_id': userId,
        'label': place['label'] ?? place['name'],
        'address': place['address'],
        'latitude': place['latitude'],
        'longitude': place['longitude'],
        'category': place['category'] ?? place['type'] ?? 'other',
      };
      
      final response = await _supabase
          .from(_tableName)
          .insert(placeData)
          .select()
          .single();
      
      AppLogger.info('Local favorito adicionado: ${place['label'] ?? place['name']}');
      return response;
    } catch (e) {
      AppLogger.error('Erro ao adicionar local favorito', error: e);
      throw Exception('Erro ao adicionar local favorito: $e');
    }
  }

  /// Remove um local favorito específico por nome
  static Future<void> removePlace(String userId, String placeName) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
          .eq('label', placeName);
      
      AppLogger.info('Local favorito removido: $placeName');
    } catch (e) {
      AppLogger.error('Erro ao remover local favorito', error: e);
      throw Exception('Erro ao remover local favorito: $e');
    }
  }

  /// Remove um local favorito específico por ID
  static Future<void> removePlaceById(String placeId) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', placeId);
      
      AppLogger.info('Local favorito removido: $placeId');
    } catch (e) {
      AppLogger.error('Erro ao remover local favorito', error: e);
      throw Exception('Erro ao remover local favorito: $e');
    }
  }

  /// Verifica se um usuário tem locais favoritos salvos
  static Future<bool> hasPlaces(String userId) async {
    try {
      final places = await getPlaces(userId);
      return places.isNotEmpty;
    } catch (e) {
      AppLogger.error('Erro ao verificar locais favoritos', error: e);
      return false;
    }
  }

  /// Atualiza um local favorito específico por ID
  static Future<Map<String, dynamic>> updatePlace(String placeId, Map<String, dynamic> newPlace) async {
    try {
      final updateData = {
        'label': newPlace['label'] ?? newPlace['name'],
        'address': newPlace['address'],
        'latitude': newPlace['latitude'],
        'longitude': newPlace['longitude'],
        'category': newPlace['category'] ?? newPlace['type'] ?? 'other',
      };
      
      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', placeId)
          .select()
          .single();
      
      AppLogger.info('Local favorito atualizado: $placeId');
      return response;
    } catch (e) {
      AppLogger.error('Erro ao atualizar local favorito', error: e);
      throw Exception('Erro ao atualizar local favorito: $e');
    }
  }
}