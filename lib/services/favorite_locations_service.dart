import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite_location.dart';
import '../utils/supabase_helper.dart';

class SavedPlace {

  SavedPlace({
    required this.id,
    required this.userId,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
      id: json['id'],
      userId: json['user_id'], // Corrigido para usar user_id
      label: json['label'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      category: LocationType.values.firstWhere(
        (type) => type.name == (json['category'] ?? 'other'),
        orElse: () => LocationType.other,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  final String id;
  final String userId; // Corrigido nome do campo
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final LocationType category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
      'id': id,
      'user_id': userId, // Corrigido para usar user_id
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'category': category.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
}

class FavoriteLocationsService {
  static SupabaseClient get _supabase {
    final c = SupabaseHelper.client;
    if (c == null) {
      throw Exception('Supabase não inicializado');
    }
    return c;
  }

  /// Busca todos os locais favoritos do usuário
  static Future<List<SavedPlace>> getFavoriteLocations(String userId) async {
    try {
      final response = await _supabase
          .from('saved_places')
          .select()
          .eq('user_id', userId) // Corrigido para usar user_id
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavedPlace.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar locais favoritos: $e');
    }
  }

  /// Adiciona um novo local favorito
  static Future<SavedPlace> addFavoriteLocation({
    required String userId, // Corrigido nome do parâmetro
    required String label,
    required String address,
    required double latitude,
    required double longitude,
    required LocationType category,
  }) async {
    try {
      final locationData = {
        'user_id': userId, // Corrigido para usar user_id
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'category': category.name,
      };

      final response = await _supabase
          .from('saved_places')
          .insert(locationData)
          .select()
          .single();

      return SavedPlace.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao adicionar local favorito: $e');
    }
  }

  /// Atualiza um local favorito existente
  static Future<SavedPlace> updateFavoriteLocation({
    required String locationId,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    LocationType? category,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (label != null) updateData['label'] = label;
      if (address != null) updateData['address'] = address;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (category != null) updateData['category'] = category.name;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('saved_places')
          .update(updateData)
          .eq('id', locationId)
          .select()
          .single();

      return SavedPlace.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar local favorito: $e');
    }
  }

  /// Remove um local favorito
  static Future<void> deleteFavoriteLocation(String locationId) async {
    try {
      await _supabase
          .from('saved_places')
          .delete()
          .eq('id', locationId);
    } catch (e) {
      throw Exception('Erro ao remover local favorito: $e');
    }
  }
}