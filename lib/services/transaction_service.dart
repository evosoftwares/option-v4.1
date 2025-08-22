import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';

/// Serviço para gerenciar transações e concorrência no Supabase
/// Como o Supabase não suporta transações explícitas no cliente,
/// implementamos estratégias de retry e controle de concorrência
class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 100);
  
  /// Executa uma operação com retry automático em caso de conflito
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
    Duration baseDelay = _baseDelay,
    String? operationName,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        // Verifica se é um erro de concorrência que pode ser resolvido com retry
        if (_isRetryableError(e) && attempts < maxRetries) {
          // Delay exponencial com jitter
          final delay = Duration(
            milliseconds: baseDelay.inMilliseconds * (1 << (attempts - 1)) +
                (DateTime.now().millisecondsSinceEpoch % 100),
          );
          
          await Future.delayed(delay);
          continue;
        }
        
        // Se não é retryable ou excedeu tentativas, relança o erro
        if (operationName != null) {
          throw DatabaseException(
            'Falha na operação "$operationName" após $attempts tentativas: ${e.toString()}'
          );
        }
        
        rethrow;
      }
    }
    
    throw DatabaseException(
      'Operação falhou após $maxRetries tentativas'
    );
  }
  
  /// Executa múltiplas operações em sequência com controle de erro
  static Future<List<T>> executeBatch<T>(
    List<Future<T> Function()> operations, {
    bool stopOnFirstError = true,
    String? batchName,
  }) async {
    final results = <T>[];
    final errors = <String>[];
    
    for (int i = 0; i < operations.length; i++) {
      try {
        final result = await executeWithRetry(
          operations[i],
          operationName: batchName != null ? '$batchName[$i]' : null,
        );
        results.add(result);
      } catch (e) {
        errors.add('Operação $i: ${e.toString()}');
        
        if (stopOnFirstError) {
          throw DatabaseException(
            'Falha no lote ${batchName ?? ""}: ${errors.join("; ")}'
          );
        }
      }
    }
    
    if (errors.isNotEmpty && !stopOnFirstError) {
      throw DatabaseException(
        'Algumas operações falharam no lote ${batchName ?? ""}: ${errors.join("; ")}'
      );
    }
    
    return results;
  }
  
  /// Executa uma operação com lock otimista usando versioning
  static Future<T> executeWithOptimisticLock<T>(
    String tableName,
    String recordId,
    Future<T> Function(Map<String, dynamic> currentRecord) operation, {
    String versionColumn = 'updated_at',
    int maxRetries = _maxRetries,
  }) async {
    final supabase = Supabase.instance.client;
    
    return await executeWithRetry(
      () async {
        // 1. Busca o registro atual com sua versão
        final currentRecord = await supabase
            .from(tableName)
            .select()
            .eq('id', recordId)
            .single();
        
        final currentVersion = currentRecord[versionColumn];
        
        // 2. Executa a operação
        final result = await operation(currentRecord);
        
        // 3. Verifica se a versão ainda é a mesma
        final updatedRecord = await supabase
            .from(tableName)
            .select(versionColumn)
            .eq('id', recordId)
            .single();
        
        if (updatedRecord[versionColumn] != currentVersion) {
          throw ConcurrencyException(
            'Registro foi modificado por outro processo. Tentando novamente...'
          );
        }
        
        return result;
      },
      maxRetries: maxRetries,
      operationName: 'OptimisticLock[$tableName:$recordId]',
    );
  }
  
  /// Executa uma operação com lock pessimista simulado
  /// Usa uma tabela de locks para coordenar acesso
  static Future<T> executeWithPessimisticLock<T>(
    String lockKey,
    Future<T> Function() operation, {
    Duration lockTimeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final supabase = Supabase.instance.client;
    final lockId = _generateLockId();
    final expiresAt = DateTime.now().add(lockTimeout);
    
    try {
      // 1. Tenta adquirir o lock
      await _acquireLock(supabase, lockKey, lockId, expiresAt, pollInterval);
      
      // 2. Executa a operação
      return await operation();
      
    } finally {
      // 3. Sempre libera o lock
      await _releaseLock(supabase, lockKey, lockId);
    }
  }
  
  /// Verifica se um erro pode ser resolvido com retry
  static bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Erros de rede temporários
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return true;
    }
    
    // Erros de concorrência
    if (errorString.contains('conflict') ||
        errorString.contains('duplicate') ||
        errorString.contains('constraint')) {
      return true;
    }
    
    // Erros temporários do servidor
    if (errorString.contains('503') ||
        errorString.contains('502') ||
        errorString.contains('504')) {
      return true;
    }
    
    return false;
  }
  
  /// Tenta adquirir um lock
  static Future<void> _acquireLock(
    SupabaseClient supabase,
    String lockKey,
    String lockId,
    DateTime expiresAt,
    Duration pollInterval,
  ) async {
    while (DateTime.now().isBefore(expiresAt)) {
      try {
        // Tenta inserir o lock
        await supabase.from('system_locks').insert({
          'lock_key': lockKey,
          'lock_id': lockId,
          'expires_at': expiresAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
        
        return; // Lock adquirido com sucesso
        
      } catch (e) {
        // Se falhou, pode ser porque já existe um lock
        // Limpa locks expirados e tenta novamente
        await _cleanExpiredLocks(supabase);
        
        // Verifica se ainda há tempo
        if (DateTime.now().isAfter(expiresAt)) {
          throw TimeoutException(
            'Timeout ao tentar adquirir lock para "$lockKey"'
          );
        }
        
        // Espera antes de tentar novamente
        await Future.delayed(pollInterval);
      }
    }
    
    throw TimeoutException(
      'Timeout ao tentar adquirir lock para "$lockKey"'
    );
  }
  
  /// Libera um lock
  static Future<void> _releaseLock(
    SupabaseClient supabase,
    String lockKey,
    String lockId,
  ) async {
    try {
      await supabase
          .from('system_locks')
          .delete()
          .eq('lock_key', lockKey)
          .eq('lock_id', lockId);
    } catch (e) {
      // Ignora erros ao liberar lock
      // O lock expirará automaticamente
    }
  }
  
  /// Limpa locks expirados
  static Future<void> _cleanExpiredLocks(SupabaseClient supabase) async {
    try {
      await supabase
          .from('system_locks')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());
    } catch (e) {
      // Ignora erros na limpeza
    }
  }
  
  /// Gera um ID único para o lock
  static String _generateLockId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}

/// Exceção específica para problemas de concorrência
class ConcurrencyException extends DatabaseException {
  const ConcurrencyException(String message) : super(message);
}

/// Exceção para timeout de operações
class TimeoutException extends DatabaseException {
  const TimeoutException(String message) : super(message);
}