import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/passenger_wallet_transaction.dart';
import 'driver_wallet_service.dart';
import 'passenger_payment_service.dart';
import 'wallet_service.dart';

/// Resultado do processamento de pagamento de viagem
class TripPaymentResult {
  const TripPaymentResult({
    required this.passengerTransaction,
    required this.driverEarnings,
    required this.platformCommission,
    required this.success,
    this.errorMessage,
  });

  final PassengerWalletTransaction passengerTransaction;
  final double driverEarnings;
  final double platformCommission;
  final bool success;
  final String? errorMessage;
}

/// Serviço centralizado para processamento de pagamentos de viagem
class PaymentProcessorService {
  PaymentProcessorService({
    SupabaseClient? client,
    WalletService? walletService,
    PassengerPaymentService? passengerPaymentService,
  }) : _supabase = client ?? Supabase.instance.client,
       _walletService = walletService ?? WalletService(),
       _passengerPaymentService = passengerPaymentService ?? PassengerPaymentService();

  final SupabaseClient _supabase;
  final WalletService _walletService;
  final PassengerPaymentService _passengerPaymentService;

  /// Comissão da plataforma (10%)
  static const double platformCommissionRate = 0.10;

  /// Processa pagamento completo da viagem
  /// Debita do passageiro e credita o motorista com desconto da comissão
  Future<TripPaymentResult> processTripPayment({
    required String tripId,
    required String passengerId,
    required String driverId,
    required double totalAmount,
    String? promoCodeId,
    double? discountApplied,

  }) async {
    try {
      print('💳 [${DateTime.now()}] Iniciando processamento de pagamento');
      print('   📍 Trip ID: $tripId');
      print('   💰 Valor total: R\$ ${totalAmount.toStringAsFixed(2)}');
      
      // 1. Calcular valor final após desconto
      final finalAmount = discountApplied != null 
          ? (totalAmount - discountApplied).clamp(0.0, totalAmount)
          : totalAmount;
      
      print('   💸 Valor final (após desconto): R\$ ${finalAmount.toStringAsFixed(2)}');
      
      // 2. Verificar se passageiro tem saldo suficiente
      final hasBalance = await _walletService.hasEnoughBalance(passengerId, finalAmount);
      if (!hasBalance) {
        throw const DatabaseException('Saldo insuficiente na carteira do passageiro');
      }
      
      // 3. Processar pagamento do passageiro
    final passengerTransaction = await _passengerPaymentService.processTripPayment(
      passengerId: passengerId,
      tripId: tripId,
      amount: totalAmount,
        promoCodeId: promoCodeId,
        discountApplied: discountApplied,
      );
      
      // 4. Calcular ganhos do motorista (após comissão)
      final platformCommission = totalAmount * platformCommissionRate;
      final driverEarnings = totalAmount - platformCommission;
      
      print('   🏦 Comissão da plataforma: R\$ ${platformCommission.toStringAsFixed(2)}');
      print('   🚗 Ganhos do motorista: R\$ ${driverEarnings.toStringAsFixed(2)}');
      
      // 5. Creditar ganhos do motorista
      await DriverWalletService.processTripPayment(
        driverId: driverId,
        tripId: tripId,
        tripAmount: totalAmount,
      );
      
      // 6. Atualizar status de pagamento da viagem
      await _updateTripPaymentStatus(tripId, 'completed');
      
      print('✅ [${DateTime.now()}] Pagamento processado com sucesso');
      
      return TripPaymentResult(
        passengerTransaction: passengerTransaction,
        driverEarnings: driverEarnings,
        platformCommission: platformCommission,
        success: true,
      );
      
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro no processamento: $e');
      
      // Tentar reverter transações se necessário
      await _handlePaymentFailure(tripId, e.toString());
      
      if (e is AppException) rethrow;
      throw DatabaseException('Erro ao processar pagamento da viagem: $e');
    }
  }

  /// Processa reembolso em caso de cancelamento
  Future<void> processRefund({
    required String tripId,
    required String passengerId,
    required double amount,
    required String reason,
  }) async {
    try {
      print('💰 [${DateTime.now()}] Processando reembolso: R\$ ${amount.toStringAsFixed(2)}');
      
      // Adicionar crédito de volta à carteira do passageiro
      await _walletService.addCredit(
        passengerId: passengerId,
        amount: amount,
        description: 'Reembolso - $reason (Viagem: $tripId)',
        metadata: {
          'trip_id': tripId,
          'refund_reason': reason,
          'refund_type': 'trip_cancellation',
        },
      );
      
      // Atualizar status de pagamento
      await _updateTripPaymentStatus(tripId, 'refunded');
      
      print('✅ [${DateTime.now()}] Reembolso processado com sucesso');
      
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro no reembolso: $e');
      if (e is AppException) rethrow;
      throw DatabaseException('Erro ao processar reembolso: $e');
    }
  }

  /// Atualiza o status de pagamento da viagem
  Future<void> _updateTripPaymentStatus(String tripId, String status) async {
    try {
      await _supabase
          .from('trips')
          .update({
            'payment_status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);
    } catch (e) {
      print('⚠️ [${DateTime.now()}] Erro ao atualizar status de pagamento: $e');
      // Não propagar erro, pois é uma operação secundária
    }
  }

  /// Trata falhas no processamento de pagamento
  Future<void> _handlePaymentFailure(String tripId, String error) async {
    try {
      await _updateTripPaymentStatus(tripId, 'failed');
      
      // Log do erro para auditoria
      print('🔍 [${DateTime.now()}] Falha registrada para viagem $tripId: $error');
      
    } catch (e) {
      print('⚠️ [${DateTime.now()}] Erro ao registrar falha: $e');
    }
  }

  /// Verifica se uma viagem pode ser paga
  Future<bool> canProcessPayment({
    required String passengerId,
    required double amount,
  }) async {
    try {
      return await _walletService.hasEnoughBalance(passengerId, amount);
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro ao verificar saldo: $e');
      return false;
    }
  }

  /// Obtém estatísticas de pagamento para uma viagem
  Future<Map<String, dynamic>> getTripPaymentStats(String tripId) async {
    try {
      final tripData = await _supabase
          .from('trips')
          .select('total_amount, payment_status, created_at')
          .eq('id', tripId)
          .single();

      final totalAmount = (tripData['total_amount'] as num).toDouble();
      final platformCommission = totalAmount * platformCommissionRate;
      final driverEarnings = totalAmount - platformCommission;

      return {
        'trip_id': tripId,
        'total_amount': totalAmount,
        'platform_commission': platformCommission,
        'driver_earnings': driverEarnings,
        'commission_rate': platformCommissionRate,
        'payment_status': tripData['payment_status'],
        'created_at': tripData['created_at'],
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Erro ao obter estatísticas de pagamento: $e');
    }
  }
}