import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/user_repository.dart';
import '../../data/models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient supabase;

  UserRepositoryImpl(this.supabase);

  @override
  Future<User> createUser({
    required String authUserId,
    required String email,
    required String fullName,
    String? phone,
    String? photoUrl,
    required String userType,
  }) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  @override
  Future<User?> getUserById(String userId) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  @override
  Future<User?> getUserByAuthId(String authUserId) async {
    // Implementation would go here
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser({
    required String userId,
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    // Implementation would go here
    throw UnimplementedError();
  }
}