import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/platform_settings.dart';

class PlatformSettingsService {
  PlatformSettingsService(this._supabase);
  final SupabaseClient _supabase;

  // Sem cache - sempre consulta o Supabase diretamente

  /// Busca configurações por categoria - SEMPRE consulta o Supabase
  Future<PlatformSettings?> getSettingsByCategory(String category) async {
    try {
      print('🔍 [PLATFORM-SETTINGS] Consultando categoria: $category');
      
      final response = await _supabase
          .from('platform_settings')
          .select()
          .eq('category', category)
          .maybeSingle();

      if (response == null) {
        print('⚠️ [PLATFORM-SETTINGS] Categoria $category não encontrada');
        return null;
      }

      final settings = PlatformSettings.fromJson(response);
      print('✅ [PLATFORM-SETTINGS] Categoria $category carregada: R\$ ${settings.basePricePerKm}/km');

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

  /// Busca todas as configurações - SEMPRE consulta o Supabase
  Future<List<PlatformSettings>> getAllSettings() async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    print('⚙️ [PLATFORM-SETTINGS-$sessionId] Consultando platform_settings diretamente (sem cache)');
    
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

      // Se não houver configurações, criar as básicas
      if (settings.isEmpty) {
        print('⚠️ [PLATFORM-SETTINGS-$sessionId] Tabela vazia! Tentando criar configurações básicas...');
        await _createDefaultSettings();
        print('🔄 [PLATFORM-SETTINGS-$sessionId] Tentando buscar novamente após criação...');
        
        // Tentar buscar novamente
        final retryResponse = await _supabase
            .from('platform_settings')
            .select()
            .order('category', ascending: true);
            
        final retrySettings = (retryResponse as List<dynamic>)
            .map((json) => PlatformSettings.fromJson(json as Map<String, dynamic>))
            .toList();
            
        print('📋 [PLATFORM-SETTINGS-$sessionId] Settings após retry: ${retrySettings.length}');
        return retrySettings;
      }

      return settings;
    } on PostgrestException catch (e) {
      print('❌ [PLATFORM-SETTINGS-$sessionId] PostgrestException: ${e.code} - ${e.message}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Details: ${e.details}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Hint: ${e.hint}');
      
      // Se o erro é de permissão (usuário não autenticado), relança erro
      if (e.code == '42501' || e.code == 'PGRST301' || e.message.contains('permission denied')) {
        print('🔄 [PLATFORM-SETTINGS-$sessionId] Erro de permissão - não usando fallback hardcoded');
      }
      
      throw DatabaseException(
        'Erro ao buscar configurações da plataforma. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      print('❌ [PLATFORM-SETTINGS-$sessionId] Erro inesperado: ${e.toString()}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Tipo do erro: ${e.runtimeType}');
      print('❌ [PLATFORM-SETTINGS-$sessionId] Stack trace: ${StackTrace.current}');
      
      // Para outros erros, não usar fallback hardcoded
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('🔄 [PLATFORM-SETTINGS-$sessionId] Usuário não autenticado - não usando fallback hardcoded');
      }
      
      throw const DatabaseException(
        'Erro inesperado ao buscar configurações da plataforma. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca configurações padrão (categoria 'common_car')
  Future<PlatformSettings> getDefaultSettings() async {
    final settings = await getSettingsByCategory('common_car');
    if (settings == null) {
      throw const DatabaseException(
        'Configurações padrão da plataforma não encontradas.',
      );
    }
    return settings;
  }

  /// Métodos de conveniência para obter valores específicos
  Future<double> getBasePricePerKm([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.basePricePerKm ?? 1.5; // Fallback hardcoded
  }

  Future<double> getBasePricePerMinute([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.basePricePerMinute ?? 0.20; // Fallback hardcoded
  }

  Future<double> getPlatformCommissionPercent([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.platformCommissionPercent ?? 10.0; // Fallback hardcoded
  }

  Future<double> getMinFare([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.minFare ?? 8.0; // Fallback hardcoded
  }

  Future<double> getMinCancellationFee([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.minCancellationFee ?? 10.0; // Fallback hardcoded
  }

  Future<double> getCancellationFeePercent([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.cancellationFeePercent ?? 20.0; // Fallback hardcoded
  }

  Future<int> getNoShowWaitMinutes([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.noShowWaitMinutes ?? 3; // Fallback hardcoded
  }

  Future<int> getDriverAcceptanceTimeoutSeconds([String category = 'common_car']) async {
    final settings = await getSettingsByCategory(category);
    return settings?.driverAcceptanceTimeoutSeconds ?? 10; // Fallback hardcoded
  }

  Future<int> getSearchRadiusKm([String category = 'common_car']) async {
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

  /// Sem cache - sempre consulta dados frescos do Supabase

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
      
      // Sem cache - dados sempre atualizados
      
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
      
      // Sem cache - dados sempre atualizados
      
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


  /// Cria configurações padrão na tabela platform_settings se estiver vazia
  Future<void> _createDefaultSettings() async {
    try {
      print('🔧 [PLATFORM-SETTINGS] Criando configurações padrão...');
      
      final defaultSettings = [
        {
          'category': 'common_car',
          'base_price_per_km': 1.50,
          'base_price_per_minute': 0.20,
          'platform_commission_percent': 10.0,
          'min_fare': 8.0,
          'min_cancellation_fee': 10.0,
          'cancellation_fee_percent': 20.0,
          'no_show_wait_minutes': 3,
          'driver_acceptance_timeout_seconds': 10,
        },
        {
          'category': 'freight',
          'base_price_per_km': 2.0,
          'base_price_per_minute': 0.30,
          'platform_commission_percent': 10.0,
          'min_fare': 12.0,
          'min_cancellation_fee': 15.0,
          'cancellation_fee_percent': 20.0,
          'no_show_wait_minutes': 5,
          'driver_acceptance_timeout_seconds': 15,
        },
        {
          'category': 'tow_truck',
          'base_price_per_km': 3.0,
          'base_price_per_minute': 0.50,
          'platform_commission_percent': 10.0,
          'min_fare': 20.0,
          'min_cancellation_fee': 25.0,
          'cancellation_fee_percent': 20.0,
          'no_show_wait_minutes': 10,
          'driver_acceptance_timeout_seconds': 20,
        },
      ];

      for (final setting in defaultSettings) {
        try {
          await _supabase.from('platform_settings').insert(setting);
          print('✅ [PLATFORM-SETTINGS] Configuração criada: ${setting['category']}');
        } on PostgrestException catch (e) {
          // Se der erro de constraint único, ignora (já existe)
          if (e.code == '23505') {
            print('ℹ️ [PLATFORM-SETTINGS] Configuração já existe: ${setting['category']}');
          } else {
            print('❌ [PLATFORM-SETTINGS] Erro ao criar ${setting['category']}: $e');
          }
        }
      }
      
      print('✅ [PLATFORM-SETTINGS] Configurações padrão processadas');
    } catch (e) {
      print('❌ [PLATFORM-SETTINGS] Erro geral ao criar configurações: $e');
      // Não relança o erro para não quebrar o fluxo principal
    }
  }
}