import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/trip_request.dart';
import '../models/supabase/trip.dart';
import '../models/supabase/location.dart';
import '../exceptions/app_exceptions.dart';

class TripService {
  final SupabaseClient _supabase;

  TripService(this._supabase);

  // Trip Request Methods
  Future<TripRequest> createTripRequest({
    required String passengerId,
    required String originAddress,
    required double originLatitude,
    required double originLongitude,
    required String destinationAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required String vehicleCategory,
    required bool needsPet,
    required bool needsGrocerySpace,
    required bool isCondoDestination,
    required bool isCondoOrigin,
    required bool needsAc,
    required int numberOfStops,
    required double estimatedDistanceKm,
    required int estimatedDurationMinutes,
    required double estimatedFare,
    String? originNeighborhood,
    String? destinationNeighborhood,
  }) async {
    try {
      final response = await _supabase
          .from('trip_requests')
          .insert({
            'passenger_id': passengerId,
            'origin_address': originAddress,
            'origin_latitude': originLatitude,
            'origin_longitude': originLongitude,
            'origin_neighborhood': originNeighborhood,
            'destination_address': destinationAddress,
            'destination_latitude': destinationLatitude,
            'destination_longitude': destinationLongitude,
            'destination_neighborhood': destinationNeighborhood,
            'vehicle_category': vehicleCategory,
            'needs_pet': needsPet,
            'needs_grocery_space': needsGrocerySpace,
            'is_condo_destination': isCondoDestination,
            'is_condo_origin': isCondoOrigin,
            'needs_ac': needsAc,
            'number_of_stops': numberOfStops,
            'estimated_distance_km': estimatedDistanceKm,
            'estimated_duration_minutes': estimatedDurationMinutes,
            'estimated_fare': estimatedFare,
            'status': 'pending',
          })
          .select()
          .single();

      return TripRequest.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao criar solicitação de viagem. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao criar solicitação de viagem. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<TripRequest>> getTripRequests({
    String? passengerId,
    String? status,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from('trip_requests').select();

      if (passengerId != null) {
        query = query.eq('passenger_id', passengerId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query.order('created_at', ascending: false);

      return response.map((json) => TripRequest.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao buscar solicitações. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao buscar solicitações. Por favor, tente novamente mais tarde.');
    }
  }

  Future<TripRequest?> getTripRequest(String id) async {
    try {
      final response =
          await _supabase.from('trip_requests').select().eq('id', id).single();

      return TripRequest.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw DatabaseException(
          'Erro ao buscar solicitação. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao buscar solicitação. Por favor, tente novamente mais tarde.');
    }
  }

  Future<TripRequest> updateTripRequestStatus({
    required String id,
    required String status,
    String? driverId,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (driverId != null) {
        updateData['accepted_by_driver_id'] = driverId;
        updateData['accepted_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('trip_requests')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return TripRequest.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao atualizar status. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao atualizar status. Por favor, tente novamente mais tarde.');
    }
  }

  // Trip Methods
  Future<Trip> createTrip({
    required String tripRequestId,
    required String driverId,
    required String passengerId,
    required String originAddress,
    required double originLatitude,
    required double originLongitude,
    required String destinationAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required double actualDistanceKm,
    required int actualDurationMinutes,
    required double baseFare,
    required double finalFare,
    String? promoCodeId,
  }) async {
    try {
      final response = await _supabase
          .from('trips')
          .insert({
            'trip_request_id': tripRequestId,
            'driver_id': driverId,
            'passenger_id': passengerId,
            'origin_address': originAddress,
            'origin_latitude': originLatitude,
            'origin_longitude': originLongitude,
            'destination_address': destinationAddress,
            'destination_latitude': destinationLatitude,
            'destination_longitude': destinationLongitude,
            'actual_distance_km': actualDistanceKm,
            'actual_duration_minutes': actualDurationMinutes,
            'base_fare': baseFare,
            'final_fare': finalFare,
            'status': 'ongoing',
            'start_time': DateTime.now().toIso8601String(),
            'promo_code_id': promoCodeId,
          })
          .select()
          .single();

      return Trip.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao criar viagem. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao criar viagem. Por favor, tente novamente mais tarde.');
    }
  }

  Future<Trip?> getTrip(String id) async {
    try {
      final response =
          await _supabase.from('trips').select().eq('id', id).single();

      return Trip.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw DatabaseException(
          'Erro ao buscar viagem. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao buscar viagem. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<Trip>> getTrips({
    String? passengerId,
    String? driverId,
    String? status,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from('trips').select();

      if (passengerId != null) {
        query = query.eq('passenger_id', passengerId);
      }

      if (driverId != null) {
        query = query.eq('driver_id', driverId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query.order('created_at', ascending: false);

      return response.map((json) => Trip.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao buscar viagens. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao buscar viagens. Por favor, tente novamente mais tarde.');
    }
  }

  Future<Trip> completeTrip({
    required String tripId,
    required double actualDistanceKm,
    required int actualDurationMinutes,
    required double finalFare,
  }) async {
    try {
      final response = await _supabase
          .from('trips')
          .update({
            'status': 'completed',
            'actual_distance_km': actualDistanceKm,
            'actual_duration_minutes': actualDurationMinutes,
            'final_fare': finalFare,
            'end_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tripId)
          .select()
          .single();

      return Trip.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao completar viagem. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao completar viagem. Por favor, tente novamente mais tarde.');
    }
  }

  Future<Trip> rateTrip({
    required String tripId,
    double? driverRating,
    double? passengerRating,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (driverRating != null) {
        updateData['driver_rating'] = driverRating;
      }

      if (passengerRating != null) {
        updateData['passenger_rating'] = passengerRating;
      }

      final response = await _supabase
          .from('trips')
          .update(updateData)
          .eq('id', tripId)
          .select()
          .single();

      return Trip.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao avaliar viagem. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao avaliar viagem. Por favor, tente novamente mais tarde.');
    }
  }

  // Location Methods
  Future<Location> saveLocation({
    required String userId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? neighborhood,
    String? notes,
    bool isFavorite = false,
    String? locationType,
  }) async {
    try {
      final response = await _supabase
          .from('locations')
          .insert({
            'user_id': userId,
            'name': name,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'neighborhood': neighborhood,
            'notes': notes,
            'is_favorite': isFavorite,
            'location_type': locationType,
          })
          .select()
          .single();

      return Location.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao salvar localização. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao salvar localização. Por favor, tente novamente mais tarde.');
    }
  }

  Future<List<Location>> getUserLocations(String userId) async {
    try {
      final response = await _supabase
          .from('locations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => Location.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao buscar localizações. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao buscar localizações. Por favor, tente novamente mais tarde.');
    }
  }

  Future<Location?> getLocation(String id) async {
    try {
      final response =
          await _supabase.from('locations').select().eq('id', id).single();

      return Location.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw DatabaseException(
          'Erro ao buscar localização. Por favor, tente novamente mais tarde.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao buscar localização. Por favor, tente novamente mais tarde.');
    }
  }

  Future<Location> updateLocation({
    required String id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? neighborhood,
    String? notes,
    bool? isFavorite,
    String? locationType,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (address != null) updateData['address'] = address;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (neighborhood != null) updateData['neighborhood'] = neighborhood;
      if (notes != null) updateData['notes'] = notes;
      if (isFavorite != null) updateData['is_favorite'] = isFavorite;
      if (locationType != null) updateData['location_type'] = locationType;

      final response = await _supabase
          .from('locations')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Location.fromJson(response);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao atualizar localização. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao atualizar localização. Por favor, tente novamente mais tarde.');
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _supabase.from('locations').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(
          'Erro ao deletar localização. Por favor, verifique os dados e tente novamente.');
    } catch (e) {
      throw DatabaseException(
          'Erro inesperado ao deletar localização. Por favor, tente novamente mais tarde.');
    }
  }

  // Real-time subscriptions
  Stream<List<TripRequest>> subscribeToTripRequests({
    String? passengerId,
    String? status,
  }) {
    dynamic query = _supabase.from('trip_requests').stream(primaryKey: ['id']);

    if (passengerId != null) {
      query = query.eq('passenger_id', passengerId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    return query
        .order('created_at')
        .map((data) => data.map((json) => TripRequest.fromJson(json)).toList());
  }

  Stream<Trip?> subscribeToTrip(String tripId) {
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((data) => data.isEmpty ? null : Trip.fromJson(data.first));
  }
}
