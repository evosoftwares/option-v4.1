abstract class AuthRepository {
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String userType = 'passenger',
  });

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPassword(String email);

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  });

  String? getCurrentUserId();
  
  bool isAuthenticated();
  
  Future<bool> hasRole(String requiredRole);
}