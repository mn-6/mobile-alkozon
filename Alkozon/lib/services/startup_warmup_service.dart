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
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await _dio.get(
          '/products',
          queryParameters: const {'page': 0, 'size': 1},
          options: Options(validateStatus: (_) => true),
        );

        if (response.statusCode != null && response.statusCode! < 500) {
          return;
        }
      } on DioException catch (error) {
        if (error.response != null && error.response!.statusCode! < 500) {
          return;
        }
      }

      await Future<void>.delayed(retryDelay);
    }

    throw StateError(
      'Backend nie odpowiada pod ${ApiConfig.baseUrl}. '
      'Uruchom API (port 8080) i na telefonie USB: adb reverse tcp:8080 tcp:8080',
    );
  }
}
