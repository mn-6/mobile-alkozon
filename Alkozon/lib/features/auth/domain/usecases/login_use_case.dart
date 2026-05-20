import '../entities/login_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<LoginResult> call({
    required String email,
    required String password,
    String? verificationCode,
    String? challengeId,
  }) {
    return _repository.login(
      email: email,
      password: password,
      verificationCode: verificationCode,
      challengeId: challengeId,
    );
  }
}
