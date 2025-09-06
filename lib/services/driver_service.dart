import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../core/error_handling/postgrest_error_mapper.dart';
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

class DriverService {

  DriverService(this._supabase) :
    _driverStatusService = DriverStatusService(_supabase),
    _platformSettingsService = PlatformSettingsService(_supabase),
    _vehicleCategoryValidator = VehicleCategoryValidator(_supabase);
  
  final SupabaseClient _supabase;
  final DriverStatusService _driverStatusService;
  final PlatformSettingsService _platformSettingsService;
  final VehicleCategoryValidator _vehicleCategoryValidator;

  // Get driver profile
  Future<Driver?> getDriver(String driverId) async {
    print('🔍 [DriverService.getDriver] Iniciando busca de motorista: $driverId');
    print('🔍 [DriverService.getDriver] Cliente Supabase disponível: ${_supabase != null}');
    
    try {
      print('🔍 [DriverService.getDriver] Executando query no Supabase...');
      final response =
          await _supabase.from('drivers').select().eq('id', driverId).single();

      print('✅ [DriverService.getDriver] Motorista encontrado: $driverId');
      print('✅ [DriverService.getDriver] Dados recebidos: ${response.toString().substring(0, 100)}...');
      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      print('❌ [DriverService.getDriver] PostgrestException: ${e.code} - ${e.message}');
      print('❌ [DriverService.getDriver] Detalhes: ${e.details}');
      print('❌ [DriverService.getDriver] Hint: ${e.hint}');
      
      if (e.code == 'PGRST116') {
        print('⚠️ [DriverService.getDriver] Motorista não encontrado: $driverId');
        return null;
      }
      final mappedError = PostgrestErrorMapper.mapError(e, context: {
        'operation': 'getDriver',
        'driverId': driverId,
      });
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        mappedError,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'getDriver',
          'driverId': driverId,
          'postgrestCode': e.code,
        },
        severity: ErrorSeverity.medium,
      );
      
      throw mappedError;
    } on FormatException catch (e) {
      print('❌ [DriverService.getDriver] FormatException ao processar dados: $e');
      final error = DatabaseException(
          'Erro ao processar dados do motorista. Por favor, tente novamente mais tarde.',);
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        error,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'getDriver',
          'driverId': driverId,
          'originalError': e.toString(),
        },
        severity: ErrorSeverity.medium,
      );
      
      throw error;
    } on Exception catch (e) {
      print('❌ [DriverService.getDriver] Exception não tratada: ${e.runtimeType} - $e');
      print('❌ [DriverService.getDriver] StackTrace: ${StackTrace.current}');
      final error = DatabaseException(
          'Erro inesperado ao buscar motorista. Por favor, tente novamente mais tarde.',);
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        error,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'getDriver',
          'driverId': driverId,
          'exceptionType': e.runtimeType.toString(),
          'originalError': e.toString(),
        },
        severity: ErrorSeverity.high,
      );
      
      throw error;
    }
  }

  // Get driver profile with user data (name and photo) usando view otimizada quando possível
  Future<Map<String, dynamic>?> getDriverWithUserData(String driverId) async {
    try {
      // Tentar usar a view otimizada primeiro
      try {
        final response = await _supabase
            .from('available_drivers_view')
            .select()
            .eq('driver_id', driverId)
            .single();
        
        // Reformatar resposta para manter compatibilidade
        return {
          'id': response['driver_id'],
          'user_id': response['user_id'],
          'vehicle_brand': response['vehicle_brand'],
          'vehicle_model': response['vehicle_model'],
          'vehicle_year': response['vehicle_year'],
          'vehicle_color': response['vehicle_color'],
          'vehicle_category': response['vehicle_category'],
          'is_online': response['is_online'],
          'accepts_pet': response['accepts_pet'],
          'accepts_grocery': response['accepts_grocery'],
          'accepts_condo': response['accepts_condo'],
          'ac_policy': response['ac_policy'],
          'custom_price_per_km': response['custom_price_per_km'],
          'custom_price_per_minute': response['custom_price_per_minute'],
          'pet_fee': response['pet_fee'],
          'grocery_fee': response['grocery_fee'],
          'condo_fee': response['condo_fee'],
          'stop_fee': response['stop_fee'],
          'total_trips': response['total_trips'],
          'average_rating': response['average_rating'],
          'current_latitude': response['current_latitude'],
          'current_longitude': response['current_longitude'],
          'last_location_update': response['last_location_update'],
          'user_name': response['full_name'], // Campo compatível
          'user_photo_url': response['photo_url'], // Campo compatível
          'app_users': { // Para manter compatibilidade com código existente
            'full_name': response['full_name'],
            'photo_url': response['photo_url'],
          },
        };
            } catch (e) {
        print('⚠️ View otimizada não disponível para getDriverWithUserData, usando fallback: $e');
      }

      // Fallback para query com join manual
      final response = await _supabase
          .from('drivers')
          .select('''
            *,
            app_users!inner(
              full_name,
              photo_url
            )
          ''')
          .eq('id', driverId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      final mappedError = PostgrestErrorMapper.mapError(e, context: {
        'operation': 'getDriverWithUserData',
        'driverId': driverId,
      });
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        mappedError,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'getDriverWithUserData',
          'driverId': driverId,
          'postgrestCode': e.code,
        },
        severity: ErrorSeverity.medium,
      );
      
      throw mappedError;
    } catch (e) {
      final error = DatabaseException(
          'Erro inesperado ao buscar motorista. Por favor, tente novamente mais tarde.',);
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        error,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'getDriverWithUserData',
          'driverId': driverId,
          'originalError': e.toString(),
        },
        severity: ErrorSeverity.medium,
      );
      
      throw error;
    }
  }

  // Create driver profile aligned with drivers table schema (sem CNH e CRLV que foram removidos do banco)
  Future<Driver> createDriver({
    required String userId,
    // Vehicle details
    required String brand,
    required String model,
    required int year,
    required String color,
    required String plate,
    required String category,
    // Preferences and settings
    bool acceptsPet = false,
    bool acceptsGrocery = false,
    bool acceptsCondo = false,
    double petFee = 0.0,
    double groceryFee = 0.0,
    double condoFee = 0.0,
    double stopFee = 0.0,
    String? acPolicy,
    double? customPricePerKm,
    double? customPricePerMinute,
    String? bankAccountType,
    String? bankCode,
    String? bankAgency,
    String? bankAccount,
    String? pixKey,
    String? pixKeyType,
    String? fcmToken,
    String? devicePlatform,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      final insertData = {
        'user_id': userId,
        'vehicle_brand': brand,
        'vehicle_model': model,
        'vehicle_year': year,
        'vehicle_color': color,
        'vehicle_plate': plate,
        'vehicle_category': category,
        'approval_status': 'pending',
        'is_online': false,
        'accepts_pet': acceptsPet,
        'accepts_grocery': acceptsGrocery,
        'accepts_condo': acceptsCondo,
        'pet_fee': petFee,
        'grocery_fee': groceryFee,
        'condo_fee': condoFee,
        'stop_fee': stopFee,
        'ac_policy': acPolicy,
        'custom_price_per_km': customPricePerKm,
        'custom_price_per_minute': customPricePerMinute,
        'bank_account_type': bankAccountType,
        'bank_code': bankCode,
        'bank_agency': bankAgency,
        'bank_account': bankAccount,
        'pix_key': pixKey,
        'pix_key_type': pixKeyType,
        'fcm_token': fcmToken,
        'device_platform': devicePlatform,
        'current_latitude': currentLatitude,
        'current_longitude': currentLongitude,
        'average_rating': 0.0,
        'total_trips': 0,
        'consecutive_cancellations': 0,
      };

      // LOG DEBUG: Verificando comportamento atual da validação de placa
      print('🔍 [DriverService.createDriver] Validando placa: "$plate"');
      print('🔍 [DriverService.createDriver] Placa vazia: ${plate.trim().isEmpty}');
      print('🔍 [DriverService.createDriver] Começa com PENDENTE: ${plate.trim().startsWith('PENDENTE')}');
      
      // Verificar se a placa já existe antes da criação
      if (plate.trim().isNotEmpty && !plate.trim().startsWith('PENDENTE')) {
        print('🔍 [DriverService.createDriver] Placa válida detectada, verificando unicidade...');
        try {
          await _checkVehiclePlateUniquenessForCreation(plate.trim());
          print('✅ [DriverService.createDriver] Verificação de placa concluída com sucesso');
        } catch (e) {
          print('❌ [DriverService.createDriver] Erro durante verificação de placa: $e');
          // Re-throw para manter o comportamento original
          rethrow;
        }
      } else {
        print('🔍 [DriverService.createDriver] Placa ignorada (vazia ou começa com PENDENTE)');
      }

      // Validar se a categoria existe na tabela platform_settings
      final categoryStr = category.trim();
      if (categoryStr.isNotEmpty) {
        final isValidCategory = _vehicleCategoryValidator.isVehicleCategoryValid(categoryStr);
        if (!isValidCategory) {
          print('❌ [DriverService.createDriver] vehicle_category inválido: $categoryStr');
          throw ValidationException('Categoria de veículo inválida: $categoryStr');
        }
        print('✅ [DriverService.createDriver] vehicle_category válido: $categoryStr');
      }

      // Validar dados antes da inserção
      DatabaseConstraintsValidator.validateDriver(insertData);

      final response =
          await _supabase.from('drivers').insert(insertData).select().single();

      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      print('❌ [DriverService.createDriver] PostgrestException: ${e.code} - ${e.message}');
      print('❌ [DriverService.createDriver] Detalhes: ${e.details}');
      final mappedError = PostgrestErrorMapper.mapError(e, context: {
        'operation': 'createDriver',
        'userId': userId,
        'vehicleCategory': category,
      });
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        mappedError,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'createDriver',
          'userId': userId,
          'vehicleCategory': category,
          'postgrestCode': e.code,
        },
        severity: ErrorSeverity.high,
      );
      
      throw mappedError;
    } on ValidationException catch (e) {
      print('❌ [DriverService.createDriver] ValidationException: ${e.message}');
      // Re-throw validation exceptions without wrapping
      throw e;
    } on DatabaseException catch (e) {
      print('❌ [DriverService.createDriver] DatabaseException: ${e.message}');
      // Re-throw database exceptions without wrapping
      throw e;
    } on Exception catch (e) {
      print('❌ [DriverService.createDriver] Exception não tratada: ${e.runtimeType} - $e');
      final error = DatabaseException(
          'Erro inesperado ao criar perfil de motorista. Por favor, tente novamente mais tarde.',);
      
      // Log error for monitoring
      await ErrorLoggingService.instance.logException(
        error,
        type: AppErrorType.databaseError,
        context: {
          'operation': 'createDriver',
          'userId': userId,
          'exceptionType': e.runtimeType.toString(),
          'originalError': e.toString(),
        },
        severity: ErrorSeverity.high,
      );
      
      throw error;
    }
  }

  /// Atualiza os dados de um motorista (sem CNH e CRLV que foram removidos do banco)
  static Future<void> updateDriver(
    String driverId, {
    required String brand,
    required String model,
    required int year,
    required String plate,
    required String color,
    required String category,
  }) async {
    print('🔄 DriverService.updateDriver iniciado');
    print('  - driverId: $driverId');
    print('  - brand: $brand');
    print('  - model: $model');
    print('  - year: $year');
    print('  - plate: $plate');
    print('  - color: $color');
    print('  - category: $category');

    // Validar se a categoria existe na tabela platform_settings
    final categoryStr = category.trim();
    if (categoryStr.isNotEmpty) {
      final validator = VehicleCategoryValidator(SupabaseHelper.client!);
      final isValidCategory = validator.isVehicleCategoryValid(categoryStr);
      if (!isValidCategory) {
        print('❌ [DriverService.updateDriver] vehicle_category inválido: $categoryStr');
        throw ValidationException('Categoria de veículo inválida: $categoryStr');
      }
      print('✅ [DriverService.updateDriver] vehicle_category válido: $categoryStr');
    }

    try {
      final updates = {
        'vehicle_brand': brand,
        'vehicle_model': model,
        'vehicle_year': year,
        'vehicle_plate': plate,
        'vehicle_color': color,
        'vehicle_category': category,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseHelper.client!
          .from('drivers')
          .update(updates)
          .eq('id', driverId);

      print('✅ Driver atualizado com sucesso');
    } on PostgrestException catch (e) {
      print('❌ Erro do banco de dados: ${e.message}');
      throw DriverException('Erro ao atualizar motorista: ${e.message}');
    } catch (e) {
      print('❌ Erro inesperado: $e');
      throw DriverException('Erro inesperado ao atualizar motorista: $e');
    }
  }

  // Create driver offer
  Future<DriverOffer> createOffer({
    required String driverId,
    required String requestId,
    double? driverDistanceKm,
    int? driverEtaMinutes,
    double? baseFare,
    double? additionalFees,
    double? totalFare,
    bool isAvailable = true,
    bool wasSelected = false,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{
        'driver_id': driverId,
        'request_id': requestId,
        'is_available': isAvailable,
        'was_selected': wasSelected,
      };
      if (driverDistanceKm != null) {
        data['driver_distance_km'] = driverDistanceKm;
      }
      if (driverEtaMinutes != null) {
        data['driver_eta_minutes'] = driverEtaMinutes;
      }
      if (baseFare != null) data['base_fare'] = baseFare;
      if (additionalFees != null) data['additional_fees'] = additionalFees;
      final computedTotal =
          totalFare ?? ((baseFare ?? 0) + (additionalFees ?? 0));
      data['total_fare'] = computedTotal;
      if (notes != null) data['notes'] = notes;

      final response =
          await _supabase.from('driver_offers').insert(data).select().single();

      return DriverOffer.fromJson(response);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao criar oferta. Por favor, tente novamente mais tarde.',);
    }
  }

  // Get driver's offers
  Future<List<DriverOffer>> getDriverOffers(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_offers')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      return response.map(DriverOffer.fromJson).toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao buscar ofertas. Por favor, tente novamente mais tarde.',);
    }
  }

  // Get pending offers for driver
  Future<List<DriverOffer>> getPendingOffers(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_offers')
          .select()
          .eq('driver_id', driverId)
          .eq('is_available', true)
          .eq('was_selected', false)
          .order('created_at', ascending: false);

      return response.map(DriverOffer.fromJson).toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar ofertas pendentes');
    }
  }

  // Update offer status -> map to availability/selection flags
  Future<DriverOffer> updateOfferStatus(String offerId, String status) async {
    try {
      final updates = <String, dynamic>{};
      switch (status) {
        case 'accepted':
          updates['was_selected'] = true;
          updates['is_available'] = false;
          break;
        case 'pending':
          updates['was_selected'] = false;
          updates['is_available'] = true;
          break;
        case 'inactive':
        case 'cancelled':
        case 'rejected':
          updates['is_available'] = false;
          break;
        default:
          // No-op for unknown statuses
          break;
      }

      final response = await _supabase
          .from('driver_offers')
          .update(updates)
          .eq('id', offerId)
          .select()
          .single();

      return DriverOffer.fromJson(response);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao atualizar oferta');
    }
  }

  // Get driver's active trips
  Future<List<Trip>> getDriverActiveTrips(String driverId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('driver_id', driverId)
          .or('status.eq.accepted,status.eq.in_progress')
          .order('created_at', ascending: false);

      return response.map(Trip.fromJson).toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar viagens ativas');
    }
  }

  // Get driver's trip history
  Future<List<Trip>> getDriverTripHistory(String driverId,
      {int limit = 50,}) async {
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .eq('driver_id', driverId)
          .or('status.eq.completed,status.eq.cancelled')
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map(Trip.fromJson).toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao buscar histórico. Por favor, tente novamente mais tarde.',);
    }
  }

  // Update driver location
  Future<void> updateLocation(
      String driverId, double latitude, double longitude,) async {
    const retries = 3;
    const delays = [Duration(), Duration(milliseconds: 500), Duration(milliseconds: 1500)];
    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        await _supabase.from('drivers').update({
          'current_latitude': latitude,
          'current_longitude': longitude,
        }).eq('id', driverId);
        return; // sucesso
      } on PostgrestException catch (e) {
        if (attempt == retries - 1) {
          throw PostgrestErrorMapper.mapError(e);
        }
        await Future.delayed(delays[attempt]);
      } catch (e) {
        if (attempt == retries - 1) {
          throw const DatabaseException(
              'Erro inesperado ao atualizar localização. Por favor, tente novamente mais tarde.',);
        }
        await Future.delayed(delays[attempt]);
      }
    }
  }

  // Update driver availability (online/offline)
  Future<void> updateAvailability(String driverId, bool isOnline) async {
    print('🔵 [DRIVER_SERVICE] updateAvailability iniciado');
    print('   🔹 Driver ID: $driverId');
    print('   🔹 isOnline: $isOnline');
    print('   🔹 Tamanho do driverId: ${driverId.length}');
    print('   🔹 DriverId é vazio: ${driverId.isEmpty}');
    
    // Validação de driverId
    if (driverId.isEmpty) {
      print('❌ [DRIVER_SERVICE] Driver ID inválido (vazio)');
      throw const ValidationException('Driver ID inválido (vazio)');
    }
    
    try {
      print('🔗 [DRIVER_SERVICE] Fazendo update no Supabase...');
      print('   🔹 Tabela: drivers');
      print('   🔹 Update data: {\'is_online\': $isOnline}');
      print('   🔹 Condição: eq(\'id\', \'$driverId\')');
      
      final response = await _supabase.from('drivers').update({
        'is_online': isOnline,
      }).eq('id', driverId);
      
      print('📊 [DRIVER_SERVICE] Update executado com sucesso');
      print('   🔹 Response: $response');
      print('   🔹 Tipo do response: ${response.runtimeType}');
    } on PostgrestException catch (e) {
      print('❌ [DRIVER_SERVICE] PostgrestException em updateAvailability: ${e.code} - ${e.message}');
      print('❌ [DRIVER_SERVICE] Details: ${e.details}');
      print('❌ [DRIVER_SERVICE] Hint: ${e.hint}');
      throw PostgrestErrorMapper.mapError(e);
    } catch (e, stackTrace) {
      print('❌ [DRIVER_SERVICE] Erro inesperado em updateAvailability: ${e.toString()}');
      print('❌ [DRIVER_SERVICE] Tipo do erro: ${e.runtimeType}');
      print('❌ [DRIVER_SERVICE] Stack trace: $stackTrace');
      throw const DatabaseException(
          'Erro inesperado ao atualizar disponibilidade. Por favor, tente novamente mais tarde.');
    }
  }

  // Update driver AC policy
  static Future<void> updateAcPolicy(String driverId, String acPolicy) async {
    try {
      await SupabaseHelper.client!.from('drivers').update({
        'ac_policy': acPolicy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', driverId);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao atualizar política de ar-condicionado. Por favor, tente novamente mais tarde.');
    }
  }

  // Stream driver profile updates
  Stream<Driver> streamDriver(String driverId) => _supabase
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('id', driverId)
        .map((data) => Driver.fromJson(data.first));

  // Stream driver's active trips
  Stream<List<Trip>> streamDriverActiveTrips(String driverId) => _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .map((data) => data
            .where((trip) => ['accepted', 'in_progress'].contains(trip['status']))
            .map(Trip.fromJson)
            .toList(),);

  // Busca motoristas disponíveis próximos usando a view otimizada available_drivers_view
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
      
      print('🎯 [${DateTime.now()}] Busca finalizada com ${limitedDriversData.length} motoristas com dados de usuário');
      
      return limitedDriversData;
    } on PostgrestException catch (e) {
      print('❌ [${DateTime.now()}] PostgrestException em getAvailableDriversNearbyWithUserData:');
      print('  - Código: ${e.code}');
      print('  - Mensagem: ${e.message}');
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      print('❌ [${DateTime.now()}] Erro inesperado em getAvailableDriversNearbyWithUserData:');
      print('  - Tipo: ${e.runtimeType}');
      print('  - Mensagem: $e');
      throw const DatabaseException('Erro inesperado ao buscar motoristas disponíveis.');
    }
  }

  // Filtra motoristas baseado nas zonas excluídas
  Future<List<Driver>> _filterDriversByExcludedZones(
    List<Driver> drivers,
    String neighborhoodName,
    String city,
    String state,
  ) async {
    try {
      final excludedZonesService = DriverExcludedZonesService(_supabase);
      final filteredDrivers = <Driver>[];

      for (final driver in drivers) {
        final isExcluded = await excludedZonesService.isZoneExcluded(
          driverId: driver.id,
          neighborhoodName: neighborhoodName,
          city: city,
          state: state,
        );

        if (!isExcluded) {
          filteredDrivers.add(driver);
        }
      }

      return filteredDrivers;
    } catch (e) {
      // Em caso de erro na verificação de zonas excluídas, retorna todos os motoristas
      // para não impactar a funcionalidade principal
      return drivers;
    }
  }

  /// Busca categorias de veículos disponíveis em uma região
  /// Retorna dados baseados em platform_settings + contagem de motoristas ativos
  Future<List<VehicleCategoryData>> getAvailableCategoriesInRegion({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Busca contagem de motoristas por categoria na região
      final response = await _supabase.rpc('get_available_categories_stats', params: {
        'lat': latitude,
        'lng': longitude,
        'radius_km': radiusKm,
      },);

      // Buscar preços base de cada categoria do platform_settings
      final categoryDataList = <VehicleCategoryData>[];
      
      for (final category in VehicleCategory.popularCategories) {
        // Buscar configurações da categoria específica ou usar padrão
        final pricingConfig = await _platformSettingsService.getPricingConfig(category.id);
        
        // Encontrar contagem de motoristas para esta categoria
        int driverCount = 0;
        if (response != null && response is List) {
          final categoryStats = (response)
              .where((stat) => stat['vehicle_category'] == category.id)
              .firstOrNull;
          driverCount = categoryStats?['driver_count'] as int? ?? 0;
        }

        categoryDataList.add(VehicleCategoryData(
          category: category,
          basePricePerKm: pricingConfig['basePricePerKm'] as double,
          basePricePerMinute: pricingConfig['basePricePerMinute'] as double,
          availableDrivers: driverCount,
          isAvailable: driverCount > 0,
          minFare: pricingConfig['minFare'] as double,
        ));
      }

      return categoryDataList;
    } on PostgrestException catch (e) {
      // Se a função RPC não existir, criar dados usando apenas platform_settings
      if (e.code == '42883') {
        return _createCategoryDataWithoutDriverCount();
      }
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      // Fallback para dados com platform_settings
      return _createCategoryDataWithoutDriverCount();
    }
  }

  /// Cria dados de categoria usando apenas platform_settings (sem contagem de motoristas)
  Future<List<VehicleCategoryData>> _createCategoryDataWithoutDriverCount() async {
    final categoryDataList = <VehicleCategoryData>[];
    
    for (final category in VehicleCategory.popularCategories) {
      try {
        final pricingConfig = await _platformSettingsService.getPricingConfig(category.id);
        
        categoryDataList.add(VehicleCategoryData(
          category: category,
          basePricePerKm: pricingConfig['basePricePerKm'] as double,
          basePricePerMinute: pricingConfig['basePricePerMinute'] as double,
          availableDrivers: 5, // Valor padrão assumindo disponibilidade
          isAvailable: true,
          minFare: pricingConfig['minFare'] as double,
        ));
      } catch (e) {
        // Fallback para dados hardcoded se platform_settings falhar
        categoryDataList.add(VehicleCategoryData.defaultForCategory(category));
      }
    }
    
    return categoryDataList;
  }

  /// Busca dados de uma categoria específica
  Future<VehicleCategoryData?> getCategoryData(VehicleCategory category, {
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

  // === Métodos para o novo sistema de status ===
  
  /// Obtém o status efetivo do motorista (calculado pela view)
  Future<DriverEffectiveStatus?> getDriverEffectiveStatus(String driverId) async => await _driverStatusService.getDriverEffectiveStatus(driverId);
  
  /// Verifica detalhadamente por que o motorista não pode ficar online
  Future<Map<String, dynamic>> getOnlineEligibilityStatus(String driverId) async {
    print('🔍 [DRIVER_SERVICE] getOnlineEligibilityStatus iniciado para driver: $driverId');
    
    if (driverId.isEmpty) {
      return {
        'canGoOnline': false,
        'reason': 'Driver ID inválido',
        'message': 'ID do motorista não foi fornecido.',
        'actionRequired': 'Faça login novamente.',
      };
    }
    
    try {
      // 1. Verificar se o motorista está aprovado
      final driverData = await _supabase
          .from('drivers')
          .select('approval_status')
          .eq('id', driverId)
          .single();
      
      final approvalStatus = driverData['approval_status'] as String?;
      
      if (approvalStatus != 'approved') {
        String message;
        String actionRequired;
        
        switch (approvalStatus) {
          case 'pending':
            message = 'Seu perfil ainda está em análise pela nossa equipe.';
            actionRequired = 'Aguarde a aprovação do seu cadastro.';
            break;
          case 'rejected':
            message = 'Seu perfil foi rejeitado. Entre em contato com o suporte.';
            actionRequired = 'Contate o suporte para mais informações.';
            break;
          default:
            message = 'Status de aprovação desconhecido.';
            actionRequired = 'Entre em contato com o suporte.';
        }
        
        return {
          'canGoOnline': false,
          'reason': 'Motorista não aprovado',
          'message': message,
          'actionRequired': actionRequired,
          'approvalStatus': approvalStatus,
        };
      }
      
      // 2. Verificar documentos usando o status service
      final documentsStatus = await _driverStatusService.checkRequiredDocumentsApproved(driverId);
      
      if (!documentsStatus['allApproved']) {
        final pendingDocs = documentsStatus['pendingDocuments'] as List<String>;
        final rejectedDocs = documentsStatus['rejectedDocuments'] as List<String>;
        final missingDocs = documentsStatus['missingDocuments'] as List<String>;
        
        String message = 'Você precisa ter todos os documentos aprovados para ficar online.';
        String actionRequired = 'Complete o envio e aprovação dos documentos obrigatórios.';
        
        if (missingDocs.isNotEmpty) {
          message = 'Documentos obrigatórios não enviados: ${missingDocs.join(', ')}.';
          actionRequired = 'Envie todos os documentos obrigatórios.';
        } else if (rejectedDocs.isNotEmpty) {
          message = 'Documentos rejeitados: ${rejectedDocs.join(', ')}.';
          actionRequired = 'Reenvie os documentos rejeitados.';
        } else if (pendingDocs.isNotEmpty) {
          message = 'Documentos aguardando aprovação: ${pendingDocs.join(', ')}.';
          actionRequired = 'Aguarde a análise dos documentos enviados.';
        }
        
        return {
          'canGoOnline': false,
          'reason': 'Documentos não aprovados',
          'message': message,
          'actionRequired': actionRequired,
          'documentsStatus': documentsStatus,
        };
      }
      
      // 3. Verificar horários de trabalho
      final canGoOnlineNow = await _driverStatusService.canDriverGoOnlineNow(driverId);
      
      if (!canGoOnlineNow) {
        return {
          'canGoOnline': false,
          'reason': 'Fora do horário de trabalho',
          'message': 'Você só pode ficar online durante seus horários de trabalho configurados.',
          'actionRequired': 'Configure seus horários ou aguarde o horário permitido.',
        };
      }
      
      // Tudo aprovado
      return {
        'canGoOnline': true,
        'reason': 'Aprovado',
        'message': 'Você está habilitado para ficar online!',
        'actionRequired': null,
      };
      
    } catch (e) {
      print('❌ [DRIVER_SERVICE] Erro ao verificar elegibilidade: $e');
      return {
        'canGoOnline': false,
        'reason': 'Erro do sistema',
        'message': 'Ocorreu um erro ao verificar sua elegibilidade.',
        'actionRequired': 'Tente novamente mais tarde.',
        'error': e.toString(),
      };
    }
  }

  /// Verifica se o motorista pode ficar online (documentos aprovados)
  Future<bool> canDriverGoOnline(String driverId) async {
    print('🔵 [DRIVER_SERVICE] canDriverGoOnline iniciado para driver: $driverId');
    
    if (driverId.isEmpty) {
      print('❌ [DRIVER_SERVICE] Driver ID inválido (vazio)');
      return false;
    }
    
    try {
      print('🔗 [DRIVER_SERVICE] Chamando _driverStatusService.canDriverGoOnlineNow...');
      final canGoOnline = await _driverStatusService.canDriverGoOnlineNow(driverId);
      print('📊 [DRIVER_SERVICE] Resultado: $canGoOnline para driver: $driverId');
      
      return canGoOnline;
    } catch (e) {
      print('❌ [DRIVER_SERVICE] Erro ao verificar se pode ficar online: $e');
      return false;
    }
  }
  
  /// Obtém a intenção de ficar online do motorista
  Future<bool> getDriverOnlineIntent(String driverId) async {
    final status = await _driverStatusService.getDriverStatus(driverId);
    return status?.onlineIntent ?? false;
  }
  
  
  /// Obtém lista de motoristas efetivamente online
  Future<List<DriverEffectiveStatus>> getEffectivelyOnlineDrivers() async => await _driverStatusService.getOnlineDrivers();
  
  /// Obtém estatísticas de status dos motoristas
  Future<Map<String, int>> getDriverStatusStats() async => await _driverStatusService.getDriverStatusStats();

  /// Verifica se a placa do veículo já está sendo usada por outro motorista
  Future<void> _checkVehiclePlateUniqueness(String plate, String currentDriverId) async {
    print('🔍 [DriverService._checkVehiclePlateUniqueness] Verificando unicidade da placa: "$plate" para motorista: $currentDriverId');
    try {
      final response = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('vehicle_plate', plate)
          .neq('id', currentDriverId);

      print('🔍 [DriverService._checkVehiclePlateUniqueness] Resultado da consulta: ${response.length} registros encontrados');
      if (response.isNotEmpty) {
        print('❌ [DriverService._checkVehiclePlateUniqueness] Placa já existe: ${response.map((r) => r['id']).toList()}');
        throw const ValidationException(
          'Esta placa já está cadastrada por outro motorista. Por favor, verifique os dados e tente novamente.',
        );
      }
      print('✅ [DriverService._checkVehiclePlateUniqueness] Placa disponível: "$plate"');
    } on PostgrestException catch (e) {
      print('❌ [DriverService._checkVehiclePlateUniqueness] PostgrestException: ${e.code} - ${e.message}');
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      print('❌ [DriverService._checkVehiclePlateUniqueness] Erro inesperado: $e');
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao verificar placa do veículo.',
      );
    }
  }

  /// Verifica se a placa do veículo já existe na criação de um novo motorista
  Future<void> _checkVehiclePlateUniquenessForCreation(String plate) async {
    try {
      print('🔍 [_checkVehiclePlateUniquenessForCreation] Verificando unicidade da placa: "$plate"');
      
      final response = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('vehicle_plate', plate);

      print('🔍 [_checkVehiclePlateUniquenessForCreation] Resposta do Supabase: $response');
      
      if (response.isNotEmpty) {
        print('❌ [_checkVehiclePlateUniquenessForCreation] Placa já existe no banco!');
        throw const ValidationException(
          'Esta placa já está cadastrada por outro motorista. Por favor, verifique os dados e tente novamente.',
        );
      }
      
      print('✅ [_checkVehiclePlateUniquenessForCreation] Placa disponível!');
    } on PostgrestException catch (e) {
      print('❌ [_checkVehiclePlateUniquenessForCreation] PostgrestException: ${e.code} - ${e.message}');
      throw PostgrestErrorMapper.mapError(e);
    } catch (e) {
      print('❌ [_checkVehiclePlateUniquenessForCreation] Erro inesperado: $e');
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao verificar placa do veículo.',
      );
    }
  }

  /// Valida apenas os campos que estão sendo atualizados
  void _validateUpdateData(Map<String, dynamic> updates) {
    // DEBUG: Log de entrada para validação
    print('🔍 [DriverService._validateUpdateData] Iniciando validação. Campos: ${updates.keys.toList()}');
    
    // Validação de vehicle_category usando VehicleCategoryValidator
    if (updates.containsKey('vehicle_category')) {
      final category = updates['vehicle_category'];
      print('🔍 [DriverService._validateUpdateData] Validando vehicle_category: $category');
      if (category == null) {
        print('❌ [DriverService._validateUpdateData] vehicle_category é nulo');
        throw const ValidationException('vehicle_category não pode ser nulo');
      }
      
      // Validar se a categoria existe na tabela platform_settings
      final categoryStr = category.toString().trim();
      if (categoryStr.isNotEmpty) {
        final isValidCategory = _vehicleCategoryValidator.isVehicleCategoryValid(categoryStr);
        if (!isValidCategory) {
          print('❌ [DriverService._validateUpdateData] vehicle_category inválido: $categoryStr');
          throw ValidationException('Categoria de veículo inválida: $categoryStr');
        }
        print('✅ [DriverService._validateUpdateData] vehicle_category válido: $categoryStr');
      }
    }
    
    // Validar vehicle_plate se presente (campo crítico)
    if (updates.containsKey('vehicle_plate')) {
      final plate = updates['vehicle_plate'];
      print('🔍 [DriverService._validateUpdateData] Validando vehicle_plate: $plate');
      if (plate != null) {
        final plateStr = plate.toString().trim();
        print('🔍 [DriverService._validateUpdateData] Placa após trim: "$plateStr"');
        
        if (plateStr.isNotEmpty && !plateStr.startsWith('PENDENTE')) {
          final cleanPlate = plateStr.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
          print('🔍 [DriverService._validateUpdateData] Placa limpa: "$cleanPlate"');
          
          if (cleanPlate.length != 7) {
            print('❌ [DriverService._validateUpdateData] Placa com tamanho inválido: ${cleanPlate.length} caracteres');
            throw ValidationException('Placa deve ter exatamente 7 caracteres (ex: ABC1234). Tamanho atual: ${cleanPlate.length}');
          }
          
          // Formato brasileiro: ABC1234 ou ABC1D23 (Mercosul)
          // LOG DEBUG: Testando regex antigo vs novo
          final oldPlateRegex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');
          final newPlateRegex = RegExp(r'^[A-Z]{3}[0-9]{4}$|^[A-Z]{3}[0-9][A-Z][0-9]{2}$');
          
          print('🔍 [DriverService._validateUpdateData] Testando placa: "$cleanPlate"');
          print('🔍 [DriverService._validateUpdateData] Regex antigo: ${oldPlateRegex.pattern} - Match: ${oldPlateRegex.hasMatch(cleanPlate)}');
          print('🔍 [DriverService._validateUpdateData] Regex novo: ${newPlateRegex.pattern} - Match: ${newPlateRegex.hasMatch(cleanPlate)}');
          
          if (!newPlateRegex.hasMatch(cleanPlate)) {
            print('❌ [DriverService._validateUpdateData] Placa não corresponde ao novo regex');
            print('❌ [DriverService._validateUpdateData] Formatos válidos: ABC1234 (antigo) ou ABC1D23 (Mercosul)');
            throw ValidationException('Formato de placa inválido. Use ABC1234 (antigo) ou ABC1D23 (Mercosul). Placa recebida: $plateStr');
          }
          print('✅ [DriverService._validateUpdateData] Placa válida: "$cleanPlate"');
        } else {
          print('⚠️ [DriverService._validateUpdateData] Placa vazia ou começa com PENDENTE: "$plateStr"');
        }
      } else {
        print('⚠️ [DriverService._validateUpdateData] Placa é nula, pulando validação');
      }
    }
    
    // Validar vehicle_year se presente
    if (updates.containsKey('vehicle_year')) {
      final year = updates['vehicle_year'];
      if (year != null) {
        int? yearInt;
        if (year is String) {
          yearInt = int.tryParse(year);
        } else if (year is int) {
          yearInt = year;
        }
        
        if (yearInt != null) {
          final currentYear = DateTime.now().year;
          if (yearInt < 1990 || yearInt > currentYear + 1) {
            throw ValidationException('vehicle_year deve estar entre 1990 e ${currentYear + 1}: $yearInt');
          }
        }
      }
    }
    
    // Para outros campos, apenas verificar se não são nulos quando obrigatórios
    final requiredFields = ['vehicle_brand', 'vehicle_model', 'vehicle_color'];
    for (final field in requiredFields) {
      if (updates.containsKey(field)) {
        final value = updates[field];
        if (value == null || value.toString().trim().isEmpty) {
          throw ValidationException('$field é obrigatório e não pode estar vazio');
        }
      }
    }
  }
}
