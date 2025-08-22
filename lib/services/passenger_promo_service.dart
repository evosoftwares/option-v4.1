import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import '../models/passenger_promo_code.dart';
import '../models/user.dart' as app_user;

class PassengerPromoService {
  PassengerPromoService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Get available promo codes for a user
  Future<List<PassengerPromoCode>> getAvailablePromoCodes(String userId) async {
    try {
      final now = DateTime.now();
      final data = await _supabase
          .from('passenger_promo_codes')
          .select()
          .eq('is_active', true)
          .lte('valid_from', now.toIso8601String())
          .gte('valid_until', now.toIso8601String())
          .order('created_at', ascending: false);

      final promoCodes = (data as List)
          .map((item) => PassengerPromoCode.fromMap(item as Map<String, dynamic>))
          .where((promo) => promo.isValid)
          .toList();

      // Filter out already used promo codes for first ride only codes
      final filteredCodes = <PassengerPromoCode>[];
      for (final promo in promoCodes) {
        if (promo.isFirstRideOnly) {
          final hasUsed = await _hasUserUsedPromoCode(userId, promo.id);
          if (!hasUsed) {
            filteredCodes.add(promo);
          }
        } else {
          // Check usage limit
          if (promo.usageLimit == null || promo.usageCount < promo.usageLimit!) {
            filteredCodes.add(promo);
          }
        }
      }

      return filteredCodes;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar códigos promocionais', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar códigos promocionais: $e');
    }
  }

  /// Validate and get promo code by code string
  Future<PassengerPromoCode?> validatePromoCode(String code, String userId, {double? tripAmount}) async {
    try {
      final data = await _supabase
          .from('passenger_promo_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (data == null) return null;

      final promoCode = PassengerPromoCode.fromMap(data);

      if (!promoCode.isValid) return null;

      // Check if user already used this promo code (for first ride only codes)
      if (promoCode.isFirstRideOnly) {
        final hasUsed = await _hasUserUsedPromoCode(userId, promoCode.id);
        if (hasUsed) return null;
      }

      // Check minimum amount requirement
      if (tripAmount != null && !promoCode.canBeUsedForAmount(tripAmount)) {
        return null;
      }

      return promoCode;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao validar código promocional', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao validar código promocional: $e');
    }
  }

  /// Apply promo code to a trip
  Future<PassengerPromoCodeUsage> applyPromoCode({
    required String userId,
    required String promoCodeId,
    required double originalAmount,
    String? tripId,
  }) async {
    try {
      // Get promo code details
      final promoData = await _supabase
          .from('passenger_promo_codes')
          .select()
          .eq('id', promoCodeId)
          .single();

      final promoCode = PassengerPromoCode.fromMap(promoData);

      if (!promoCode.isValid) {
        throw const DatabaseException('Código promocional inválido ou expirado');
      }

      // Calculate discount
      final discountAmount = promoCode.calculateDiscount(originalAmount);
      final finalAmount = originalAmount - discountAmount;

      // Create usage record
      final usagePayload = {
        'user_id': userId,
        'promo_code_id': promoCodeId,
        'trip_id': tripId,
        'original_amount': originalAmount,
        'discount_amount': discountAmount,
        'final_amount': finalAmount,
        'used_at': DateTime.now().toIso8601String(),
      };

      final usageData = await _supabase
          .from('passenger_promo_code_usage')
          .insert(usagePayload)
          .select()
          .single();

      // Update promo code usage count
      await _supabase
          .from('passenger_promo_codes')
          .update({'usage_count': 'usage_count + 1'})
          .eq('id', promoCodeId);

      return PassengerPromoCodeUsage.fromMap(usageData);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao aplicar código promocional', e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Erro inesperado ao aplicar código promocional: $e');
    }
  }

  /// Get user's promo code usage history
  Future<List<PassengerPromoCodeUsage>> getUserPromoHistory(String userId) async {
    try {
      final data = await _supabase
          .from('passenger_promo_code_usage')
          .select()
          .eq('user_id', userId)
          .order('used_at', ascending: false);

      return (data as List)
          .map((item) => PassengerPromoCodeUsage.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar histórico de promoções', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar histórico de promoções: $e');
    }
  }

  /// Check if user has used a specific promo code
  Future<bool> _hasUserUsedPromoCode(String userId, String promoCodeId) async {
    try {
      final data = await _supabase
          .from('passenger_promo_code_usage')
          .select('id')
          .eq('user_id', userId)
          .eq('promo_code_id', promoCodeId)
          .limit(1);

      return (data as List).isNotEmpty;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao verificar uso de código promocional', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao verificar uso de código promocional: $e');
    }
  }

  /// Calculate dynamic cashback percentage based on user activity
  double calculateDynamicCashback(int tripsThisMonth, double totalSpent) {
    // Base cashback rate
    double baseRate = 0.02; // 2%

    // Bonus for frequent users
    if (tripsThisMonth >= 20) {
      baseRate += 0.01; // +1% for 20+ trips
    } else if (tripsThisMonth >= 10) {
      baseRate += 0.005; // +0.5% for 10+ trips
    }

    // Bonus for high spenders (over R$ 200 this month)
    if (totalSpent >= 200.0) {
      baseRate += 0.005; // +0.5% for high spenders
    }

    // Cap at 4%
    return baseRate > 0.04 ? 0.04 : baseRate;
  }

  /// Get user's cashback statistics
  Future<Map<String, dynamic>> getCashbackStats(String userId) async {
    try {
      // Get current month data
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      // Count trips this month
      final tripsData = await _supabase
          .from('trips')
          .select('id, total_fare')
          .eq('passenger_id', userId)
          .gte('created_at', firstDayOfMonth.toIso8601String())
          .eq('payment_status', 'completed');

      final tripsThisMonth = (tripsData as List).length;
      final totalSpentThisMonth = (tripsData as List)
          .fold<double>(0.0, (sum, trip) => sum + ((trip['total_fare'] as num?)?.toDouble() ?? 0.0));

      // Get total cashback earned
      final cashbackData = await _supabase
          .from('passenger_wallet_transactions')
          .select('amount')
          .eq('passenger_id', userId)
          .eq('type', 'cashback');

      final totalCashbackEarned = (cashbackData as List)
          .fold<double>(0.0, (sum, tx) => sum + ((tx['amount'] as num?)?.toDouble() ?? 0.0));

      final currentCashbackRate = calculateDynamicCashback(tripsThisMonth, totalSpentThisMonth);

      return {
        'trips_this_month': tripsThisMonth,
        'total_spent_this_month': totalSpentThisMonth,
        'total_cashback_earned': totalCashbackEarned,
        'current_cashback_rate': currentCashbackRate,
        'next_tier_trips': _getNextTierTrips(tripsThisMonth),
        'next_tier_bonus': _getNextTierBonus(tripsThisMonth),
      };
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar estatísticas de cashback', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar estatísticas de cashback: $e');
    }
  }

  int? _getNextTierTrips(int currentTrips) {
    if (currentTrips < 10) return 10;
    if (currentTrips < 20) return 20;
    return null; // Already at max tier
  }

  double? _getNextTierBonus(int currentTrips) {
    if (currentTrips < 10) return 0.005; // +0.5%
    if (currentTrips < 20) return 0.01; // +1%
    return null; // Already at max tier
  }

  /// Create a welcome promo code for new users
  Future<void> createWelcomePromoForUser(app_user.User user) async {
    try {
      // Check if user already has a welcome promo
      final existingPromo = await _supabase
          .from('passenger_promo_code_usage')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if ((existingPromo as List).isNotEmpty) {
        return; // User already used a promo code
      }

      // Create a personal welcome promo code
      final welcomeCode = 'BEMVINDO${user.id.substring(0, 6).toUpperCase()}';
      final validUntil = DateTime.now().add(const Duration(days: 30));

      final promoPayload = {
        'code': welcomeCode,
        'type': 'percentage',
        'value': 50.0, // 50% off
        'min_amount': 10.0,
        'max_discount': 20.0, // Max R$ 20 discount
        'is_active': true,
        'is_first_ride_only': true,
        'usage_limit': 1,
        'valid_from': DateTime.now().toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
      };

      await _supabase
          .from('passenger_promo_codes')
          .insert(promoPayload);
    } on PostgrestException catch (e) {
      // Don't throw error for promo creation failure to not block user registration
      print('Failed to create welcome promo: ${e.message}');
    } catch (e) {
      print('Failed to create welcome promo: $e');
    }
  }

  /// Get referral bonus amount based on referee's spending
  double calculateReferralBonus(double refereeFirstTripAmount) {
    // Both referrer and referee get 10% of first trip amount (min R$ 5, max R$ 25)
    final bonus = refereeFirstTripAmount * 0.10;
    if (bonus < 5.0) return 5.0;
    if (bonus > 25.0) return 25.0;
    return bonus;
  }
}