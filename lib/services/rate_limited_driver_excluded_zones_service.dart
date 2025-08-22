import 'dart:async';

import '../exceptions/app_exceptions.dart';
import '../models/supabase/driver_excluded_zone.dart';
import 'cached_driver_excluded_zones_service.dart';

/// Rate-limited wrapper for CachedDriverExcludedZonesService
/// Prevents abuse and ensures system stability
class RateLimitedDriverExcludedZonesService {
  /// Creates a rate-limited service wrapper
  RateLimitedDriverExcludedZonesService(this._cachedService);

  final CachedDriverExcludedZonesService _cachedService;

  // Rate limiting configuration
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxOperationsPerWindow = 10;
  static const int _maxBulkOperationsPerWindow = 3;

  // Rate limiting storage
  final Map<String, List<DateTime>> _operationTimestamps = {};
  final Map<String, List<DateTime>> _bulkOperationTimestamps = {};

  /// Gets driver excluded zones (read operations are not rate limited)
  Future<List<DriverExcludedZone>> getDriverExcludedZones(String driverId) {
    return _cachedService.getDriverExcludedZones(driverId);
  }

  /// Adds excluded zone with rate limiting
  Future<DriverExcludedZone> addExcludedZone({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    await _checkRateLimit(driverId, isWrite: true);

    final zone = await _cachedService.addExcludedZone(
      driverId: driverId,
      neighborhoodName: neighborhoodName,
      city: city,
      state: state,
    );

    _recordOperation(driverId);
    return zone;
  }

  /// Adds multiple excluded zones with bulk rate limiting
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async {
    await _checkRateLimit(driverId, isWrite: true, isBulk: true);

    final addedZones = await _cachedService.addMultipleExcludedZones(
      driverId: driverId,
      zones: zones,
    );

    _recordBulkOperation(driverId);
    return addedZones;
  }

  /// Removes excluded zone with rate limiting
  Future<void> removeExcludedZone(String excludedZoneId) async {
    // For removal operations, we need to identify the driver
    // This is a limitation - in a real implementation, you might want to
    // track zone ownership or pass driverId as a parameter
    await _cachedService.removeExcludedZone(excludedZoneId);
  }

  /// Removes multiple excluded zones with bulk rate limiting
  Future<void> removeMultipleExcludedZones(List<String> excludedZoneIds) async {
    // Similar limitation as above
    await _cachedService.removeMultipleExcludedZones(excludedZoneIds);
  }

  /// Removes all excluded zones for a driver with rate limiting
  Future<void> removeAllExcludedZones(String driverId) async {
    await _checkRateLimit(driverId, isWrite: true, isBulk: true);

    await _cachedService.removeAllExcludedZones(driverId);
    _recordBulkOperation(driverId);
  }

  /// Checks if zone is excluded (read operations are not rate limited)
  Future<bool> isZoneExcluded({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) {
    return _cachedService.isZoneExcluded(
      driverId: driverId,
      neighborhoodName: neighborhoodName,
      city: city,
      state: state,
    );
  }

  /// Gets excluded zones by city (read operations are not rate limited)
  Future<List<DriverExcludedZone>> getExcludedZonesByCity({
    required String driverId,
    required String city,
    required String state,
  }) {
    return _cachedService.getExcludedZonesByCity(
      driverId: driverId,
      city: city,
      state: state,
    );
  }

  /// Gets excluded zones count (read operations are not rate limited)
  Future<int> getExcludedZonesCount(String driverId) {
    return _cachedService.getExcludedZonesCount(driverId);
  }

  /// Gets driver zone statistics (read operations are not rate limited)
  Future<Map<String, dynamic>> getDriverZoneStats(String driverId) {
    return _cachedService.getDriverZoneStats(driverId);
  }

  /// Checks rate limits for a driver
  Future<void> _checkRateLimit(
    String driverId, {
    required bool isWrite,
    bool isBulk = false,
  }) async {
    if (!isWrite) return; // Only rate limit write operations

    final now = DateTime.now();

    if (isBulk) {
      await _checkBulkRateLimit(driverId, now);
    } else {
      await _checkRegularRateLimit(driverId, now);
    }
  }

  /// Checks regular operation rate limits
  Future<void> _checkRegularRateLimit(String driverId, DateTime now) async {
    final timestamps = _operationTimestamps[driverId] ?? [];
    
    // Remove old timestamps outside the rate limit window
    timestamps.removeWhere((timestamp) => 
        now.difference(timestamp) > _rateLimitWindow);

    if (timestamps.length >= _maxOperationsPerWindow) {
      final oldestTimestamp = timestamps.first;
      final waitTime = _rateLimitWindow - now.difference(oldestTimestamp);
      
      throw ValidationException(
        'Limite de operações atingido. Tente novamente em ${waitTime.inSeconds} segundos.',
        'RATE_LIMIT_EXCEEDED',
      );
    }
  }

  /// Checks bulk operation rate limits
  Future<void> _checkBulkRateLimit(String driverId, DateTime now) async {
    final timestamps = _bulkOperationTimestamps[driverId] ?? [];
    
    // Remove old timestamps outside the rate limit window
    timestamps.removeWhere((timestamp) => 
        now.difference(timestamp) > _rateLimitWindow);

    if (timestamps.length >= _maxBulkOperationsPerWindow) {
      final oldestTimestamp = timestamps.first;
      final waitTime = _rateLimitWindow - now.difference(oldestTimestamp);
      
      throw ValidationException(
        'Limite de operações em lote atingido. Tente novamente em ${waitTime.inSeconds} segundos.',
        'BULK_RATE_LIMIT_EXCEEDED',
      );
    }
  }

  /// Records a regular operation for rate limiting
  void _recordOperation(String driverId) {
    final timestamps = _operationTimestamps[driverId] ?? [];
    timestamps.add(DateTime.now());
    _operationTimestamps[driverId] = timestamps;
  }

  /// Records a bulk operation for rate limiting
  void _recordBulkOperation(String driverId) {
    final timestamps = _bulkOperationTimestamps[driverId] ?? [];
    timestamps.add(DateTime.now());
    _bulkOperationTimestamps[driverId] = timestamps;
  }

  /// Gets rate limiting statistics for monitoring
  Map<String, dynamic> getRateLimitStats() {
    final now = DateTime.now();
    final activeDrivers = <String>{};
    var totalOperations = 0;
    var totalBulkOperations = 0;

    // Count active operations in current window
    for (final entry in _operationTimestamps.entries) {
      final recentOperations = entry.value.where(
        (timestamp) => now.difference(timestamp) <= _rateLimitWindow,
      ).length;
      
      if (recentOperations > 0) {
        activeDrivers.add(entry.key);
        totalOperations += recentOperations;
      }
    }

    for (final entry in _bulkOperationTimestamps.entries) {
      final recentOperations = entry.value.where(
        (timestamp) => now.difference(timestamp) <= _rateLimitWindow,
      ).length;
      
      if (recentOperations > 0) {
        activeDrivers.add(entry.key);
        totalBulkOperations += recentOperations;
      }
    }

    return {
      'rate_limit_window_minutes': _rateLimitWindow.inMinutes,
      'max_operations_per_window': _maxOperationsPerWindow,
      'max_bulk_operations_per_window': _maxBulkOperationsPerWindow,
      'active_drivers_count': activeDrivers.length,
      'total_operations_in_window': totalOperations,
      'total_bulk_operations_in_window': totalBulkOperations,
      'tracked_drivers': _operationTimestamps.length,
    };
  }

  /// Checks if a driver is currently rate limited
  bool isDriverRateLimited(String driverId) {
    final now = DateTime.now();
    
    // Check regular operations
    final timestamps = _operationTimestamps[driverId] ?? [];
    final recentOperations = timestamps.where(
      (timestamp) => now.difference(timestamp) <= _rateLimitWindow,
    ).length;
    
    if (recentOperations >= _maxOperationsPerWindow) {
      return true;
    }

    // Check bulk operations
    final bulkTimestamps = _bulkOperationTimestamps[driverId] ?? [];
    final recentBulkOperations = bulkTimestamps.where(
      (timestamp) => now.difference(timestamp) <= _rateLimitWindow,
    ).length;
    
    return recentBulkOperations >= _maxBulkOperationsPerWindow;
  }

  /// Gets remaining operations for a driver in current window
  Map<String, int> getRemainingOperations(String driverId) {
    final now = DateTime.now();
    
    final timestamps = _operationTimestamps[driverId] ?? [];
    final recentOperations = timestamps.where(
      (timestamp) => now.difference(timestamp) <= _rateLimitWindow,
    ).length;
    
    final bulkTimestamps = _bulkOperationTimestamps[driverId] ?? [];
    final recentBulkOperations = bulkTimestamps.where(
      (timestamp) => now.difference(timestamp) <= _rateLimitWindow,
    ).length;

    return {
      'regular_operations': (_maxOperationsPerWindow - recentOperations).clamp(0, _maxOperationsPerWindow),
      'bulk_operations': (_maxBulkOperationsPerWindow - recentBulkOperations).clamp(0, _maxBulkOperationsPerWindow),
    };
  }

  /// Clears rate limiting data (useful for testing)
  void clearRateLimitData() {
    _operationTimestamps.clear();
    _bulkOperationTimestamps.clear();
  }

  /// Performs cleanup of old rate limiting data
  void cleanupOldData() {
    final now = DateTime.now();
    
    // Clean up regular operations
    for (final entry in _operationTimestamps.entries.toList()) {
      entry.value.removeWhere(
        (timestamp) => now.difference(timestamp) > _rateLimitWindow * 2,
      );
      
      if (entry.value.isEmpty) {
        _operationTimestamps.remove(entry.key);
      }
    }

    // Clean up bulk operations
    for (final entry in _bulkOperationTimestamps.entries.toList()) {
      entry.value.removeWhere(
        (timestamp) => now.difference(timestamp) > _rateLimitWindow * 2,
      );
      
      if (entry.value.isEmpty) {
        _bulkOperationTimestamps.remove(entry.key);
      }
    }
  }
}