import 'package:flutter/foundation.dart' show kIsWeb;
import 'location_service.dart';
import 'location_service_web.dart';

abstract class LocationServiceBase {
  Future<List<Map<String, dynamic>>> searchPlaces(String query);
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId);
  Future<Map<String, dynamic>?> getCurrentLocation();
  Future<bool> ensureLocationPermissions({bool background = false});
  Future<Map<String, dynamic>?> geocodeAddress(String address);
}

class LocationServiceFactory {
  static LocationServiceBase create({required String apiKey}) {
    if (kIsWeb) {
      return LocationServiceWebAdapter(LocationServiceWeb(apiKey: apiKey));
    } else {
      return LocationServiceAdapter(LocationService(apiKey: apiKey));
    }
  }
}

// Adapter for LocationService
class LocationServiceAdapter implements LocationServiceBase {
  final LocationService _service;
  
  LocationServiceAdapter(this._service);
  
  @override
  Future<List<Map<String, dynamic>>> searchPlaces(String query) => _service.searchPlaces(query);
  
  @override
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) => _service.getPlaceDetails(placeId);
  
  @override
  Future<Map<String, dynamic>?> getCurrentLocation() => _service.getCurrentLocation();
  
  @override
  Future<bool> ensureLocationPermissions({bool background = false}) => _service.ensureLocationPermissions(background: background);
  
  @override
  Future<Map<String, dynamic>?> geocodeAddress(String address) => _service.geocodeAddress(address);
}

// Adapter for LocationServiceWeb
class LocationServiceWebAdapter implements LocationServiceBase {
  final LocationServiceWeb _service;
  
  LocationServiceWebAdapter(this._service);
  
  @override
  Future<List<Map<String, dynamic>>> searchPlaces(String query) => _service.searchPlaces(query);
  
  @override
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) => _service.getPlaceDetails(placeId);
  
  @override
  Future<Map<String, dynamic>?> getCurrentLocation() => _service.getCurrentLocation();
  
  @override
  Future<bool> ensureLocationPermissions({bool background = false}) => _service.ensureLocationPermissions(background: background);
  
  @override
  Future<Map<String, dynamic>?> geocodeAddress(String address) => _service.geocodeAddress(address);
}