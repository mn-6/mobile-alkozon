import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/work_log_entry.dart';

class WorkLogRemoteDataSource {
  WorkLogRemoteDataSource(this._authRepository, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final AuthRepository _authRepository;
  final Dio _dio;

  Future<WorkLogEntry> clockIn({String? notes}) async {
    final response = await _authorizedPost(
      '/work-log/clock-in',
      queryParameters: notes?.trim().isNotEmpty == true
          ? {'notes': notes!.trim()}
          : null,
    );
    return WorkLogEntry.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkLogEntry> clockOut() async {
    final response = await _authorizedPost('/work-log/clock-out');
    return WorkLogEntry.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkLogEntry> startBreak() async {
    final response = await _authorizedPost('/work-log/break/start');
    return WorkLogEntry.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WorkLogEntry> endBreak() async {
    final response = await _authorizedPost('/work-log/break/end');
    return WorkLogEntry.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<WorkLogEntry>> getMyLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final token = await _authRepository.getAccessToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    final response = await _dio.get(
      '/work-log/my',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((item) => WorkLogEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WorkLogEntry?> getCurrentOpenSession() async {
    final now = DateTime.now().toUtc();
    final logs = await getMyLogs(
      from: now.subtract(const Duration(days: 365)),
      to: now.add(const Duration(days: 1)),
    );
    for (final log in logs) {
      if (log.isOpenSession) {
        return log;
      }
    }
    return null;
  }

  Future<Response<dynamic>> _authorizedPost(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await _authRepository.getAccessToken();
    if (token == null) {
      throw Exception('Brak tokenu logowania');
    }

    return _dio.post(
      path,
      queryParameters: queryParameters,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
