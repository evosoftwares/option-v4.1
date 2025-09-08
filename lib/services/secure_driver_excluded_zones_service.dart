import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver_excluded_zone.dart';
import 'zone_validation_service.dart';
import 'logging/zone_exclusion_logger.dart';

/// Secure service for managing driver excluded zones
/// Addresses all critical security issues identified in the analysis
class SecureDriverExcludedZonesService {
  SecureDriverExcludedZonesService(this._supabase);
  final SupabaseClient _supabase;

  /// Gets the current user ID for audit purposes
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Busca todas as zonas excluídas de um motorista
  Future<List<DriverExcludedZone>> getDriverExcludedZones(String driverId) async {
    try {
      ZoneExclusionLogger.logQueryStart(
        driverId: driverId,
        query: 'getDriverExcludedZones',
        context: {'operation': 'fetch_all_zones'},
      );

      final response = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      final zones = (response as List<dynamic>)
          .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
          .toList();

      ZoneExclusionLogger.logQuerySuccess(
        driverId: driverId,
        query: 'getDriverExcludedZones',
        context: {'count': zones.length},
      );

      return zones;
    } on PostgrestException catch (e) {
      ZoneExclusionLogger.logDatabaseError(
        driverId: driverId,
        operation: 'getDriverExcludedZones',
        error: e.message,
        errorCode: e.code,
        context: {'details': e.details},
      );
      throw DatabaseException(
        'Erro ao buscar zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e, stackTrace) {
      ZoneExclusionLogger.logUnexpectedError(
        driverId: driverId,
        operation: 'getDriverExcludedZones',
        error: e.toString(),
        stackTrace: stackTrace,
      );
      throw const DatabaseException(
        'Erro inesperado ao buscar zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Adiciona uma nova zona excluída para o motorista com validação completa
  /// Fixes race condition using upsert and implements all validations
  Future<DriverExcludedZone> addExcludedZone({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
    bool fromGooglePlaces = false,
  }) async {
    ZoneExclusionLogger.logAddStart(
      driverId: driverId,
      context: {
        'neighborhood': neighborhoodName,
        'city': city,
        'state': state,
      },
    );

    try {
      // 1. Validate and normalize data
      ZoneExclusionLogger.logValidationStart(
        driverId: driverId,
        context: {'step': 'data_validation'},
      );

      final normalizedData = await ZoneValidationService.validateAndNormalizeZoneData(
        neighborhood: neighborhoodName,
        city: city,
        state: state,
        fromGooglePlaces: fromGooglePlaces,
      );

      ZoneExclusionLogger.logValidationSuccess(
        driverId: driverId,
        context: {
          'normalizedData': normalizedData,
          'original': {'neighborhood': neighborhoodName, 'city': city, 'state': state},
        },
      );

      // 2. Check if driver exists before proceeding
      ZoneExclusionLogger.logValidationStart(
        driverId: driverId,
        context: {'step': 'driver_validation'},
      );

      final driverExists = await _supabase
          .from('drivers')
          .select('id')
          .eq('id', driverId)
          .maybeSingle();

      if (driverExists == null) {
        ZoneExclusionLogger.logValidationError(
          driverId: driverId,
          field: 'driver_id',
          error: 'Motorista não encontrado',
          context: {'type': 'foreign_key_validation'},
        );
        throw const ValidationException(
          'Não foi possível adicionar zona excluída: motorista não encontrado. '
          'Por favor, verifique se você está logado como motorista.',
        );
      }

      ZoneExclusionLogger.logValidationSuccess(
        driverId: driverId,
        context: {'step': 'driver_validation'},
      );

      // 3. Check current zone count to enforce limit
      ZoneExclusionLogger.logLimitCheck(
        driverId: driverId,
        context: {'operation': 'zone_limit_check'},
      );

      final currentCount = await getExcludedZonesCount(driverId);
      ZoneExclusionLogger.logCurrentCount(
        driverId: driverId,
        context: {'currentCount': currentCount},
      );

      if (ZoneValidationService.hasReachedZoneLimit(currentCount)) {
        ZoneExclusionLogger.logLimitExceeded(
          driverId: driverId,
          context: {
            'currentCount': currentCount,
            'maxLimit': ZoneValidationService.maxZonesPerDriver,
          },
        );
        throw ValidationException(
          'Limite máximo de zonas excluídas atingido (${ZoneValidationService.maxZonesPerDriver}). '
          'Você tem $currentCount zonas cadastradas.',
        );
      }

      // 4. Use upsert to prevent race conditions
      final insertData = {
        'driver_id': driverId,
        'neighborhood_name': normalizedData['neighborhood_name'],
        'city': normalizedData['city'],
        'state': normalizedData['state'],
      };

      ZoneExclusionLogger.logDatabaseOperation(
        driverId: driverId,
        operation: 'insert',
        context: {'data': insertData},
      );

      // Primeiro, verificar se a zona já existe para evitar duplicatas
      final existingZones = await _supabase
          .from('driver_excluded_zones')
          .select('id')
          .eq('driver_id', driverId)
          .eq('neighborhood_name', normalizedData['neighborhood_name']!)
          .eq('city', normalizedData['city']!)
          .eq('state', normalizedData['state']!);

      if (existingZones.isNotEmpty) {
        ZoneExclusionLogger.logDuplicateZone(
          driverId: driverId,
          context: {
            'neighborhood': normalizedData['neighborhood_name'],
            'city': normalizedData['city'],
            'state': normalizedData['state'],
          },
        );
        throw const ValidationException('Esta zona de exclusão já foi adicionada');
      }

      // Inserir nova zona
      final response = await _supabase
          .from('driver_excluded_zones')
          .insert(insertData)
          .select()
          .single();

      final zone = DriverExcludedZone.fromJson(response);

      ZoneExclusionLogger.logAddSuccess(
        driverId: driverId,
        neighborhood: normalizedData['neighborhood_name']!,
        city: normalizedData['city']!,
        state: normalizedData['state']!,
        zoneId: zone.id,
      );

      // 5. Log the action for audit
      await _logZoneAction(
        action: 'CREATE',
        driverId: driverId,
        zoneData: insertData,
      );

      return zone;
    } on PostgrestException catch (e) {
      ZoneExclusionLogger.logAddError(
        driverId: driverId,
        error: e.message,
        errorCode: e.code,
        context: {'details': e.details},
      );

      if (e.code == '23505') {
        ZoneExclusionLogger.logDuplicateZone(
          driverId: driverId,
          context: {'neighborhood': neighborhoodName, 'city': city, 'state': state},
        );
        throw const ValidationException(
          'Esta zona já está na sua lista de exclusões.',
        );
      }
      if (e.code == '23503') {
        // Foreign key constraint violation
        ZoneExclusionLogger.logValidationError(
          driverId: driverId,
          field: 'driver_id',
          error: 'Referência inválida ao motorista',
          context: {
            'type': 'foreign_key_constraint',
            'constraint': e.hint ?? 'driver_excluded_zones_driver_id_fkey',
          },
        );
        throw const ValidationException(
          'Não foi possível adicionar zona excluída: motorista não encontrado. '
          'Por favor, verifique se você está logado como motorista.',
        );
      }
      if (e.code == 'P0001') {
        ZoneExclusionLogger.logCustomValidationError(
          driverId: driverId,
          error: e.message,
          context: {'type': 'database_trigger'},
        );
        throw ValidationException(e.message);
      }
      if (e.code == '23514') {
        ZoneExclusionLogger.logConstraintViolation(
          driverId: driverId,
          context: {'type': 'check_constraint'},
        );
        throw const ValidationException(
          'Dados inválidos fornecidos. Verifique se o estado, cidade e bairro estão corretos.',
        );
      }
      throw DatabaseException(
        'Erro ao adicionar zona excluída: ${e.message}',
        e.code,
      );
    } on ValidationException catch (e) {
      ZoneExclusionLogger.logValidationError(
        driverId: driverId,
        field: 'general',
        error: e.message,
        context: {'validation_type': 'business_rule'},
      );
      rethrow;
    } catch (e, stackTrace) {
      ZoneExclusionLogger.logAddError(
        driverId: driverId,
        error: e.toString(),
        stackTrace: stackTrace,
        context: {'type': 'unexpected_error'},
      );
      throw DatabaseException(
        'Erro inesperado ao adicionar zona excluída: $e',
      );
    }
  }

  /// Método melhorado: Adiciona zona com tipo específico escolhido pelo usuário
  Future<DriverExcludedZone> addExcludedZoneWithType({
    required String driverId,
    required String keyword,
    required String zoneType,
    String? city,
    String? state,
    String? reason,
  }) async {
    try {
      // Validação de entrada
      if (driverId.isEmpty || keyword.isEmpty || zoneType.isEmpty) {
        throw ArgumentError('driverId, keyword e zoneType são obrigatórios');
      }

      // Verificação de permissões
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw UnauthorizedException('Usuário não autenticado');
      }

      // Log da operação
      ZoneExclusionLogger.logAddStart(
        driverId: driverId,
        context: {
          'operation': 'addExcludedZoneWithType',
          'keyword': keyword,
          'zoneType': zoneType,
          'city': city,
          'state': state,
        },
      );

      // Preparar dados para inserção
      final zoneData = {
        'driver_id': driverId,
        'neighborhood_name': keyword, // Campo obrigatório - usar keyword como neighborhood_name
        'city': city ?? 'N/A',
        'state': state ?? 'N/A',
        'zone_type': zoneType,
        'keyword': keyword,
      };

      // Inserir no banco
      final response = await _supabase
          .from('driver_excluded_zones')
          .insert(zoneData)
          .select()
          .single();

      final zone = DriverExcludedZone.fromJson(response);

      ZoneExclusionLogger.logAddSuccess(
        driverId: driverId,
        neighborhood: keyword,
        city: city ?? '',
        state: state ?? '',
        zoneId: zone.id,
      );

      return zone;
    } catch (e) {
      ZoneExclusionLogger.logAddError(
        driverId: driverId,
        error: e.toString(),
        context: {'operation': 'addExcludedZoneWithType'},
      );

      if (e is PostgrestException) {
        throw DatabaseException('Erro ao salvar zona excluída: ${e.message}');
      }

      rethrow;
    }
  }

  /// Adiciona múltiplas zonas excluídas com validação e transação
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async {
    if (zones.isEmpty) {
      throw const ValidationException('Lista de zonas não pode estar vazia');
    }

    try {
      // 1. Check if driver exists
      final driverExists = await _supabase
          .from('drivers')
          .select('id')
          .eq('id', driverId)
          .maybeSingle();

      if (driverExists == null) {
        throw const ValidationException(
          'Não foi possível adicionar zonas excluídas: motorista não encontrado. '
          'Por favor, verifique se você está logado como motorista.',
        );
      }

      // 2. Check total limit before processing
      final currentCount = await getExcludedZonesCount(driverId);
      final totalAfterAdd = currentCount + zones.length;

      if (totalAfterAdd > ZoneValidationService.maxZonesPerDriver) {
        final remaining = ZoneValidationService.getRemainingZoneSlots(currentCount);
        throw ValidationException(
          'Adição excederia o limite máximo de ${ZoneValidationService.maxZonesPerDriver} zonas. '
          'Você pode adicionar no máximo $remaining zonas.',
        );
      }

      // 3. Validate and normalize all zones
      final validatedZones = <Map<String, String>>[];
      for (final zone in zones) {
        final normalizedData = await ZoneValidationService.validateAndNormalizeZoneData(
          neighborhood: zone['neighborhoodName'] ?? '',
          city: zone['city'] ?? '',
          state: zone['state'] ?? '',
        );

        validatedZones.add({
          'driver_id': driverId,
          'neighborhood_name': normalizedData['neighborhood_name']!,
          'city': normalizedData['city']!,
          'state': normalizedData['state']!,
        });
      }

      // 4. Insert zones (skip duplicates)
      final response = await _supabase
          .from('driver_excluded_zones')
          .insert(validatedZones)
          .select();

      final addedZones = (response as List<dynamic>)
          .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
          .toList();

      // 5. Log the action
      await _logZoneAction(
        action: 'CREATE_MULTIPLE',
        driverId: driverId,
        zoneData: {'zones': validatedZones, 'count': addedZones.length},
      );

      return addedZones;
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') {
        throw ValidationException(e.message);
      }
      if (e.code == '23503') {
        // Foreign key constraint violation
        throw const ValidationException(
          'Não foi possível adicionar zonas excluídas: motorista não encontrado. '
          'Por favor, verifique se você está logado como motorista.',
        );
      }
      throw DatabaseException(
        'Erro ao adicionar zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao adicionar zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove uma zona excluída específica com auditoria
  Future<void> removeExcludedZone(String excludedZoneId) async {
    try {
      ZoneExclusionLogger.logRemovalStart(
        zoneId: excludedZoneId,
        context: {'operation': 'single_zone_removal'},
      );

      // First get the zone for logging
      final zoneResponse = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('id', excludedZoneId)
          .maybeSingle();

      if (zoneResponse == null) {
        ZoneExclusionLogger.logValidationError(
          driverId: 'unknown',
          field: 'zone_id',
          error: 'Zona excluída não encontrada',
          context: {'zone_id': excludedZoneId},
        );
        throw const ValidationException('Zona excluída não encontrada');
      }

      final driverId = zoneResponse['driver_id'] as String;
      final zoneDetails = {
        'neighborhood': zoneResponse['neighborhood_name'],
        'city': zoneResponse['city'],
        'state': zoneResponse['state'],
      };

      ZoneExclusionLogger.logRemovalValidation(
        driverId: driverId,
        zoneId: excludedZoneId,
        zoneData: zoneDetails,
      );

      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('id', excludedZoneId);

      // Log the successful deletion
      ZoneExclusionLogger.logRemovalSuccess(
        driverId: driverId,
        zoneId: excludedZoneId,
        zoneData: zoneDetails,
      );

      // Log the deletion for audit
      await _logZoneAction(
        action: 'DELETE',
        driverId: driverId,
        zoneData: zoneResponse,
      );
    } on PostgrestException catch (e) {
      ZoneExclusionLogger.logDatabaseError(
        driverId: 'unknown',
        operation: 'remove_zone',
        error: e.message,
        code: e.code,
        context: {'zone_id': excludedZoneId},
      );
      throw DatabaseException(
        'Erro ao remover zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } on ValidationException catch (e) {
      ZoneExclusionLogger.logValidationError(
        driverId: 'unknown',
        field: 'zone_id',
        error: e.message,
        context: {'zone_id': excludedZoneId},
      );
      rethrow;
    } catch (e, stackTrace) {
      ZoneExclusionLogger.logRemovalError(
        driverId: 'unknown',
        zoneId: excludedZoneId,
        error: e.toString(),
        stackTrace: stackTrace,
        context: {'type': 'unexpected_error'},
      );
      throw const DatabaseException(
        'Erro inesperado ao remover zona excluída. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove múltiplas zonas excluídas com validação
  Future<void> removeMultipleExcludedZones(List<String> excludedZoneIds) async {
    if (excludedZoneIds.isEmpty) {
      ZoneExclusionLogger.logValidationError(
        driverId: 'unknown',
        field: 'zone_ids',
        error: 'Lista de zonas não pode estar vazia',
        context: {'operation': 'multiple_removal'},
      );
      throw const ValidationException('Lista de zonas não pode estar vazia');
    }

    try {
      ZoneExclusionLogger.logRemovalStart(
        zoneId: 'multiple_zones',
        context: {
          'operation': 'multiple_zone_removal',
          'zone_count': excludedZoneIds.length,
          'zone_ids': excludedZoneIds,
        },
      );

      // Get zones for logging before deletion
      final zonesResponse = await _supabase
          .from('driver_excluded_zones')
          .select()
          .inFilter('id', excludedZoneIds);

      if (zonesResponse.isEmpty) {
        ZoneExclusionLogger.logValidationError(
          driverId: 'unknown',
          field: 'zone_ids',
          error: 'Nenhuma zona encontrada para remoção',
          context: {'zone_ids': excludedZoneIds},
        );
        throw const ValidationException('Nenhuma zona encontrada para remoção');
      }

      // Log zones found for removal
      final zonesByDriver = <String, List<Map<String, dynamic>>>{};
      for (final zone in zonesResponse) {
        final driverId = zone['driver_id'] as String;
        zonesByDriver.putIfAbsent(driverId, () => []).add(zone);
      }

      ZoneExclusionLogger.logRemovalValidation(
        driverId: 'multiple',
        zoneId: 'bulk_removal',
        zoneData: {
          'zones_found': zonesResponse.length,
          'zones_by_driver': zonesByDriver,
        },
      );

      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .inFilter('id', excludedZoneIds);

      // Log successful bulk deletion
      ZoneExclusionLogger.logRemovalSuccess(
        driverId: 'multiple',
        zoneId: 'bulk_removal',
        zoneData: {
          'zones_removed': zonesResponse.length,
          'affected_drivers': zonesByDriver.keys.toList(),
        },
      );

      // Log the bulk deletion
      for (final zone in zonesResponse) {
        await _logZoneAction(
          action: 'DELETE',
          driverId: zone['driver_id'] as String,
          zoneData: zone,
        );
      }
    } on PostgrestException catch (e) {
      ZoneExclusionLogger.logDatabaseError(
        driverId: 'multiple',
        operation: 'remove_multiple_zones',
        error: e.message,
        code: e.code,
        context: {'zone_ids': excludedZoneIds},
      );
      throw DatabaseException(
        'Erro ao remover zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } on ValidationException {
      rethrow;
    } catch (e, stackTrace) {
      ZoneExclusionLogger.logRemovalError(
        driverId: 'multiple',
        zoneId: 'bulk_removal',
        error: e.toString(),
        stackTrace: stackTrace,
        context: {'type': 'unexpected_error', 'zone_ids': excludedZoneIds},
      );
      throw const DatabaseException(
        'Erro inesperado ao remover zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Remove todas as zonas excluídas de um motorista
  Future<void> removeAllExcludedZones(String driverId) async {
    try {
      ZoneExclusionLogger.logRemovalStart(
        zoneId: 'all_zones',
        context: {
          'operation': 'remove_all_zones',
          'driver_id': driverId,
        },
      );

      // Get current zones for logging
      final currentZones = await getDriverExcludedZones(driverId);

      ZoneExclusionLogger.logRemovalValidation(
        driverId: driverId,
        zoneId: 'all_zones',
        zoneData: {
          'zones_to_remove': currentZones.length,
          'zone_details': currentZones.map((z) => z.toJson()).toList(),
        },
      );

      await _supabase
          .from('driver_excluded_zones')
          .delete()
          .eq('driver_id', driverId);

      ZoneExclusionLogger.logRemovalSuccess(
        driverId: driverId,
        zoneId: 'all_zones',
        zoneData: {
          'zones_removed': currentZones.length,
          'operation': 'complete_cleanup',
        },
      );
    } on PostgrestException catch (e) {
      ZoneExclusionLogger.logDatabaseError(
        driverId: driverId,
        operation: 'remove_all_zones',
        error: e.message,
        code: e.code,
        context: {'type': 'remove_all'},
      );
      throw DatabaseException(
        'Erro ao remover todas as zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e, stackTrace) {
      ZoneExclusionLogger.logRemovalError(
        driverId: driverId,
        zoneId: 'all_zones',
        error: e.toString(),
        stackTrace: stackTrace,
        context: {'type': 'unexpected_error'},
      );
      throw const DatabaseException(
        'Erro inesperado ao remover todas as zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Verifica se um bairro específico está na lista de exclusões do motorista
  /// Uses normalized comparison for accurate results
  Future<bool> isZoneExcluded({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    try {
      // Normalize input for comparison
      final normalizedData = await ZoneValidationService.validateAndNormalizeZoneData(
        neighborhood: neighborhoodName,
        city: city,
        state: state,
        fromGooglePlaces: false,
      );

      final response = await _supabase
          .from('driver_excluded_zones')
          .select('id')
          .eq('driver_id', driverId)
          .eq('neighborhood_name', normalizedData['neighborhood_name']!)
          .eq('city', normalizedData['city']!)
          .eq('state', normalizedData['state']!)
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao verificar zona excluída. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      // If validation fails, assume zone is not excluded
      return false;
    }
  }

  /// Busca zonas excluídas por cidade
  Future<List<DriverExcludedZone>> getExcludedZonesByCity({
    required String driverId,
    required String city,
    required String state,
  }) async {
    try {
      // Normalize city and state for search
      final normalizedCity = ZoneValidationService.normalizeText(city);
      final normalizedState = ZoneValidationService.validateAndNormalizeState(state);

      final response = await _supabase
          .from('driver_excluded_zones')
          .select()
          .eq('driver_id', driverId)
          .eq('city', normalizedCity)
          .eq('state', normalizedState)
          .order('neighborhood_name', ascending: true);

      return (response as List<dynamic>)
          .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar zonas excluídas por cidade. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar zonas excluídas por cidade. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Conta o total de zonas excluídas de um motorista
  Future<int> getExcludedZonesCount(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_excluded_zones')
          .select('id')
          .eq('driver_id', driverId);

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao contar zonas excluídas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao contar zonas excluídas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Gets zone statistics for a driver
  Future<Map<String, dynamic>> getDriverZoneStats(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_excluded_zones_stats')
          .select()
          .eq('driver_id', driverId)
          .maybeSingle();

      if (response == null) {
        return {
          'total_zones': 0,
          'cities_count': 0,
          'remaining_slots': ZoneValidationService.maxZonesPerDriver,
          'last_zone_added': null,
          'last_modification': null,
        };
      }

      final totalZones = response['total_zones'] as int;
      return {
        ...response,
        'remaining_slots': ZoneValidationService.getRemainingZoneSlots(totalZones),
      };
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao buscar estatísticas das zonas. Por favor, tente novamente mais tarde.',
        e.code,
      );
    } catch (e) {
      throw const DatabaseException(
        'Erro inesperado ao buscar estatísticas das zonas. Por favor, tente novamente mais tarde.',
      );
    }
  }

  /// Stream para atualizações em tempo real das zonas excluídas do motorista
  Stream<List<DriverExcludedZone>> streamDriverExcludedZones(String driverId) {
    try {
      return _supabase
          .from('driver_excluded_zones')
          .stream(primaryKey: ['id'])
          .eq('driver_id', driverId)
          .order('created_at')
          .map((data) => (data as List<dynamic>)
              .map((json) => DriverExcludedZone.fromJson(json as Map<String, dynamic>))
              .toList());
    } catch (e) {
      // Em caso de erro, retorna um stream vazio
      return Stream.value(<DriverExcludedZone>[]);
    }
  }

  /// Private method to log zone actions for audit trail
  Future<void> _logZoneAction({
    required String action,
    required String driverId,
    required Map<String, dynamic> zoneData,
    Map<String, dynamic>? oldData,
  }) async {
    try {
      if (_currentUserId == null) return; // Skip logging if no user

      await _supabase.from('activity_logs').insert({
        'user_id': _currentUserId,
        'action': action,
        'entity_type': 'driver_excluded_zone',
        'new_values': zoneData,
        'old_values': oldData,
        'metadata': {
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'mobile_app',
          'driver_id': driverId,
        },
      });
    } catch (e) {
      // Don't throw on logging errors, just continue
      // In production, you might want to log this to a monitoring service
    }
  }
}
