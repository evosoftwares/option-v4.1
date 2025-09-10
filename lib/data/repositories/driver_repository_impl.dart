import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/driver_repository.dart';
import '../../data/models/driver_model.dart';

class DriverRepositoryImpl implements DriverRepository {
  final SupabaseClient supabase;

  DriverRepositoryImpl(this.supabase);

  @override
  Future<Driver?> getDriver(String driverId) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  @override
  Future<Driver?> getDriverByUserId(String userId) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  @override
  Future<List<Driver>> getAvailableDrivers({
    required double userLat,
    required double userLng,
    required double searchRadiusKm,
    required String requiredCategory,
  }) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  @override
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  @override
  Future<void> updateDriverStatus({
    required String driverId,
    required bool isOnline,
  }) async {
    // Implementation would go here
    throw UnimplementedError();
  }
}