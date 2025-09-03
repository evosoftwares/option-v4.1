import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_handling/postgrest_error_mapper.dart';
import '../core/error_handling/error_logger.dart';
import '../core/error_handling/app_error.dart';
import '../exceptions/app_exceptions.dart';
import '../exceptions/wallet_exceptions.dart';
import '../models/passenger_wallet.dart';
import '../models/passenger_wallet_transaction.dart';
import '../models/payment_method.dart';
import '../models/user.dart' as app_user;
import 'asaas_service.dart';
import 'security_service.dart';

class WalletService {

  WalletService({SupabaseClient? client, AsaasService? asaas})
      : _supabase = client ?? Supabase.instance.client,
        _asaas = asaas ?? AsaasService();
  final SupabaseClient _supabase;
  final AsaasService _asaas;

  Future<String?> getDriverIdForUser(String userId) async {
    try {
      // Add timeout to prevent hanging
      final data = await _supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      
      if (data != null) {
        return data['id'] as String;
      }
      
      // If no driver record found, try to create one automatically with timeout
      return await _autoCreateDriverRecord(userId)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      print('❌ Timeout ao buscar/criar motorista para usuário: $userId');
      throw const DatabaseException('Operação demorou muito para completar. Verifique sua conexão e tente novamente.');
    } on PostgrestException catch (e) {
      print('❌ Erro PostgreSQL ao buscar motorista: ${e.code} - ${e.message}');
      final mappedError = PostgrestErrorMapper.mapError(e, context: {
        'operation': 'getDriverIdForUser',
        'userId': userId,
      });
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        mappedError,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'getDriverIdForUser',
          'userId': userId,
          'postgrestCode': e.code,
        },
        severity: ErrorSeverity.medium,
      );
      
      throw mappedError;
    } catch (e) {
      print('❌ Erro inesperado ao buscar motorista: $e');
      final error = DatabaseException('Erro inesperado ao buscar motorista: $e');
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        error,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'getDriverIdForUser',
          'userId': userId,
          'originalError': e.toString(),
        },
        severity: ErrorSeverity.medium,
      );
      
      throw error;
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getDriverWallet', 'driverId': driverId});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar carteira. Por favor, tente novamente mais tarde.');
    }
  }

  /// Automatically creates a driver record if user is a driver but doesn't have one
  Future<String?> _autoCreateDriverRecord(String userId) async {
    try {
      // First check if user is actually a driver
      final userData = await _supabase
          .from('app_users')
          .select('user_type, email, full_name')
          .eq('id', userId)
          .maybeSingle();
      
      if (userData == null || userData['user_type']?.toLowerCase() != 'driver') {
        return null; // User is not a driver, so no driver record needed
      }
      
      print('🔧 Criando registro de motorista automaticamente para usuário: $userId');
      
      // Create basic driver record with placeholder values
      final driverData = {
        'user_id': userId,
        'cnh_number': 'PENDENTE_CADASTRO',
        'cnh_expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
        'cnh_photo_url': '',
        'vehicle_brand': 'PENDENTE',
        'vehicle_model': 'PENDENTE', 
        'vehicle_year': 2020,
        'vehicle_color': 'PENDENTE',
        'vehicle_plate': 'PENDENTE_${userId.substring(0, 8)}',
        'vehicle_category': 'standard',
        'crlv_photo_url': '',
        'approval_status': 'pending',
        'approved_by': null,
        'approved_at': null,
        'is_online': false,
        'accepts_pet': false,
        'pet_fee': 0.0,
        'accepts_grocery': false,
        'grocery_fee': 0.0,
        'accepts_condo': false,
        'condo_fee': 0.0,
        'stop_fee': 0.0,
        'ac_policy': 'on_request',
        'custom_price_per_km': 0.0,
        'custom_price_per_minute': 0.0,
        'bank_account_type': null,
        'bank_code': null,
        'bank_agency': null,
        'bank_account': null,
        'pix_key': '',
        'pix_key_type': 'email',
        'consecutive_cancellations': 0,
        'total_trips': 0,
        'average_rating': null,
        'current_latitude': null,
        'current_longitude': null,
        'last_location_update': null,
      };

      final result = await _supabase
          .from('drivers')
          .insert(driverData)
          .select('id')
          .single();
          
      print('✅ Registro de motorista criado automaticamente com ID: ${result['id']}');
      return result['id'] as String;
      
    } on PostgrestException catch (e) {
      print('❌ Erro ao criar registro de motorista automaticamente: ${e.code} - ${e.message}');
      return null; // Return null instead of throwing to allow graceful fallback
    } catch (e) {
      print('❌ Erro inesperado ao criar registro de motorista: $e');
      return null;
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getWalletTransactions', 'driverId': driverId});
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'requestWithdrawal', 'driverId': driverId, 'amount': amount});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao solicitar saque. Por favor, tente novamente mais tarde.');
    }
  }

  // ========== PASSENGER WALLET METHODS ==========

  Future<String?> getPassengerIdForUser(String userId) async {
    try {
      // First, try to find existing passenger record with timeout
      final data = await _supabase
          .from('passengers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
          
      if (data != null) {
        return data['id'] as String;
      }
      
      // If no passenger record exists, check if this is a passenger-type user
      // and auto-create the missing passenger record with timeout
      return await _autoCreateMissingPassengerRecord(userId)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      print('❌ Timeout ao buscar/criar passageiro para usuário: $userId');
      throw const DatabaseException('Operação demorou muito para completar. Verifique sua conexão e tente novamente.');
    } on PostgrestException catch (e) {
      print('❌ Erro PostgreSQL ao buscar passageiro: ${e.code} - ${e.message}');
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getPassengerIdForUser', 'userId': userId});
    } catch (e) {
      print('❌ Erro inesperado ao buscar passageiro: $e');
      throw DatabaseException('Erro inesperado ao buscar passageiro: $e');
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getPassengerWallet', 'passengerId': passengerId});
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

      };
      final data = await _supabase
          .from('passenger_wallets')
          .insert(payload)
          .select()
          .single();
      return PassengerWallet.fromMap(data);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'createPassengerWallet', 'passengerId': passengerId, 'userId': userId});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao criar carteira. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<PassengerWalletTransaction>> getPassengerWalletTransactions(
    String passengerId, {
    int limit = 50,
    int page = 0,
  }) async {
    try {
      final offset = page * limit;
      final data = await _supabase
          .from('passenger_wallet_transactions')
          .select()
          .eq('passenger_id', passengerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (data as List)
          .map((item) => PassengerWalletTransaction.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getPassengerWalletTransactions', 'passengerId': passengerId, 'limit': limit, 'page': page});
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'addCredit', 'passengerId': passengerId, 'amount': amount});
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'debitTrip', 'passengerId': passengerId, 'tripId': tripId, 'amount': amount});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao debitar viagem. Por favor, tente novamente mais tarde.');
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getPaymentMethods', 'userId': userId});
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'addPaymentMethod', 'userId': userId, 'type': type.value});
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

        'recent_transactions_count': recentTransactions.length,
      };
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getPassengerWalletSummary', 'passengerId': passengerId});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar resumo da carteira. Por favor, tente novamente mais tarde.');
    }
  }

  /// Auto-creates a missing passenger record for passenger-type users
  /// This provides fallback support for existing users who were created before
  /// the passenger record creation logic was implemented
  Future<String?> _autoCreateMissingPassengerRecord(String userId) async {
    try {
      // First, verify this is actually a passenger-type user
      final userResponse = await _supabase
          .from('app_users')
          .select('user_type')
          .eq('user_id', userId)
          .maybeSingle();
          
      if (userResponse == null) {
        print('🚨 User $userId not found in app_users table');
        // User doesn't exist in app_users table, create passenger anyway for flexibility
        // This allows the wallet to work even if app_users is not properly configured
      } else {
        final userType = userResponse['user_type'] as String?;
        print('🔍 User $userId has type: $userType');
        
        // Allow creation for passenger type or if type is null/empty (default to passenger)
        if (userType != null && 
            userType.toLowerCase() != 'passenger' && 
            userType.toLowerCase() != '') {
          print('❌ User type $userType is not passenger, skipping creation');
          return null;
        }
      }
      
      // Create the missing passenger record
      final passengerData = {
        'user_id': userId,
        'consecutive_cancellations': 0,
        'total_trips': 0,
        'average_rating': null,
        'payment_method_id': null,
      };

      final response = await _supabase
          .from('passengers')
          .insert(passengerData)
          .select('id')
          .single();
          
      final passengerId = response['id'] as String;
      
      // The database trigger should automatically create the wallet,
      // but let's log this for monitoring
      print('🆘 Auto-created missing passenger record for user $userId -> passenger $passengerId');
      
      return passengerId;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation - passenger record was created by another process
        // Try to fetch the existing record
        final data = await _supabase
            .from('passengers')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        return data != null ? (data['id'] as String) : null;
      }
      
      print('❌ Failed to auto-create passenger record: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected error auto-creating passenger record: $e');
      return null;
    }
  }

  /// Processa um saque para passageiro
  Future<PassengerWalletTransaction> requestPassengerWithdrawal({
    required String passengerId,
    required double amount,
    required String pixKey,
    String? description,
  }) async {
    final securityService = SecurityService();
    
    try {
      // Verificações de segurança (rate limiting)
      final securityCheck = await securityService.canPerformWithdrawal(passengerId);
      if (!securityCheck.allowed) {
        await securityService.logAuditEvent(
          passengerId: passengerId,
          eventType: 'WITHDRAWAL_BLOCKED',
          description: 'Tentativa de saque bloqueada: ${securityCheck.reason}',
          metadata: {
            'amount': amount,
            'pix_key': pixKey,
            'block_type': securityCheck.type.name,
          },
        );
        
        throw WithdrawalException(
          type: WalletErrorType.rateLimitExceeded,
          details: securityCheck.reason,
          amount: amount,
          pixKey: pixKey,
        );
      }
      
      // Detectar atividade suspeita
      final isSuspicious = await securityService.detectSuspiciousActivity(passengerId);
      if (isSuspicious) {
        throw const WithdrawalException(
          type: WalletErrorType.suspiciousActivity,
          details: 'Atividade suspeita detectada. Tente novamente mais tarde.',
        );
      }
      
      // Validações básicas
      if (amount <= 0) {
        throw const WithdrawalException(
          type: WalletErrorType.invalidAmount,
          details: 'O valor deve ser maior que zero',
        );
      }

      // Verificar se o passageiro tem saldo suficiente
      final wallet = await getPassengerWallet(passengerId);
      if (wallet == null) {
        throw const WithdrawalException(
          type: WalletErrorType.walletNotFound,
          details: 'Carteira do passageiro não encontrada',
        );
      }

      if (wallet.availableBalance < amount) {
        throw WithdrawalException(
          type: WalletErrorType.insufficientBalance,
          details: 'Saldo disponível: R\$ ${wallet.availableBalance.toStringAsFixed(2)}',
          amount: amount,
          pixKey: pixKey,
        );
      }

      // Criar transação de saque
      final transactionData = {
        'id': _generateUuid(),
        'wallet_id': wallet.id,
        'passenger_id': passengerId,
        'type': TransactionType.withdrawal.value,
        'amount': amount,
        'description': description ?? 'Saque via PIX para $pixKey',
        'status': TransactionStatus.pending.value,
        'metadata': {
          'pix_key': pixKey,
          'withdrawal_method': 'pix',
          'requested_at': DateTime.now().toIso8601String(),
        },
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('passenger_wallet_transactions')
          .insert(transactionData)
          .select()
          .single();

      // Atualizar saldo da carteira (debitar o valor)
      final newBalance = wallet.availableBalance - amount;
      await _supabase
          .from('passenger_wallets')
          .update({'available_balance': newBalance})
          .eq('id', wallet.id);

      // Registrar tentativa de saque para rate limiting
      await securityService.recordWithdrawalAttempt(passengerId);
      
      // Log de auditoria para saque bem-sucedido
      await securityService.logAuditEvent(
        passengerId: passengerId,
        eventType: 'WITHDRAWAL_SUCCESS',
        description: 'Saque processado com sucesso',
        metadata: {
          'amount': amount,
          'pix_key': pixKey,
          'transaction_id': response['id'],
          'wallet_id': wallet.id,
        },
      );
      
      print('✅ Saque processado com sucesso: R\$ ${amount.toStringAsFixed(2)} para $pixKey');
      return PassengerWalletTransaction.fromMap(response);
    } catch (e) {
      print('❌ Erro ao processar saque do passageiro: $e');
      
      // Log de auditoria para erro
      await securityService.logAuditEvent(
        passengerId: passengerId,
        eventType: 'WITHDRAWAL_ERROR',
        description: 'Erro ao processar saque: ${e.toString()}',
        metadata: {
          'amount': amount,
          'pix_key': pixKey,
          'error_type': e.runtimeType.toString(),
        },
      );
      
      // Se já é uma WalletException, apenas relança
      if (e is WalletException) {
        rethrow;
      }
      
      // Converte outros erros em WalletException
      throw WalletErrorHandler.handleError(e);
    }
  }

  /// Gera um UUID simples para transações
  String _generateUuid() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'txn_$random';
  }
}