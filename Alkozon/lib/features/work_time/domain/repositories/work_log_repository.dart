import '../entities/work_log_entry.dart';

abstract class WorkLogRepository {
  Future<WorkLogEntry> clockIn({String? notes});
  Future<WorkLogEntry> clockOut();
  Future<WorkLogEntry> startBreak();
  Future<WorkLogEntry> endBreak();
  Future<List<WorkLogEntry>> getMyLogs({
    required DateTime from,
    required DateTime to,
  });
  Future<WorkLogEntry?> getCurrentOpenSession();
}
