import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/supabase_helper.dart';

/// Serviço para monitoramento de integridade de dados
/// 
/// Monitora e previne tentativas de inserção de dados corrompidos
class DataIntegrityService {
  static SupabaseClient get _supabase {
    final client = SupabaseHelper.client;
    if (client == null) {
      throw Exception('Supabase não foi inicializado. Verifique a configuração antes de usar DataIntegrityService.');
    }
    return client;
  }

  /// Verifica se há dados corrompidos no banco
  static Future<DataIntegrityReport> checkDataIntegrity() async {
    try {
      // Consultar view de monitoramento
      final response = await _supabase
          .from('clean_users_monitor')
          .select()
          .single();

      return DataIntegrityReport.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao verificar integridade dos dados: $e');
    }
  }

  /// Lista usuários com dados potencialmente corrompidos
  static Future<List<CorruptedUserData>> findCorruptedUsers() async {
    try {
      final response = await _supabase
          .from('app_users')
          .select('id, email, full_name, created_at')
          .or(
            'full_name.like.%{%}%,'
            'full_name.like.%[%]%,'
            'full_name.like.%missing_passenger_records%,'
            'full_name.like.%issue%,'
            'full_name.like.%count%,'
            'full_name.like.%error%'
          )
          .order('created_at', ascending: false);

      return response
          .map<CorruptedUserData>(CorruptedUserData.fromMap)
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar usuários corrompidos: $e');
    }
  }

  /// Log de tentativa de dados corrompidos
  static Future<void> logCorruptionAttempt({
    required String tableName,
    required String columnName,
    required String attemptedValue,
    String? userId,
    String? errorMessage,
  }) async {
    try {
      await _supabase.from('data_corruption_attempts').insert({
        'table_name': tableName,
        'column_name': columnName,
        'attempted_value': attemptedValue,
        'user_id': userId,
        'error_message': errorMessage,
        'attempted_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Não falhar o processo principal por causa do log
      print('⚠️ Falha ao registrar tentativa de corrupção: $e');
    }
  }

  /// Executa limpeza de emergência (APENAS EM CASOS EXTREMOS)
  static Future<EmergencyCleanResult> emergencyCleanData() async {
    try {
      print('🚨 EXECUTANDO LIMPEZA DE EMERGÊNCIA...');
      
      // Chamar função do banco para limpeza
      final response = await _supabase.rpc('emergency_clean_user_data');
      
      print('✅ Limpeza de emergência concluída');
      return EmergencyCleanResult.fromMap(response);
    } catch (e) {
      print('❌ Erro na limpeza de emergência: $e');
      throw Exception('Erro na limpeza de emergência: $e');
    }
  }

  /// Monitora logs de tentativas de corrupção
  static Future<List<CorruptionAttemptLog>> getCorruptionAttempts({
    int limit = 50,
    DateTime? since,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('data_corruption_attempts')
          .select();

      if (since != null) {
        queryBuilder = queryBuilder.gte('attempted_at', since.toIso8601String());
      }

      final response = await queryBuilder
          .order('attempted_at', ascending: false)
          .limit(limit);

      return response
          .map<CorruptionAttemptLog>(CorruptionAttemptLog.fromMap)
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar logs de tentativas de corrupção: $e');
    }
  }

  /// Valida dados antes de enviar ao banco (camada adicional de segurança)
  static void validateDataBeforeInsert(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String && _isCorruptedString(value)) {
        // Log da tentativa
        logCorruptionAttempt(
          tableName: 'unknown',
          columnName: key,
          attemptedValue: value,
          errorMessage: 'Dados corrompidos detectados pela validação do app',
        );

        throw Exception('Dados corrompidos detectados no campo $key: $value');
      }
    }
  }

  /// Detecção rigorosa de strings corrompidas
  static bool _isCorruptedString(String data) {
    // 1. JSON/estruturas
    if (data.contains('{') || data.contains('}') || 
        data.contains('[') || data.contains(']')) {
      return true;
    }
    
    // 2. Palavras de erro
    const errorWords = [
      'missing_passenger_records', 'issue', 'count', 'error', 'exception',
      'null', 'undefined', 'nan', 'select', 'from', 'where', 'insert',
      'update', 'delete', 'drop', 'alter', 'create', 'function', 'return',
    ];
    
    final lowerData = data.toLowerCase();
    for (final word in errorWords) {
      if (lowerData.contains(word)) return true;
    }

    // 3. Códigos suspeitos
    if (RegExp(r'^[0-9]{3}$').hasMatch(data)) return true; // HTTP codes
    if (data.startsWith('0x') || data.startsWith('#')) return true; // Hex codes

    return false;
  }
}

/// Relatório de integridade de dados
class DataIntegrityReport {

  DataIntegrityReport({
    required this.totalUsers,
    required this.potentiallyCorrupted,
    required this.cleanNames,
    required this.cleanEmails,
    required this.checkedAt,
  });

  factory DataIntegrityReport.fromMap(Map<String, dynamic> map) => DataIntegrityReport(
      totalUsers: map['total_users'] ?? 0,
      potentiallyCorrupted: map['potentially_corrupted'] ?? 0,
      cleanNames: map['clean_names'] ?? 0,
      cleanEmails: map['clean_emails'] ?? 0,
      checkedAt: DateTime.parse(map['checked_at']),
    );
  final int totalUsers;
  final int potentiallyCorrupted;
  final int cleanNames;
  final int cleanEmails;
  final DateTime checkedAt;

  bool get hasCorruptedData => potentiallyCorrupted > 0;
  double get corruptionPercentage => 
      totalUsers > 0 ? (potentiallyCorrupted / totalUsers) * 100 : 0;
}

/// Dados de usuário corrompido
class CorruptedUserData {

  CorruptedUserData({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  factory CorruptedUserData.fromMap(Map<String, dynamic> map) => CorruptedUserData(
      id: map['id'],
      email: map['email'],
      fullName: map['full_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  final String id;
  final String email;
  final String fullName;
  final DateTime createdAt;
}

/// Log de tentativa de corrupção
class CorruptionAttemptLog {

  CorruptionAttemptLog({
    required this.id,
    required this.tableName,
    required this.columnName,
    required this.attemptedValue,
    this.userId,
    required this.attemptedAt,
    this.errorMessage,
  });

  factory CorruptionAttemptLog.fromMap(Map<String, dynamic> map) => CorruptionAttemptLog(
      id: map['id'],
      tableName: map['table_name'],
      columnName: map['column_name'],
      attemptedValue: map['attempted_value'],
      userId: map['user_id'],
      attemptedAt: DateTime.parse(map['attempted_at']),
      errorMessage: map['error_message'],
    );
  final int id;
  final String tableName;
  final String columnName;
  final String attemptedValue;
  final String? userId;
  final DateTime attemptedAt;
  final String? errorMessage;
}

/// Resultado da limpeza de emergência
class EmergencyCleanResult {

  EmergencyCleanResult({
    required this.cleanedCount,
    required this.affectedUsers,
  });

  factory EmergencyCleanResult.fromMap(Map<String, dynamic> map) => EmergencyCleanResult(
      cleanedCount: map['cleaned_count'] ?? 0,
      affectedUsers: List<String>.from(map['affected_users'] ?? []),
    );
  final int cleanedCount;
  final List<String> affectedUsers;
}