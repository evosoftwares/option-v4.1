import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/driver.dart';
import '../models/supabase/vehicle.dart';
import '../models/supabase/driver_offer.dart';
import '../models/supabase/trip.dart';
import '../exceptions/app_exceptions.dart';

class DriverService {
  final SupabaseClient _supabase;

  DriverService(this._supabase);

  // Get driver profile
  Future<Driver?> getDriver(String driverId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('id', driverId)
          .single();

      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw DatabaseException('Erro ao buscar motorista: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar motorista');
    }
  }

  // Create driver profile
  Future<Driver> createDriver({
    required String userId,
    required String name,
    required String cpf,
    required String phone,
    required String licenseNumber,
    required DateTime licenseExpiry,
    String? photoUrl,
  }) async {
    try {
      final response = await _supabase.from('drivers').insert({
        'user_id': userId,
        'name': name,
        'cpf': cpf,
        'phone': phone,
        'license_number': licenseNumber,
        'license_expiry': licenseExpiry.toIso8601String(),
        'photo_url': photoUrl,
        'is_verified': false,
        'rating': 0.0,
        'total_trips': 0,
      }).select().single();

      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao criar perfil de motorista: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao criar perfil de motorista');
    }
  }

  // Update driver profile
  Future<Driver> updateDriver(String driverId, {
    String? name,
    String? phone,
    String? photoUrl,
    bool? isAvailable,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (isAvailable != null) updates['is_available'] = isAvailable;

      final response = await _supabase
          .from('drivers')
          .update(updates)
          .eq('id', driverId)
          .select()
          .single();

      return Driver.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao atualizar motorista: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao atualizar motorista');
    }
  }

  // Create vehicle
  Future<Vehicle> createVehicle({
    required String driverId,
    required String brand,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
    required String renavam,
    required String fuelType,
    required int capacity,
    String? photoUrl,
  }) async {
    try {
      final response = await _supabase.from('vehicles').insert({
        'driver_id': driverId,
        'brand': brand,
        'model': model,
        'year': year,
        'color': color,
        'license_plate': licensePlate,
        'renavam': renavam,
        'fuel_type': fuelType,
        'capacity': capacity,
        'photo_url': photoUrl,
        'is_verified': false,
      }).select().single();

      return Vehicle.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao criar veículo: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao criar veículo');
    }
  }

  // Get driver's vehicles
  Future<List<Vehicle>> getDriverVehicles(String driverId) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      return response.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar veículos: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar veículos');
    }
  }

  // Create driver offer
  Future<DriverOffer> createOffer({
    required String driverId,
    required String tripId,
    required double price,
    required Duration estimatedDuration,
    String? notes,
  }) async {
    try {
      final response = await _supabase.from('driver_offers').insert({
        'driver_id': driverId,
        'trip_id': tripId,
        'price': price,
        'estimated_duration_minutes': estimatedDuration.inMinutes,
        'notes': notes,
        'status': 'pending',
      }).select().single();

      return DriverOffer.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao criar oferta: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao criar oferta');
    }
  }

  // Get driver's offers
  Future<List<DriverOffer>> getDriverOffers(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_offers')
          .select('''
            *,
            trip:trips(*)
          ''')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      return response.map((offer) => DriverOffer.fromJson(offer)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar ofertas: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar ofertas');
    }
  }

  // Get pending offers for driver
  Future<List<DriverOffer>> getPendingOffers(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_offers')
          .select('''
            *,
            trip:trips(*)
          ''')
          .eq('driver_id', driverId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return response.map((offer) => DriverOffer.fromJson(offer)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar ofertas pendentes: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar ofertas pendentes');
    }
  }

  // Update offer status
  Future<DriverOffer> updateOfferStatus(String offerId, String status) async {
    try {
      final response = await _supabase
          .from('driver_offers')
          .update({'status': status})
          .eq('id', offerId)
          .select()
          .single();

      return DriverOffer.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao atualizar oferta: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao atualizar oferta');
    }
  }

  // Get driver's active trips
  Future<List<Trip>> getDriverActiveTrips(String driverId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('''
            *,
            driver_offer:driver_offers!inner(*)
          ''')
          .eq('driver_offer.driver_id', driverId)
          .or('status.eq.accepted,status.eq.in_progress')
          .order('created_at', ascending: false);

      return response.map((trip) => Trip.fromJson(trip)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar viagens ativas: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar viagens ativas');
    }
  }

  // Get driver's trip history
  Future<List<Trip>> getDriverTripHistory(String driverId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('''
            *,
            driver_offer:driver_offers!inner(*)
          ''')
          .eq('driver_offer.driver_id', driverId)
          .or('status.eq.completed,status.eq.cancelled')
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((trip) => Trip.fromJson(trip)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao buscar histórico: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao buscar histórico');
    }
  }

  // Update driver location
  Future<void> updateLocation(String driverId, double latitude, double longitude) async {
    try {
      await _supabase.from('drivers').update({
        'current_latitude': latitude,
        'current_longitude': longitude,
        'last_location_update': DateTime.now().toIso8601String(),
      }).eq('id', driverId);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao atualizar localização: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao atualizar localização');
    }
  }

  // Update driver availability
  Future<void> updateAvailability(String driverId, bool isAvailable) async {
    try {
      await _supabase.from('drivers').update({
        'is_available': isAvailable,
      }).eq('id', driverId);
    } on PostgrestException catch (e) {
      throw DatabaseException('Erro ao atualizar disponibilidade: ${e.message}');
    } catch (e) {
      throw DatabaseException('Erro inesperado ao atualizar disponibilidade');
    }
  }

  // Stream driver profile updates
  Stream<Driver> streamDriver(String driverId) {
    return _supabase
        .from('drivers:id=eq.$driverId')
        .stream(primaryKey: ['id'])
        .map((data) => Driver.fromJson(data.first));
  }

  // Stream driver's active trips
  Stream<List<Trip>> streamDriverActiveTrips(String driverId) {
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((trip) {
              final driverOffer = trip['driver_offer'] as Map<String, dynamic>?;
              return driverOffer != null && 
                     driverOffer['driver_id'] == driverId &&
                     ['accepted', 'in_progress'].contains(trip['status']);
            })
            .map((trip) => Trip.fromJson(trip))
            .toList());
  }
}