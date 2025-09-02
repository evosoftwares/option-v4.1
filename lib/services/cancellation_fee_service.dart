import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver.dart';
import '../models/supabase/trip.dart';
import '../models/supabase/trip_request.dart';

/// Resultado do cálculo de taxa de cancelamento
class CancellationFeeResult {
  const CancellationFeeResult({
    required this.shouldChargeFee,
    required this.feeAmount,
    required this.reason,
    this.baseFee,
    this.displacementFactor,
    this.driverEarnings,
  });

  final bool shouldChargeFee;
  final double feeAmount;
  final String reason;
  final double? baseFee;
  final double? displacementFactor;
  final double? driverEarnings;

  @override
  String toString() => 'CancellationFeeResult(shouldCharge: $shouldChargeFee, '
        'amount: R\$ ${feeAmount.toStringAsFixed(2)}, reason: $reason)';
}

/// Contexto para cálculo de cancelamento
class CancellationContext {
  const CancellationContext({
    required this.tripRequest,
    required this.cancelledBy,
    this.driver,
    this.trip,
    this.driverCurrentLatitude,
    this.driverCurrentLongitude,
    this.waitTimeMinutes,
  });

  final TripRequest tripRequest;
  final String cancelledBy; // 'passenger' ou 'driver'
  final Driver? driver;
  final Trip? trip;
  final double? driverCurrentLatitude;
  final double? driverCurrentLongitude;
  final int? waitTimeMinutes; // Para casos de No-Show
}

/// Serviço para cálculo e aplicação de taxas de cancelamento
/// Implementa as regras conforme especificação de negócio
class CancellationFeeService {
  CancellationFeeService(this._supabase);

  final SupabaseClient _supabase;

  /// Calcula a taxa de cancelamento baseado no contexto
  /// 
  /// Implementa as regras:
  /// - MultaBase = MÍNIMO((PreçoTotalEstimado * 0.20), 10.00)
  /// - FatorDeslocamento = DistânciaJáPercorrida / DistânciaTotalAtéOPassageiro
  /// - TaxaFinal = MultaBase * FatorDeslocamento
  /// - No-Show: FatorDeslocamento = 1 (100%)
  Future<CancellationFeeResult> calculateCancellationFee(CancellationContext context) async {
    try {
      print('🧮 [${DateTime.now()}] Calculando taxa de cancelamento');
      print('  📝 Contexto: ${context.cancelledBy} cancelou');
      print('  💰 Valor estimado: R\$ ${context.tripRequest.estimatedFare.toStringAsFixed(2)}');
      
      // 1. Verificar se deve cobrar taxa
      final shouldCharge = _shouldChargeCancellationFee(context);
      if (!shouldCharge.shouldCharge) {
        return CancellationFeeResult(
          shouldChargeFee: false,
          feeAmount: 0,
          reason: shouldCharge.reason,
        );
      }

      // 2. Calcular multa base
      final baseFee = _calculateBaseFee(context.tripRequest.estimatedFare);
      print('  🎯 Multa base: R\$ ${baseFee.toStringAsFixed(2)}');

      // 3. Calcular fator de deslocamento
      final displacementFactor = await _calculateDisplacementFactor(context);
      print('  📏 Fator deslocamento: ${(displacementFactor * 100).toStringAsFixed(1)}%');

      // 4. Calcular taxa final
      final finalFee = baseFee * displacementFactor;
      print('  💸 Taxa final: R\$ ${finalFee.toStringAsFixed(2)}');

      // 5. Calcular ganhos do motorista (taxa menos comissão da plataforma)
      const platformCommission = 0.10; // 10% de comissão
      final driverEarnings = finalFee * (1 - platformCommission);

      return CancellationFeeResult(
        shouldChargeFee: true,
        feeAmount: finalFee,
        reason: 'Cancelamento após motorista a caminho',
        baseFee: baseFee,
        displacementFactor: displacementFactor,
        driverEarnings: driverEarnings,
      );
    } catch (e, stackTrace) {
      print('❌ [${DateTime.now()}] Erro ao calcular taxa: $e');
      print('📍 Stack: $stackTrace');
      // Em caso de erro, não cobra taxa para não prejudicar usuário
      return const CancellationFeeResult(
        shouldChargeFee: false,
        feeAmount: 0,
        reason: 'Erro no cálculo - taxa dispensada',
      );
    }
  }

  /// Processa o cancelamento completo com cobrança de taxa
  Future<void> processCancellation(CancellationContext context) async {
    try {
      print('🔄 [${DateTime.now()}] Processando cancelamento completo');
      
      // 1. Calcular taxa
      final feeResult = await calculateCancellationFee(context);
      
      // 2. Atualizar status da solicitação/viagem
      await _updateTripStatus(context);
      
      // 3. Incrementar contador de cancelamentos
      await _incrementCancellationCount(context);
      
      // 4. Processar cobrança se necessário
      if (feeResult.shouldChargeFee && feeResult.feeAmount > 0) {
        await _processCancellationPayment(context, feeResult);
      }
      
      // 5. Verificar política de suspensão
      await _checkSuspensionPolicy(context);
      
      print('✅ [${DateTime.now()}] Cancelamento processado com sucesso');
    } catch (e, stackTrace) {
      print('❌ [${DateTime.now()}] Erro ao processar cancelamento: $e');
      print('📍 Stack: $stackTrace');
      throw DatabaseException('Erro ao processar cancelamento: $e');
    }
  }

  /// Verifica se deve cobrar taxa de cancelamento
  ({bool shouldCharge, String reason}) _shouldChargeCancellationFee(CancellationContext context) {
    // Só cobra se passageiro cancelou
    if (context.cancelledBy != 'passenger') {
      return (shouldCharge: false, reason: 'Motorista cancelou - sem taxa');
    }

    // Só cobra se o motorista já aceitou
    if (context.tripRequest.acceptedByDriverId == null) {
      return (shouldCharge: false, reason: 'Motorista ainda não aceitou - sem taxa');
    }

    // Só cobra se não é um cancelamento imediato (menos de 1 minuto)
    if (context.tripRequest.acceptedAt != null) {
      final timeSinceAccepted = DateTime.now().difference(context.tripRequest.acceptedAt!);
      if (timeSinceAccepted.inMinutes < 1) {
        return (shouldCharge: false, reason: 'Cancelamento imediato - sem taxa');
      }
    }

    return (shouldCharge: true, reason: 'Passageiro cancelou após aceitação');
  }

  /// Calcula a multa base: MÍNIMO((PreçoTotal * 0.20), 10.00)
  double _calculateBaseFee(double estimatedFare) {
    final percentageFee = estimatedFare * 0.20; // 20% do valor
    return math.min(percentageFee, 10); // Máximo R$ 10,00
  }

  /// Calcula o fator de deslocamento do motorista
  Future<double> _calculateDisplacementFactor(CancellationContext context) async {
    try {
      // Para casos de No-Show (passageiro não apareceu), fator é 100%
      if (context.waitTimeMinutes != null && context.waitTimeMinutes! >= 3) {
        return 1.0; // 100% da taxa
      }

      // Verificar se temos localização atual do motorista
      if (context.driverCurrentLatitude == null || context.driverCurrentLongitude == null) {
        // Sem localização atual, usar localização do motorista no perfil
        if (context.driver?.currentLatitude == null || context.driver?.currentLongitude == null) {
          return 0.5; // 50% como fallback
        }
      }

      final driverLat = context.driverCurrentLatitude ?? context.driver!.currentLatitude!;
      final driverLng = context.driverCurrentLongitude ?? context.driver!.currentLongitude!;

      // Calcular distância já percorrida pelo motorista
      final distanceTraveled = Geolocator.distanceBetween(
        driverLat,
        driverLng,
        context.tripRequest.originLatitude,
        context.tripRequest.originLongitude,
      ) / 1000; // Converter para km

      // Calcular distância total que o motorista percorreria
      final totalDistance = await _calculateInitialDriverDistance(context);
      
      // Calcular fator de deslocamento
      if (totalDistance <= 0) {
        return 0.5; // 50% como fallback
      }

      final factor = math.min(1, distanceTraveled / totalDistance);
      return math.max(0.1, factor.toDouble()); // Mínimo 10%, máximo 100%
    } catch (e) {
      print('⚠️ Erro ao calcular fator de deslocamento: $e');
      return 0.5; // 50% como fallback seguro
    }
  }

  /// Calcula a distância inicial entre motorista e passageiro
  Future<double> _calculateInitialDriverDistance(CancellationContext context) async {
    try {
      // Tentar obter da tabela driver_offers se disponível
      if (context.driver != null) {
        final offerQuery = await _supabase
            .from('driver_offers')
            .select('driver_distance_km')
            .eq('request_id', context.tripRequest.id)
            .eq('driver_id', context.driver!.id)
            .maybeSingle();

        if (offerQuery != null) {
          return (offerQuery['driver_distance_km'] as num).toDouble();
        }
      }

      // Fallback: calcular distância direta
      if (context.driver?.currentLatitude != null && context.driver?.currentLongitude != null) {
        return Geolocator.distanceBetween(
          context.driver!.currentLatitude!,
          context.driver!.currentLongitude!,
          context.tripRequest.originLatitude,
          context.tripRequest.originLongitude,
        ) / 1000; // Converter para km
      }

      return 5.0; // 5km como fallback
    } catch (e) {
      print('⚠️ Erro ao calcular distância inicial: $e');
      return 5.0;
    }
  }

  /// Atualiza status da viagem/solicitação
  Future<void> _updateTripStatus(CancellationContext context) async {
    if (context.trip != null) {
      // Atualizar viagem existente
      await _supabase
          .from('trips')
          .update({
            'status': 'cancelled',
            'cancelled_by': context.cancelledBy,
            'cancelled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', context.trip!.id);
    } else {
      // Atualizar solicitação
      await _supabase
          .from('trip_requests')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', context.tripRequest.id);
    }
  }

  /// Incrementa contador de cancelamentos
  Future<void> _incrementCancellationCount(CancellationContext context) async {
    if (context.cancelledBy == 'passenger') {
      // Incrementar cancelamentos do passageiro
      await _supabase.rpc('increment_passenger_cancellations', params: {
        'passenger_user_id': context.tripRequest.passengerId,
      });
    } else if (context.cancelledBy == 'driver' && context.driver != null) {
      // Incrementar cancelamentos do motorista
      await _supabase.rpc('increment_driver_cancellations', params: {
        'driver_user_id': context.driver!.userId,
      });
    }
  }

  /// Processa pagamento da taxa de cancelamento
  Future<void> _processCancellationPayment(CancellationContext context, CancellationFeeResult feeResult) async {
    try {
      print('💳 [${DateTime.now()}] Processando pagamento da taxa: R\$ ${feeResult.feeAmount.toStringAsFixed(2)}');
      
      // 1. Cobrar taxa do passageiro via transação na carteira
      await _supabase
          .from('passenger_wallet_transactions')
          .insert({
            'user_id': context.tripRequest.passengerId,
            'amount': -feeResult.feeAmount.abs(), // Valor negativo (débito)
            'type': 'cancellation_fee',
            'description': 'Taxa de cancelamento - ${context.tripRequest.id}',
            'transaction_date': DateTime.now().toIso8601String(),
            'status': 'completed',
          });

      // 2. Creditar motorista (se aplicável)
      if (context.driver != null && feeResult.driverEarnings != null && feeResult.driverEarnings! > 0) {
        // Adicionar aos ganhos do motorista
        await _supabase.rpc('add_driver_earnings', params: {
          'driver_user_id': context.driver!.userId,
          'amount': feeResult.driverEarnings,
          'description': 'Compensação por cancelamento - ${context.tripRequest.id}',
        });
      }

      print('✅ [${DateTime.now()}] Pagamento da taxa processado com sucesso');
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro ao processar pagamento da taxa: $e');
      // Não relançar erro para não impedir o cancelamento
    }
  }

  /// Verifica e aplica política de suspensão por cancelamentos abusivos
  Future<void> _checkSuspensionPolicy(CancellationContext context) async {
    try {
      if (context.cancelledBy == 'passenger') {
        // Verificar cancelamentos consecutivos do passageiro
        final passengerData = await _supabase
            .from('passengers')
            .select('consecutive_cancellations, user_id')
            .eq('user_id', context.tripRequest.passengerId)
            .maybeSingle();

        if (passengerData != null) {
          final consecutiveCancellations = passengerData['consecutive_cancellations'] as int? ?? 0;
          
          if (consecutiveCancellations >= 3) {
            // Suspender passageiro
            await _supabase
                .from('app_users')
                .update({
                  'status': 'suspended',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', context.tripRequest.passengerId);
            
            print('🚫 [${DateTime.now()}] Passageiro suspenso por cancelamentos abusivos');
          }
        }
      } else if (context.cancelledBy == 'driver' && context.driver != null) {
        // Verificar cancelamentos consecutivos do motorista
        final driverData = await _supabase
            .from('drivers')
            .select('consecutive_cancellations')
            .eq('user_id', context.driver!.userId)
            .maybeSingle();

        if (driverData != null) {
          final consecutiveCancellations = driverData['consecutive_cancellations'] as int? ?? 0;
          
          if (consecutiveCancellations >= 3) {
            // Suspender motorista
            await _supabase
                .from('app_users')
                .update({
                  'status': 'suspended',
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', context.driver!.userId);
            
            print('🚫 [${DateTime.now()}] Motorista suspenso por cancelamentos abusivos');
          }
        }
      }
    } catch (e) {
      print('⚠️ Erro ao verificar política de suspensão: $e');
      // Não relançar erro para não impedir o cancelamento
    }
  }
}