import 'package:supabase_flutter/supabase_flutter.dart';

class UserApiDataSource {
  final SupabaseClient supabase;

  UserApiDataSource(this.supabase);

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>?> getUserByAuthId(String authUserId) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> updateData) async {
    // Implementation would go here
    throw UnimplementedError();
  }
}