import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/passenger_wallet_transaction.dart';

/// Serviço de segurança para rate limiting e auditoria
class SecurityService {
  static const String _withdrawalAttemptsKey = 'withdrawal_attempts';
  static const String _lastWithdrawalKey = 'last_withdrawal_time';
  
  // Limites de segurança
  static const int maxWithdrawalsPerHour = 3;
  static const int maxWithdrawalsPerDay = 10;
  static const Duration cooldownPeriod = Duration(minutes: 5);
  
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Verifica se o usuário pode fazer um saque (rate limiting)
  Future<SecurityCheckResult> canPerformWithdrawal(String passengerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Verifica último saque (cooldown)
      final lastWithdrawalStr = prefs.getString('${_lastWithdrawalKey}_$passengerId');
      if (lastWithdrawalStr != null) {
        final lastWithdrawal = DateTime.parse(lastWithdrawalStr);
        final timeSinceLastWithdrawal = now.difference(lastWithdrawal);
        
        if (timeSinceLastWithdrawal < cooldownPeriod) {
          final remainingTime = cooldownPeriod - timeSinceLastWithdrawal;
          return SecurityCheckResult(
            allowed: false,
            reason: 'Aguarde ${remainingTime.inMinutes + 1} minutos antes do próximo saque',
            type: SecurityCheckType.cooldown,
          );
        }
      }
      
      // Verifica tentativas na última hora
      final hourlyAttempts = await _getWithdrawalAttemptsInPeriod(
        passengerId, 
        const Duration(hours: 1),
      );
      
      if (hourlyAttempts >= maxWithdrawalsPerHour) {
        return const SecurityCheckResult(
          allowed: false,
          reason: 'Limite de $maxWithdrawalsPerHour saques por hora atingido',
          type: SecurityCheckType.hourlyLimit,
        );
      }
      
      // Verifica tentativas no último dia
      final dailyAttempts = await _getWithdrawalAttemptsInPeriod(
        passengerId, 
        const Duration(days: 1),
      );
      
      if (dailyAttempts >= maxWithdrawalsPerDay) {
        return const SecurityCheckResult(
          allowed: false,
          reason: 'Limite de $maxWithdrawalsPerDay saques por dia atingido',
          type: SecurityCheckType.dailyLimit,
        );
      }
      
      return const SecurityCheckResult(
        allowed: true,
        reason: 'Saque autorizado',
        type: SecurityCheckType.approved,
      );
      
    } catch (e) {
      print('❌ Erro na verificação de segurança: $e');
      return const SecurityCheckResult(
        allowed: false,
        reason: 'Erro interno de segurança',
        type: SecurityCheckType.error,
      );
    }
  }
  
  /// Registra uma tentativa de saque
  Future<void> recordWithdrawalAttempt(String passengerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_lastWithdrawalKey}_$passengerId',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('❌ Erro ao registrar tentativa de saque: $e');
    }
  }
  
  /// Conta tentativas de saque em um período específico
  Future<int> _getWithdrawalAttemptsInPeriod(
    String passengerId, 
    Duration period,
  ) async {
    try {
      final cutoffTime = DateTime.now().subtract(period);
      
      final response = await _supabase
          .from('passenger_wallet_transactions')
          .select('id')
          .eq('passenger_id', passengerId)
          .eq('type', TransactionType.withdrawal.value)
          .gte('created_at', cutoffTime.toIso8601String());
      
      return response.length;
    } catch (e) {
      print('❌ Erro ao contar tentativas de saque: $e');
      return 0;
    }
  }
  
  /// Registra log de auditoria para transações
  Future<void> logAuditEvent({
    required String passengerId,
    required String eventType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auditData = {
        'passenger_id': passengerId,
        'event_type': eventType,
        'description': description,
        'metadata': metadata ?? {},
        'ip_address': 'mobile_app', // Em um app real, você obteria o IP
        'user_agent': 'Flutter Mobile App',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase
          .from('audit_logs')
          .insert(auditData);
      
      print('✅ Log de auditoria registrado: $eventType para $passengerId');
    } catch (e) {
      print('❌ Erro ao registrar log de auditoria: $e');
      // Não falha a operação principal se o log falhar
    }
  }
  
  /// Verifica se há atividade suspeita
  Future<bool> detectSuspiciousActivity(String passengerId) async {
    try {
      // Verifica múltiplas tentativas de saque em pouco tempo
      final recentAttempts = await _getWithdrawalAttemptsInPeriod(
        passengerId,
        const Duration(minutes: 10),
      );
      
      if (recentAttempts > 5) {
        await logAuditEvent(
          passengerId: passengerId,
          eventType: 'SUSPICIOUS_ACTIVITY',
          description: 'Múltiplas tentativas de saque em curto período',
          metadata: {
            'attempts_count': recentAttempts,
            'time_window': '10_minutes',
          },
        );
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Erro na detecção de atividade suspeita: $e');
      return false;
    }
  }
}

/// Resultado da verificação de segurança
class SecurityCheckResult {
  
  const SecurityCheckResult({
    required this.allowed,
    required this.reason,
    required this.type,
  });
  final bool allowed;
  final String reason;
  final SecurityCheckType type;
}

/// Tipos de verificação de segurança
enum SecurityCheckType {
  approved,
  cooldown,
  hourlyLimit,
  dailyLimit,
  suspicious,
  error,
}

extension SecurityCheckTypeExtension on SecurityCheckType {
  String get displayName {
    switch (this) {
      case SecurityCheckType.approved:
        return 'Aprovado';
      case SecurityCheckType.cooldown:
        return 'Período de espera';
      case SecurityCheckType.hourlyLimit:
        return 'Limite por hora';
      case SecurityCheckType.dailyLimit:
        return 'Limite diário';
      case SecurityCheckType.suspicious:
        return 'Atividade suspeita';
      case SecurityCheckType.error:
        return 'Erro de sistema';
    }
  }
  
  bool get isBlocking {
    switch (this) {
      case SecurityCheckType.approved:
        return false;
      default:
        return true;
    }
  }
}