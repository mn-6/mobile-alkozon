import '../../domain/repositories/startup_repository.dart';
import '../datasources/startup_warmup_remote_data_source.dart';

class StartupRepositoryImpl implements StartupRepository {
  StartupRepositoryImpl(this._remoteDataSource);

  final StartupWarmupRemoteDataSource _remoteDataSource;

  @override
  Future<void> waitForServerReady({Duration? timeout}) =>
      _remoteDataSource.waitForServerReady(timeout: timeout);
}
