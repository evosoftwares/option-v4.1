import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/user.dart';

abstract class UserRepository {
  Future<User> createUser({
    required String authUserId,
    required String email,
    required String fullName,
    String? phone,
    String? photoUrl,
    required String userType,
  });

  Future<User?> getUserById(String userId);
  
  Future<User?> getUserByAuthId(String authUserId);
  
  Future<void> updateUser({
    required String userId,
    String? fullName,
    String? phone,
    String? photoUrl,
  });
  
  Future<void> deleteUser(String userId);
}