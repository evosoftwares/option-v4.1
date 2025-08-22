import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/promo_code.dart';
import '../exceptions/app_exceptions.dart';

class PromoCodeService {
  final SupabaseClient _client = Supabase.instance.client;

  // Buscar todos os códigos promocionais (admin)
  Future<List<PromoCode>> getAllPromoCodes() async {
    try {
      final response = await _client
          .from('promo_codes')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PromoCode.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar códigos promocionais: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao buscar códigos promocionais: $e');
    }
  }

  // Buscar códigos promocionais ativos
  Future<List<PromoCode>> getActivePromoCodes() async {
    try {
      final response = await _client
          .from('promo_codes')
          .select()
          .eq('is_active', true)
          .gte('valid_until', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PromoCode.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar códigos ativos: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao buscar códigos ativos: $e');
    }
  }

  // Buscar código promocional por código
  Future<PromoCode?> getPromoCodeByCode(String code) async {
    try {
      final response = await _client
          .from('promo_codes')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (response == null) return null;
      return PromoCode.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar código promocional: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao buscar código promocional: $e');
    }
  }

  // Validar código promocional para uma viagem específica
  Future<bool> validatePromoCodeForTrip({
    required String code,
    required String userId,
    required double tripValue,
    List<String>? cities,
    List<String>? categories,
    bool isFirstTrip = false,
  }) async {
    try {
      final promoCode = await getPromoCodeByCode(code);
      if (promoCode == null) return false;

      // Verificar se o código pode ser usado para esta viagem
      if (!promoCode.canBeUsedForTrip(tripValue, cities: cities, categories: categories)) {
        return false;
      }

      // Verificar se é apenas para primeira viagem
      if (promoCode.isFirstTripOnly == true && !isFirstTrip) {
        return false;
      }

      // Verificar quantas vezes o usuário já usou este código
      final maxUsesPerUser = promoCode.maxUsesPerUser;
      if (maxUsesPerUser != null) {
        final userUsageCount = await _getUserUsageCount(userId, promoCode.id);
        if (userUsageCount >= maxUsesPerUser) {
          return false;
        }
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao validar código promocional: $e');
    }
  }

  // Criar novo código promocional (admin)
  Future<PromoCode> createPromoCode({
    required String code,
    required String description,
    required String discountType, // 'percentage' ou 'fixed'
    required double discountValue,
    double? maxDiscount,
    double? minTripValue,
    int? maxUsesPerUser,
    required DateTime validFrom,
    required DateTime validUntil,
    int? usageLimit,
    List<String>? targetCities,
    List<String>? targetCategories,
    bool isFirstTripOnly = false,
    required String createdBy,
  }) async {
    try {
      final promoCodeData = {
        'code': code.toUpperCase(),
        'description': description,
        'discount_type': discountType,
        'discount_value': discountValue,
        'max_discount': maxDiscount,
        'min_trip_value': minTripValue,
        'max_uses_per_user': maxUsesPerUser,
        'valid_from': validFrom.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
        'usage_limit': usageLimit,
        'used_count': 0,
        'target_cities': targetCities,
        'target_categories': targetCategories,
        'is_first_trip_only': isFirstTripOnly,
        'is_active': true,
        'created_by': createdBy,
      };

      final response = await _client
          .from('promo_codes')
          .insert(promoCodeData)
          .select()
          .single();

      return PromoCode.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw DatabaseException('Código promocional já existe', e.code);
      }
      throw DatabaseException('Erro ao criar código promocional: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao criar código promocional: $e');
    }
  }

  // Atualizar código promocional (admin)
  Future<PromoCode> updatePromoCode(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _client
          .from('promo_codes')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return PromoCode.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao atualizar código promocional: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao atualizar código promocional: $e');
    }
  }

  // Desativar código promocional (admin)
  Future<void> deactivatePromoCode(String id) async {
    try {
      await _client
          .from('promo_codes')
          .update({'is_active': false})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao desativar código promocional: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao desativar código promocional: $e');
    }
  }

  // Registrar uso de código promocional
  Future<void> recordPromoCodeUsage({
    required String promoCodeId,
    required String userId,
    required String tripId,
    required double discountAmount,
  }) async {
    try {
      // Registrar o uso na tabela promo_code_usage
      await _client.from('promo_code_usage').insert({
        'promo_code_id': promoCodeId,
        'user_id': userId,
        'trip_id': tripId,
        'discount_amount': discountAmount,
        'used_at': DateTime.now().toIso8601String(),
      });

      // Incrementar o contador de uso do código
      await _client.rpc('increment_promo_code_usage', params: {
        'promo_code_id': promoCodeId,
      });
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao registrar uso do código: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao registrar uso do código: $e');
    }
  }

  // Obter estatísticas de uso de um código promocional (admin)
  Future<Map<String, dynamic>> getPromoCodeStats(String promoCodeId) async {
    try {
      final response = await _client
          .from('promo_code_usage')
          .select('discount_amount, used_at')
          .eq('promo_code_id', promoCodeId);

      final usages = response as List;
      final totalUsages = usages.length;
      final totalDiscount = usages.fold<double>(
        0.0,
        (sum, usage) => sum + (usage['discount_amount'] as num).toDouble(),
      );

      return {
        'total_usages': totalUsages,
        'total_discount_given': totalDiscount,
        'average_discount': totalUsages > 0 ? totalDiscount / totalUsages : 0.0,
        'last_used': usages.isNotEmpty
            ? usages.map((u) => DateTime.parse(u['used_at'])).reduce(
                (a, b) => a.isAfter(b) ? a : b,
              )
            : null,
      };
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao obter estatísticas: ${e.message}', e.code);
    } catch (e) {
      throw Exception('Erro inesperado ao obter estatísticas: $e');
    }
  }

  // Buscar códigos promocionais disponíveis para um usuário específico
  Future<List<PromoCode>> getAvailablePromoCodesForUser({
    required String userId,
    required double tripValue,
    List<String>? cities,
    List<String>? categories,
    bool isFirstTrip = false,
  }) async {
    try {
      final activeCodes = await getActivePromoCodes();
      final availableCodes = <PromoCode>[];

      for (final code in activeCodes) {
        final isValid = await validatePromoCodeForTrip(
          code: code.code,
          userId: userId,
          tripValue: tripValue,
          cities: cities,
          categories: categories,
          isFirstTrip: isFirstTrip,
        );

        if (isValid) {
          availableCodes.add(code);
        }
      }

      return availableCodes;
    } catch (e) {
      throw Exception('Erro ao buscar códigos disponíveis: $e');
    }
  }

  // Método privado para contar quantas vezes um usuário usou um código
  Future<int> _getUserUsageCount(String userId, String promoCodeId) async {
    try {
      final response = await _client
          .from('promo_code_usage')
          .select('id')
          .eq('user_id', userId)
          .eq('promo_code_id', promoCodeId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}