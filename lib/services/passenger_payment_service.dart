import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user.dart' as app_user;
import '../models/passenger_wallet_transaction.dart';
import '../models/payment_method.dart';
import 'asaas_service.dart';
import 'wallet_service.dart';

class PassengerPaymentService {
  PassengerPaymentService({
    SupabaseClient? client,
    AsaasService? asaasService,
    WalletService? walletService,
    http.Client? httpClient,
  }) : _supabase = client ?? Supabase.instance.client,
       _asaas = asaasService ?? AsaasService(),
       _wallet = walletService ?? WalletService(),
       _http = httpClient ?? http.Client();

  final SupabaseClient _supabase;
  final AsaasService _asaas;
  final WalletService _wallet;
  final http.Client _http;

  /// Create a payment for adding credit to passenger wallet
  Future<Map<String, dynamic>> createCreditPayment({
    required String passengerId,
    required app_user.User user,
    required double amount,
    required PaymentMethodType paymentMethod,
    String? description,
  }) async {
    try {
      // Ensure Asaas customer exists
      final customer = await _asaas.ensureCustomer(
        name: user.fullName,
        email: user.email,
        mobilePhone: user.phone,
      );

      final customerId = customer['id'] as String;
      
      switch (paymentMethod) {
        case PaymentMethodType.pix:
          return await _createPixPayment(
            customerId: customerId,
            amount: amount,
            description: description ?? 'Recarga de carteira',
            passengerId: passengerId,
          );
        // case PaymentMethodType.creditCard: // Removido: não suportado
        // case PaymentMethodType.debitCard: // Removido: não suportado
        case PaymentMethodType.wallet:
          throw const DatabaseException('Não é possível adicionar crédito usando a própria carteira');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erro ao processar pagamento: $e');
    }
  }

  /// Create PIX payment using Asaas
  Future<Map<String, dynamic>> _createPixPayment({
    required String customerId,
    required double amount,
    required String description,
    required String passengerId,
  }) async {
    try {
      // Create payment using AsaasService
      final paymentData = await _asaas.createPixPayment(
        customerId: customerId,
        amount: amount,
        description: description,
        dueInMinutes: 30,
        externalReference: 'wallet-credit-$passengerId-${DateTime.now().millisecondsSinceEpoch}',
      );

      final paymentId = paymentData['id'] as String;

      // Get PIX QR Code
      final pixData = await _asaas.getPixQrCode(paymentId);
      if (pixData != null) {
        paymentData['pixQrCode'] = pixData;
      }

      // Store pending transaction in our database
      await _storePendingTransaction(
        passengerId: passengerId,
        amount: amount,
        description: description,
        asaasPaymentId: paymentId,
        paymentData: paymentData,
      );

      return {
        'payment_id': paymentId,
        'amount': amount,
        'payment_method': 'pix',
        'status': 'pending',
        'qr_code': paymentData['pixQrCode']?['encodedImage'],
        'pix_copy_paste': paymentData['pixQrCode']?['payload'],
        'expires_at': paymentData['dueDate'],
        'asaas_data': paymentData,
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erro ao criar pagamento PIX: $e');
    }
  }

  /// Store a pending transaction while payment is being processed
  Future<void> _storePendingTransaction({
    required String passengerId,
    required double amount,
    required String description,
    required String asaasPaymentId,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final payload = {
        'wallet_id': passengerId,
        'passenger_id': passengerId,
        'type': TransactionType.credit.value,
        'amount': amount,
        'description': description,
        'asaas_payment_id': asaasPaymentId,
        'status': TransactionStatus.pending.value,
        'metadata': {
          'payment_method': 'pix',
          'asaas_data': paymentData,
        },
      };

      await _supabase
          .from('passenger_wallet_transactions')
          .insert(payload);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao armazenar transação pendente', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao armazenar transação pendente: $e');
    }
  }

  /// Process webhook notification from Asaas
  Future<void> processPaymentWebhook(Map<String, dynamic> webhookData) async {
    try {
      final payment = webhookData['payment'] as Map<String, dynamic>?;
      
      if (payment == null) return;
      
      final asaasPaymentId = payment['id'] as String;
      final status = payment['status'] as String;

      // Find the pending transaction
      final transactionData = await _supabase
          .from('passenger_wallet_transactions')
          .select()
          .eq('asaas_payment_id', asaasPaymentId)
          .eq('status', TransactionStatus.pending.value)
          .maybeSingle();

      if (transactionData == null) return;

      final transaction = PassengerWalletTransaction.fromMap(transactionData);

      switch (status) {
        case 'CONFIRMED':
        case 'RECEIVED':
          await _confirmPayment(transaction);
          break;
        case 'REFUNDED':
        case 'CANCELLED':
          await _cancelPayment(transaction);
          break;
        default:
          // Update status but don't process
          await _updateTransactionStatus(transaction.id, TransactionStatus.processing);
      }
    } catch (e) {
      // Log error but don't throw to avoid webhook failures
      print('Error processing payment webhook: $e');
    }
  }

  /// Confirm payment and add credit to wallet
  Future<void> _confirmPayment(PassengerWalletTransaction transaction) async {
    try {
      // Update transaction status to completed
      await _supabase
          .from('passenger_wallet_transactions')
          .update({
            'status': TransactionStatus.completed.value,
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transaction.id);

      // Add credit to wallet balance
      await _supabase
          .from('passenger_wallets')
          .update({
            'available_balance': 'available_balance + ${transaction.amount}',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('passenger_id', transaction.passengerId);

    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao confirmar pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao confirmar pagamento: $e');
    }
  }

  /// Cancel payment
  Future<void> _cancelPayment(PassengerWalletTransaction transaction) async {
    try {
      await _supabase
          .from('passenger_wallet_transactions')
          .update({
            'status': TransactionStatus.cancelled.value,
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transaction.id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao cancelar pagamento', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao cancelar pagamento: $e');
    }
  }

  /// Update transaction status
  Future<void> _updateTransactionStatus(String transactionId, TransactionStatus status) async {
    try {
      await _supabase
          .from('passenger_wallet_transactions')
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao atualizar status da transação', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao atualizar status da transação: $e');
    }
  }

  /// Check payment status from Asaas
  Future<Map<String, dynamic>> checkPaymentStatus(String asaasPaymentId) async {
    try {
      final response = await _http.get(
        Uri.parse('https://sandbox.asaas.com/api/v3/payments/$asaasPaymentId'), // TODO: Use config
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'access_token': 'YOUR_ASAAS_API_KEY', // TODO: Use config
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw NetworkException('Erro ao consultar status do pagamento');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Erro ao consultar status do pagamento: $e');
    }
  }

  /// Get pending payments for a passenger
  Future<List<PassengerWalletTransaction>> getPendingPayments(String passengerId) async {
    try {
      final data = await _supabase
          .from('passenger_wallet_transactions')
          .select()
          .eq('passenger_id', passengerId)
          .eq('type', TransactionType.credit.value)
          .inFilter('status', [TransactionStatus.pending.value, TransactionStatus.processing.value])
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => PassengerWalletTransaction.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar pagamentos pendentes', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar pagamentos pendentes: $e');
    }
  }

  /// Calculate cashback for a trip
  double calculateCashback(double tripAmount, {double percentage = 0.02}) {
    return tripAmount * percentage;
  }

  /// Process trip payment using wallet balance
  Future<PassengerWalletTransaction> processTripPayment({
    required String passengerId,
    required String tripId,
    required double amount,
    bool applyCashback = true,
    String? promoCodeId,
    double? discountApplied,
  }) async {
    try {
      // Calculate final amount after discount
      final finalAmount = discountApplied != null 
          ? (amount - discountApplied).clamp(0.0, amount)
          : amount;
      
      // Check if passenger has enough balance for final amount
      final hasBalance = await _wallet.hasEnoughBalance(passengerId, finalAmount);
      if (!hasBalance) {
        throw const DatabaseException('Saldo insuficiente na carteira');
      }

      // Register promo code usage if applicable
      if (promoCodeId != null && discountApplied != null && discountApplied > 0) {
        await _registerPromoCodeUsage(passengerId, promoCodeId, tripId);
      }

      // Debit final amount (with discount applied)
      final transaction = await _wallet.debitTrip(
        passengerId: passengerId,
        tripId: tripId,
        amount: finalAmount,
      );

      // Add cashback if enabled
      if (applyCashback) {
        final cashbackAmount = calculateCashback(amount);
        if (cashbackAmount > 0.01) { // Only add cashback if more than 1 cent
          await _wallet.addCashback(
            passengerId: passengerId,
            amount: cashbackAmount,
            description: 'Cashback da viagem',
            tripId: tripId,
          );
        }
      }

      return transaction;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Erro ao processar pagamento da viagem: $e');
    }
  }

  /// Refund a trip payment
  Future<PassengerWalletTransaction> refundTripPayment({
    required String passengerId,
    required String tripId,
    required double amount,
    String reason = 'Reembolso de viagem',
  }) async {
    try {
      final walletId = passengerId;
      final payload = {
        'wallet_id': walletId,
        'passenger_id': passengerId,
        'type': TransactionType.refund.value,
        'amount': amount,
        'description': reason,
        'trip_id': tripId,
        'status': TransactionStatus.completed.value,
        'processed_at': DateTime.now().toIso8601String(),
      };

      final transactionData = await _supabase
          .from('passenger_wallet_transactions')
          .insert(payload)
          .select()
          .single();

      // Add refund to wallet balance
      await _supabase
          .from('passenger_wallets')
          .update({
            'available_balance': 'available_balance + $amount',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('passenger_id', passengerId);

      return PassengerWalletTransaction.fromMap(transactionData);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao processar reembolso', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao processar reembolso: $e');
    }
  }

  /// Register promo code usage
  Future<void> _registerPromoCodeUsage(
    String passengerId,
    String promoCodeId,
    String tripId,
  ) async {
    try {
      // Check if it's a passenger promo code
      final passengerPromo = await _supabase
          .from('passenger_promo_codes')
          .select()
          .eq('id', promoCodeId)
          .maybeSingle();

      if (passengerPromo != null) {
        // Update passenger promo code usage
        await _supabase
            .from('passenger_promo_codes')
            .update({
              'is_used': true,
              'used_at': DateTime.now().toIso8601String(),
              'trip_id': tripId,
            })
            .eq('id', promoCodeId);
      } else {
        // It's a general promo code, increment usage count
        await _supabase
            .from('promo_codes')
            .update({
              'current_usage_count': 'current_usage_count + 1',
            })
            .eq('id', promoCodeId);

        // Record the usage in promo_code_usage table if it exists
        await _supabase
            .from('promo_code_usage')
            .insert({
              'promo_code_id': promoCodeId,
              'passenger_id': passengerId,
              'trip_id': tripId,
              'used_at': DateTime.now().toIso8601String(),
            });
      }
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao registrar uso do código promocional', e.code);
    } catch (e) {
      throw DatabaseException('Erro inesperado ao registrar uso do código promocional: $e');
    }
  }
}