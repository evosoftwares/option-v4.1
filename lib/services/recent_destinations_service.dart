import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_location.dart';

class RecentDestinationsService {
  static const String _key = 'recent_destinations';
  static const int _maxRecentItems = 10;
  
  static RecentDestinationsService? _instance;
  
  static RecentDestinationsService get instance {
    _instance ??= RecentDestinationsService._internal();
    return _instance!;
  }
  
  RecentDestinationsService._internal();

  Future<List<FavoriteLocation>> getRecentDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => FavoriteLocation.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addRecentDestination(FavoriteLocation destination) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getRecentDestinations();
      
      currentList.removeWhere((item) => 
          item.placeId == destination.placeId || 
          (item.latitude == destination.latitude && 
           item.longitude == destination.longitude));
      
      currentList.insert(0, destination);
      
      if (currentList.length > _maxRecentItems) {
        currentList.removeRange(_maxRecentItems, currentList.length);
      }
      
      final jsonString = json.encode(
        currentList.map((location) => location.toJson()).toList(),
      );
      
      await prefs.setString(_key, jsonString);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> removeRecentDestination(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getRecentDestinations();
      
      currentList.removeWhere((item) => item.id == id);
      
      final jsonString = json.encode(
        currentList.map((location) => location.toJson()).toList(),
      );
      
      await prefs.setString(_key, jsonString);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> clearRecentDestinations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      // Silently fail
    }
  }
}