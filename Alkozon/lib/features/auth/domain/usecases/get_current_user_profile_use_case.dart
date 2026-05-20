import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserProfileUseCase {
  const GetCurrentUserProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserProfile?> call() => _repository.getCurrentUserProfile();
}
