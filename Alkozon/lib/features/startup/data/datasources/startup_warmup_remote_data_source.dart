import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../device_security/data/datasources/app_check_remote_data_source.dart';

class StartupWarmupRemoteDataSource {
  StartupWarmupRemoteDataSource()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.isLocal
              ? const Duration(seconds: 8)
              : const Duration(seconds: 30),
          receiveTimeout: ApiConfig.isLocal
              ? const Duration(seconds: 8)
              : const Duration(seconds: 30),
        ),
      ),
      _appCheckDataSource = AppCheckRemoteDataSource();

  final Dio _dio;
  final AppCheckRemoteDataSource _appCheckDataSource;
  bool _appCheckSubmitted = false;

  Future<void> waitForServerReady({
    Duration? retryDelay,
    Duration? timeout,
  }) async {
    final effectiveRetryDelay = retryDelay ??
        (ApiConfig.isLocal
            ? const Duration(seconds: 2)
            : const Duration(seconds: 3));
    final effectiveTimeout = timeout ??
        (ApiConfig.isLocal
            ? const Duration(seconds: 60)
            : const Duration(seconds: 120));
    final deadline = DateTime.now().add(effectiveTimeout);

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

      await Future<void>.delayed(effectiveRetryDelay);
    }

    final hint = ApiConfig.isLocal
        ? 'Uruchom API na porcie 8080 i podłącz telefon USB: adb reverse tcp:8080 tcp:8080'
        : 'Serwer produkcyjny (Render) mógł się usypiać — poczekaj chwilę i spróbuj ponownie. '
            'Sprawdź też połączenie z internetem.';

    throw StateError(
      'Backend nie odpowiada pod ${ApiConfig.baseUrl}.\n$hint',
    );
  }

  Future<void> _submitAppCheckOnce() async {
    if (_appCheckSubmitted) {
      return;
    }
    _appCheckSubmitted = true;
      await _appCheckDataSource.submitAppCheck();
  }
}
