import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_method.dart';
import '../exceptions/app_exceptions.dart';

class PaymentService {
  static final _supabase = Supabase.instance.client;

  /// Get all payment methods for the current user
  static Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Usuário não autenticado');

      final data = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => PaymentMethod.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar métodos de pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }

  /// Add a new payment method
  static Future<PaymentMethod> addPaymentMethod(PaymentMethod method) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Usuário não autenticado');

      // If this is the first payment method, make it default
      final existingMethods = await getPaymentMethods();
      final isFirstMethod = existingMethods.isEmpty;

      final payload = {
        'user_id': userId,
        'type': method.type.value,
        'is_default': isFirstMethod || method.isDefault,
        'is_active': true,
        'pix_data': method.pixData?.toMap(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final data = await _supabase
          .from('payment_methods')
          .insert(payload)
          .select()
          .single();

      // If this is being set as default, update other methods
      if (isFirstMethod || method.isDefault) {
        await _updateDefaultPaymentMethod(data['id'] as String);
      }

      return PaymentMethod.fromMap(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao adicionar método de pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }

  /// Remove a payment method
  static Future<void> removePaymentMethod(String methodId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Usuário não autenticado');

      // Check if this is the default method
      final method = await _supabase
          .from('payment_methods')
          .select()
          .eq('id', methodId)
          .eq('user_id', userId)
          .single();

      final isDefault = method['is_default'] as bool;

      // Remove the method
      await _supabase
          .from('payment_methods')
          .update({'is_active': false})
          .eq('id', methodId)
          .eq('user_id', userId);

      // If this was the default, set another as default
      if (isDefault) {
        final remainingMethods = await getPaymentMethods();
        if (remainingMethods.isNotEmpty) {
          await _updateDefaultPaymentMethod(remainingMethods.first.id);
        }
      }
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao remover método de pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }

  /// Set a payment method as default
  static Future<void> setAsDefault(String methodId) async {
    try {
      await _updateDefaultPaymentMethod(methodId);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao definir método padrão', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }

  /// Update default payment method
  static Future<void> _updateDefaultPaymentMethod(String methodId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Usuário não autenticado');

    // First, unset all current default methods
    await _supabase
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', userId);

    // Then set the new default
    await _supabase
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', methodId)
        .eq('user_id', userId);
  }

  /// Get default payment method
  static Future<PaymentMethod?> getDefaultPaymentMethod() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw const AuthException('Usuário não autenticado');

      final data = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .eq('is_active', true)
          .maybeSingle();

      if (data == null) return null;

      return PaymentMethod.fromMap(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar método padrão', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }
}