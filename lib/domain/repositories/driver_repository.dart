abstract class DriverRepository {
  Future<Driver?> getDriver(String driverId);
  
  Future<Driver?> getDriverByUserId(String userId);
  
  Future<List<Driver>> getAvailableDrivers({
    required double userLat,
    required double userLng,
    required double searchRadiusKm,
    required String requiredCategory,
  });
  
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  });
  
  Future<void> updateDriverStatus({
    required String driverId,
    required bool isOnline,
  });
}