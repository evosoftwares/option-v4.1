import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_handling/error_logger.dart';
import '../core/error_handling/app_error.dart';
import '../models/supabase/driver.dart';
import '../models/supabase/driver_offer.dart';
import '../models/supabase/driver_effective_status.dart';
import '../models/supabase/trip.dart';
import '../models/vehicle_category.dart';
import '../validators/database_constraints_validator.dart';
import 'driver_excluded_zones_service.dart';
import 'driver_status_service.dart';
import 'platform_settings_service.dart';
import 'vehicle_category_validator.dart';
import '../utils/supabase_helper.dart';

/// Classe auxiliar para armazenar motorista com sua distância calculada
class DriverWithDistance {
  const DriverWithDistance({
    required this.driver,
    required this.distanceKm,
  });

  final Driver driver;
  final double distanceKm;
}

/// Classe auxiliar para erro específico de motorista
class DriverError extends AppError {
  const DriverError(super.message, [super.code]);
}

/// PostgrestException mapper específico para drivers
class DriverPostgrestErrorMapper extends PostgrestErrorMapper {
  static AppError mapError(PostgrestException e) {
    if (e.code == '23505' && (e.message?.contains('drivers_user_id_key') ?? false)) {
      return const DriverError('Já existe um cadastro de motorista para este usuário.', 'DRIVER_EXISTS');
    }
    if (e.code == '23503' && (e.message?.contains('drivers_user_id_fkey') ?? false)) {
      return const DriverError('Usuário não encontrado.', 'USER_NOT_FOUND');
    }
    if (e.code == '23505' && (e.message?.contains('drivers_cnh_number_key') ?? false)) {
      return const DriverError('Número da CNH já cadastrado.', 'CNH_EXISTS');
    }
    if (e.code == '23505' && (e.message?.contains('drivers_vehicle_plate_key') ?? false)) {
      return const DriverError('Placa do veículo já cadastrada.', 'PLATE_EXISTS');
    }
    return PostgrestErrorMapper.mapError(e);
  }
}

/// Serviço para gerenciar motoristas
class DriverService {
  DriverService(this._supabase) {
    _driverStatusService = DriverStatusService(_supabase);
    _driverExcludedZonesService = DriverExcludedZonesService(_supabase);
    _platformSettingsService = PlatformSettingsService(_supabase);
    _vehicleCategoryValidator = VehicleCategoryValidator(_supabase);
  }

  final SupabaseClient _supabase;
  late final DriverStatusService _driverStatusService;
  late final DriverExcludedZonesService _driverExcludedZonesService;
  late final PlatformSettingsService _platformSettingsService;
  late final VehicleCategoryValidator _vehicleCategoryValidator;

  /// Busca um motorista pelo ID
  Future<Driver?> getDriver(String driverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('id', driverId)
          .maybeSingle();

      if (response == null) return null;
      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao buscar motorista.');
    }
  }

  /// Busca um motorista pelo ID do usuário
  Future<Driver?> getDriverByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao buscar motorista.');
    }
  }

  /// Cria um novo motorista
  Future<Driver> createDriver(Map<String, dynamic> driverData) async {
    try {
      final validator = DatabaseConstraintsValidator(_supabase);
      await validator.validateDriverConstraints(driverData);

      final response = await _supabase
          .from('drivers')
          .insert(driverData)
          .select()
          .single();

      final driver = Driver.fromJson(response);

      // Inicializar status do motorista
      await _driverStatusService.initializeDriverStatus(driver.id);

      return driver;
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao criar motorista.');
    }
  }

  /// Atualiza dados do motorista
  Future<Driver> updateDriver(String driverId, Map<String, dynamic> updates) async {
    try {
      final validator = DatabaseConstraintsValidator(_supabase);
      await validator.validateDriverConstraints(updates, isUpdate: true);

      final response = await _supabase
          .from('drivers')
          .update(updates)
          .eq('id', driverId)
          .select()
          .single();

      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao atualizar motorista.');
    }
  }

  /// Remove um motorista
  Future<void> deleteDriver(String driverId) async {
    try {
      await _supabase
          .from('drivers')
          .delete()
          .eq('id', driverId);
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao remover motorista.');
    }
  }

  /// Busca motoristas com paginação
  Future<List<Driver>> getDrivers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      dynamic query = _supabase
          .from('drivers')
          .select()
          .order('created_at', ascending: false);

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'full_name.ilike.%$search%,email.ilike.%$search%,vehicle_plate.ilike.%$search%',
        );
      }

      if (status != null && status.isNotEmpty) {
        query = query.eq('approval_status', status);
      }

      final response = await query
          .range((page - 1) * limit, page * limit - 1);

      return (response as List<dynamic>)
          .map((json) => Driver.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao buscar motoristas.');
    }
  }

  /// Conta total de motoristas
  Future<int> getDriversCount({String? search, String? status}) async {
    try {
      dynamic query = _supabase
          .from('drivers')
          .select('count()', count: CountOption.exact);

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'full_name.ilike.%$search%,email.ilike.%$search%,vehicle_plate.ilike.%$search%',
        );
      }

      if (status != null && status.isNotEmpty) {
        query = query.eq('approval_status', status);
      }

      final response = await query;
      return (response as List<dynamic>).first['count'] as int;
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao contar motoristas.');
    }
  }

  /// Aprova ou rejeita um motorista
  Future<Driver> reviewDriver(
    String driverId,
    String status,
    String? reviewedBy,
    String? rejectionReason,
  ) async {
    try {
      final updates = <String, dynamic>{
        'approval_status': status,
        'approved_by': reviewedBy,
        'approved_at': status == 'approved' ? DateTime.now().toIso8601String() : null,
        'rejection_reason': status == 'rejected' ? rejectionReason : null,
      };

      final response = await _supabase
          .from('drivers')
          .update(updates)
          .eq('id', driverId)
          .select()
          .single();

      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao revisar motorista.');
    }
  }

  /// Define status online do motorista
  Future<void> setDriverOnlineStatus(String driverId, bool isOnline) async {
    try {
      await _supabase
          .from('drivers')
          .update({'is_online': isOnline})
          .eq('id', driverId);
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao atualizar status online.');
    }
  }

  /// Atualiza localização do motorista
  Future<void> updateDriverLocation(
    String driverId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _supabase
          .from('drivers')
          .update({
        'current_latitude': latitude,
        'current_longitude': longitude,
        'last_location_update': DateTime.now().toIso8601String(),
      })
          .eq('id', driverId);
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao atualizar localização.');
    }
  }

  /// Busca viagens ativas do motorista
  Future<List<Trip>> getDriverActiveTrips(String driverId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('driver_id', driverId)
          .inFilter('status', ['accepted', 'in_progress', 'arrived']);

      return (response as List<dynamic>)
          .map((json) => Trip.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao buscar viagens ativas.');
    }
  }

  /// Busca histórico de viagens do motorista
  Future<List<Trip>> getDriverTripHistory(
    String driverId, {
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      dynamic query = _supabase
          .from('trips')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response = await query
          .range((page - 1) * limit, page * limit - 1);

      return (response as List<dynamic>)
          .map((json) => Trip.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao buscar histórico de viagens.');
    }
  }

  /// Conta viagens do motorista
  Future<int> getDriverTripsCount(String driverId, {String? status}) async {
    try {
      dynamic query = _supabase
          .from('trips')
          .select('count()', count: CountOption.exact)
          .eq('driver_id', driverId);

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response = await query;
      return (response as List<dynamic>).first['count'] as int;
    } on PostgrestException catch (e) {
      throw DriverPostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DriverError('Erro inesperado ao contar viagens.');
    }
  }

  /// Busca status efetivo do motorista
  Future<DriverEffectiveStatus?> getDriverEffectiveStatus(String driverId) async =>
      await _driverStatusService.getDriverEffectiveStatus(driverId);

  /// Define intenção online do motorista
  Future<DriverStatus> setDriverOnlineIntent(String driverId, bool isOnline) async {
    if (isOnline) {
      // Verificar se o motorista pode ficar online
      final canGoOnline = await _driverStatusService.canDriverGoOnlineNow(driverId);
      if (!canGoOnline) {
        throw const DriverError('Motorista não pode ficar online. Verifique aprovação e documentos.');
      }
    }

    return isOnline
        ? await _driverStatusService.setDriverOnline(driverId)
        : await _driverStatusService.setDriverOffline(driverId);
  }

  /// Obtém a intenção online do motorista
  Future<bool> getDriverOnlineIntent(String driverId) async {
    final status = await _driverStatusService.getDriverStatus(driverId);
    return status?.onlineIntent ?? false;
  }

  /// Busca motoristas disponíveis próximos usando a view otimizada available_drivers_view
  Future<List<Driver>> getAvailableDriversNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? category,
    bool? needsPet,
    bool? needsGrocerySpace,
    bool? isCondoOrigin,
    bool? isCondoDestination,
    bool? needsAc,
    String? destinationNeighborhood,
    String? destinationCity,
    String? destinationState,
    int? limit,
  }) async {
    print('🔍 [${DateTime.now()}] Iniciando getAvailableDriversNearby...');
    print('📍 Parâmetros de busca:');
    print('  - latitude: $latitude');
    print('  - longitude: $longitude');
    print('  - radiusKm: $radiusKm');
    print('  - category: $category');
    print('  - needsPet: $needsPet');
    print('  - needsGrocerySpace: $needsGrocerySpace');
    print('  - isCondoOrigin: $isCondoOrigin');
    print('  - isCondoDestination: $isCondoDestination');
    print('  - needsAc: $needsAc');
    print('  - limit: $limit');
    
    try {
      // Aproximação de raio usando bounding box
      final latDelta = radiusKm / 111.0; // ~111km por grau
      final lngDelta = radiusKm / (111.0 * math.cos(latitude * math.pi / 180.0)).abs().clamp(0.0001, double.infinity);
      
      print('📐 [${DateTime.now()}] Calculando bounding box:');
      print('  - latDelta: $latDelta');
      print('  - lngDelta: $lngDelta');
      print('  - lat range: ${latitude - latDelta} to ${latitude + latDelta}');
      print('  - lng range: ${longitude - lngDelta} to ${longitude + lngDelta}');

      // Tentar usar a view available_drivers_view otimizada primeiro
      dynamic response;
      var usedOptimizedView = false;
      
      try {
        print('🚀 [${DateTime.now()}] Tentando usar available_drivers_view otimizada...');
        
        dynamic query = _supabase.from('available_drivers_view').select().eq('is_online', true);
        print('🔧 [${DateTime.now()}] Query inicial criada: available_drivers_view online');

        // Filtro de categoria
        if (category != null && category.isNotEmpty) {
          query = query.eq('vehicle_category', category);
          print('🚗 [${DateTime.now()}] Filtro de categoria aplicado: $category');
        }

        // Preferências
        if (needsPet ?? false) {
          query = query.eq('accepts_pet', true);
          print('🐕 [${DateTime.now()}] Filtro pet aplicado');
        }
        if (needsGrocerySpace ?? false) {
          query = query.eq('accepts_grocery', true);
          print('🛒 [${DateTime.now()}] Filtro grocery aplicado');
        }
        if ((isCondoOrigin ?? false) || (isCondoDestination ?? false)) {
          query = query.eq('accepts_condo', true);
          print('🏢 [${DateTime.now()}] Filtro condo aplicado');
        }
        
        // Filtro de ar-condicionado
        if (needsAc ?? false) {
          query = query.or('ac_policy.eq.always_on,ac_policy.eq.on_request');
          print('❄️ [${DateTime.now()}] Filtro ar-condicionado aplicado');
        }

        // Bounding box
        query = query
            .gte('current_latitude', latitude - latDelta)
            .lte('current_latitude', latitude + latDelta)
            .gte('current_longitude', longitude - lngDelta)
            .lte('current_longitude', longitude + lngDelta)
            .order('average_rating', ascending: false);
        print('📍 [${DateTime.now()}] Filtro de localização aplicado');

        if (limit != null && limit > 0) {
          query = query.limit(limit);
          print('🔢 [${DateTime.now()}] Limite aplicado: $limit');
        }

        response = await query;
        usedOptimizedView = true;
        print('✅ [${DateTime.now()}] View otimizada utilizada com sucesso! Registros retornados: ${(response as List).length}');
      } catch (e) {
        print('⚠️ [${DateTime.now()}] View otimizada não disponível, usando fallback para tabela drivers: $e');
        
        // Fallback para a tabela drivers original
        dynamic query = _supabase.from('drivers').select().eq('is_online', true);
        print('🔧 [${DateTime.now()}] Query fallback criada: drivers online');

        // Somente aprovados
        query = query.or('approval_status.eq.approved,approval_status.is.null');
        print('✅ [${DateTime.now()}] Filtro de aprovação aplicado');

        // Filtro de categoria
        if (category != null && category.isNotEmpty) {
          query = query.eq('vehicle_category', category);
          print('🚗 [${DateTime.now()}] Filtro de categoria aplicado: $category');
        }

        // Preferências
        if (needsPet ?? false) {
          query = query.eq('accepts_pet', true);
          print('🐕 [${DateTime.now()}] Filtro pet aplicado');
        }
        if (needsGrocerySpace ?? false) {
          query = query.eq('accepts_grocery', true);
          print('🛒 [${DateTime.now()}] Filtro grocery aplicado');
        }
        if ((isCondoOrigin ?? false) || (isCondoDestination ?? false)) {
          query = query.eq('accepts_condo', true);
          print('🏢 [${DateTime.now()}] Filtro condo aplicado');
        }
        
        // Filtro de ar-condicionado
        if (needsAc ?? false) {
          query = query.or('ac_policy.eq.always_on,ac_policy.eq.on_request');
          print('❄️ [${DateTime.now()}] Filtro ar-condicionado aplicado');
        }

        // Bounding box
        query = query
            .gte('current_latitude', latitude - latDelta)
            .lte('current_latitude', latitude + latDelta)
            .gte('current_longitude', longitude - lngDelta)
            .lte('current_longitude', longitude + lngDelta);
        print('📍 [${DateTime.now()}] Filtro de localização aplicado');

        if (limit != null && limit > 0) {
          query = query.limit(limit);
          print('🔢 [${DateTime.now()}] Limite aplicado: $limit');
        }

        try {
          query = query.order('average_rating', ascending: false);
          response = await query;
        } on PostgrestException catch (e2) {
          // Fallback sem ordenação por average_rating se a coluna não existir
          final msg = (e2.message ?? '').toLowerCase();
          final isMissingAverageRating = e2.code == '42703' || msg.contains('average_rating') || msg.contains('column');
          if (isMissingAverageRating) {
            if (kDebugMode) {
              debugPrint('getAvailableDriversNearby: coluna average_rating ausente. Aplicando fallback sem ordenação. (${e2.code})');
            }
            // Recriar query sem ordenação
            dynamic fb = _supabase.from('drivers').select().eq('is_online', true);
            fb = fb.or('approval_status.eq.approved,approval_status.is.null');
            if (category != null && category.isNotEmpty) fb = fb.eq('vehicle_category', category);
            if (needsPet ?? false) fb = fb.eq('accepts_pet', true);
            if (needsGrocerySpace ?? false) fb = fb.eq('accepts_grocery', true);
            if ((isCondoOrigin ?? false) || (isCondoDestination ?? false)) fb = fb.eq('accepts_condo', true);
            if (needsAc ?? false) fb = fb.or('ac_policy.eq.always_on,ac_policy.eq.on_request');
            fb = fb
                .gte('current_latitude', latitude - latDelta)
                .lte('current_latitude', latitude + latDelta)
                .gte('current_longitude', longitude - lngDelta)
                .lte('current_longitude', longitude + lngDelta);
            if (limit != null && limit > 0) fb = fb.limit(limit);
            response = await fb;
          } else {
            rethrow;
          }
        }
        
        print('📊 [${DateTime.now()}] Query fallback executada com sucesso. Registros retornados: ${(response as List).length}');
      }

      print('🔄 [${DateTime.now()}] Processando dados dos motoristas...');
      var drivers = <Driver>[];
      
      if (usedOptimizedView) {
        // Converter dados da view para objetos Driver
        for (final json in response) {
          final driverData = json as Map<String, dynamic>;
          // Mapear campos da view para campos esperados pelo modelo Driver
          final mappedData = {
            'id': driverData['driver_id'],
            'user_id': driverData['user_id'],
            'vehicle_brand': driverData['vehicle_brand'],
            'vehicle_model': driverData['vehicle_model'],
            'vehicle_year': driverData['vehicle_year'],
            'vehicle_color': driverData['vehicle_color'],
            'vehicle_category': driverData['vehicle_category'],
            'vehicle_plate': driverData['vehicle_plate'] ?? '', // Assumindo que pode não existir na view
  
            'approval_status': 'approved', // Só motoristas aprovados aparecem na view
            'is_online': driverData['is_online'],
            'accepts_pet': driverData['accepts_pet'],
            'accepts_grocery': driverData['accepts_grocery'], 
            'accepts_condo': driverData['accepts_condo'],
            'ac_policy': driverData['ac_policy'],
            'custom_price_per_km': driverData['custom_price_per_km'],
            'custom_price_per_minute': driverData['custom_price_per_minute'],
            'pet_fee': driverData['pet_fee'],
            'grocery_fee': driverData['grocery_fee'],
            'condo_fee': driverData['condo_fee'],
            'stop_fee': driverData['stop_fee'],
            'consecutive_cancellations': 0, // Assumir 0 para motoristas na view
            'total_trips': driverData['total_trips'] ?? 0,
            'average_rating': driverData['average_rating'] ?? 0.0,
            'current_latitude': driverData['current_latitude'],
            'current_longitude': driverData['current_longitude'],
            'last_location_update': driverData['last_location_update'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          try {
            drivers.add(Driver.fromJson(mappedData));
          } catch (e) {
            print('⚠️ Erro ao mapear motorista da view: $e');
            // Continuar com outros motoristas
          }
        }
      } else {
        // Dados já no formato esperado da tabela drivers
        drivers = response
            .map((json) => Driver.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      print('✅ [${DateTime.now()}] ${drivers.length} motoristas processados com sucesso');

      // Filtrar motoristas que excluíram a zona de destino
      if (destinationNeighborhood != null && destinationCity != null && destinationState != null) {
        print('🚫 [${DateTime.now()}] Aplicando filtro de zonas excluídas...');
        final originalCount = drivers.length;
        drivers = await _filterDriversByExcludedZones(
          drivers,
          destinationNeighborhood,
          destinationCity,
          destinationState,
        );
        print('📉 [${DateTime.now()}] Filtro de zonas aplicado: $originalCount -> ${drivers.length} motoristas');
      }

      // Calcular distância real para cada motorista e ordenar por proximidade
      print('📏 [${DateTime.now()}] Calculando distâncias reais...');
      final driversWithDistance = <DriverWithDistance>[];
      
      for (final driver in drivers) {
        if (driver.currentLatitude != null && driver.currentLongitude != null) {
          final distance = _calculateHaversineDistance(
            latitude,
            longitude,
            driver.currentLatitude!,
            driver.currentLongitude!,
          );
          
          // Filtrar apenas motoristas dentro do raio especificado
          if (distance <= radiusKm) {
            driversWithDistance.add(DriverWithDistance(
              driver: driver,
              distanceKm: distance,
            ));
          }
        }
      }
      
      // Ordenar por distância (mais próximos primeiro)
      driversWithDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      
      // Limitar aos 10 motoristas mais próximos
      final limitedDrivers = driversWithDistance
          .take(10)
          .map((dwd) => dwd.driver)
          .toList();
      
      print('🎯 [${DateTime.now()}] Busca finalizada com ${limitedDrivers.length} motoristas mais próximos');
      if (driversWithDistance.isNotEmpty) {
        print('📊 Distâncias: ${driversWithDistance.take(5).map((d) => '${d.distanceKm.toStringAsFixed(2)}km').join(', ')}');
      }
      
      return limitedDrivers;
    } on PostgrestException catch (e) {
      print('❌ [${DateTime.now()}] PostgrestException em getAvailableDriversNearby:');
      print('  - Código: ${e.code}');
      print('  - Mensagem: ${e.message}');
      print('  - Detalhes: ${e.details}');
      throw PostgrestErrorMapper.mapError(e);
    } catch (e, stackTrace) {
      print('❌ [${DateTime.now()}] Erro inesperado em getAvailableDriversNearby:');
      print('  - Tipo: ${e.runtimeType}');
      print('  - Mensagem: $e');
      print('  - Stack trace: $stackTrace');
      throw const DatabaseException('Erro inesperado ao buscar motoristas disponíveis.');
    }
  }

  // Get available drivers nearby with user data (name and photo)
  Future<List<Map<String, dynamic>>> getAvailableDriversNearbyWithUserData({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? category,
    bool? needsPet,
    bool? needsGrocerySpace,
    bool? isCondoOrigin,
    bool? isCondoDestination,
    String? destinationNeighborhood,
    String? destinationCity,
    String? destinationState,
    int? limit,
  }) async {
    print('🔍 [${DateTime.now()}] Iniciando getAvailableDriversNearbyWithUserData...');
    
    try {
      // Aproximação de raio usando bounding box
      final latDelta = radiusKm / 111.0; // ~111km por grau
      final lngDelta = radiusKm / (111.0 * math.cos(latitude * math.pi / 180.0)).abs().clamp(0.0001, double.infinity);
      
      dynamic query = _supabase.from('drivers').select('''
        *,
        app_users!inner(
          full_name,
          photo_url
        )
      ''').eq('is_online', true);
      
      // Somente aprovados
      query = query.or('approval_status.eq.approved,approval_status.is.null');
      
      // Filtro de categoria
      if (category != null && category.isNotEmpty) {
        query = query.eq('vehicle_category', category);
      }
      
      // Preferências
      if (needsPet ?? false) {
        query = query.eq('accepts_pet', true);
      }
      if (needsGrocerySpace ?? false) {
        query = query.eq('accepts_grocery', true);
      }
      if ((isCondoOrigin ?? false) || (isCondoDestination ?? false)) {
        query = query.eq('accepts_condo', true);
      }
      
      // Bounding box
      query = query
          .gte('current_latitude', latitude - latDelta)
          .lte('current_latitude', latitude + latDelta)
          .gte('current_longitude', longitude - lngDelta)
          .lte('current_longitude', longitude + lngDelta);
      
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }
      
      final response = await query;
      
      final driversData = response as List<Map<String, dynamic>>;
      
      // Calcular distância real e filtrar
      final driversWithDistance = <Map<String, dynamic>>[];
      
      for (final driverData in driversData) {
        final currentLat = driverData['current_latitude'] as double?;
        final currentLng = driverData['current_longitude'] as double?;
        
        if (currentLat != null && currentLng != null) {
          final distance = _calculateHaversineDistance(
            latitude,
            longitude,
            currentLat,
            currentLng,
          );
          
          if (distance <= radiusKm) {
            driverData['distance_km'] = distance;
            driversWithDistance.add(driverData);
          }
        }
      }
      
      // Ordenar por distância
      driversWithDistance.sort((a, b) => 
        (a['distance_km'] as double).compareTo(b['distance_km'] as double));
      
      // Limitar aos 10 motoristas mais próximos
      final limitedDriversData = driversWithDistance.take(10).toList();
      
      print('✅ [${DateTime.now()}] Busca finalizada com ${limitedDriversData.length} motoristas');
      return limitedDriversData;
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro em getAvailableDriversNearbyWithUserData: $e');
      rethrow;
    }
  }

  /// Calcula a distância entre dois pontos usando a fórmula de Haversine
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Raio da Terra em km
    
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Filtra motoristas por zonas excluídas
  Future<List<Driver>> _filterDriversByExcludedZones(
    List<Driver> drivers,
    String neighborhood,
    String city,
    String state,
  ) async {
    try {
      // Buscar motoristas que excluíram esta zona
      final excludedDriversResponse = await _supabase
          .from('driver_excluded_zones')
          .select('driver_id')
          .eq('neighborhood_name', neighborhood)
          .eq('city', city)
          .eq('state', state);

      final excludedDriverIds = (excludedDriversResponse as List<dynamic>)
          .map((row) => row['driver_id'] as String)
          .toSet();

      // Filtrar motoristas que NÃO excluíram esta zona
      return drivers.where((driver) => !excludedDriverIds.contains(driver.id)).toList();
    } catch (e) {
      // Em caso de erro, retorna todos os motoristas para não impactar a funcionalidade
      print('⚠️ Erro ao filtrar por zonas excluídas: $e');
      return drivers;
    }
  }

  /// Stream de atualizações de localização de motoristas
  Stream<List<Driver>> streamDriverLocationUpdates(String driverId) =>
      _supabase
          .from('drivers')
          .stream(primaryKey: ['id'])
          .eq('id', driverId)
          .map((data) => data
              .map(Driver.fromJson)
              .toList(),);

  /// Busca dados de desempenho do motorista
  Future<Map<String, dynamic>> getDriverPerformanceData(String driverId) async {
    try {
      final trips = await getDriverTripHistory(driverId, limit: 100);
      
      final completedTrips = trips.where((trip) => trip.status == 'completed').toList();
      final cancelledTrips = trips.where((trip) => trip.status == 'cancelled').toList();
      
      // Calcular média de avaliações
      double averageRating = 0;
      int totalRatings = 0;
      double sumRatings = 0;
      
      for (final trip in completedTrips) {
        if (trip.driverRating != null && trip.driverRating! > 0) {
          sumRatings += trip.driverRating!;
          totalRatings++;
        }
      }
      
      if (totalRatings > 0) {
        averageRating = sumRatings / totalRatings;
      }
      
      return {
        'total_trips': trips.length,
        'completed_trips': completedTrips.length,
        'cancelled_trips': cancelledTrips.length,
        'average_rating': averageRating,
        'total_earnings': completedTrips.fold(0.0, (sum, trip) => sum + (trip.driverEarnings ?? 0)),
      };
    } catch (e) {
      throw const DriverError('Erro ao buscar dados de desempenho do motorista.');
    }
  }

  /// Busca dados da categoria do veículo
  Future<VehicleCategoryData> getVehicleCategoryData(
    VehicleCategory category, {
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Buscar preços da categoria no platform_settings
      final pricingConfig = await _platformSettingsService.getPricingConfig(category.id);
      
      // Contar motoristas disponíveis na região para esta categoria
      final drivers = await getAvailableDriversNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        category: category.id,
      );

      return VehicleCategoryData(
        category: category,
        basePricePerKm: pricingConfig['basePricePerKm'] as double,
        basePricePerMinute: pricingConfig['basePricePerMinute'] as double,
        availableDrivers: drivers.length,
        isAvailable: drivers.isNotEmpty,
        minFare: pricingConfig['minFare'] as double,
      );
    } catch (e) {
      // Fallback para dados padrão
      return VehicleCategoryData.defaultForCategory(category);
    }
  }

  String _calculateEstimatedArrival(double? avgDistanceKm) {
    if (avgDistanceKm == null) return '5-10 min';
    
    // Estimativa baseada em 30km/h médio no trânsito urbano
    final minutes = (avgDistanceKm * 2).round(); // 30km/h = 0.5km/min
    
    if (minutes <= 5) return '2-5 min';
    if (minutes <= 10) return '5-10 min';
    if (minutes <= 15) return '10-15 min';
    if (minutes <= 20) return '15-20 min';
    return '20+ min';
  }
}