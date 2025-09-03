import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver.dart';
import '../models/supabase/driver_offer.dart';
import '../models/supabase/driver_effective_status.dart';
import '../models/supabase/working_hours.dart';
import '../models/supabase/trip.dart';
import '../models/vehicle_category.dart';
import '../validators/database_constraints_validator.dart';
import 'driver_document_service.dart';
import 'driver_excluded_zones_service.dart';
import 'driver_status_service.dart';
import 'working_hours_service.dart';

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
    _workingHoursService = WorkingHoursService(_supabase);
  
  final SupabaseClient _supabase;
  final DriverStatusService _driverStatusService;
  final WorkingHoursService _workingHoursService;

  // Get driver profile
  Future<Driver?> getDriver(String driverId) async {
    try {
      final response =
          await _supabase.from('drivers').select().eq('id', driverId).single();

      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw const DatabaseException(
          'Erro ao buscar motorista. Por favor, tente novamente mais tarde.',);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao buscar motorista. Por favor, tente novamente mais tarde.',);
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
      throw const DatabaseException(
          'Erro ao buscar motorista. Por favor, tente novamente mais tarde.',);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao buscar motorista. Por favor, tente novamente mais tarde.',);
    }
  }

  // Create driver profile aligned with drivers table schema
  Future<Driver> createDriver({
    required String userId,
    required String cnhNumber,
    required DateTime cnhExpiryDate,
    String? cnhPhotoUrl,
    // Vehicle details
    required String brand,
    required String model,
    required int year,
    required String color,
    required String plate,
    required String category,
    String? crlvPhotoUrl,
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
        'cnh_number': cnhNumber,
        'cnh_expiry_date': cnhExpiryDate.toIso8601String(),
        'cnh_photo_url': cnhPhotoUrl,
        'vehicle_brand': brand,
        'vehicle_model': model,
        'vehicle_year': year,
        'vehicle_color': color,
        'vehicle_plate': plate,
        'vehicle_category': category,
        'crlv_photo_url': crlvPhotoUrl,
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

      // Verificar se a placa já existe antes da criação
      if (plate.trim().isNotEmpty && !plate.trim().startsWith('PENDENTE')) {
        await _checkVehiclePlateUniquenessForCreation(plate.trim());
      }

      // Validar dados antes da inserção
      DatabaseConstraintsValidator.validateDriver(insertData);

      final response =
          await _supabase.from('drivers').insert(insertData).select().single();

      return Driver.fromJson(response);
    } on PostgrestException {
      throw const DatabaseException(
          'Erro ao criar perfil de motorista. Por favor, verifique os dados e tente novamente.',);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao criar perfil de motorista. Por favor, tente novamente mais tarde.',);
    }
  }

  // Update driver profile aligned with drivers table schema
  Future<Driver> updateDriver(
    String driverId, {
    // CNH
    String? cnhNumber,
    DateTime? cnhExpiryDate,
    String? cnhPhotoUrl,
    // Vehicle details
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
    String? category,
    String? crlvPhotoUrl,
    // Status & availability
    String? approvalStatus,
    bool? isOnline,
    // Preferences and settings
    bool? acceptsPet,
    bool? acceptsGrocery,
    bool? acceptsCondo,
    double? petFee,
    double? groceryFee,
    double? condoFee,
    double? stopFee,
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
      final updates = <String, dynamic>{};
      if (cnhNumber != null) updates['cnh_number'] = cnhNumber;
      if (cnhExpiryDate != null) {
        updates['cnh_expiry_date'] = cnhExpiryDate.toIso8601String();
      }
      if (cnhPhotoUrl != null) updates['cnh_photo_url'] = cnhPhotoUrl;

      if (brand != null) updates['vehicle_brand'] = brand;
      if (model != null) updates['vehicle_model'] = model;
      if (year != null) updates['vehicle_year'] = year;
      if (color != null) updates['vehicle_color'] = color;
      if (plate != null) updates['vehicle_plate'] = plate;
      if (category != null) updates['vehicle_category'] = category;
      if (crlvPhotoUrl != null) updates['crlv_photo_url'] = crlvPhotoUrl;

      if (approvalStatus != null) updates['approval_status'] = approvalStatus;
      
      // Validação obrigatória: verificar documentos antes de ficar online
      if (isOnline ?? false) {
        final documentationStatus = await DriverDocumentService.getDocumentationStatus(driverId);
        
        if (!documentationStatus['isComplete']) {
          final missingDocs = documentationStatus['missingDocuments'] as List;
          final rejectedDocs = documentationStatus['rejectedDocuments'] as List;
          final pendingDocs = documentationStatus['pendingDocuments'] as List;
          final expiredDocs = documentationStatus['expiredDocuments'] as List;
          
          var errorMessage = 'Não é possível ficar online. ';
          
          if (missingDocs.isNotEmpty) {
            errorMessage += 'Documentos não enviados: ${missingDocs.join(', ')}. ';
          }
          if (rejectedDocs.isNotEmpty) {
            errorMessage += 'Documentos rejeitados: ${rejectedDocs.join(', ')}. ';
          }
          if (pendingDocs.isNotEmpty) {
            errorMessage += 'Documentos aguardando aprovação: ${pendingDocs.join(', ')}. ';
          }
          if (expiredDocs.isNotEmpty) {
            errorMessage += 'Documentos expirados: ${expiredDocs.join(', ')}. ';
          }
          
          throw DocumentationRequiredException(errorMessage.trim());
        }
      }
      
      // Usar novo sistema de status ao invés de atualizar is_online diretamente
      if (isOnline != null) {
        await _driverStatusService.updateOnlineIntent(driverId, isOnline);
        // Não atualizar is_online na tabela drivers - será calculado pela view
      }

      if (acceptsPet != null) updates['accepts_pet'] = acceptsPet;
      if (acceptsGrocery != null) updates['accepts_grocery'] = acceptsGrocery;
      if (acceptsCondo != null) updates['accepts_condo'] = acceptsCondo;

      if (petFee != null) updates['pet_fee'] = petFee;
      if (groceryFee != null) updates['grocery_fee'] = groceryFee;
      if (condoFee != null) updates['condo_fee'] = condoFee;
      if (stopFee != null) updates['stop_fee'] = stopFee;
      if (acPolicy != null) updates['ac_policy'] = acPolicy;
      if (customPricePerKm != null) {
        updates['custom_price_per_km'] = customPricePerKm;
      }
      if (customPricePerMinute != null) {
        updates['custom_price_per_minute'] = customPricePerMinute;
      }
      if (bankAccountType != null) updates['bank_account_type'] = bankAccountType;
      if (bankCode != null) updates['bank_code'] = bankCode;
      if (bankAgency != null) updates['bank_agency'] = bankAgency;
      if (bankAccount != null) updates['bank_account'] = bankAccount;
      if (pixKey != null) updates['pix_key'] = pixKey;
      if (pixKeyType != null) updates['pix_key_type'] = pixKeyType;
      if (fcmToken != null) updates['fcm_token'] = fcmToken;
      if (devicePlatform != null) updates['device_platform'] = devicePlatform;

      if (currentLatitude != null) {
        updates['current_latitude'] = currentLatitude;
      }
      if (currentLongitude != null) {
        updates['current_longitude'] = currentLongitude;
      }

      // Verificar se a placa já existe antes da atualização
      if (plate != null && plate.trim().isNotEmpty && !plate.trim().startsWith('PENDENTE')) {
        await _checkVehiclePlateUniqueness(plate.trim(), driverId);
      }

      // Validar dados antes da atualização
      if (updates.isNotEmpty) {
        DatabaseConstraintsValidator.validateDriver(updates);
      }

      final response = await _supabase
          .from('drivers')
          .update(updates)
          .eq('id', driverId)
          .select()
          .single();

      return Driver.fromJson(response);
    } on PostgrestException {
      throw const DatabaseException(
          'Erro ao atualizar motorista. Por favor, verifique os dados e tente novamente.',);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao atualizar motorista. Por favor, tente novamente mais tarde.',);
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
    } on PostgrestException {
      throw const DatabaseException(
          'Erro ao criar oferta. Por favor, verifique os dados e tente novamente.',);
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
      throw DatabaseException('Erro ao buscar ofertas: ${e.message}');
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
      throw DatabaseException('Erro ao buscar ofertas pendentes: ${e.message}');
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
      throw DatabaseException('Erro ao atualizar oferta: ${e.message}');
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
      throw DatabaseException('Erro ao buscar viagens ativas: ${e.message}');
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
    } on PostgrestException {
      throw const DatabaseException(
          'Erro ao buscar histórico. Por favor, tente novamente mais tarde.',);
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
      } on PostgrestException {
        if (attempt == retries - 1) {
          throw const DatabaseException(
              'Erro ao atualizar localização. Por favor, tente novamente mais tarde.',);
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
    try {
      await _supabase.from('drivers').update({
        'is_online': isOnline,
      }).eq('id', driverId);
    } on PostgrestException {
      throw const DatabaseException(
          'Erro ao atualizar disponibilidade. Por favor, tente novamente mais tarde.',);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao atualizar disponibilidade. Por favor, tente novamente mais tarde.',);
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
            'cnh_number': '', // Dados não expostos na view por privacidade
            'cnh_expiry_date': null,
            'cnh_photo_url': null,
            'crlv_photo_url': null,
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
      throw DatabaseException('Erro ao buscar motoristas disponíveis: ${e.message}', e.code);
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
      throw DatabaseException('Erro ao buscar motoristas disponíveis: ${e.message}', e.code);
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
  /// Retorna dados reais baseados nos motoristas ativos
  Future<List<VehicleCategoryData>> getAvailableCategoriesInRegion({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Busca estatísticas por categoria dos motoristas online na região
      final response = await _supabase.rpc('get_available_categories_stats', params: {
        'lat': latitude,
        'lng': longitude,
        'radius_km': radiusKm,
      },);

      if (response == null || response.isEmpty) {
        // Fallback: retorna categorias padrão se não houver dados reais
        return VehicleCategory.popularCategories
            .map(VehicleCategoryData.defaultForCategory)
            .toList();
      }

      return (response as List).map((stat) {
        final categoryId = stat['vehicle_category'] as String;
        final category = VehicleCategory.fromId(categoryId) ?? VehicleCategory.standard;
        
        return VehicleCategoryData(
          category: category,
          basePricePerKm: (stat['avg_price_per_km'] as num?)?.toDouble() ?? 1.5,
          basePricePerMinute: (stat['avg_price_per_minute'] as num?)?.toDouble() ?? 0.20,
          availableDrivers: stat['driver_count'] as int? ?? 0,
          isAvailable: (stat['driver_count'] as int? ?? 0) > 0,
        );
      }).toList();
    } on PostgrestException catch (e) {
      // Se a função RPC não existir, retorna dados padrão
      if (e.code == '42883') {
        return VehicleCategory.popularCategories
            .map(VehicleCategoryData.defaultForCategory)
            .toList();
      }
      throw DatabaseException('Erro ao buscar categorias disponíveis: ${e.message}');
    } catch (e) {
      // Fallback para dados padrão em caso de erro
      return VehicleCategory.popularCategories
          .map(VehicleCategoryData.defaultForCategory)
          .toList();
    }
  }

  /// Busca dados de uma categoria específica
  Future<VehicleCategoryData?> getCategoryData(VehicleCategory category, {
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      final drivers = await getAvailableDriversNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        category: category.id,
      );

      if (drivers.isEmpty) {
        return VehicleCategoryData.defaultForCategory(category).copyWith(
          availableDrivers: 0,
          isAvailable: false,
        );
      }

      // Calcula preços médios dos motoristas disponíveis
      var avgPricePerKm = 1.5;
      var avgPricePerMinute = 0.20;
      
      final pricesPerKm = drivers
          .where((d) => d.customPricePerKm != null && d.customPricePerKm! > 0)
          .map((d) => d.customPricePerKm!)
          .toList();
      
      final pricesPerMinute = drivers
          .where((d) => d.customPricePerMinute != null && d.customPricePerMinute! > 0)
          .map((d) => d.customPricePerMinute!)
          .toList();

      if (pricesPerKm.isNotEmpty) {
        avgPricePerKm = pricesPerKm.reduce((a, b) => a + b) / pricesPerKm.length;
      }
      
      if (pricesPerMinute.isNotEmpty) {
        avgPricePerMinute = pricesPerMinute.reduce((a, b) => a + b) / pricesPerMinute.length;
      }

      return VehicleCategoryData(
        category: category,
        basePricePerKm: avgPricePerKm,
        basePricePerMinute: avgPricePerMinute,
        availableDrivers: drivers.length,
      );
    } catch (e) {
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
  
  /// Verifica se o motorista pode ficar online baseado nos horários de trabalho
  Future<bool> canDriverGoOnline(String driverId) async => await _driverStatusService.canDriverGoOnlineNow(driverId);
  
  /// Obtém a intenção de ficar online do motorista
  Future<bool> getDriverOnlineIntent(String driverId) async {
    final status = await _driverStatusService.getDriverStatus(driverId);
    return status?.onlineIntent ?? false;
  }
  
  /// Obtém os horários de trabalho do motorista
  Future<List<WorkingHours>> getDriverWorkingHours(String driverId) async => await _workingHoursService.getWorkingHours(driverId);
  
  /// Atualiza os horários de trabalho do motorista
  Future<void> updateDriverWorkingHours(String driverId, List<Map<String, dynamic>> workingHours) async {
    // Remove horários existentes
    await _workingHoursService.deleteAllWorkingHours(driverId);
    
    // Adiciona novos horários
    for (final hours in workingHours) {
      await _workingHoursService.createWorkingHours(
        driverId: driverId,
        dayOfWeek: hours['dayOfWeek'] as int,
        startTime: TimeOfDay(
          hour: int.parse(hours['startTime'].toString().split(':')[0]),
          minute: int.parse(hours['startTime'].toString().split(':')[1]),
        ),
        endTime: TimeOfDay(
          hour: int.parse(hours['endTime'].toString().split(':')[0]),
          minute: int.parse(hours['endTime'].toString().split(':')[1]),
        ),
      );
    }
  }
  
  /// Obtém lista de motoristas efetivamente online
  Future<List<DriverEffectiveStatus>> getEffectivelyOnlineDrivers() async => await _driverStatusService.getOnlineDrivers();
  
  /// Obtém estatísticas de status dos motoristas
  Future<Map<String, int>> getDriverStatusStats() async => await _driverStatusService.getDriverStatusStats();

  /// Verifica se a placa do veículo já está sendo usada por outro motorista
  Future<void> _checkVehiclePlateUniqueness(String plate, String currentDriverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('vehicle_plate', plate)
          .neq('id', currentDriverId);

      if (response.isNotEmpty) {
        throw const ValidationException(
          'Esta placa já está cadastrada por outro motorista. Por favor, verifique os dados e tente novamente.',
        );
      }
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao verificar placa do veículo: ${e.message}',
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao verificar placa do veículo.',
      );
    }
  }

  /// Verifica se a placa do veículo já existe na criação de um novo motorista
  Future<void> _checkVehiclePlateUniquenessForCreation(String plate) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('id, vehicle_plate')
          .eq('vehicle_plate', plate);

      if (response.isNotEmpty) {
        throw const ValidationException(
          'Esta placa já está cadastrada por outro motorista. Por favor, verifique os dados e tente novamente.',
        );
      }
    } on PostgrestException catch (e) {
      throw DatabaseException(
        'Erro ao verificar placa do veículo: ${e.message}',
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw const DatabaseException(
        'Erro inesperado ao verificar placa do veículo.',
      );
    }
  }
}
