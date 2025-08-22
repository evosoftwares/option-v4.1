import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user.dart' as app_user;
import '../models/passenger_wallet.dart';
import '../models/passenger_wallet_transaction.dart';
import '../models/payment_method.dart';
import 'asaas_service.dart';

class WalletService {

  WalletService({SupabaseClient? client, AsaasService? asaas})
      : _supabase = client ?? Supabase.instance.client,
        _asaas = asaas ?? AsaasService();
  final SupabaseClient _supabase;
  final AsaasService _asaas;

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
      throw const DatabaseException('Erro inesperado ao buscar motorista do usuário. Por favor, tente novamente mais tarde.');
    }
  }

  Future<Map<String, dynamic>?> getDriverWallet(String driverId) async {
    try {
      final data = await _supabase
          .from('driver_wallets')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();
      return data;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar carteira. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar carteira. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<Map<String, dynamic>>> getWalletTransactions(String driverId, {int limit = 50}) async {
    try {
      final data = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', driverId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar transações. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar transações. Por favor, tente novamente mais tarde.');
    }
  }

  Future<void> ensureAsaasCustomerForUser(app_user.User user) async {
    try {
      await _asaas.ensureCustomer(
        name: user.fullName,
        email: user.email,
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
      return data;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao solicitar saque. Por favor, verifique os dados e tente novamente.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao solicitar saque. Por favor, tente novamente mais tarde.');
    }
  }

  // ========== PASSENGER WALLET METHODS ==========

  Future<String?> getPassengerIdForUser(String userId) async {
    try {
      final data = await _supabase
          .from('passengers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return data != null ? (data['id'] as String) : null;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar passageiro do usuário. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar passageiro do usuário. Por favor, tente novamente mais tarde.');
    }
  }

  Future<PassengerWallet?> getPassengerWallet(String passengerId) async {
    try {
      final data = await _supabase
          .from('passenger_wallets')
          .select()
          .eq('passenger_id', passengerId)
          .maybeSingle();
      return data != null ? PassengerWallet.fromMap(data) : null;
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar carteira. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar carteira. Por favor, tente novamente mais tarde.');
    }
  }

  Future<PassengerWallet> createPassengerWallet(String passengerId, String userId) async {
    try {
      final payload = {
        'passenger_id': passengerId,
        'user_id': userId,
        'available_balance': 0.0,
        'pending_balance': 0.0,
        'total_spent': 0.0,
        'total_cashback': 0.0,
      };
      final data = await _supabase
          .from('passenger_wallets')
          .insert(payload)
          .select()
          .single();
      return PassengerWallet.fromMap(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao criar carteira. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao criar carteira. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<PassengerWalletTransaction>> getPassengerWalletTransactions(
    String passengerId, {
    int limit = 50,
  }) async {
    try {
      final data = await _supabase
          .from('passenger_wallet_transactions')
          .select()
          .eq('passenger_id', passengerId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List)
          .map((item) => PassengerWalletTransaction.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar transações. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar transações. Por favor, tente novamente mais tarde.');
    }
  }

  Future<PassengerWalletTransaction> addCredit({
    required String passengerId,
    required double amount,
    required String description,
    String? paymentMethodId,
    String? asaasPaymentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final walletId = passengerId; // Assuming wallet_id is same as passenger_id
      final payload = {
        'wallet_id': walletId,
        'passenger_id': passengerId,
        'type': TransactionType.credit.value,
        'amount': amount,
        'description': description,
        'payment_method_id': paymentMethodId,
        'asaas_payment_id': asaasPaymentId,
        'status': TransactionStatus.completed.value,
        'metadata': metadata,
        'processed_at': DateTime.now().toIso8601String(),
      };

      final transactionData = await _supabase
          .from('passenger_wallet_transactions')
          .insert(payload)
          .select()
          .single();

      // Update wallet balance
      await _supabase
          .from('passenger_wallets')
          .update({
            'available_balance': 'available_balance + $amount',
          })
          .eq('passenger_id', passengerId);

      return PassengerWalletTransaction.fromMap(transactionData);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao adicionar crédito. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao adicionar crédito. Por favor, tente novamente mais tarde.');
    }
  }

  Future<PassengerWalletTransaction> debitTrip({
    required String passengerId,
    required String tripId,
    required double amount,
    String description = 'Pagamento de viagem',
  }) async {
    try {
      final walletId = passengerId; // Assuming wallet_id is same as passenger_id
      final payload = {
        'wallet_id': walletId,
        'passenger_id': passengerId,
        'type': TransactionType.tripPayment.value,
        'amount': amount,
        'description': description,
        'trip_id': tripId,
        'status': TransactionStatus.completed.value,
        'processed_at': DateTime.now().toIso8601String(),
      };

      final transactionData = await _supabase
          .from('passenger_wallet_transactions')
          .insert(payload)
          .select()
          .single();

      // Update wallet balance and total spent
      await _supabase
          .from('passenger_wallets')
          .update({
            'available_balance': 'available_balance - $amount',
            'total_spent': 'total_spent + $amount',
          })
          .eq('passenger_id', passengerId);

      return PassengerWalletTransaction.fromMap(transactionData);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao debitar viagem. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao debitar viagem. Por favor, tente novamente mais tarde.');
    }
  }

  Future<PassengerWalletTransaction> addCashback({
    required String passengerId,
    required double amount,
    String description = 'Cashback',
    String? tripId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final walletId = passengerId; // Assuming wallet_id is same as passenger_id
      final payload = {
        'wallet_id': walletId,
        'passenger_id': passengerId,
        'type': TransactionType.cashback.value,
        'amount': amount,
        'description': description,
        'trip_id': tripId,
        'status': TransactionStatus.completed.value,
        'metadata': metadata,
        'processed_at': DateTime.now().toIso8601String(),
      };

      final transactionData = await _supabase
          .from('passenger_wallet_transactions')
          .insert(payload)
          .select()
          .single();

      // Update wallet balance and total cashback
      await _supabase
          .from('passenger_wallets')
          .update({
            'available_balance': 'available_balance + $amount',
            'total_cashback': 'total_cashback + $amount',
          })
          .eq('passenger_id', passengerId);

      return PassengerWalletTransaction.fromMap(transactionData);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao adicionar cashback. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao adicionar cashback. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    try {
      final data = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      return (data as List)
          .map((item) => PaymentMethod.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar métodos de pagamento. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar métodos de pagamento. Por favor, tente novamente mais tarde.');
    }
  }

  Future<PaymentMethod> addPaymentMethod({
    required String userId,
    required PaymentMethodType type,
    CardData? cardData,
    PixData? pixData,
    bool isDefault = false,
  }) async {
    try {
      // If setting as default, unset other defaults
      if (isDefault) {
        await _supabase
            .from('payment_methods')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      final payload = {
        'user_id': userId,
        'type': type.value,
        'is_default': isDefault,
        'is_active': true,
        'card_data': cardData?.toMap(),
        'pix_data': pixData?.toMap(),
      };

      final data = await _supabase
          .from('payment_methods')
          .insert(payload)
          .select()
          .single();

      return PaymentMethod.fromMap(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao adicionar método de pagamento. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao adicionar método de pagamento. Por favor, tente novamente mais tarde.');
    }
  }

  Future<bool> hasEnoughBalance(String passengerId, double amount) async {
    final wallet = await getPassengerWallet(passengerId);
    return wallet != null && wallet.availableBalance >= amount;
  }

  Future<Map<String, dynamic>> getPassengerWalletSummary(String passengerId) async {
    final wallet = await getPassengerWallet(passengerId);
    if (wallet == null) return {};

    try {
      // Get recent transactions count
      final recentTransactions = await _supabase
          .from('passenger_wallet_transactions')
          .select()
          .eq('passenger_id', passengerId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      return {
        'available_balance': wallet.availableBalance,
        'pending_balance': wallet.pendingBalance,
        'total_spent': wallet.totalSpent,
        'total_cashback': wallet.totalCashback,
        'recent_transactions_count': recentTransactions.length,
      };
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar resumo da carteira. Por favor, tente novamente mais tarde.', e.code);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar resumo da carteira. Por favor, tente novamente mais tarde.');
    }
  }
}