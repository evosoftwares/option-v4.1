import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uber_clone/exceptions/app_exceptions.dart';
import 'package:uber_clone/models/user.dart' as app_user;
import 'package:uber_clone/services/asaas_service.dart';

class WalletService {
  final SupabaseClient _supabase;
  final AsaasService _asaas;

  WalletService({SupabaseClient? client, AsaasService? asaas})
      : _supabase = client ?? Supabase.instance.client,
        _asaas = asaas ?? AsaasService();

  Future<String?> getDriverIdForUser(String userId) async {
    try {
      final data = await _supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return data != null ? (data['id'] as String) : null;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar motorista do usuário. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar motorista do usuário. Por favor, tente novamente mais tarde.');
    }
  }

  Future<Map<String, dynamic>?> getDriverWallet(String driverId) async {
    try {
      final data = await _supabase
          .from('driver_wallets')
          .select('*')
          .eq('driver_id', driverId)
          .maybeSingle();
      return data as Map<String, dynamic>?;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar carteira. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar carteira. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions(String driverId, {int limit = 50}) async {
    try {
      final data = await _supabase
          .from('wallet_transactions')
          .select('*')
          .eq('wallet_id', driverId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar transações. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar transações. Por favor, tente novamente mais tarde.');
    }
  }

  Future<void> ensureAsaasCustomerForUser(app_user.User user) async {
    try {
      await _asaas.ensureCustomer(
        name: user.fullName,
        email: user.email,
        cpfCnpj: null, // Pode ser preenchido quando disponível
        mobilePhone: user.phone,
      );
    } catch (e) {
      // Propagar como NetworkException já vem do serviço
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required String driverId,
    required double amount,
    String method = 'pix',
    Map<String, dynamic>? bankAccountInfo,
  }) async {
    try {
      final payload = {
        'driver_id': driverId,
        'wallet_id': driverId,
        'amount': amount,
        'withdrawal_method': method,
        'bank_account_info': bankAccountInfo,
        'status': 'requested',
        'requested_at': DateTime.now().toIso8601String(),
      };
      final data = await _supabase
          .from('withdrawals')
          .insert(payload)
          .select()
          .single();
      return data as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao solicitar saque. Por favor, verifique os dados e tente novamente.', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao solicitar saque. Por favor, tente novamente mais tarde.');
    }
  }
}