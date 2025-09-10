import 'package:supabase_flutter/supabase_flutter.dart';

class UserLocalDataSource {

  UserLocalDataSource();

  Future<void> cacheUser(Map<String, dynamic> userData) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getCachedUser(String userId) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  Future<void> clearCachedUser(String userId) async {
    // Implementation would go here
    throw UnimplementedError();
  }
}