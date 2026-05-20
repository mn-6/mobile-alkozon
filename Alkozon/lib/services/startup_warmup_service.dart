import 'package:dio/dio.dart';

import 'api_config.dart';
import 'app_check_service.dart';

class StartupWarmupService {
  StartupWarmupService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      ),
      _appCheckService = AppCheckService();

  final Dio _dio;
  final AppCheckService _appCheckService;
  bool _appCheckSubmitted = false;

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
          await _submitAppCheckOnce();
          return;
        }
      } on DioException catch (error) {
        if (error.response != null && error.response!.statusCode! < 500) {
          await _submitAppCheckOnce();
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

  Future<void> _submitAppCheckOnce() async {
    if (_appCheckSubmitted) {
      return;
    }
    _appCheckSubmitted = true;
    await _appCheckService.submitAppCheck();
  }
}
