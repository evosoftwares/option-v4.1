import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver_status.dart';
import '../models/supabase/driver_effective_status.dart';

/// Serviço para gerenciar o status online dos motoristas
/// Separa a intenção (toggle) do status efetivo (calculado pela view)
class DriverStatusService {
  DriverStatusService(this._supabase);
  final SupabaseClient _supabase;

  /// Busca o status de intenção online do motorista
  Future<DriverStatus?> getDriverStatus(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_status')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response == null) return null;
      return DriverStatus.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar status do motorista. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar status do motorista. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca o status efetivo do motorista (da view)
  Future<DriverEffectiveStatus?> getDriverEffectiveStatus(String driverId) async {
    print('🔵 [DRIVER_STATUS_SERVICE] getDriverEffectiveStatus iniciado');
    print('   🔹 Driver ID recebido: $driverId');
    print('   🔹 Tamanho do driverId: ${driverId.length}');
    print('   🔹 DriverId é vazio: ${driverId.isEmpty}');
    
    // Validação de driverId
    if (driverId.isEmpty) {
      print('❌ [DRIVER_STATUS_SERVICE] Driver ID inválido (vazio)');
      return null;
    }
    
    try {
      print('🔗 [DRIVER_STATUS_SERVICE] Fazendo consulta na view driver_effective_status...');
      print('   🔹 Query: SELECT * FROM driver_effective_status WHERE driver_id = \'$driverId\' LIMIT 1');
      final response = await _supabase
          .from('driver_effective_status')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      print('📊 [DRIVER_STATUS_SERVICE] Resposta da view: $response');
      print('📊 [DRIVER_STATUS_SERVICE] Tipo da resposta: ${response.runtimeType}');
      print('📊 [DRIVER_STATUS_SERVICE] Resposta é null: ${response == null}');

      if (response == null) {
        print('⚠️ [DRIVER_STATUS_SERVICE] Nenhum registro encontrado na view para o motorista $driverId');
        print('💡 [DRIVER_STATUS_SERVICE] Possíveis causas:');
        print('   🔍 Motorista não tem registro na driver_status');
        print('   🔍 Motorista não tem registro de status');
        print('   🔍 View driver_effective_status não está atualizada');
        print('   🔍 Problemas de permissão na view');
        return null;
      }
      
      print('✅ [DRIVER_STATUS_SERVICE] Dados encontrados na view, criando DriverEffectiveStatus...');
      print('   🔹 Conteúdo da resposta: ${response.toString()}');
      print('   🔹 Chaves da resposta: ${response.keys.toList()}');
      
      // Verificar se os campos necessários estão presentes
      final requiredFields = ['driver_id', 'online_intent', 'effective_online'];
      for (final field in requiredFields) {
        if (!response.containsKey(field)) {
          print('⚠️ [DRIVER_STATUS_SERVICE] Campo obrigatório ausente: $field');
        } else {
          print('   🔹 $field: ${response[field]}');
        }
      }
      
      final effectiveStatus = DriverEffectiveStatus.fromJson(response);
      print('📋 [DRIVER_STATUS_SERVICE] DriverEffectiveStatus criado com sucesso');
      print('   🔹 Driver ID: ${effectiveStatus.driverId}');
      print('   🔹 Online Intent: ${effectiveStatus.onlineIntent}');
      print('   🔹 Status Description: ${effectiveStatus.statusDescription}');
      print('   🔹 Effective Online: ${effectiveStatus.effectiveOnline}');
      
      return effectiveStatus;
    } on PostgrestException catch (e) {
      print('❌ [DRIVER_STATUS_SERVICE] PostgrestException em getDriverEffectiveStatus: ${e.code} - ${e.message}');
      print('❌ [DRIVER_STATUS_SERVICE] Details: ${e.details}');
      print('❌ [DRIVER_STATUS_SERVICE] Hint: ${e.hint}');
      
      if (e.code == '42P01') {
        print('💡 [DRIVER_STATUS_SERVICE] DIAGNÓSTICO: View driver_effective_status não existe!');
        print('💡 [DRIVER_STATUS_SERVICE] SOLUÇÃO: Execute o arquivo sql/auto_online_schema.sql');
      }
      
      throw DatabaseException(
        'Erro ao buscar status efetivo do motorista. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e, stackTrace) {
      print('❌ [DRIVER_STATUS_SERVICE] Erro inesperado em getDriverEffectiveStatus: ${e.toString()}');
      print('❌ [DRIVER_STATUS_SERVICE] Tipo do erro: ${e.runtimeType}');
      print('❌ [DRIVER_STATUS_SERVICE] Stack trace: $stackTrace');
      
      throw const DatabaseException(
        'Erro inesperado ao buscar status efetivo do motorista. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Atualiza a intenção online do motorista
  Future<DriverStatus> updateOnlineIntent(
    String driverId,
    bool onlineIntent,
  ) async {
    try {
      final data = {
        'driver_id': driverId,
        'online_intent': onlineIntent,
      };

      final response = await _supabase
          .from('driver_status')
          .upsert(data)
          .select()
          .single();

      return DriverStatus.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao atualizar status online. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao atualizar status online. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Cria ou atualiza o status do motorista
  Future<DriverStatus> createOrUpdateDriverStatus({
    required String driverId,
    required bool onlineIntent,
  }) async => updateOnlineIntent(driverId, onlineIntent);

  /// Liga o motorista (define intenção como true)
  Future<DriverStatus> setDriverOnline(String driverId) async => updateOnlineIntent(driverId, true);

  /// Desliga o motorista (define intenção como false)
  Future<DriverStatus> setDriverOffline(String driverId) async => updateOnlineIntent(driverId, false);

  /// Verifica se o motorista pode ficar online agora
  /// (documentos aprovados e elegível)
  Future<bool> canDriverGoOnlineNow(String driverId) async {
    print('🔵 [DRIVER_STATUS_SERVICE] canDriverGoOnlineNow iniciado');
    print('   🔹 Driver ID recebido: $driverId');
    
    // Validação de driverId
    if (driverId.isEmpty) {
      print('❌ [DRIVER_STATUS_SERVICE] Driver ID inválido (vazio)');
      return false;
    }
    
    try {
      // 1. Verificar se o motorista está aprovado
      print('🔗 [DRIVER_STATUS_SERVICE] Verificando aprovação do motorista...');
      final driverData = await _supabase
          .from('drivers')
          .select('approval_status')
          .eq('id', driverId)
          .single();
      
      final approvalStatus = driverData['approval_status'] as String?;
      print('📋 [DRIVER_STATUS_SERVICE] Status de aprovação: $approvalStatus');
      
      if (approvalStatus != 'approved') {
        print('❌ [DRIVER_STATUS_SERVICE] Motorista NÃO aprovado - não pode ficar online');
        return false;
      }
      
      // 2. Verificar se todos os documentos obrigatórios estão aprovados
      print('🔗 [DRIVER_STATUS_SERVICE] Verificando documentos obrigatórios...');
      final documentsStatus = await checkRequiredDocumentsApproved(driverId);
      
      if (!documentsStatus['allApproved']) {
        print('❌ [DRIVER_STATUS_SERVICE] Documentos obrigatórios NÃO aprovados');
        return false;
      }
      
      print('✅ [DRIVER_STATUS_SERVICE] Motorista aprovado e documentos OK - pode ficar online');
      return true;
      
    } catch (e) {
      print('❌ [DRIVER_STATUS_SERVICE] Erro ao verificar se pode ficar online: ${e.toString()}');
      print('⚠️ [DRIVER_STATUS_SERVICE] Retornando false por segurança');
      return false;
    }
  }

  /// Verifica se todos os documentos obrigatórios estão aprovados
  Future<Map<String, dynamic>> checkRequiredDocumentsApproved(String driverId) async {
    print('🔍 [DRIVER_STATUS_SERVICE] Verificando documentos obrigatórios para driver: $driverId');
    
    try {
      // Buscar documentos do motorista
      final documents = await _supabase
          .from('driver_documents')
          .select('document_type, status')
          .eq('driver_id', driverId)
          .eq('is_current', true);
      
      print('📋 [DRIVER_STATUS_SERVICE] Documentos encontrados: ${documents.length}');
      
      // Documentos obrigatórios
      const requiredDocuments = [
        'CNH_FRONT',
        'CNH_BACK', 
        'CRLV'
      ];
      
      final pendingDocuments = <String>[];
      final rejectedDocuments = <String>[];
      final approvedDocuments = <String>[];
      final missingDocuments = <String>[];
      
      // Mapear documentos existentes
      final documentsByType = <String, String>{};
      for (final doc in documents) {
        final type = doc['document_type'] as String;
        final status = doc['status'] as String;
        documentsByType[type] = status;
        
        print('   📄 $type: $status');
        
        switch (status) {
          case 'pending':
            pendingDocuments.add(type);
            break;
          case 'approved':
            approvedDocuments.add(type);
            break;
          case 'rejected':
            rejectedDocuments.add(type);
            break;
        }
      }
      
      // Verificar documentos obrigatórios em falta
      for (final required in requiredDocuments) {
        if (!documentsByType.containsKey(required)) {
          missingDocuments.add(required);
          print('   ❌ Documento obrigatório em falta: $required');
        }
      }
      
      // Determinar se todos os obrigatórios estão aprovados
      final allRequiredApproved = requiredDocuments.every(
        (required) => documentsByType[required] == 'approved'
      );
      
      final result = {
        'allApproved': allRequiredApproved,
        'approvedDocuments': approvedDocuments,
        'pendingDocuments': pendingDocuments,
        'rejectedDocuments': rejectedDocuments,
        'missingDocuments': missingDocuments,
        'totalRequired': requiredDocuments.length,
        'totalApproved': approvedDocuments.where(requiredDocuments.contains).length,
      };
      
      print('📊 [DRIVER_STATUS_SERVICE] Resultado da verificação:');
      print('   ✅ Todos aprovados: $allRequiredApproved');
      print('   📋 Aprovados (${approvedDocuments.length}): $approvedDocuments');
      print('   ⏳ Pendentes (${pendingDocuments.length}): $pendingDocuments');
      print('   ❌ Rejeitados (${rejectedDocuments.length}): $rejectedDocuments');
      print('   🔍 Em falta (${missingDocuments.length}): $missingDocuments');
      
      return result;
      
    } catch (e) {
      print('❌ [DRIVER_STATUS_SERVICE] Erro ao verificar documentos: $e');
      return {
        'allApproved': false,
        'approvedDocuments': <String>[],
        'pendingDocuments': <String>[],
        'rejectedDocuments': <String>[],
        'missingDocuments': <String>[],
        'error': e.toString(),
      };
    }
  }

  /// Busca todos os motoristas efetivamente online
  Future<List<DriverEffectiveStatus>> getOnlineDrivers() async {
    try {
      final response = await _supabase
          .from('driver_effective_status')
          .select()
          .eq('effective_online', true)
          .order('intent_updated_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => DriverEffectiveStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar motoristas online. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar motoristas online. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Busca motoristas com intenção online mas fora do horário
  Future<List<DriverEffectiveStatus>> getDriversWithIntentButOffline() async {
    try {
      final response = await _supabase
          .from('driver_effective_status')
          .select()
          .eq('online_intent', true)
          .eq('effective_online', false)
          .order('intent_updated_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => DriverEffectiveStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar motoristas com intenção online. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar motoristas com intenção online. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove o status do motorista (usado quando motorista é excluído)
  Future<void> deleteDriverStatus(String driverId) async {
    try {
      await _supabase
          .from('driver_status')
          .delete()
          .eq('driver_id', driverId);
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao remover status do motorista. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao remover status do motorista. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Inicializa o status do motorista (usado quando motorista é criado)
  Future<DriverStatus> initializeDriverStatus(
    String driverId, {
    bool initialOnlineIntent = false,
  }) async => createOrUpdateDriverStatus(
      driverId: driverId,
      onlineIntent: initialOnlineIntent,
    );

  /// Busca estatísticas de status dos motoristas
  Future<Map<String, int>> getDriverStatusStats() async {
    try {
      final response = await _supabase
          .from('driver_effective_status')
          .select('online_intent, effective_online');

      var totalDrivers = 0;
      var withIntent = 0;
      var effectivelyOnline = 0;
      var intentButOffline = 0;

      for (final row in response as List<dynamic>) {
        totalDrivers++;
        final intent = row['online_intent'] as bool;
        final effective = row['effective_online'] as bool;

        if (intent) withIntent++;
        if (effective) effectivelyOnline++;
        if (intent && !effective) intentButOffline++;
      }

      return {
        'total_drivers': totalDrivers,
        'with_intent': withIntent,
        'effectively_online': effectivelyOnline,
        'intent_but_offline': intentButOffline,
        'offline': totalDrivers - withIntent,
      };
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar estatísticas de status. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar estatísticas de status. Por favor, tente novamente mais tarde.',
      );
    }
  }
}