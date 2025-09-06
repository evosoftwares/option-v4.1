import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/platform_settings.dart';

class PlatformSettingsService {
  PlatformSettingsService(this._supabase);
  final SupabaseClient _supabase;

  // Cache para evitar múltiplas consultas
  static final Map<String, PlatformSettings> _settingsCache = {};
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Busca configurações por categoria com cache
  Future<PlatformSettings?> getSettingsByCategory(String category) async {
    try {
      // Verifica cache
      if (_isValidCache(category)) {
        return _settingsCache[category];
      }

      final response = await _supabase
          .from('platform_settings')
          .select()
          .eq('category', category)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final settings = PlatformSettings.fromJson(response);
      
      // Atualiza cache
      _settingsCache[category] = settings;
      _lastCacheUpdate = DateTime.now();

      return settings;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar configurações da plataforma. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar configurações da plataforma. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca todas as configurações
  Future<List<PlatformSettings>> getAllSettings() async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    print('⚙️ [PLATFORM-SETTINGS-$sessionId] Iniciando getAllSettings()');
    
    try {
      // Log do usuário atual
      final currentUser = _supabase.auth.currentUser;
      print('👤 [PLATFORM-SETTINGS-$sessionId] Usuário: ${currentUser?.id}');
      print('📧 [PLATFORM-SETTINGS-$sessionId] Email: ${currentUser?.email}');
      
      print('🔍 [PLATFORM-SETTINGS-$sessionId] Fazendo consulta na tabela platform_settings...');
      final response = await _supabase
          .from('platform_settings')
          .select()
          .order('category', ascending: true);

      print('📊 [PLATFORM-SETTINGS-$sessionId] Resposta recebida: ${response.toString()}');
      print('📊 [PLATFORM-SETTINGS-$sessionId] Tipo da resposta: ${response.runtimeType}');
      print('📊 [PLATFORM-SETTINGS-$sessionId] Número de registros: ${(response as List<dynamic>).length}');

      final settings = (response as List<dynamic>)
          .map((json) {
            print('🔧 [PLATFORM-SETTINGS-$sessionId] Processando JSON: $json');
            return PlatformSettings.fromJson(json as Map<String, dynamic>);
          })
          .toList();

      print('📋 [PLATFORM-SETTINGS-$sessionId] Settings processados: ${settings.length}');
      for (int i = 0; i < settings.length; i++) {
        final setting = settings[i];
        print('   📋 [$i] ${setting.category}: km=${setting.basePricePerKm}, min=${setting.minFare}');
      }

      // Atualiza cache com todas as configurações
      for (final setting in settings) {
        _settingsCache[setting.category] = setting;
        print('💾 [PLATFORM-SETTINGS-$sessionId] Cached: ${setting.category}');
      }
      _lastCacheUpdate = DateTime.now();
      print('✅ [PLATFORM-SETTINGS-$sessionId] Cache atualizado');

      return settings;
    } on PostgrestException catch (e) {
      print('❌ [PLATFORM-SETTINGS-$sessionId] PostgrestException: ${e.code} - ${e.message}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Details: ${e.details}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Hint: ${e.hint}');
      throw DatabaseException(
        'Erro ao buscar configurações da plataforma. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      print('❌ [PLATFORM-SETTINGS-$sessionId] Erro inesperado: ${e.toString()}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Tipo do erro: ${e.runtimeType}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Stack trace: ${StackTrace.current}');
      throw const DatabaseException(
        'Erro inesperado ao buscar configurações da plataforma. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca configurações padrão (categoria 'Comum')
  Future<PlatformSettings> getDefaultSettings() async {
    final settings = await getSettingsByCategory('Comum');
    if (settings == null) {
      throw const DatabaseException(
        'Configurações padrão da plataforma não encontradas.',
      );
    }
    return settings;
  }

  /// Métodos de conveniência para obter valores específicos
  Future<double> getBasePricePerKm([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.basePricePerKm ?? 1.5; // Fallback hardcoded
  }

  Future<double> getBasePricePerMinute([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.basePricePerMinute ?? 0.20; // Fallback hardcoded
  }

  Future<double> getPlatformCommissionPercent([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.platformCommissionPercent ?? 10.0; // Fallback hardcoded
  }

  Future<double> getMinFare([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.minFare ?? 8.0; // Fallback hardcoded
  }

  Future<double> getMinCancellationFee([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.minCancellationFee ?? 10.0; // Fallback hardcoded
  }

  Future<double> getCancellationFeePercent([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.cancellationFeePercent ?? 20.0; // Fallback hardcoded
  }

  Future<int> getNoShowWaitMinutes([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.noShowWaitMinutes ?? 3; // Fallback hardcoded
  }

  Future<int> getDriverAcceptanceTimeoutSeconds([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.driverAcceptanceTimeoutSeconds ?? 10; // Fallback hardcoded
  }

  Future<int> getSearchRadiusKm([String category = 'Comum']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.searchRadiusKm ?? 10; // Fallback hardcoded
  }

  /// Busca configurações para cálculo de preços de uma categoria de veículo
  Future<Map<String, dynamic>> getPricingConfig(String vehicleCategory) async {
    try {
      // Tenta buscar configurações específicas da categoria do veículo
      var settings = await getSettingsByCategory(vehicleCategory);
      
      // Se não encontrar, usa configurações padrão
      settings ??= await getDefaultSettings();

      return {
        'basePricePerKm': settings.basePricePerKm,
        'basePricePerMinute': settings.basePricePerMinute,
        'platformCommissionPercent': settings.platformCommissionPercent,
        'minFare': settings.minFare,
      };
    } catch (e) {
      // Fallback com valores hardcoded em caso de erro
      return {
        'basePricePerKm': 1.5,
        'basePricePerMinute': 0.20,
        'platformCommissionPercent': 10.0,
        'minFare': 8.0,
      };
    }
  }

  /// Limpa o cache (útil para forçar atualização)
  void clearCache() {
    _settingsCache.clear();
    _lastCacheUpdate = null;
  }

  /// Verifica se o cache é válido para uma categoria
  bool _isValidCache(String category) {
    if (!_settingsCache.containsKey(category) || _lastCacheUpdate == null) {
      return false;
    }
    
    final now = DateTime.now();
    final cacheAge = now.difference(_lastCacheUpdate!);
    return cacheAge < _cacheTimeout;
  }

  /// Atualiza uma configuração (apenas para administradores)
  Future<PlatformSettings> updateSettings({
    required String id,
    String? category,
    double? basePricePerKm,
    double? basePricePerMinute,
    double? platformCommissionPercent,
    double? minFare,
    double? minCancellationFee,
    double? cancellationFeePercent,
    int? noShowWaitMinutes,
    int? driverAcceptanceTimeoutSeconds,
    int? searchRadiusKm,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (category != null) updateData['category'] = category;
      if (basePricePerKm != null) updateData['base_price_per_km'] = basePricePerKm;
      if (basePricePerMinute != null) updateData['base_price_per_minute'] = basePricePerMinute;
      if (platformCommissionPercent != null) updateData['platform_commission_percent'] = platformCommissionPercent;
      if (minFare != null) updateData['min_fare'] = minFare;
      if (minCancellationFee != null) updateData['min_cancellation_fee'] = minCancellationFee;
      if (cancellationFeePercent != null) updateData['cancellation_fee_percent'] = cancellationFeePercent;
      if (noShowWaitMinutes != null) updateData['no_show_wait_minutes'] = noShowWaitMinutes;
      if (driverAcceptanceTimeoutSeconds != null) updateData['driver_acceptance_timeout_seconds'] = driverAcceptanceTimeoutSeconds;
      if (searchRadiusKm != null) updateData['search_radius_km'] = searchRadiusKm;

      if (updateData.isEmpty) {
        throw const ValidationException('Nenhum campo foi fornecido para atualização.');
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('platform_settings')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final settings = PlatformSettings.fromJson(response);
      
      // Limpa cache após atualização
      clearCache();
      
      return settings;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao atualizar configurações. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao atualizar configurações. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Cria novas configurações de categoria
  Future<PlatformSettings> createSettings({
    required String category,
    required double basePricePerKm,
    required double basePricePerMinute,
    required double platformCommissionPercent,
    double minFare = 8.0,
    double minCancellationFee = 10.0,
    double cancellationFeePercent = 20.0,
    int noShowWaitMinutes = 3,
    int driverAcceptanceTimeoutSeconds = 10,
    int searchRadiusKm = 10,
  }) async {
    try {
      final insertData = {
        'category': category,
        'base_price_per_km': basePricePerKm,
        'base_price_per_minute': basePricePerMinute,
        'platform_commission_percent': platformCommissionPercent,
        'min_fare': minFare,
        'min_cancellation_fee': minCancellationFee,
        'cancellation_fee_percent': cancellationFeePercent,
        'no_show_wait_minutes': noShowWaitMinutes,
        'driver_acceptance_timeout_seconds': driverAcceptanceTimeoutSeconds,
        'search_radius_km': searchRadiusKm,
      };

      final response = await _supabase
          .from('platform_settings')
          .insert(insertData)
          .select()
          .single();

      final settings = PlatformSettings.fromJson(response);
      
      // Limpa cache após criação
      clearCache();
      
      return settings;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao criar configurações. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao criar configurações. Por favor, tente novamente mais tarde.',
      );
    }
  }
}