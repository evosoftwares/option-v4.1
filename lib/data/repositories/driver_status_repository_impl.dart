import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/driver_status_repository.dart';
import '../../domain/entities/driver_status.dart';
import '../../domain/entities/driver_effective_status.dart';
import '../datasources/driver_status_api_data_source.dart';
import '../../data/models/supabase/driver_status.dart' as model;
import '../../data/models/supabase/driver_effective_status.dart' as model;

class DriverStatusRepositoryImpl implements DriverStatusRepository {
  final DriverStatusApiDataSource _dataSource;

  DriverStatusRepositoryImpl(this._dataSource);

  @override
  Future<DriverStatus?> getDriverStatus(String driverId) async {
    try {
      final data = await _dataSource.getDriverStatus(driverId);
      if (data == null) return null;
      
      final driverStatus = model.DriverStatus.fromJson(data);
      return driverStatus.toEntity();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar status do motorista: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar status do motorista: $e');
    }
  }

  @override
  Future<DriverEffectiveStatus?> getDriverEffectiveStatus(String driverId) async {
    if (driverId.isEmpty) {
      return null;
    }
    
    try {
      final data = await _dataSource.getDriverEffectiveStatus(driverId);
      if (data == null) return null;
      
      final driverStatus = model.DriverEffectiveStatus.fromJson(data);
      return driverStatus.toEntity();
    } on PostgrestException catch (e) {
      if (e.code == '42P01') {
        throw Exception('View driver_effective_status não existe. Execute o arquivo sql/auto_online_schema.sql');
      }
      throw Exception('Erro ao buscar status efetivo do motorista: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar status efetivo do motorista: $e');
    }
  }

  @override
  Future<DriverStatus> updateOnlineIntent(String driverId, bool onlineIntent) async {
    try {
      final data = await _dataSource.updateOnlineIntent(driverId, onlineIntent);
      final driverStatus = model.DriverStatus.fromJson(data);
      return driverStatus.toEntity();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao atualizar status online: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao atualizar status online: $e');
    }
  }

  @override
  Future<DriverStatus> setDriverOnline(String driverId) async {
    return updateOnlineIntent(driverId, true);
  }

  @override
  Future<DriverStatus> setDriverOffline(String driverId) async {
    return updateOnlineIntent(driverId, false);
  }

  @override
  Future<bool> canDriverGoOnlineNow(String driverId) async {
    if (driverId.isEmpty) {
      return false;
    }
    
    try {
      // 1. Verificar se o motorista está aprovado
      final driverData = await _dataSource.getDriverApprovalStatus(driverId);
      if (driverData == null) {
        return false;
      }
      
      final approvalStatus = driverData['approval_status'] as String?;
      if (approvalStatus != 'approved') {
        return false;
      }
      
      // 2. Verificar se todos os documentos obrigatórios estão aprovados
      final documentsStatus = await checkRequiredDocumentsApproved(driverId);
      return documentsStatus['allApproved'] == true;
      
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> checkRequiredDocumentsApproved(String driverId) async {
    try {
      // Buscar documentos do motorista
      final documents = await _dataSource.getDriverDocuments(driverId);
      
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
        }
      }
      
      // Determinar se todos os obrigatórios estão aprovados
      final allRequiredApproved = requiredDocuments.every(
        (required) => documentsByType[required] == 'approved'
      );
      
      return {
        'allApproved': allRequiredApproved,
        'approvedDocuments': approvedDocuments,
        'pendingDocuments': pendingDocuments,
        'rejectedDocuments': rejectedDocuments,
        'missingDocuments': missingDocuments,
        'totalRequired': requiredDocuments.length,
        'totalApproved': approvedDocuments.where(requiredDocuments.contains).length,
      };
      
    } catch (e) {
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

  @override
  Future<List<DriverEffectiveStatus>> getOnlineDrivers() async {
    try {
      final dataList = await _dataSource.getOnlineDrivers();
      return dataList
          .map((data) => model.DriverEffectiveStatus.fromJson(data).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar motoristas online: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar motoristas online: $e');
    }
  }

  @override
  Future<List<DriverEffectiveStatus>> getDriversWithIntentButOffline() async {
    try {
      final dataList = await _dataSource.getDriversWithIntentButOffline();
      return dataList
          .map((data) => model.DriverEffectiveStatus.fromJson(data).toEntity())
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erro ao buscar motoristas com intenção online: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar motoristas com intenção online: $e');
    }
  }

  @override
  Future<void> deleteDriverStatus(String driverId) async {
    try {
      await _dataSource.deleteDriverStatus(driverId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao remover status do motorista: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao remover status do motorista: $e');
    }
  }

  @override
  Future<DriverStatus> initializeDriverStatus(
    String driverId, {
    bool initialOnlineIntent = false,
  }) async {
    return updateOnlineIntent(driverId, initialOnlineIntent);
  }

  @override
  Future<Map<String, int>> getDriverStatusStats() async {
    try {
      final dataList = await _dataSource.getDriverStatusStats();

      var totalDrivers = 0;
      var withIntent = 0;
      var effectivelyOnline = 0;
      var intentButOffline = 0;

      for (final row in dataList) {
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
      throw Exception('Erro ao buscar estatísticas de status: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar estatísticas de status: $e');
    }
  }

  @override
  Future<void> updateLastNotificationAt(String driverId) async {
    try {
      await _dataSource.updateLastNotificationAt(driverId);
    } catch (e) {
      // Não falha a operação principal se a atualização falhar
    }
  }
}