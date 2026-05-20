import '../../domain/entities/work_log_entry.dart';
import '../../domain/repositories/work_log_repository.dart';
import '../datasources/work_log_remote_data_source.dart';

class WorkLogRepositoryImpl implements WorkLogRepository {
  WorkLogRepositoryImpl(this._remoteDataSource);

  final WorkLogRemoteDataSource _remoteDataSource;

  @override
  Future<WorkLogEntry> clockIn({String? notes}) =>
      _remoteDataSource.clockIn(notes: notes);

  @override
  Future<WorkLogEntry> clockOut() => _remoteDataSource.clockOut();

  @override
  Future<WorkLogEntry> startBreak() => _remoteDataSource.startBreak();

  @override
  Future<WorkLogEntry> endBreak() => _remoteDataSource.endBreak();

  @override
  Future<List<WorkLogEntry>> getMyLogs({
    required DateTime from,
    required DateTime to,
  }) => _remoteDataSource.getMyLogs(from: from, to: to);

  @override
  Future<WorkLogEntry?> getCurrentOpenSession() =>
      _remoteDataSource.getCurrentOpenSession();
}
