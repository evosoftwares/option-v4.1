import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço especializado para gerenciamento de tokens FCM
/// Inclui validação, sincronização, limpeza e analytics
class TokenManagementService {
  factory TokenManagementService() => _instance;
  TokenManagementService._internal();
  static final TokenManagementService _instance = TokenManagementService._internal();

  final Logger _logger = Logger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static const String _tokenKey = 'fcm_token';
  static const String _tokenTimestampKey = 'fcm_token_timestamp';
  static const String _lastSyncKey = 'fcm_last_sync';
  static const String _deviceIdKey = 'device_id';
  
  /// Registra ou atualiza token FCM
  Future<bool> registerToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        _logger.w('Token FCM não disponível');
        return false;
      }
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _logger.w('Usuário não autenticado');
        await _saveTokenLocally(token);
        return false;
      }
      
      // Verificar se o token mudou
      final lastToken = await _getLocalToken();
      if (lastToken == token) {
        _logger.i('Token FCM não mudou, verificando sincronização');
        return await _ensureTokenSynced(token, currentUser.id);
      }
      
      // Registrar novo token
      final success = await _saveTokenToDatabase(token, currentUser.id);
      if (success) {
        await _saveTokenLocally(token);
        await _updateLastSync();
        _logger.i('Token FCM registrado com sucesso');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      _logger.e('Erro ao registrar token FCM', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Salva token no banco de dados
  Future<bool> _saveTokenToDatabase(String token, String userId) async {
    try {
      final platform = _getCurrentPlatform();
      final deviceId = await _getDeviceId();
      final timestamp = DateTime.now().toIso8601String();
      
      // Verificar se é motorista ou passageiro
      final userType = await _getUserType(userId);
      
      if (userType == 'driver') {
        await Supabase.instance.client
            .from('drivers')
            .update({
              'fcm_token': token,
              'device_platform': platform,
              'device_id': deviceId,
              'token_updated_at': timestamp,
              'token_active': true,
            })
            .eq('user_id', userId);
      } else {
        await Supabase.instance.client
            .from('app_users')
            .update({
              'fcm_token': token,
              'device_platform': platform,
              'device_id': deviceId,
              'token_updated_at': timestamp,
              'token_active': true,
            })
            .eq('user_id', userId);
      }
      
      // Registrar no histórico de tokens
      await _logTokenRegistration(token, userId, platform, deviceId);
      
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
  
  /// Garante que o token está sincronizado
  Future<bool> _ensureTokenSynced(String token, String userId) async {
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
          .select('fcm_token, token_active')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null || 
          response['fcm_token'] != token || 
          response['token_active'] != true) {
        // Token não sincronizado, forçar atualização
        return await _saveTokenToDatabase(token, userId);
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
      
      // Limpar token local
      await _clearLocalToken();
      
      _logger.i('Token FCM invalidado com sucesso');
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
      
      // Limpar tokens de motoristas inativos
      await Supabase.instance.client
          .from('drivers')
          .update({'fcm_token': null, 'token_active': false})
          .lt('token_updated_at', cutoffDate.toIso8601String());
      
      // Limpar tokens de passageiros inativos
      await Supabase.instance.client
          .from('app_users')
          .update({'fcm_token': null, 'token_active': false})
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
          .select('fcm_token, token_active, device_platform')
          .not('fcm_token', 'is', null);
      
      // Estatísticas de passageiros
      final usersStats = await Supabase.instance.client
          .from('app_users')
          .select('fcm_token, token_active, device_platform')
          .not('fcm_token', 'is', null);
      
      final stats = {
        'total_tokens': driversStats.length + usersStats.length,
        'active_tokens': driversStats.where((d) => d['token_active'] == true).length +
                        usersStats.where((u) => u['token_active'] == true).length,
        'drivers_with_tokens': driversStats.length,
        'users_with_tokens': usersStats.length,
        'platform_distribution': _calculatePlatformDistribution(driversStats + usersStats),
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
  
  /// Registra token no histórico
  Future<void> _logTokenRegistration(String token, String userId, String platform, String deviceId) async {
    try {
      await Supabase.instance.client.from('fcm_token_history').insert({
        'user_id': userId,
        'token_hash': _hashToken(token),
        'platform': platform,
        'device_id': deviceId,
        'action': 'registered',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Erro ao registrar token no histórico', error: e);
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
  
  /// Salva token localmente
  Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_tokenTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      _logger.e('Erro ao salvar token localmente', error: e);
    }
  }
  
  /// Obtém token local
  Future<String?> _getLocalToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }
  
  /// Limpa token local
  Future<void> _clearLocalToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenTimestampKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      _logger.e('Erro ao limpar token local', error: e);
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
  
  /// Obtém token atual
  Future<String?> getCurrentToken() async => _getLocalToken();
  
  /// Verifica se token está válido
  Future<bool> isTokenValid() async {
    try {
      final token = await _getLocalToken();
      if (token == null) return false;
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return false;
      
      return await _ensureTokenSynced(token, currentUser.id);
    } catch (e) {
      return false;
    }
  }
}