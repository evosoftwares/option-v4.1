import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_handling/postgrest_error_mapper.dart';
import '../core/error_handling/error_logger.dart';
import '../core/error_handling/app_error.dart';
import '../core/resilience/resilient_supabase_client.dart';
import '../core/resilience/network_error_interceptor.dart';
import '../../domain/exceptions/app_exceptions.dart';
import '../../domain/exceptions/wallet_exceptions.dart';
import '../../data/models/passenger_wallet.dart';
import '../../data/models/passenger_wallet_transaction.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/user.dart' as app_user;
import 'asaas_service.dart';
import 'security_service.dart';
import 'auth_service.dart';
import 'wallet_logger.dart';
import 'app_logger.dart';
import 'platform_settings_service.dart';

class WalletService {

  WalletService({SupabaseClient? client, AsaasService? asaas})
      : _supabase = client ?? Supabase.instance.client,
        _asaas = asaas ?? AsaasService(),
        _networkInterceptor = NetworkErrorInterceptor() {
    _initializeResilientClient();
  }
  
  final SupabaseClient _supabase;
  final AsaasService _asaas;
  final NetworkErrorInterceptor _networkInterceptor;
  late final ResilientSupabaseClient _resilientClient;
  
  /// Inicializa o cliente resiliente
  Future<void> _initializeResilientClient() async {
    _resilientClient = ResilientSupabaseClient(
      client: _supabase,
      config: const ResilientClientConfig(
        enableCache: true,
        cacheExpiration: Duration(minutes: 2),
        enableOfflineMode: true,
        enableFallback: true,
      ),
    );
    await _resilientClient.initialize();
  }

  /// Busca o ID do motorista para um usuário com validações de segurança
  Future<String?> getDriverIdForUser(String userId) async {
    final startTime = DateTime.now();
    
    try {
      AppLogger.process('Buscando ID do motorista para usuário', tag: 'WALLET_SERVICE');
      AppLogger.query('drivers', 1, tag: 'WALLET_SERVICE', filters: {'user_id': userId});
      
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        AppLogger.security('wallet_access_unauthorized', details: 'User not authenticated');
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Validar se o usuário pode acessar este recurso
      await AuthService.validateUserAccess(
        resourceUserId: userId,
        operation: 'read_driver_info',
      );
      
      AppLogger.security('wallet_driver_access_validated', userId: currentUserId);
      
      // Usar cliente resiliente com cache e retry
      final data = await _resilientClient.select(
        'drivers',
        select: 'id',
        filters: {'user_id': userId},
        limit: 1,
        operationName: 'get_driver_by_user',
      ).then((results) => results.isNotEmpty ? results.first : null);
      
      if (data != null) {
        final driverId = data['id'] as String;
        final duration = DateTime.now().difference(startTime);
        
        AppLogger.performance('get_driver_id', duration, tag: 'WALLET_SERVICE');
        AppLogger.success('ID do motorista encontrado', tag: 'WALLET_SERVICE');
        AppLogger.read('Driver', driverId, tag: 'WALLET_SERVICE');
        
        return driverId;
      }
      
      // If no driver record found, try to create one automatically
      return await _autoCreateDriverRecord(userId);
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

  /// Busca a carteira do motorista com validações de segurança
  Future<Map<String, dynamic>?> getDriverWallet(String driverId) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Buscar o user_id do motorista para validação
      final driverData = await _resilientClient.select(
        'drivers',
        select: 'user_id',
        filters: {'id': driverId},
        limit: 1,
        operationName: 'get_driver_user_id',
      ).then((results) => results.isNotEmpty ? results.first : null);
      
      if (driverData == null) {
        throw const DatabaseException('Motorista não encontrado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: driverData['user_id'],
        operation: 'read_wallet',
      );
      final data = await _resilientClient.select(
        'driver_wallets',
        filters: {'driver_id': driverId},
        limit: 1,
        operationName: 'get_driver_wallet',
      ).then((results) => results.isNotEmpty ? results.first : null);
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'DRIVER_WALLET_ACCESSED',
        description: 'Carteira do motorista acessada',
        metadata: {
          'driver_id': driverId,
          'driver_user_id': driverData['user_id'],
        },
      );
      
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
      final userData = await _resilientClient.select(
        'app_users',
        select: 'user_type, email, full_name',
        filters: {'id': userId},
        limit: 1,
        operationName: 'get_user_type',
      ).then((results) => results.isNotEmpty ? results.first : null);
      
      if (userData == null || userData['user_type']?.toLowerCase() != 'driver') {
        return null; // User is not a driver, so no driver record needed
      }
      
      print('🔧 Criando registro de motorista automaticamente para usuário: $userId');
      
      // Get first available category from platform_settings instead of hardcoded value
      String defaultCategory = 'common_car'; // fallback
      try {
        final platformSettingsService = PlatformSettingsService(_supabase);
        final availableSettings = await platformSettingsService.getAllSettings();
        if (availableSettings.isNotEmpty) {
          defaultCategory = availableSettings.first.category;
          print('✅ Usando categoria do platform_settings: $defaultCategory');
        } else {
          print('⚠️ Platform_settings vazio, usando fallback: $defaultCategory');
        }
      } catch (e) {
        print('⚠️ Erro ao buscar platform_settings, usando fallback: $e');
      }
      
      // Criar registro de driver básico
      final driverData = {
        'user_id': userId,
        'vehicle_brand': 'PENDENTE',
        'vehicle_model': 'PENDENTE',
        'vehicle_year': 2020,
        'vehicle_color': 'PENDENTE',
        'vehicle_plate': 'PENDENTE_${userId.substring(0, 8)}',
        'vehicle_category': defaultCategory,
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

      final result = await _resilientClient.insert(
        'drivers',
        driverData,
        operationName: 'auto_create_driver',
      );
          
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

  /// Busca transações da carteira com validações de segurança
  Future<List<Map<String, dynamic>>> getWalletTransactions(String driverId, {int limit = 50}) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Buscar o user_id do motorista para validação
      final driverData = await _resilientClient.select(
        'drivers',
        select: 'user_id',
        filters: {'id': driverId},
        limit: 1,
        operationName: 'get_driver_for_transactions',
      ).then((results) => results.isNotEmpty ? results.first : null);
      
      if (driverData == null) {
        throw const DatabaseException('Motorista não encontrado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: driverData['user_id'],
        operation: 'read_wallet_transactions',
      );
      
      final data = await _resilientClient.select(
        'wallet_transactions',
        filters: {'wallet_id': driverId},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
        operationName: 'get_wallet_transactions',
      );
      
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'WALLET_TRANSACTIONS_ACCESSED',
        description: 'Transações da carteira acessadas',
        metadata: {
          'driver_id': driverId,
          'driver_user_id': driverData['user_id'],
          'limit': limit,
        },
      );
      
      return (data as List<dynamic>)
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              throw Exception('Tipo de item inesperado nas transações: ${item.runtimeType}');
            }
          })
          .toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getWalletTransactions', 'driverId': driverId});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar transações. Por favor, tente novamente mais tarde.');
    }
  }

  Future<void> ensureAsaasCustomerForUser(app_user.User user) async {
    try {
      // Verificar se as credenciais do Asaas estão configuradas
      if (_asaas.baseUrl.isEmpty || _asaas.headers['access_token']?.isEmpty == true) {
        print('⚠️ Credenciais do Asaas não configuradas. Pulando criação de cliente.');
        return; // Não falhar, apenas pular a criação
      }
      
      await _asaas.ensureCustomer(
        name: user.fullName,
        email: user.email,
        mobilePhone: user.phone,
      );
    } catch (e) {
      // Log do erro mas não propagar para não travar a UI
      print('❌ Erro ao garantir cliente Asaas: $e');
      // Não rethrow para evitar travamento da tela
    }
  }

  /// Solicita saque com validações de segurança
  Future<Map<String, dynamic>> requestWithdrawal({
    required String driverId,
    required double amount,
    String method = 'pix',
    Map<String, dynamic>? bankAccountInfo,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Buscar o user_id do motorista para validação
      final driverData = await _resilientClient.select(
        'drivers',
        select: 'user_id',
        filters: {'id': driverId},
        limit: 1,
        operationName: 'get_driver_for_withdrawal',
      ).then((results) => results.isNotEmpty ? results.first : null);
      
      if (driverData == null) {
        throw const DatabaseException('Motorista não encontrado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: driverData['user_id'],
        operation: 'request_withdrawal',
      );
      
      final payload = {
        'driver_id': driverId,
        'wallet_id': driverId,
        'amount': amount,
        'withdrawal_method': method,
        'bank_account_info': bankAccountInfo,
        'status': 'requested',
        'requested_at': DateTime.now().toIso8601String(),
      };
      
      final data = await _resilientClient.insert(
        'withdrawals',
        payload,
        operationName: 'request_withdrawal',
      );
      
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'WITHDRAWAL_REQUESTED',
        description: 'Saque solicitado',
        metadata: {
          'driver_id': driverId,
          'driver_user_id': driverData['user_id'],
          'amount': amount,
          'method': method,
          'withdrawal_id': data['id'],
        },
      );
      
      // Log específico da carteira
      await WalletLogger().logWithdrawalRequested(
        walletId: driverId,
        userId: driverData['user_id'],
        amount: amount,
        method: method,
        withdrawalId: data['id'],
        additionalContext: {
          'bank_account_info_provided': bankAccountInfo != null,
        },
      );
      
      return data;
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'requestWithdrawal', 'driverId': driverId, 'amount': amount});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao solicitar saque. Por favor, tente novamente mais tarde.');
    }
  }

  // ========== PASSENGER WALLET METHODS ==========

  /// Busca o ID do passageiro para um usuário com validações de segurança
  Future<String?> getPassengerIdForUser(String userId) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Validar se o usuário pode acessar este recurso
      await AuthService.validateUserAccess(
        resourceUserId: userId,
        operation: 'read_passenger_info',
      );
      // First, try to find existing passenger record
      final data = await _resilientClient.select(
        'passengers',
        select: 'id',
        filters: {'user_id': userId},
        limit: 1,
        operationName: 'get_passenger_by_user',
      ).then((results) => results.isNotEmpty ? results.first : null);
          
      if (data != null) {
        return data['id'] as String;
      }
      
      // If no passenger record exists, check if this is a passenger-type user
      // and auto-create the missing passenger record
      return await _autoCreateMissingPassengerRecord(userId);
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

  /// Busca a carteira do passageiro com validações de segurança
  Future<PassengerWallet?> getPassengerWallet(String passengerId) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Buscar o user_id do passageiro para validação
      final passengerData = await _resilientClient.select(
        'passengers',
        select: 'user_id',
        filters: {'id': passengerId},
        limit: 1,
        operationName: 'get_passenger_user_id',
      ).then((results) => results.isNotEmpty ? results.first : null);
      
      if (passengerData == null) {
        throw const DatabaseException('Passageiro não encontrado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: passengerData['user_id'],
        operation: 'read_passenger_wallet',
      );
      final data = await _resilientClient.select(
        'passenger_wallets',
        filters: {'passenger_id': passengerId},
        limit: 1,
        operationName: 'get_passenger_wallet',
      ).then((results) => results.isNotEmpty ? results.first : null);
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PASSENGER_WALLET_ACCESSED',
        description: 'Carteira do passageiro acessada',
        metadata: {
          'passenger_id': passengerId,
          'passenger_user_id': passengerData['user_id'],
        },
      );
      
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
      final data = await _resilientClient.insert(
        'passenger_wallets',
        payload,
        operationName: 'create_passenger_wallet',
      );
      return PassengerWallet.fromMap(data);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'createPassengerWallet', 'passengerId': passengerId, 'userId': userId});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao criar carteira. Por favor, tente novamente mais tarde.');
    }
  }

  /// Busca transações da carteira do passageiro com validações de segurança
  Future<List<PassengerWalletTransaction>> getPassengerWalletTransactions(
    String passengerId, {
    int limit = 50,
    int page = 0,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Buscar o user_id do passageiro para validação
      final passengerData = await _supabase
          .from('passengers')
          .select('user_id')
          .eq('id', passengerId)
          .maybeSingle();
      
      if (passengerData == null) {
        throw const DatabaseException('Passageiro não encontrado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: passengerData['user_id'],
        operation: 'read_passenger_wallet_transactions',
      );
      final offset = page * limit;
      final data = await _supabase
          .from('passenger_wallet_transactions')
          .select()
          .eq('passenger_id', passengerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PASSENGER_WALLET_TRANSACTIONS_ACCESSED',
        description: 'Transações da carteira do passageiro acessadas',
        metadata: {
          'passenger_id': passengerId,
          'passenger_user_id': passengerData['user_id'],
          'limit': limit,
          'page': page,
        },
      );
      
      return (data as List)
          .map((item) => PassengerWalletTransaction.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getPassengerWalletTransactions', 'passengerId': passengerId, 'limit': limit, 'page': page});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar transações. Por favor, tente novamente mais tarde.');
    }
  }

  /// Adiciona crédito à carteira do passageiro com validações de segurança
  Future<PassengerWalletTransaction> addCredit({
    required String passengerId,
    required double amount,
    required String description,
    String? paymentMethodId,
    String? asaasPaymentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Buscar o user_id do passageiro para validação
      final passengerData = await _supabase
          .from('passengers')
          .select('user_id')
          .eq('id', passengerId)
          .maybeSingle();
      
      if (passengerData == null) {
        throw const DatabaseException('Passageiro não encontrado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: passengerData['user_id'],
        operation: 'add_credit',
      );
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

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'CREDIT_ADDED',
        description: 'Crédito adicionado à carteira do passageiro',
        metadata: {
          'passenger_id': passengerId,
          'passenger_user_id': passengerData['user_id'],
          'amount': amount,
          'description': description,
          'payment_method_id': paymentMethodId,
          'asaas_payment_id': asaasPaymentId,
          'transaction_id': transactionData['id'],
        },
      );
      
      // Log específico da carteira
      await WalletLogger().logPassengerCreditAdded(
        passengerId: passengerId,
        userId: passengerData['user_id'],
        amount: amount,
        description: description,
        transactionId: transactionData['id'],
        additionalContext: {
          'payment_method_id': paymentMethodId,
          'asaas_payment_id': asaasPaymentId,
        },
      );
      
      return PassengerWalletTransaction.fromMap(transactionData);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'addCredit', 'passengerId': passengerId, 'amount': amount});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao adicionar crédito. Por favor, tente novamente mais tarde.');
    }
  }

  /// Debita valor da carteira do passageiro para pagamento de viagem com validações de segurança
  Future<PassengerWalletTransaction> debitTrip({
    required String passengerId,
    required String tripId,
    required double amount,
    String description = 'Pagamento de viagem',
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Buscar o user_id do passageiro para validação
      final passengerData = await _supabase
          .from('passengers')
          .select('user_id')
          .eq('id', passengerId)
          .maybeSingle();
      
      if (passengerData == null) {
        throw const DatabaseException('Passageiro não encontrado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: passengerData['user_id'],
        operation: 'debit_trip_payment',
      );
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

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'TRIP_PAYMENT_DEBITED',
        description: 'Pagamento de viagem debitado da carteira do passageiro',
        metadata: {
          'passenger_id': passengerId,
          'passenger_user_id': passengerData['user_id'],
          'trip_id': tripId,
          'amount': amount,
          'description': description,
          'transaction_id': transactionData['id'],
        },
      );
      
      // Log específico da carteira
      await WalletLogger().logPassengerDebit(
        passengerId: passengerId,
        userId: passengerData['user_id'],
        tripId: tripId,
        amount: amount,
        description: description,
        transactionId: transactionData['id'],
      );
      
      return PassengerWalletTransaction.fromMap(transactionData);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'debitTrip', 'passengerId': passengerId, 'tripId': tripId, 'amount': amount});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao debitar viagem. Por favor, tente novamente mais tarde.');
    }
  }



  /// Busca métodos de pagamento com validações de segurança
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: userId,
        operation: 'read_payment_methods',
      );
      final data = await _supabase
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PAYMENT_METHODS_ACCESSED',
        description: 'Métodos de pagamento acessados',
        metadata: {
          'user_id': userId,
          'methods_count': (data as List).length,
        },
      );
      
      return (data as List)
          .map((item) => PaymentMethod.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getPaymentMethods', 'userId': userId});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar métodos de pagamento. Por favor, tente novamente mais tarde.');
    }
  }

  /// Adiciona método de pagamento com validações de segurança
  Future<PaymentMethod> addPaymentMethod({
    required String userId,
    required PaymentMethodType type,
    CardData? cardData,
    PixData? pixData,
    bool isDefault = false,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      // Validar acesso
      await AuthService.validateUserAccess(
        resourceUserId: userId,
        operation: 'add_payment_method',
      );
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

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'PAYMENT_METHOD_ADDED',
        description: 'Método de pagamento adicionado',
        metadata: {
          'user_id': userId,
          'payment_method_type': type.value,
          'is_default': isDefault,
          'payment_method_id': data['id'],
        },
      );
      
      return PaymentMethod.fromMap(data);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'addPaymentMethod', 'userId': userId, 'type': type.value});
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao adicionar método de pagamento. Por favor, tente novamente mais tarde.');
    }
  }

  /// Verifica se o passageiro tem saldo suficiente com validações de segurança
  Future<bool> hasEnoughBalance(String passengerId, double amount) async {
    // Validações de segurança
    if (!AuthService.isAuthenticated()) {
      throw const UnauthorizedException('Usuário não autenticado');
    }
    
    // Buscar o user_id do passageiro para validação
    final passengerData = await _supabase
        .from('passengers')
        .select('user_id')
        .eq('id', passengerId)
        .maybeSingle();
    
    if (passengerData == null) {
      throw const DatabaseException('Passageiro não encontrado');
    }
    
    // Validar acesso
    await AuthService.validateUserAccess(
      resourceUserId: passengerData['user_id'],
      operation: 'check_balance',
    );
    
    final wallet = await getPassengerWallet(passengerId);
    return wallet != null && wallet.availableBalance >= amount;
  }

  /// Busca resumo da carteira do passageiro com validações de segurança
  Future<Map<String, dynamic>> getPassengerWalletSummary(String passengerId) async {
    // Validações de segurança
    if (!AuthService.isAuthenticated()) {
      throw const UnauthorizedException('Usuário não autenticado');
    }
    
    // Buscar o user_id do passageiro para validação
    final passengerData = await _supabase
        .from('passengers')
        .select('user_id')
        .eq('id', passengerId)
        .maybeSingle();
    
    if (passengerData == null) {
      throw const DatabaseException('Passageiro não encontrado');
    }
    
    // Validar acesso
    await AuthService.validateUserAccess(
      resourceUserId: passengerData['user_id'],
      operation: 'read_wallet_summary',
    );
    
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
        
        // Log específico da carteira para saque bloqueado
        await WalletLogger().logWithdrawalBlocked(
          userId: passengerId,
          reason: securityCheck.reason,
          blockType: securityCheck.type.name,
          amount: amount,
          pixKey: pixKey,
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
        // Log específico da carteira para atividade suspeita
        await WalletLogger().logSuspiciousActivity(
          userId: passengerId,
          activityType: 'withdrawal_attempt',
          additionalContext: {
            'amount': amount,
            'pix_key': pixKey,
          },
        );
        
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
      
      // Log específico da carteira para saque solicitado
      await WalletLogger().logWithdrawalRequested(
        walletId: wallet.id,
        userId: passengerId,
        amount: amount,
        method: 'pix',
        withdrawalId: response['id'],
        additionalContext: {
          'pix_key': pixKey,
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