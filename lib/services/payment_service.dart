import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/payment_method.dart';
import '../utils/supabase_helper.dart';
import 'auth_service.dart';

class PaymentService {
  static SupabaseClient get _supabase {
    final client = SupabaseHelper.client;
    if (client == null) {
      throw const AuthException('Supabase não inicializado');
    }
    return client;
  }

  /// Get all payment methods for the current user with security validations
  static Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw const UnauthorizedException('ID do usuário não disponível');
      }

      final data = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PAYMENT_METHODS_ACCESSED',
        description: 'Métodos de pagamento acessados via PaymentService',
        metadata: {
          'user_id': userId,
          'methods_count': (data as List).length,
        },
      );
      
      return (data as List)
          .map((item) => PaymentMethod.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar métodos de pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }

  /// Add a new payment method with security validations
  static Future<PaymentMethod> addPaymentMethod(PaymentMethod method) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final userId = AuthService.getCurrentUserId();

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

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PAYMENT_METHOD_ADDED',
        description: 'Novo método de pagamento adicionado via PaymentService',
        metadata: {
          'user_id': userId,
          'payment_method_id': data['id'],
          'type': method.type.value,
          'is_default': isFirstMethod || method.isDefault,
        },
      );

      return PaymentMethod.fromMap(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao adicionar método de pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }

  /// Remove a payment method with security validations
  static Future<void> removePaymentMethod(String methodId) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw const UnauthorizedException('ID do usuário não disponível');
      }
      
      // Verificar se o método de pagamento pertence ao usuário
      final existingMethod = await _supabase
          .from('payment_methods')
          .select('id, type')
          .eq('id', methodId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingMethod == null) {
        throw const UnauthorizedException('Método de pagamento não encontrado ou não autorizado');
      }

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
      
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PAYMENT_METHOD_REMOVED',
        description: 'Método de pagamento removido via PaymentService',
        metadata: {
          'user_id': userId,
          'payment_method_id': methodId,
          'type': existingMethod['type'],
        },
      );
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao remover método de pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }

  /// Set a payment method as default with security validations
  static Future<void> setAsDefault(String methodId) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw const UnauthorizedException('ID do usuário não disponível');
      }
      
      // Verificar se o método de pagamento pertence ao usuário
      final existingMethod = await _supabase
          .from('payment_methods')
          .select('id, type')
          .eq('id', methodId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingMethod == null) {
        throw const UnauthorizedException('Método de pagamento não encontrado ou não autorizado');
      }
      
      await _updateDefaultPaymentMethod(methodId);
      
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PAYMENT_METHOD_SET_DEFAULT',
        description: 'Método de pagamento definido como padrão via PaymentService',
        metadata: {
          'user_id': userId,
          'payment_method_id': methodId,
          'type': existingMethod['type'],
        },
      );
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

  /// Get the default payment method for the current user with security validations
  static Future<PaymentMethod?> getDefaultPaymentMethod() async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw const UnauthorizedException('ID do usuário não disponível');
      }

      final data = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .eq('is_active', true)
          .maybeSingle();

      if (data == null) return null;

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'DEFAULT_PAYMENT_METHOD_ACCESSED',
        description: 'Método de pagamento padrão acessado via PaymentService',
        metadata: {
          'user_id': userId,
          'payment_method_id': data['id'],
          'type': data['type'],
        },
      );

      return PaymentMethod.fromMap(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar método de pagamento padrão', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado: $e');
    }
  }
}