import 'package:dio/dio.dart';

import 'api_config.dart';

class StartupWarmupService {
  StartupWarmupService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

  final Dio _dio;

  Future<void> waitForServerReady({
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    while (true) {
      try {
        final response = await _dio.get(
          '/users/me',
          options: Options(validateStatus: (_) => true),
        );

        // Any HTTP status means backend responded (including 401/404/500).
        if (response.statusCode != null) {
          return;
        }
      } on DioException catch (error) {
        // Keep waiting only for no-response transport failures.
        if (error.response != null) {
          return;
        }
      }

      await Future<void>.delayed(retryDelay);
    }
  }
}
