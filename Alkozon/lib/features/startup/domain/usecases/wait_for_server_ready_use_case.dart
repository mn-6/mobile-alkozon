import '../repositories/startup_repository.dart';

class WaitForServerReadyUseCase {
  const WaitForServerReadyUseCase(this._repository);

  final StartupRepository _repository;

  Future<void> call({Duration? timeout}) =>
      _repository.waitForServerReady(timeout: timeout);
}
