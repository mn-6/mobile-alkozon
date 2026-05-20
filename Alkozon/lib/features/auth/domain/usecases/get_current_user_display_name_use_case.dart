import '../repositories/auth_repository.dart';

class GetCurrentUserDisplayNameUseCase {
  const GetCurrentUserDisplayNameUseCase(this._repository);

  final AuthRepository _repository;

  Future<String?> call() => _repository.getCurrentUserFullName();
}
