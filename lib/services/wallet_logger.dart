/// Sistema de logging específico para operações de carteira
/// Estende o sistema de logging existente com funcionalidades específicas para carteira
library;

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../core/error_handling/error_logger.dart';
import '../core/error_handling/app_error.dart';
import '../models/passenger_wallet.dart';
import '../models/driver_wallet.dart';
import '../models/wallet_transaction.dart';

/// Nível de log para operações de carteira
enum WalletLogLevel {
  debug(100),
  info(200),
  warning(300),
  error(400),
  critical(500);

  const WalletLogLevel(this.value);
  final int value;
}

/// Logger específico para operações de carteira
class WalletLogger {
  static final WalletLogger _instance = WalletLogger._internal();
  factory WalletLogger() => _instance;
  WalletLogger._internal();

  /// Loga uma operação de crédito na carteira do passageiro
  Future<void> logPassengerCreditAdded({
    required String passengerId,
    required String userId,
    required double amount,
    required String description,
    required String transactionId,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'passenger_id': passengerId,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'transaction_id': transactionId,
      'operation': 'credit_added',
      'wallet_type': 'passenger',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: WalletLogLevel.info,
      message: 'Crédito adicionado à carteira do passageiro',
      context: context,
    );
  }

  /// Loga uma operação de débito na carteira do passageiro
  Future<void> logPassengerDebit({
    required String passengerId,
    required String userId,
    required String tripId,
    required double amount,
    required String description,
    required String transactionId,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'passenger_id': passengerId,
      'user_id': userId,
      'trip_id': tripId,
      'amount': amount,
      'description': description,
      'transaction_id': transactionId,
      'operation': 'debit',
      'wallet_type': 'passenger',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: WalletLogLevel.info,
      message: 'Débito realizado na carteira do passageiro',
      context: context,
    );
  }

  /// Loga ganhos adicionados à carteira do motorista
  Future<void> logDriverEarningsAdded({
    required String driverId,
    required String userId,
    required double amount,
    required String description,
    required String referenceType,
    required String referenceId,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'driver_id': driverId,
      'user_id': userId,
      'amount': amount,
      'description': description,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'operation': 'earnings_added',
      'wallet_type': 'driver',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: WalletLogLevel.info,
      message: 'Ganhos adicionados à carteira do motorista',
      context: context,
    );
  }

  /// Loga um saque solicitado
  Future<void> logWithdrawalRequested({
    required String walletId,
    required String userId,
    required double amount,
    required String method,
    required String withdrawalId,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'wallet_id': walletId,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'withdrawal_id': withdrawalId,
      'operation': 'withdrawal_requested',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: WalletLogLevel.info,
      message: 'Saque solicitado',
      context: context,
    );
  }

  /// Loga um saque processado
  Future<void> logWithdrawalProcessed({
    required String walletId,
    required String userId,
    required double amount,
    required String method,
    required String withdrawalId,
    required String status,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'wallet_id': walletId,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'withdrawal_id': withdrawalId,
      'status': status,
      'operation': 'withdrawal_processed',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: status == 'completed' ? WalletLogLevel.info : WalletLogLevel.warning,
      message: 'Saque processado',
      context: context,
    );
  }

  /// Loga uma operação de consulta de saldo
  Future<void> logBalanceChecked({
    required String walletId,
    required String userId,
    required String walletType, // 'passenger' or 'driver'
    required double balance,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'wallet_id': walletId,
      'user_id': userId,
      'wallet_type': walletType,
      'balance': balance,
      'operation': 'balance_checked',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: WalletLogLevel.debug,
      message: 'Consulta de saldo realizada',
      context: context,
    );
  }

  /// Loga uma tentativa de saque bloqueada por segurança
  Future<void> logWithdrawalBlocked({
    required String userId,
    required String reason,
    required String blockType,
    double? amount,
    String? pixKey,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'user_id': userId,
      'reason': reason,
      'block_type': blockType,
      'amount': amount,
      'pix_key': pixKey,
      'operation': 'withdrawal_blocked',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: WalletLogLevel.warning,
      message: 'Tentativa de saque bloqueada por segurança',
      context: context,
    );
  }

  /// Loga atividade suspeita detectada
  Future<void> logSuspiciousActivity({
    required String userId,
    required String activityType,
    Map<String, dynamic>? additionalContext,
  }) async {
    final context = <String, dynamic>{
      'user_id': userId,
      'activity_type': activityType,
      'operation': 'suspicious_activity',
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    await _logWalletOperation(
      level: WalletLogLevel.critical,
      message: 'Atividade suspeita detectada',
      context: context,
    );
  }

  /// Loga uma operação de carteira genérica
  Future<void> _logWalletOperation({
    required WalletLogLevel level,
    required String message,
    required Map<String, dynamic> context,
  }) async {
    try {
      // Log no console em desenvolvimento
      if (kDebugMode) {
        developer.log(
          message,
          name: 'WalletLogger',
          level: level.value * 10, // Multiplicar por 10 para corresponder aos níveis do dart:developer
          error: context,
        );
      }

      // Log no sistema de erro centralizado
      final appError = AppError(
        type: AppErrorType.unknownError,
        message: message,
        technicalDetails: 'Wallet operation logged',
        context: context,
        severity: _mapWalletLogLevelToErrorSeverity(level),
      );

      await ErrorLoggingService.instance.logError(appError);
    } catch (e) {
      // Se falhar ao logar, pelo menos loga no console
      if (kDebugMode) {
        developer.log(
          'Failed to log wallet operation: $e',
          name: 'WalletLogger',
          level: WalletLogLevel.error.value * 10,
        );
      }
    }
  }

  /// Mapeia o nível de log da carteira para a severidade do erro
  ErrorSeverity _mapWalletLogLevelToErrorSeverity(WalletLogLevel level) {
    switch (level) {
      case WalletLogLevel.debug:
        return ErrorSeverity.low;
      case WalletLogLevel.info:
        return ErrorSeverity.low;
      case WalletLogLevel.warning:
        return ErrorSeverity.medium;
      case WalletLogLevel.error:
        return ErrorSeverity.high;
      case WalletLogLevel.critical:
        return ErrorSeverity.critical;
    }
  }

  /// Loga estatísticas da carteira para monitoramento
  Future<void> logWalletStats({
    required String userId,
    required String walletType, // 'passenger' or 'driver'
    required Map<String, dynamic> stats,
  }) async {
    final context = <String, dynamic>{
      'user_id': userId,
      'wallet_type': walletType,
      'stats': stats,
      'operation': 'wallet_stats',
    };

    await _logWalletOperation(
      level: WalletLogLevel.debug,
      message: 'Estatísticas da carteira registradas',
      context: context,
    );
  }
}

/// Extensão para adicionar métodos de logging às classes de modelo
extension WalletLoggingExtension on PassengerWallet {
  /// Loga informações da carteira do passageiro
  Future<void> logWalletInfo() async {
    await WalletLogger().logBalanceChecked(
      walletId: id,
      userId: userId,
      walletType: 'passenger',
      balance: availableBalance,
      additionalContext: {
        'pending_balance': pendingBalance,
        'total_spent': totalSpent,
      },
    );
  }
}

/// Extensão para adicionar métodos de logging às classes de modelo
extension DriverWalletLoggingExtension on DriverWallet {
  /// Loga informações da carteira do motorista
  Future<void> logWalletInfo() async {
    await WalletLogger().logBalanceChecked(
      walletId: id,
      userId: '', // DriverWallet doesn't have userId field
      walletType: 'driver',
      balance: availableBalance,
      additionalContext: {
        'pending_balance': pendingBalance,
        'total_earned': totalEarned,
        'total_withdrawn': totalWithdrawn,
      },
    );
  }
}

/// Extensão para adicionar métodos de logging às transações
extension WalletTransactionLoggingExtension on WalletTransaction {
  /// Loga informações da transação
  Future<void> logTransaction() async {
    final context = <String, dynamic>{
      'transaction_type': type.value,
      'amount': amount,
      'status': status.value,
    };

    if (referenceType != null) {
      context['reference_type'] = referenceType;
    }

    if (referenceId != null) {
      context['reference_id'] = referenceId;
    }

    if (balanceAfter != null) {
      context['balance_after'] = balanceAfter;
    }

    await WalletLogger()._logWalletOperation(
      level: WalletLogLevel.info,
      message: 'Transação registrada: ${type.displayName}',
      context: context,
    );
  }
}