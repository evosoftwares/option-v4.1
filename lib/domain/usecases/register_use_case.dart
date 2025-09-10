import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  Future<Map<String, dynamic>> call({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String userType = 'passenger',
  }) async {
    return await _authRepository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      userType: userType,
    );
  }
}