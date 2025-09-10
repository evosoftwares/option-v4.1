import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<Map<String, dynamic>> call({
    required String email,
    required String password,
  }) async {
    return await _authRepository.signIn(
      email: email,
      password: password,
    );
  }
}