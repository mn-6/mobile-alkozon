import '../repositories/auth_repository.dart';

class IsAuthenticatedUseCase {
  const IsAuthenticatedUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call() => _repository.isAuthenticated();
}
