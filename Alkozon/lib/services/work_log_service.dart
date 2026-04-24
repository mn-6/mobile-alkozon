import 'package:dio/dio.dart';

import 'auth_service.dart';

class WorkLogEntry {
  const WorkLogEntry({
    required this.id,
    required this.clockInAt,
    this.clockOutAt,
    this.breakStartedAt,
    this.breakEndedAt,
    this.notes,
  });

  final int id;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final DateTime? breakStartedAt;
  final DateTime? breakEndedAt;
  final String? notes;

  bool get isOpenSession => clockOutAt == null;

  factory WorkLogEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.parse(value as String);
    }

    return WorkLogEntry(
      id: json['id'] as int,
      clockInAt: DateTime.parse(json['clockInAt'] as String),
      clockOutAt: parseDate(json['clockOutAt']),
      breakStartedAt: parseDate(json['breakStartedAt']),
      breakEndedAt: parseDate(json['breakEndedAt']),
      notes: json['notes'] as String?,
    );
  }
}

class WorkLogService {
  WorkLogService({AuthService? authService})
    : _authService = authService ?? AuthService();

  static const String _apiUrl = 'http://192.168.0.101:8080/api';

  final AuthService _authService;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

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

  Future<List<WorkLogEntry>> getMyLogs({
    required DateTime from,
    required DateTime to,
  }) async {
    final token = await _authService.getToken();
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
    final token = await _authService.getToken();
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
