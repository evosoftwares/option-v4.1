import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import 'driver_wallet_service.dart';
import 'passenger_payment_service.dart';
import 'payment_processor_service.dart';
import 'platform_settings_service.dart';
import 'wallet_service.dart';

// Exportar TripPaymentResult do PaymentProcessorService
export 'payment_processor_service.dart' show TripPaymentResult;

/// Serviço para processamento automático de pagamentos de viagem
/// Responsável por debitar passageiro e creditar motorista com cálculo de comissões
class TripPaymentService {
  TripPaymentService({
    SupabaseClient? client,
    WalletService? walletService,
    PassengerPaymentService? passengerPaymentService,
    PaymentProcessorService? paymentProcessor,
    PlatformSettingsService? platformSettingsService,
  }) : _supabase = client ?? Supabase.instance.client,
       _walletService = walletService ?? WalletService(),
       _passengerPaymentService = passengerPaymentService ?? PassengerPaymentService(),
       _paymentProcessor = paymentProcessor ?? PaymentProcessorService(),
       _platformSettingsService = platformSettingsService ?? PlatformSettingsService(Supabase.instance.client);

  final SupabaseClient _supabase;
  final WalletService _walletService;
  final PassengerPaymentService _passengerPaymentService;
  final PaymentProcessorService _paymentProcessor;
  final PlatformSettingsService _platformSettingsService;

  /// Processa pagamento automático da viagem
  /// Debita do passageiro e credita o motorista com desconto da comissão
  Future<TripPaymentResult> processAutomaticTripPayment({
    required String tripId,
    required String passengerId,
    required String driverId,
    required double totalAmount,
    String? promoCodeId,
    double? discountApplied,
    String? vehicleCategory,

  }) async {
    try {
      print('💳 [${DateTime.now()}] Delegando processamento para PaymentProcessorService');
      
      // Usar o PaymentProcessorService centralizado
       final result = await _paymentProcessor.processTripPayment(
         tripId: tripId,
         passengerId: passengerId,
         driverId: driverId,
         totalAmount: totalAmount,
         promoCodeId: promoCodeId,
         discountApplied: discountApplied,
         vehicleCategory: vehicleCategory,
       );
       
       return result;
      
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro no processamento automático: $e');
      if (e is AppException) rethrow;
      throw DatabaseException('Erro ao processar pagamento automático da viagem: $e');
    }
  }
  
  /// Credita ganhos do motorista usando o DriverWalletService
  Future<void> _creditDriverEarnings({
    required String driverId,
    required double amount,
    required String tripId,
    required String description,
  }) async {
    try {
      // Usar o DriverWalletService para creditar o motorista
      await DriverWalletService.addDriverEarnings(
        driverId: driverId,
        amount: amount,
        description: description,
        referenceType: 'trip',
        referenceId: tripId,
      );
      
      print('✅ [${DateTime.now()}] Ganhos creditados ao motorista: R\$ ${amount.toStringAsFixed(2)}');
      
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro ao creditar motorista: $e');
      throw DatabaseException('Erro ao creditar ganhos do motorista: $e');
    }
  }
  
  /// Registra comissão da plataforma na tabela de transações gerais
  Future<void> _recordPlatformCommission({
    required String tripId,
    required double amount,
    required double originalAmount,
    required double commissionRate,
  }) async {
    try {
      await _supabase
          .from('wallet_transactions')
          .insert({
            'wallet_id': 'platform', // ID especial para a plataforma
            'amount': amount,
            'type': 'platform_commission',
            'description': 'Comissão da plataforma - Viagem $tripId',
            'status': 'completed',
            'metadata': {
              'trip_id': tripId,
              'original_amount': originalAmount,
              'commission_rate': commissionRate,
            },
            'created_at': DateTime.now().toIso8601String(),
          });
      
      print('✅ [${DateTime.now()}] Comissão da plataforma registrada: R\$ ${amount.toStringAsFixed(2)}');
      
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro ao registrar comissão: $e');
      // Não relançar erro para não impedir o processamento principal
    }
  }
  
  /// Atualiza status de pagamento da viagem
  Future<void> _updateTripPaymentStatus(String tripId, String status) async {
    try {
      await _supabase
          .from('trips')
          .update({
            'payment_status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId);
      
      print('✅ [${DateTime.now()}] Status de pagamento atualizado: $status');
      
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro ao atualizar status: $e');
      throw DatabaseException('Erro ao atualizar status de pagamento: $e');
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
}