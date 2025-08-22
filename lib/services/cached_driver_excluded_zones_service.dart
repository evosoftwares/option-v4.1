import 'dart:async';
import 'dart:collection';

import '../models/supabase/driver_excluded_zone.dart';
import 'secure_driver_excluded_zones_service.dart';

/// Cached wrapper for SecureDriverExcludedZonesService
/// Provides performance optimization through intelligent caching
class CachedDriverExcludedZonesService {
  /// Creates a cached service wrapper
  CachedDriverExcludedZonesService(this._secureService);

  final SecureDriverExcludedZonesService _secureService;

  // Cache configuration
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static const int _maxCacheSize = 100; // Max drivers to cache

  // Cache storage
  final Map<String, _CachedDriverZones> _driversCache = {};
  final Map<String, _CachedZoneCheck> _zoneChecksCache = {};

  /// Gets cached excluded zones for a driver
  Future<List<DriverExcludedZone>> getDriverExcludedZones(String driverId) async {
    final cached = _driversCache[driverId];
    
    if (cached != null && !cached.isExpired) {
      return cached.zones;
    }

    // Cache miss or expired - fetch from service
    final zones = await _secureService.getDriverExcludedZones(driverId);
    
    // Update cache
    _updateDriverCache(driverId, zones);
    
    return zones;
  }

  /// Adds excluded zone with cache invalidation
  Future<DriverExcludedZone> addExcludedZone({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    final zone = await _secureService.addExcludedZone(
      driverId: driverId,
      neighborhoodName: neighborhoodName,
      city: city,
      state: state,
    );

    // Invalidate cache for this driver
    _invalidateDriverCache(driverId);
    
    return zone;
  }

  /// Adds multiple excluded zones with cache invalidation
  Future<List<DriverExcludedZone>> addMultipleExcludedZones({
    required String driverId,
    required List<Map<String, String>> zones,
  }) async {
    final addedZones = await _secureService.addMultipleExcludedZones(
      driverId: driverId,
      zones: zones,
    );

    // Invalidate cache for this driver
    _invalidateDriverCache(driverId);
    
    return addedZones;
  }

  /// Removes excluded zone with cache invalidation
  Future<void> removeExcludedZone(String excludedZoneId) async {
    await _secureService.removeExcludedZone(excludedZoneId);

    // Invalidate all driver caches since we don't know which driver this zone belongs to
    // In a more sophisticated implementation, we could track zone-to-driver mappings
    _invalidateAllDriverCaches();
  }

  /// Removes multiple excluded zones with cache invalidation
  Future<void> removeMultipleExcludedZones(List<String> excludedZoneIds) async {
    await _secureService.removeMultipleExcludedZones(excludedZoneIds);

    // Invalidate all driver caches
    _invalidateAllDriverCaches();
  }

  /// Removes all excluded zones for a driver with cache invalidation
  Future<void> removeAllExcludedZones(String driverId) async {
    await _secureService.removeAllExcludedZones(driverId);

    // Invalidate cache for this specific driver
    _invalidateDriverCache(driverId);
  }

  /// Checks if zone is excluded with caching
  Future<bool> isZoneExcluded({
    required String driverId,
    required String neighborhoodName,
    required String city,
    required String state,
  }) async {
    final cacheKey = _createZoneCheckKey(driverId, neighborhoodName, city, state);
    final cached = _zoneChecksCache[cacheKey];
    
    if (cached != null && !cached.isExpired) {
      return cached.isExcluded;
    }

    // Cache miss or expired - check with service
    final isExcluded = await _secureService.isZoneExcluded(
      driverId: driverId,
      neighborhoodName: neighborhoodName,
      city: city,
      state: state,
    );

    // Update cache
    _updateZoneCheckCache(cacheKey, isExcluded);
    
    return isExcluded;
  }

  /// Gets excluded zones by city (no caching for this specific query)
  Future<List<DriverExcludedZone>> getExcludedZonesByCity({
    required String driverId,
    required String city,
    required String state,
  }) async {
    // This method is less frequently used, so we don't cache it
    return _secureService.getExcludedZonesByCity(
      driverId: driverId,
      city: city,
      state: state,
    );
  }

  /// Gets excluded zones count with caching
  Future<int> getExcludedZonesCount(String driverId) async {
    final cached = _driversCache[driverId];
    
    if (cached != null && !cached.isExpired) {
      return cached.zones.length;
    }

    // If not cached, fetch zones to update cache and return count
    final zones = await getDriverExcludedZones(driverId);
    return zones.length;
  }

  /// Gets driver zone statistics (no caching for dynamic stats)
  Future<Map<String, dynamic>> getDriverZoneStats(String driverId) async {
    return _secureService.getDriverZoneStats(driverId);
  }

  /// Updates driver cache with new zones
  void _updateDriverCache(String driverId, List<DriverExcludedZone> zones) {
    // Implement LRU cache - remove oldest if at capacity
    if (_driversCache.length >= _maxCacheSize && !_driversCache.containsKey(driverId)) {
      _removeOldestDriverCache();
    }

    _driversCache[driverId] = _CachedDriverZones(zones);
  }

  /// Updates zone check cache
  void _updateZoneCheckCache(String cacheKey, bool isExcluded) {
    // Simple cache size management for zone checks
    if (_zoneChecksCache.length >= _maxCacheSize * 10) {
      _cleanupZoneCheckCache();
    }

    _zoneChecksCache[cacheKey] = _CachedZoneCheck(isExcluded);
  }

  /// Invalidates cache for a specific driver
  void _invalidateDriverCache(String driverId) {
    _driversCache.remove(driverId);
    
    // Also invalidate zone checks for this driver
    _zoneChecksCache.removeWhere((key, _) => key.startsWith('$driverId|'));
  }

  /// Invalidates all driver caches
  void _invalidateAllDriverCaches() {
    _driversCache.clear();
    _zoneChecksCache.clear();
  }

  /// Removes the oldest driver cache entry
  void _removeOldestDriverCache() {
    if (_driversCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _driversCache.entries) {
      if (oldestTime == null || entry.value.cachedAt.isBefore(oldestTime)) {
        oldestTime = entry.value.cachedAt;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _driversCache.remove(oldestKey);
    }
  }

  /// Removes expired zone check cache entries
  void _cleanupZoneCheckCache() {
    _zoneChecksCache.removeWhere((_, cached) => cached.isExpired);
  }

  /// Creates a cache key for zone exclusion checks
  String _createZoneCheckKey(String driverId, String neighborhood, String city, String state) {
    // Note: We should normalize the input before creating the key
    return '$driverId|${neighborhood.toLowerCase().trim()}|${city.toLowerCase().trim()}|${state.toLowerCase().trim()}';
  }

  /// Clears all caches (useful for testing or memory management)
  void clearCache() {
    _driversCache.clear();
    _zoneChecksCache.clear();
  }

  /// Gets cache statistics for monitoring
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    var validDriverCaches = 0;
    var expiredDriverCaches = 0;
    var validZoneChecks = 0;
    var expiredZoneChecks = 0;

    for (final cached in _driversCache.values) {
      if (cached.isExpired) {
        expiredDriverCaches++;
      } else {
        validDriverCaches++;
      }
    }

    for (final cached in _zoneChecksCache.values) {
      if (cached.isExpired) {
        expiredZoneChecks++;
      } else {
        validZoneChecks++;
      }
    }

    return {
      'driver_caches': {
        'total': _driversCache.length,
        'valid': validDriverCaches,
        'expired': expiredDriverCaches,
      },
      'zone_checks': {
        'total': _zoneChecksCache.length,
        'valid': validZoneChecks,
        'expired': expiredZoneChecks,
      },
      'cache_expiration_minutes': _cacheExpiration.inMinutes,
      'max_cache_size': _maxCacheSize,
    };
  }
}

/// Cached driver zones with expiration
class _CachedDriverZones {
  _CachedDriverZones(this.zones) : cachedAt = DateTime.now();

  final List<DriverExcludedZone> zones;
  final DateTime cachedAt;

  bool get isExpired => DateTime.now().difference(cachedAt) > CachedDriverExcludedZonesService._cacheExpiration;
}

/// Cached zone check result with expiration
class _CachedZoneCheck {
  _CachedZoneCheck(this.isExcluded) : cachedAt = DateTime.now();

  final bool isExcluded;
  final DateTime cachedAt;

  bool get isExpired => DateTime.now().difference(cachedAt) > CachedDriverExcludedZonesService._cacheExpiration;
}