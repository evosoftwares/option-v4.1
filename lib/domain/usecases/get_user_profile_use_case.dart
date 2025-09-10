import '../repositories/user_repository.dart';

class GetUserProfileUseCase {
  final UserRepository _userRepository;

  GetUserProfileUseCase(this._userRepository);

  Future<User?> call(String userId) async {
    return await _userRepository.getUserById(userId);
  }
}