import 'dart:async';

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço para segmentação de públicos para notificações push
/// Permite criar segmentos baseados em critérios específicos
class NotificationSegmentationService {
  factory NotificationSegmentationService() => _instance;
  NotificationSegmentationService._internal();
  static final NotificationSegmentationService _instance = NotificationSegmentationService._internal();

  final Logger _logger = Logger();
  
  /// Obtém tokens de usuários baseado em segmentação
  Future<List<String>> getTokensBySegmentation({
    required String audience,
    Map<String, dynamic>? customFilters,
  }) async {
    try {
      switch (audience) {
        case 'all':
          return await _getAllActiveTokens();
        case 'drivers':
          return await _getDriverTokens();
        case 'passengers':
          return await _getPassengerTokens();
        case 'active_drivers':
          return await _getActiveDriverTokens();
        case 'nearby_drivers':
          return await _getNearbyDriverTokens(customFilters);
        case 'frequent_users':
          return await _getFrequentUserTokens();
        case 'new_users':
          return await _getNewUserTokens();
        case 'custom':
          return await _getCustomSegmentTokens(customFilters);
        default:
          _logger.w('Tipo de audiência desconhecido: $audience');
          return [];
      }
    } catch (e, stackTrace) {
      _logger.e('Erro ao obter tokens por segmentação', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Obtém todos os tokens ativos
  Future<List<String>> _getAllActiveTokens() async {
    final driversResponse = await Supabase.instance.client
        .from('drivers')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .not('onesignal_player_id', 'is', null);
    
    final usersResponse = await Supabase.instance.client
        .from('app_users')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .not('onesignal_player_id', 'is', null);
    
    final tokens = <String>[];
    
    for (final driver in driversResponse) {
      if (driver['onesignal_player_id'] != null) {
        tokens.add(driver['onesignal_player_id']);
      }
    }
    
    for (final user in usersResponse) {
      if (user['onesignal_player_id'] != null) {
        tokens.add(user['onesignal_player_id']);
      }
    }
    
    return tokens;
  }
  
  /// Obtém tokens de todos os motoristas
  Future<List<String>> _getDriverTokens() async {
    final response = await Supabase.instance.client
        .from('drivers')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .not('onesignal_player_id', 'is', null);
    
    return response
        .map<String>((driver) => driver['onesignal_player_id'] as String)
        .toList();
  }
  
  /// Obtém tokens de todos os passageiros
  Future<List<String>> _getPassengerTokens() async {
    final response = await Supabase.instance.client
        .from('app_users')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .not('onesignal_player_id', 'is', null);
    
    return response
        .map<String>((user) => user['onesignal_player_id'] as String)
        .toList();
  }
  
  /// Obtém tokens de motoristas ativos (online)
  Future<List<String>> _getActiveDriverTokens() async {
    final response = await Supabase.instance.client
        .from('drivers')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .eq('is_online', true)
        .not('onesignal_player_id', 'is', null);
    
    return response
        .map<String>((driver) => driver['onesignal_player_id'] as String)
        .toList();
  }
  
  /// Obtém tokens de motoristas próximos a uma localização
  Future<List<String>> _getNearbyDriverTokens(Map<String, dynamic>? filters) async {
    if (filters == null || !filters.containsKey('latitude') || !filters.containsKey('longitude')) {
      _logger.w('Filtros de localização não fornecidos para motoristas próximos');
      return [];
    }
    
    final latitude = filters['latitude'] as double;
    final longitude = filters['longitude'] as double;
    final radiusKm = filters['radius_km'] as double? ?? 10.0;
    
    // Usar função PostGIS para buscar motoristas próximos (compatível com retorno antigo)
    final response = await Supabase.instance.client
        .rpc('get_nearby_drivers', params: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radiusKm,
        });
    
    return response
        .map<String>((driver) {
          final dynamic pid = driver['onesignal_player_id'] ?? driver['player_id'];
          return (pid is String) ? pid : '';
        })
        .where((token) => token.isNotEmpty)
        .toList();
  }
  
  /// Obtém tokens de usuários frequentes
  Future<List<String>> _getFrequentUserTokens() async {
    // Usuários com mais de 10 viagens nos últimos 30 dias
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    final response = await Supabase.instance.client
        .rpc('get_frequent_users', params: {
          'min_trips': 10,
          'since_date': cutoffDate.toIso8601String(),
        });
    
    return response
        .map<String>((user) {
          final dynamic pid = user['onesignal_player_id'] ?? user['player_id'];
          return (pid is String) ? pid : '';
        })
        .where((token) => token.isNotEmpty)
        .toList();
  }
  
  /// Obtém tokens de usuários novos
  Future<List<String>> _getNewUserTokens() async {
    // Usuários cadastrados nos últimos 7 dias
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    
    final driversResponse = await Supabase.instance.client
        .from('drivers')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .gte('created_at', cutoffDate.toIso8601String())
        .not('onesignal_player_id', 'is', null);
    
    final usersResponse = await Supabase.instance.client
        .from('app_users')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .gte('created_at', cutoffDate.toIso8601String())
        .not('onesignal_player_id', 'is', null);
    
    final tokens = <String>[];
    
    for (final driver in driversResponse) {
      if (driver['onesignal_player_id'] != null) {
        tokens.add(driver['onesignal_player_id']);
      }
    }
    
    for (final user in usersResponse) {
      if (user['onesignal_player_id'] != null) {
        tokens.add(user['onesignal_player_id']);
      }
    }
    
    return tokens;
  }
  
  /// Obtém tokens baseado em filtros personalizados
  Future<List<String>> _getCustomSegmentTokens(Map<String, dynamic>? filters) async {
    if (filters == null || filters.isEmpty) {
      return [];
    }
    
    final tokens = <String>[];
    
    // Filtros para motoristas
    if (filters.containsKey('driver_filters')) {
      final driverFilters = filters['driver_filters'] as Map<String, dynamic>;
      final driverTokens = await _getDriverTokensWithFilters(driverFilters);
      tokens.addAll(driverTokens);
    }
    
    // Filtros para passageiros
    if (filters.containsKey('user_filters')) {
      final userFilters = filters['user_filters'] as Map<String, dynamic>;
      final userTokens = await _getUserTokensWithFilters(userFilters);
      tokens.addAll(userTokens);
    }
    
    return tokens.toSet().toList(); // Remove duplicatas
  }
  
  /// Obtém tokens de motoristas com filtros específicos
  Future<List<String>> _getDriverTokensWithFilters(Map<String, dynamic> filters) async {
    var query = Supabase.instance.client
        .from('drivers')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .not('onesignal_player_id', 'is', null);
    
    // Aplicar filtros
    if (filters.containsKey('vehicle_type')) {
      query = query.eq('vehicle_type', filters['vehicle_type']);
    }
    
    if (filters.containsKey('rating_min')) {
      query = query.gte('rating', filters['rating_min']);
    }
    
    if (filters.containsKey('is_online')) {
      query = query.eq('is_online', filters['is_online']);
    }
    
    if (filters.containsKey('city')) {
      query = query.eq('city', filters['city']);
    }
    
    if (filters.containsKey('created_after')) {
      query = query.gte('created_at', filters['created_after']);
    }
    
    if (filters.containsKey('created_before')) {
      query = query.lte('created_at', filters['created_before']);
    }
    
    final response = await query;
    
    return response
        .map<String>((driver) => driver['onesignal_player_id'] as String)
        .toList();
  }
  
  /// Obtém tokens de usuários com filtros específicos
  Future<List<String>> _getUserTokensWithFilters(Map<String, dynamic> filters) async {
    var query = Supabase.instance.client
        .from('app_users')
        .select('onesignal_player_id')
        .eq('token_active', true)
        .not('onesignal_player_id', 'is', null);
    
    // Aplicar filtros
    if (filters.containsKey('city')) {
      query = query.eq('city', filters['city']);
    }
    
    if (filters.containsKey('age_min')) {
      final birthDateMax = DateTime.now().subtract(Duration(days: (filters['age_min'] as int) * 365));
      query = query.lte('birth_date', birthDateMax.toIso8601String());
    }
    
    if (filters.containsKey('age_max')) {
      final birthDateMin = DateTime.now().subtract(Duration(days: (filters['age_max'] as int) * 365));
      query = query.gte('birth_date', birthDateMin.toIso8601String());
    }
    
    if (filters.containsKey('created_after')) {
      query = query.gte('created_at', filters['created_after']);
    }
    
    if (filters.containsKey('created_before')) {
      query = query.lte('created_at', filters['created_before']);
    }
    
    final response = await query;
    
    return response
        .map<String>((user) => user['onesignal_player_id'] as String)
        .toList();
  }
  
  /// Cria um segmento personalizado e salva no banco
  Future<String?> createCustomSegment({
    required String name,
    required String description,
    required Map<String, dynamic> criteria,
    String? createdBy,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('notification_segments')
          .insert({
            'name': name,
            'description': description,
            'criteria': criteria,
            'created_by': createdBy ?? Supabase.instance.client.auth.currentUser?.id,
            'created_at': DateTime.now().toIso8601String(),
            'is_active': true,
          })
          .select('id')
          .single();
      
      _logger.i('Segmento personalizado criado: $name');
      return response['id'];
      
    } catch (e) {
      _logger.e('Erro ao criar segmento personalizado', error: e);
      return null;
    }
  }
  
  /// Lista segmentos personalizados salvos
  Future<List<Map<String, dynamic>>> getCustomSegments() async {
    try {
      final response = await Supabase.instance.client
          .from('notification_segments')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      _logger.e('Erro ao listar segmentos personalizados', error: e);
      return [];
    }
  }
  
  /// Obtém tokens de um segmento personalizado salvo
  Future<List<String>> getTokensFromSavedSegment(String segmentId) async {
    try {
      final segmentResponse = await Supabase.instance.client
          .from('notification_segments')
          .select('criteria')
          .eq('id', segmentId)
          .eq('is_active', true)
          .single();
      
      final criteria = segmentResponse['criteria'] as Map<String, dynamic>;
      return await _getCustomSegmentTokens(criteria);
      
    } catch (e) {
      _logger.e('Erro ao obter tokens do segmento salvo', error: e);
      return [];
    }
  }
  
  /// Calcula estatísticas de um segmento
  Future<Map<String, dynamic>> getSegmentStatistics(String audience, [Map<String, dynamic>? filters]) async {
    try {
      final tokens = await getTokensBySegmentation(
        audience: audience,
        customFilters: filters,
      );
      
      return {
        'total_users': tokens.length,
        'audience_type': audience,
        'calculated_at': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      _logger.e('Erro ao calcular estatísticas do segmento', error: e);
      return {
        'total_users': 0,
        'audience_type': audience,
        'error': e.toString(),
      };
    }
  }
  
  /// Valida critérios de segmentação
  bool validateSegmentationCriteria(Map<String, dynamic> criteria) {
    try {
      // Validações básicas
      if (criteria.isEmpty) return false;
      
      // Validar filtros de motoristas
      if (criteria.containsKey('driver_filters')) {
        final driverFilters = criteria['driver_filters'] as Map<String, dynamic>;
        if (!_validateDriverFilters(driverFilters)) return false;
      }
      
      // Validar filtros de usuários
      if (criteria.containsKey('user_filters')) {
        final userFilters = criteria['user_filters'] as Map<String, dynamic>;
        if (!_validateUserFilters(userFilters)) return false;
      }
      
      return true;
      
    } catch (e) {
      _logger.e('Erro ao validar critérios de segmentação', error: e);
      return false;
    }
  }
  
  bool _validateDriverFilters(Map<String, dynamic> filters) {
    // Validar tipos de veículo permitidos
    if (filters.containsKey('vehicle_type')) {
      final allowedTypes = ['car', 'motorcycle', 'bicycle', 'truck'];
      if (!allowedTypes.contains(filters['vehicle_type'])) return false;
    }
    
    // Validar rating
    if (filters.containsKey('rating_min')) {
      final rating = filters['rating_min'];
      if (rating is! num || rating < 0 || rating > 5) return false;
    }
    
    return true;
  }
  
  bool _validateUserFilters(Map<String, dynamic> filters) {
    // Validar idades
    if (filters.containsKey('age_min')) {
      final age = filters['age_min'];
      if (age is! int || age < 0 || age > 120) return false;
    }
    
    if (filters.containsKey('age_max')) {
      final age = filters['age_max'];
      if (age is! int || age < 0 || age > 120) return false;
    }
    
    return true;
  }
}