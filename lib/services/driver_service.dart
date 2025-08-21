import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/driver.dart';
import '../models/supabase/driver_offer.dart';
import '../models/supabase/trip.dart';
import '../exceptions/app_exceptions.dart';

class DriverService {

  DriverService(this._supabase);
  final SupabaseClient _supabase;

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
    Map<String, dynamic> fees = const {},
    String? acPolicy,
    double? customPricePerKm,
    double? customPricePerMinute,
    Map<String, dynamic>? bankData,
    Map<String, dynamic>? pixData,
    double? currentLatitude,
    double? currentLongitude,
  }) async {
    try {
      final insertData = {
        'user_id': userId,
        'cnh_number': cnhNumber,
        'cnh_expiry_date': cnhExpiryDate.toIso8601String(),
        'cnh_photo_url': cnhPhotoUrl,
        'brand': brand,
        'model': model,
        'year': year,
        'color': color,
        'plate': plate,
        'category': category,
        'crlv_photo_url': crlvPhotoUrl,
        'approval_status': 'pending',
        'is_online': false,
        'accepts_pet': acceptsPet,
        'accepts_grocery': acceptsGrocery,
        'accepts_condo': acceptsCondo,
        'fees': fees,
        'ac_policy': acPolicy,
        'custom_price_per_km': customPricePerKm,
        'custom_price_per_minute': customPricePerMinute,
        'bank_data': bankData,
        'pix_data': pixData,
        'current_latitude': currentLatitude,
        'current_longitude': currentLongitude,
        'ratings': 0.0,
        'trips': 0,
        'cancellations': 0,
      };

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
    Map<String, dynamic>? fees,
    String? acPolicy,
    double? customPricePerKm,
    double? customPricePerMinute,
    Map<String, dynamic>? bankData,
    Map<String, dynamic>? pixData,
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

      if (brand != null) updates['brand'] = brand;
      if (model != null) updates['model'] = model;
      if (year != null) updates['year'] = year;
      if (color != null) updates['color'] = color;
      if (plate != null) updates['plate'] = plate;
      if (category != null) updates['category'] = category;
      if (crlvPhotoUrl != null) updates['crlv_photo_url'] = crlvPhotoUrl;

      if (approvalStatus != null) updates['approval_status'] = approvalStatus;
      if (isOnline != null) updates['is_online'] = isOnline;

      if (acceptsPet != null) updates['accepts_pet'] = acceptsPet;
      if (acceptsGrocery != null) updates['accepts_grocery'] = acceptsGrocery;
      if (acceptsCondo != null) updates['accepts_condo'] = acceptsCondo;

      if (fees != null) updates['fees'] = fees;
      if (acPolicy != null) updates['ac_policy'] = acPolicy;
      if (customPricePerKm != null) {
        updates['custom_price_per_km'] = customPricePerKm;
      }
      if (customPricePerMinute != null) {
        updates['custom_price_per_minute'] = customPricePerMinute;
      }
      if (bankData != null) updates['bank_data'] = bankData;
      if (pixData != null) updates['pix_data'] = pixData;

      if (currentLatitude != null) {
        updates['current_latitude'] = currentLatitude;
      }
      if (currentLongitude != null) {
        updates['current_longitude'] = currentLongitude;
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
    try {
      await _supabase.from('drivers').update({
        'current_latitude': latitude,
        'current_longitude': longitude,
      }).eq('id', driverId);
    } on PostgrestException {
      throw const DatabaseException(
          'Erro ao atualizar localização. Por favor, tente novamente mais tarde.',);
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao atualizar localização. Por favor, tente novamente mais tarde.',);
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
            .where((trip) {
              return ['accepted', 'in_progress'].contains(trip['status']);
            })
            .map((trip) => Trip.fromJson(trip))
            .toList());

  // Busca motoristas disponíveis próximos com filtros de categoria e preferências
  Future<List<Driver>> getAvailableDriversNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? category,
    bool? needsPet,
    bool? needsGrocery,
    bool? needsCondo,
    int? limit,
  }) async {
    try {
      // Aproximação de raio usando bounding box
      final latDelta = radiusKm / 111.0; // ~111km por grau
      final lngDelta = radiusKm / (111.0 * math.cos(latitude * math.pi / 180.0)).abs().clamp(0.0001, double.infinity);

      dynamic query = _supabase.from('drivers').select().eq('is_online', true);

      // Somente aprovados (se existir esse status)
      query = query.or('approval_status.eq.approved,approval_status.is.null');

      // Filtro de categoria
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // Preferências
      if (needsPet ?? false) query = query.eq('accepts_pet', true);
      if (needsGrocery ?? false) query = query.eq('accepts_grocery', true);
      if (needsCondo ?? false) query = query.eq('accepts_condo', true);

      // Bounding box
      query = query
          .gte('current_latitude', latitude - latDelta)
          .lte('current_latitude', latitude + latDelta)
          .gte('current_longitude', longitude - lngDelta)
          .lte('current_longitude', longitude + lngDelta)
          .order('ratings', ascending: false);

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List)
          .map((json) => Driver.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar motoristas disponíveis: ${e.message}');
    } catch (e) {
      throw const DatabaseException('Erro inesperado ao buscar motoristas disponíveis.');
    }
  }
}
