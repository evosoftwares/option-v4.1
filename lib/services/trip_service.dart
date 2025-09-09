import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error_handling/postgrest_error_mapper.dart';
import '../core/error_handling/error_logger.dart';
import '../core/error_handling/app_error.dart';
import '../exceptions/app_exceptions.dart';
import '../models/supabase/trip.dart';
import '../models/supabase/trip_request.dart';
import 'auth_service.dart';
import 'app_logger.dart';

class TripService {

  TripService(this._supabase);
  final SupabaseClient _supabase;

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
    final startTime = DateTime.now();
    
    try {
      AppLogger.process('Iniciando criação de solicitação de viagem', tag: 'TRIP_SERVICE');
      AppLogger.create('TripRequest', passengerId, tag: 'TRIP_SERVICE', data: {
        'passenger_id': passengerId,
        'origin_address': originAddress,
        'destination_address': destinationAddress,
        'vehicle_category': vehicleCategory,
        'estimated_distance_km': estimatedDistanceKm,
        'estimated_fare': estimatedFare
      });
      
      // Validar autenticação e autorização
      if (!AuthService.isAuthenticated()) {
        AppLogger.security('trip_request_unauthorized', details: 'User not authenticated');
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      AppLogger.security('trip_request_auth_validated', userId: currentUserId);
      
      // Verificar se o usuário pode criar trip request para este passageiro
      await AuthService.validateUserAccess(
        resourceUserId: passengerId,
        operation: 'create_trip_request',
      );
      
      AppLogger.trip('solicitation_created', 'GENERATING', passengerId: passengerId, data: {
        'origin': originAddress,
        'destination': destinationAddress,
        'category': vehicleCategory
      });
      
      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'TRIP_REQUEST_CREATED',
        description: 'Nova solicitação de viagem criada',
        metadata: {
          'passenger_id': passengerId,
          'origin_address': originAddress,
          'destination_address': destinationAddress,
          'vehicle_category': vehicleCategory,
        },
      );
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
      final context = {
        'operation': 'createTripRequest',
        'passengerId': passengerId,
        'originAddress': originAddress,
        'destinationAddress': destinationAddress,
        'postgrestCode': e.code,
        'postgrestMessage': e.message
      };
      
      await ErrorLoggingService.instance.logException(
        e,
        context: context,
        type: AppErrorType.databaseError,
        severity: ErrorSeverity.high,
      );
      
      throw PostgrestErrorMapper.mapError(e, context: context);
    } catch (e) {
      final context = {
        'operation': 'createTripRequest',
        'passengerId': passengerId,
        'originAddress': originAddress,
        'destinationAddress': destinationAddress,
        'errorType': e.runtimeType.toString()
      };
      
      if (e is Exception) {
        await ErrorLoggingService.instance.logException(
          e,
          context: context,
          type: AppErrorType.databaseError,
          severity: ErrorSeverity.high,
        );
      }
      
      throw const DatabaseException(
          'Erro inesperado ao criar solicitação de viagem. Por favor, tente novamente mais tarde.',);
    }
  }

  Future<List<TripRequest>> getTripRequests({
    String? passengerId,
    String? status,
    int? limit,
  }) async {
    try {
      // Validar autenticação
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw const UnauthorizedException('ID do usuário não disponível');
      }
      
      // Se passengerId não foi fornecido, usar o usuário atual
      String? filterPassengerId = passengerId;
      if (filterPassengerId == null) {
        // Buscar o passenger_id do usuário atual
        final passenger = await _supabase
            .from('passengers')
            .select('id')
            .eq('auth_user_id', currentUserId)
            .maybeSingle();
        filterPassengerId = passenger?['id'];
      } else {
        // Validar acesso ao passageiro especificado
        await AuthService.validateUserAccess(
          resourceUserId: filterPassengerId,
          operation: 'read_trip_requests',
        );
      }
      dynamic query = _supabase.from('trip_requests').select();

      // SEMPRE filtrar por passenger_id para segurança
      query = query.eq('passenger_id', filterPassengerId);
    
      if (status != null) {
        query = query.eq('status', status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query.order('created_at', ascending: false);

      return response.map((json) => TripRequest.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      final context = {
        'operation': 'getTripRequests',
        'passengerId': passengerId,
        'status': status,
        'limit': limit,
        'postgrestCode': e.code,
        'postgrestMessage': e.message
      };
      
      await ErrorLoggingService.instance.logException(
        e,
        context: context,
        type: AppErrorType.databaseError,
        severity: ErrorSeverity.medium,
      );
      
      throw PostgrestErrorMapper.mapError(e, context: context);
    } catch (e) {
      final context = {
        'operation': 'getTripRequests',
        'passengerId': passengerId,
        'status': status,
        'limit': limit,
        'errorType': e.runtimeType.toString()
      };
      
      if (e is Exception) {
        await ErrorLoggingService.instance.logException(
          e,
          context: context,
          type: AppErrorType.databaseError,
          severity: ErrorSeverity.medium,
        );
      }
      
      throw const DatabaseException(
          'Erro inesperado ao buscar solicitações. Por favor, tente novamente mais tarde.',);
    }
  }

  Future<TripRequest?> getTripRequest(String id) async {
    try {
      // Validar autenticação
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Buscar a trip request primeiro para validar ownership
      final response = await _supabase
          .from('trip_requests')
          .select('*, passengers!inner(auth_user_id)')
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      // Validar se o usuário tem acesso a esta trip request
      final passengerAuthUserId = response['passengers']['auth_user_id'];
      if (passengerAuthUserId != currentUserId) {
        // Verificar se é um motorista que pode ver esta solicitação
        final isDriver = await AuthService.hasRole('driver');
        if (!isDriver) {
          throw const UnauthorizedException('Acesso negado a esta solicitação de viagem.');
        }
      }
      return TripRequest.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      
      final context = {
        'operation': 'getTripRequest',
        'id': id,
        'postgrestCode': e.code,
        'postgrestMessage': e.message
      };
      
      await ErrorLoggingService.instance.logException(
        e,
        context: context,
        type: AppErrorType.databaseError,
        severity: ErrorSeverity.medium,
      );
      
      throw PostgrestErrorMapper.mapError(e, context: context);
    } catch (e) {
      final context = {
        'operation': 'getTripRequest',
        'id': id,
        'errorType': e.runtimeType.toString()
      };
      
      if (e is Exception) {
        await ErrorLoggingService.instance.logException(
          e,
          context: context,
          type: AppErrorType.databaseError,
          severity: ErrorSeverity.medium,
        );
      }
      
      throw const DatabaseException(
          'Erro inesperado ao buscar solicitação. Por favor, tente novamente mais tarde.',);
    }
  }

  Future<TripRequest> updateTripRequestStatus({
    required String id,
    required String status,
    String? driverId,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Buscar a trip request para validar ownership
      final existingRequest = await getTripRequest(id);
      if (existingRequest == null) {
        throw const DatabaseException('Solicitação de viagem não encontrada');
      }
      
      // Validar se o usuário pode atualizar esta solicitação
      final canUpdate = currentUserId == existingRequest.passengerId ||
          (driverId != null && currentUserId == driverId) ||
          await AuthService.hasRole('admin');
      
      if (!canUpdate) {
        await AuthService.logSecurityEvent(
          eventType: 'UNAUTHORIZED_TRIP_UPDATE',
          description: 'Tentativa de atualizar solicitação sem permissão',
          metadata: {
            'trip_request_id': id,
            'current_user_id': currentUserId,
            'passenger_id': existingRequest.passengerId,
            'target_status': status,
          },
        );
        throw const UnauthorizedException('Você não tem permissão para atualizar esta solicitação');
      }
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

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'TRIP_REQUEST_STATUS_UPDATED',
        description: 'Status da solicitação de viagem atualizado',
        metadata: {
          'trip_request_id': id,
          'old_status': existingRequest.status,
          'new_status': status,
          'driver_id': driverId,
        },
      );

      return TripRequest.fromJson(response);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'updateTripRequestStatus', 'id': id, 'status': status, 'driverId': driverId});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao atualizar status. Por favor, tente novamente mais tarde.',);
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
    double? discountApplied,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Validar se o usuário pode criar viagem (deve ser o motorista ou admin)
      final canCreate = currentUserId == driverId || await AuthService.hasRole('admin');
      
      if (!canCreate) {
        await AuthService.logSecurityEvent(
          eventType: 'UNAUTHORIZED_TRIP_CREATION',
          description: 'Tentativa de criar viagem sem permissão',
          metadata: {
            'current_user_id': currentUserId,
            'target_driver_id': driverId,
            'passenger_id': passengerId,
          },
        );
        throw const UnauthorizedException('Apenas o motorista designado pode criar a viagem');
      }
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
            'discount_applied': discountApplied,
          })
          .select()
          .single();

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'TRIP_CREATED',
        description: 'Nova viagem criada',
        metadata: {
          'trip_id': response['id'],
          'trip_request_id': tripRequestId,
          'driver_id': driverId,
          'passenger_id': passengerId,
          'base_fare': baseFare,
        },
      );

      return Trip.fromJson(response);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'createTrip', 'tripRequestId': tripRequestId, 'driverId': driverId, 'passengerId': passengerId});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao criar viagem. Por favor, tente novamente mais tarde.',);
    }
  }

  Future<Trip?> getTrip(String id) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Buscar a viagem com informações de relacionamento para validação
      final response = await _supabase
          .from('trips')
          .select('*, passengers!inner(auth_user_id), drivers!inner(auth_user_id)')
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      // Validar se o usuário pode acessar esta viagem
      final passengerAuthUserId = response['passengers']['auth_user_id'];
      final driverAuthUserId = response['drivers']['auth_user_id'];
      
      final canAccess = currentUserId == passengerAuthUserId ||
          currentUserId == driverAuthUserId ||
          await AuthService.hasRole('admin');
      
      if (!canAccess) {
        await AuthService.logSecurityEvent(
          eventType: 'UNAUTHORIZED_TRIP_ACCESS',
          description: 'Tentativa de acessar viagem sem permissão',
          metadata: {
            'trip_id': id,
            'current_user_id': currentUserId,
            'driver_auth_user_id': driverAuthUserId,
            'passenger_auth_user_id': passengerAuthUserId,
          },
        );
        throw const UnauthorizedException('Você não tem permissão para acessar esta viagem');
      }

      return Trip.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getTrip', 'id': id});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao buscar viagem. Por favor, tente novamente mais tarde.',);
    }
  }

  Future<List<Trip>> getTrips({
    String? passengerId,
    String? driverId,
    String? status,
    int? limit,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Validar acesso aos filtros especificados
      if (passengerId != null) {
        await AuthService.validateUserAccess(
          resourceUserId: passengerId,
          operation: 'read_trips',
        );
      }
      
      if (driverId != null) {
        await AuthService.validateUserAccess(
          resourceUserId: driverId,
          operation: 'read_trips',
        );
      }
      
      dynamic query = _supabase.from('trips').select();

      // Se nenhum filtro específico, filtrar pelo usuário atual
      if (passengerId == null && driverId == null) {
        // Buscar viagens onde o usuário atual é passageiro ou motorista
        query = query.or('passenger_id.eq.$currentUserId,driver_id.eq.$currentUserId');
      } else {
        if (passengerId != null) {
          query = query.eq('passenger_id', passengerId);
        }

        if (driverId != null) {
          query = query.eq('driver_id', driverId);
        }
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getTrips', 'passengerId': passengerId, 'driverId': driverId, 'status': status});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao buscar viagens. Por favor, tente novamente mais tarde.',);
    }
  }

  // Get trip history with user details for history screen
  Future<List<TripHistoryModel>> getTripHistory({
    String? passengerId,
    String? driverId,
    int limit = 20,
  }) async {
    try {
      print('🔍 [DEBUG] getTripHistory chamado - passengerId: $passengerId, driverId: $driverId');
      
      const selectQuery = '''
        id, trip_code, status, origin_address, destination_address,
        actual_distance_km, base_fare, additional_fees, created_at, trip_completed_at,
        cancelled_at, cancellation_reason, payment_status
      ''';

      dynamic query = _supabase.from('trips').select(selectQuery);

      if (passengerId != null) {
        query = query.eq('passenger_id', passengerId);
        print('🔍 [DEBUG] Filtrando por passenger_id: $passengerId');
      }

      if (driverId != null) {
        query = query.eq('driver_id', driverId);
        print('🔍 [DEBUG] Filtrando por driver_id: $driverId');
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      print('🔍 [DEBUG] Query executada com sucesso. Retornados ${response.length} registros');
      
      if (response.isEmpty) {
        print('⚠️ [DEBUG] Nenhuma viagem encontrada no banco de dados');
        return [];
      }

      // Para cada viagem, buscar informações do outro usuário
      final trips = <TripHistoryModel>[];
      
      for (final json in response) {
        print('🔍 [DEBUG] Processando viagem: ${json['id']}');
        
        String? otherUserName;
        String? otherUserPhotoUrl;
        
        try {
          // Se é passageiro, buscar info do motorista
          if (passengerId != null && json['driver_id'] != null) {
            final driverData = await _supabase
                .from('drivers')
                .select('app_users!inner(full_name, photo_url)')
                .eq('id', json['driver_id'])
                .maybeSingle();
                
            if (driverData != null && driverData['app_users'] != null) {
              otherUserName = driverData['app_users']['full_name'];
              otherUserPhotoUrl = driverData['app_users']['photo_url'];
            }
          }
          // Se é motorista, buscar info do passageiro  
          else if (driverId != null && json['passenger_id'] != null) {
            final passengerData = await _supabase
                .from('passengers')
                .select('app_users!inner(full_name, photo_url)')
                .eq('id', json['passenger_id'])
                .maybeSingle();
                
            if (passengerData != null && passengerData['app_users'] != null) {
              otherUserName = passengerData['app_users']['full_name'];
              otherUserPhotoUrl = passengerData['app_users']['photo_url'];
            }
          }
        } catch (e) {
          print('⚠️ [DEBUG] Erro ao buscar dados do outro usuário: $e');
          // Continua sem os dados do outro usuário
        }

        final trip = TripHistoryModel(
          id: json['id'],
          tripCode: json['trip_code'],
          status: json['status'] ?? 'unknown',
          originAddress: json['origin_address'] ?? '',
          destinationAddress: json['destination_address'] ?? '',
          actualDistanceKm: json['actual_distance_km']?.toDouble(),
          baseFare: (json['base_fare'] ?? 0).toDouble(),
          additionalFees: (json['additional_fees'] ?? 0).toDouble(),
          requestedAt: DateTime.parse(json['created_at']),
          completedAt: json['trip_completed_at'] != null ? DateTime.parse(json['trip_completed_at']) : null,
          cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
          cancellationReason: json['cancellation_reason'],
          paymentStatus: json['payment_status'] ?? 'pending',
          otherUserName: otherUserName,
          otherUserPhotoUrl: otherUserPhotoUrl,
        );
        
        trips.add(trip);
      }

      print('✅ [DEBUG] ${trips.length} viagens processadas com sucesso');
      return trips;
    } on PostgrestException catch (e) {
      print('❌ [DEBUG] PostgrestException: ${e.message}');
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getTripHistory', 'passengerId': passengerId, 'driverId': driverId});
    } catch (e) {
      print('❌ [DEBUG] Erro geral: $e');
      throw const DatabaseException(
          'Erro inesperado ao buscar histórico. Tente novamente.',);
    }
  }

  Future<Trip> completeTrip({
    required String tripId,
    required double actualDistanceKm,
    required int actualDurationMinutes,
    required double finalFare,
  }) async {
    try {
      // Validações de segurança
      if (!AuthService.isAuthenticated()) {
        throw const UnauthorizedException('Usuário não autenticado');
      }
      
      final currentUserId = AuthService.getCurrentUserId();
      
      // Buscar a viagem para validar ownership
      final existingTrip = await getTrip(tripId);
      if (existingTrip == null) {
        throw const DatabaseException('Viagem não encontrada');
      }
      
      // Validar se o usuário pode completar esta viagem (deve ser o motorista)
      final canComplete = currentUserId == existingTrip.driverId || await AuthService.hasRole('admin');
      
      if (!canComplete) {
        await AuthService.logSecurityEvent(
          eventType: 'UNAUTHORIZED_TRIP_COMPLETION',
          description: 'Tentativa de completar viagem sem permissão',
          metadata: {
            'trip_id': tripId,
            'current_user_id': currentUserId,
            'driver_id': existingTrip.driverId,
          },
        );
        throw const UnauthorizedException('Apenas o motorista pode completar a viagem');
      }
      
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

      // Log de auditoria
      await AuthService.logSecurityEvent(
        eventType: 'TRIP_COMPLETED',
        description: 'Viagem completada',
        metadata: {
          'trip_id': tripId,
          'driver_id': existingTrip.driverId,
          'passenger_id': existingTrip.passengerId,
          'actual_distance': actualDistanceKm,
          'actual_duration': actualDurationMinutes,
          'final_fare': finalFare,
        },
      );

      return Trip.fromJson(response);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'completeTrip', 'tripId': tripId});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao completar viagem. Por favor, tente novamente mais tarde.',);
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
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'rateTrip', 'tripId': tripId});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao avaliar viagem. Por favor, tente novamente mais tarde.',);
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

  Stream<Trip?> subscribeToTrip(String tripId) => _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((data) => data.isEmpty ? null : Trip.fromJson(data.first));

  // Targeted request methods
  Future<List<TripRequest>> getTargetedRequestsForDriver(String driverId) async {
    try {
      final response = await _supabase
          .from('trip_requests')
          .select()
          .eq('target_driver_id', driverId)
          .eq('status', 'pending')
          .gte('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return response.map(TripRequest.fromJson).toList();
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'getTargetedRequestsForDriver', 'driverId': driverId});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao buscar solicitações. Tente novamente.',);
    }
  }

  Stream<List<TripRequest>> subscribeToTargetedRequests(String driverId) => _supabase
        .from('trip_requests')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => 
                json['target_driver_id'] == driverId &&
                json['status'] == 'pending' &&
                DateTime.parse(json['expires_at'] ?? DateTime.now().toIso8601String())
                    .isAfter(DateTime.now()))
            .map(TripRequest.fromJson)
            .toList());

  Future<TripRequest> acceptTripRequest({
    required String requestId,
    required String driverId,
  }) async {
    try {
      final response = await _supabase
          .from('trip_requests')
          .update({
            'status': 'accepted',
            'accepted_by_driver_id': driverId,
            'accepted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return TripRequest.fromJson(response);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'acceptTripRequest', 'requestId': requestId, 'driverId': driverId});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao aceitar solicitação. Tente novamente.',);
    }
  }

  Future<TripRequest> declineTripRequest({
    required String requestId,
    required String driverId,
  }) async {
    try {
      // Get current request to access fallback drivers
      final currentRequest = await getTripRequest(requestId);
      if (currentRequest == null) {
        throw const DatabaseException('Solicitação não encontrada.');
      }

      // Remove current driver from fallback list and get next driver
      final fallbackList = List<String>.from(currentRequest.fallbackDrivers ?? []);
      fallbackList.remove(driverId);
      final nextDriverId = fallbackList.isNotEmpty ? fallbackList.first : null;

      final updateData = <String, dynamic>{
        'fallback_drivers': fallbackList,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If there's a next driver, assign to them
      if (nextDriverId != null) {
        updateData['target_driver_id'] = nextDriverId;
        updateData['expires_at'] = DateTime.now().add(const Duration(seconds: 10)).toIso8601String();
      } else {
        // No more fallback drivers, mark as expired
        updateData['status'] = 'expired';
        updateData['target_driver_id'] = null;
      }

      final response = await _supabase
          .from('trip_requests')
          .update(updateData)
          .eq('id', requestId)
          .select()
          .single();

      return TripRequest.fromJson(response);
    } on PostgrestException catch (e) {
      throw PostgrestErrorMapper.mapError(e, context: {'operation': 'declineTripRequest', 'requestId': requestId, 'driverId': driverId});
    } catch (e) {
      throw const DatabaseException(
          'Erro inesperado ao recusar solicitação. Tente novamente.',);
    }
  }
}

// Model for trip history screen
class TripHistoryModel {

  TripHistoryModel({
    required this.id,
    this.tripCode,
    required this.status,
    required this.originAddress,
    required this.destinationAddress,
    this.actualDistanceKm,
    required this.baseFare,
    required this.additionalFees,
    required this.requestedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.paymentStatus,
    this.driverRating,
    this.passengerRating,
    this.otherUserName,
    this.otherUserPhotoUrl,
  });

  final String id;
  final String? tripCode;
  final String status;
  final String originAddress;
  final String destinationAddress;
  final double? actualDistanceKm;
  final double baseFare;
  final double additionalFees;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String paymentStatus;
  final double? driverRating;
  final double? passengerRating;
  final String? otherUserName;
  final String? otherUserPhotoUrl;

  String get statusDisplayText {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return 'Em andamento';
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      default:
        return 'Status desconhecido';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(requestedAt);

    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${requestedAt.day}/${requestedAt.month}/${requestedAt.year}';
    }
  }

  // Calculated field for total fare (base + additional fees)
  double get totalFare => baseFare + additionalFees;

  String get shortOriginAddress {
    final parts = originAddress.split(',');
    return parts.isNotEmpty ? parts.first.trim() : originAddress;
  }

  String get shortDestinationAddress {
    final parts = destinationAddress.split(',');
    return parts.isNotEmpty ? parts.first.trim() : destinationAddress;
  }
}
