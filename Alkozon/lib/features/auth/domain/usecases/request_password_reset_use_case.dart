import '../entities/forgot_password_result.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final AuthRepository _repository;

  Future<ForgotPasswordResult> call({required String email}) =>
      _repository.requestPasswordReset(email: email);
}
