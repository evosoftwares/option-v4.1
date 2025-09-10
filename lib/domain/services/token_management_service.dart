import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço especializado para gerenciamento de tokens OneSignal
/// Inclui validação, sincronização, limpeza e analytics
class TokenManagementService {
  factory TokenManagementService() => _instance;
  TokenManagementService._internal();
  static final TokenManagementService _instance = TokenManagementService._internal();

  final Logger _logger = Logger();
  
  static const String _playerIdKey = 'onesignal_player_id';
  static const String _pushTokenKey = 'onesignal_push_token';
  static const String _playerIdTimestampKey = 'onesignal_player_id_timestamp';
  static const String _pushTokenTimestampKey = 'onesignal_push_token_timestamp';
  static const String _lastSyncKey = 'onesignal_last_sync';
  static const String _deviceIdKey = 'device_id';
  
  /// Registra ou atualiza Player ID e Push Token do OneSignal
  Future<bool> registerToken() async {
    try {
      // No OneSignal v5.x, usar getOnesignalId() que pode retornar null se chamado antes da inicialização
      final playerId = await OneSignal.User.getOnesignalId();
      final pushToken = OneSignal.User.pushSubscription.token;
      if (playerId == null && pushToken == null) {
        _logger.w('Player ID e Push Token OneSignal não disponíveis');
        return false;
      }
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _logger.w('Usuário não autenticado');
        if (playerId != null) await _savePlayerIdLocally(playerId);
        if (pushToken != null) await _savePushTokenLocally(pushToken);
        return false;
      }
      
      // Verificar se os dados mudaram
      final lastPlayerId = await _getLocalPlayerId();
      final lastPushToken = await _getLocalPushToken();
      if (lastPlayerId == playerId && lastPushToken == pushToken) {
        _logger.i('Dados OneSignal não mudaram, verificando sincronização');
        return await _ensureTokenSynced(playerId, pushToken, currentUser.id);
      }
      
      // Registrar novos dados
      final success = await _saveTokenToDatabase(playerId, pushToken, currentUser.id);
      if (success) {
        if (playerId != null) await _savePlayerIdLocally(playerId);
        if (pushToken != null) await _savePushTokenLocally(pushToken);
        await _updateLastSync();
        _logger.i('Dados OneSignal registrados com sucesso');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao registrar dados OneSignal', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Salva dados OneSignal no banco de dados
  Future<bool> _saveTokenToDatabase(String? playerId, String? pushToken, String userId) async {
    try {
      final platform = _getCurrentPlatform();
      final deviceId = await _getDeviceId();
      final timestamp = DateTime.now().toIso8601String();
      
      // Verificar se é motorista ou passageiro
      final userType = await _getUserType(userId);
      
      final updateData = <String, dynamic>{
        'token_updated_at': timestamp,
        'token_active': true,
      };
      
      if (playerId != null) {
        updateData['onesignal_player_id'] = playerId;
        // removido: updateData['player_id_updated_at'] = timestamp;
      }
      
      if (pushToken != null) {
        updateData['push_token'] = pushToken;
        // removido: updateData['push_token_updated_at'] = timestamp;
      }
      
      if (userType == 'driver') {
        updateData['device_platform'] = platform;
        updateData['device_id'] = deviceId;
      } else {
        // app_users não possui colunas de device_*, apenas manter last_active_at se existir
        updateData['last_active_at'] = timestamp;
      }
      
      if (userType == 'driver') {
        await Supabase.instance.client
            .from('drivers')
            .update(updateData)
            .eq('user_id', userId);
      } else {
        await Supabase.instance.client
            .from('app_users')
            .update(updateData)
            .eq('user_id', userId);
      }
      
      // Registrar no histórico de tokens (alinhado ao schema)
      await _logTokenRegistration(
        playerId: playerId ?? '',
        pushToken: pushToken ?? '',
        userId: userId,
        platform: platform,
        deviceId: deviceId,
        role: userType,
      );
      
      return true;
      
    } catch (e) {
      _logger.e('Erro ao salvar token no banco', error: e);
      return false;
    }
  }
  
  /// Determina o tipo de usuário (driver ou passenger)
  Future<String> _getUserType(String userId) async {
    try {
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return driverResponse != null ? 'driver' : 'passenger';
    } catch (e) {
      _logger.e('Erro ao determinar tipo de usuário', error: e);
      return 'passenger'; // Default
    }
  }
  
  /// Garante que os dados estão sincronizados
  Future<bool> _ensureTokenSynced(String? playerId, String? pushToken, String userId) async {
    try {
      final lastSync = await _getLastSync();
      final now = DateTime.now();
      
      // Verificar se precisa sincronizar (a cada 24 horas)
      if (lastSync != null && now.difference(lastSync).inHours < 24) {
        return true;
      }
      
      // Verificar se o token existe no banco
      final userType = await _getUserType(userId);
      final tableName = userType == 'driver' ? 'drivers' : 'app_users';
      
      final response = await Supabase.instance.client
          .from(tableName)
          .select('onesignal_player_id, push_token, token_active')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null || 
          response['onesignal_player_id'] != playerId || 
          response['push_token'] != pushToken ||
          response['token_active'] != true) {
        // Dados não sincronizados, forçar atualização
        return await _saveTokenToDatabase(playerId, pushToken, userId);
      }
      
      await _updateLastSync();
      return true;
      
    } catch (e) {
      _logger.e('Erro ao verificar sincronização do token', error: e);
      return false;
    }
  }
  
  /// Invalida token atual
  Future<bool> invalidateToken() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return false;
      
      final userType = await _getUserType(currentUser.id);
      final tableName = userType == 'driver' ? 'drivers' : 'app_users';
      
      await Supabase.instance.client
          .from(tableName)
          .update({
            'token_active': false,
            'token_invalidated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser.id);
      
      // Limpar dados locais
      await _clearLocalData();
      
      _logger.i('Token OneSignal invalidado com sucesso');
      return true;
      
    } catch (e) {
      _logger.e('Erro ao invalidar token', error: e);
      return false;
    }
  }
  
  /// Limpa tokens inativos do banco
  Future<void> cleanupInactiveTokens() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      // Limpar dados de motoristas inativos
      await Supabase.instance.client
          .from('drivers')
          .update({
            'onesignal_player_id': null, 
            'push_token': null, 
            'token_active': false
          })
          .lt('token_updated_at', cutoffDate.toIso8601String());
      
      // Limpar dados de passageiros inativos
      await Supabase.instance.client
          .from('app_users')
          .update({
            'onesignal_player_id': null, 
            'push_token': null, 
            'token_active': false
          })
          .lt('token_updated_at', cutoffDate.toIso8601String());
      
      _logger.i('Limpeza de tokens inativos concluída');
      
    } catch (e) {
      _logger.e('Erro na limpeza de tokens inativos', error: e);
    }
  }
  
  /// Obtém estatísticas de tokens
  Future<Map<String, dynamic>> getTokenStatistics() async {
    try {
      // Estatísticas de motoristas
      final driversStats = await Supabase.instance.client
          .from('drivers')
          .select('onesignal_player_id, push_token, token_active, device_platform')
          .not('onesignal_player_id', 'is', null);
      
      // Estatísticas de passageiros (app_users não possui device_platform)
      final usersStats = await Supabase.instance.client
          .from('app_users')
          .select('onesignal_player_id, push_token, token_active')
          .not('onesignal_player_id', 'is', null);
      
      final combined = <dynamic>[
        ...driversStats,
        ...usersStats.map((u) => {
          ...u,
          'device_platform': 'unknown',
        }),
      ];
      
      final stats = {
        'total_tokens': driversStats.length + usersStats.length,
        'active_tokens': driversStats.where((d) => d['token_active'] == true).length +
                        usersStats.where((u) => u['token_active'] == true).length,
        'drivers_with_tokens': driversStats.length,
        'users_with_tokens': usersStats.length,
        'platform_distribution': _calculatePlatformDistribution(combined),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      return stats;
      
    } catch (e) {
      _logger.e('Erro ao obter estatísticas de tokens', error: e);
      return {};
    }
  }
  
  /// Calcula distribuição por plataforma
  Map<String, int> _calculatePlatformDistribution(List<dynamic> tokens) {
    final distribution = <String, int>{};
    
    for (final token in tokens) {
      final platform = token['device_platform'] ?? 'unknown';
      distribution[platform] = (distribution[platform] ?? 0) + 1;
    }
    
    return distribution;
  }
  
  /// Registra dados no histórico
  Future<void> _logTokenRegistration({
    required String playerId,
    required String pushToken,
    required String userId,
    required String platform,
    required String deviceId,
    required String role,
  }) async {
    try {
      await Supabase.instance.client.from('onesignal_token_history').insert({
        'user_id': userId,
        'role': role,
        'player_id': playerId,
        'push_token': pushToken,
        'device_id': deviceId,
        'device_platform': platform,
        'event': 'updated',
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Erro ao registrar dados no histórico', error: e);
    }
  }
  
  /// Cria hash do token para segurança
  String _hashToken(String token) {
    // Usar apenas os primeiros e últimos caracteres para identificação
    if (token.length < 20) return token;
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }
  
  /// Obtém plataforma atual
  String _getCurrentPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'web';
  }
  
  /// Obtém ou gera ID do dispositivo
  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString(_deviceIdKey);
      
      if (deviceId == null) {
        deviceId = '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_deviceIdKey, deviceId);
      }
      
      return deviceId;
    } catch (e) {
      return 'unknown_device';
    }
  }
  
  /// Salva Player ID localmente
  Future<void> _savePlayerIdLocally(String playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playerIdKey, playerId);
      await prefs.setString(_playerIdTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Erro ao salvar Player ID localmente', error: e);
    }
  }
  
  /// Salva Push Token localmente
  Future<void> _savePushTokenLocally(String pushToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pushTokenKey, pushToken);
      await prefs.setString(_pushTokenTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Erro ao salvar Push Token localmente', error: e);
    }
  }
  
  /// Obtém Player ID local
  Future<String?> _getLocalPlayerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_playerIdKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Obtém Push Token local
  Future<String?> _getLocalPushToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_pushTokenKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Limpa dados locais
  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_playerIdKey);
      await prefs.remove(_pushTokenKey);
      await prefs.remove(_playerIdTimestampKey);
      await prefs.remove(_pushTokenTimestampKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      _logger.e('Erro ao limpar dados locais', error: e);
    }
  }
  
  /// Atualiza timestamp da última sincronização
  Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Erro ao atualizar última sincronização', error: e);
    }
  }
  
  /// Obtém timestamp da última sincronização
  Future<DateTime?> _getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncString = prefs.getString(_lastSyncKey);
      return syncString != null ? DateTime.parse(syncString) : null;
    } catch (e) {
      return null;
    }
  }
  
  /// Obtém Player ID atual
  Future<String?> getCurrentPlayerId() async => _getLocalPlayerId();
  
  /// Obtém Push Token atual
  Future<String?> getCurrentPushToken() async => _getLocalPushToken();
  
  /// Verifica se dados estão válidos
  Future<bool> areTokensValid() async {
    try {
      final playerId = await _getLocalPlayerId();
      final pushToken = await _getLocalPushToken();
      if (playerId == null && pushToken == null) return false;
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return false;
      
      return await _ensureTokenSynced(playerId, pushToken, currentUser.id);
    } catch (e) {
      return false;
    }
  }
}