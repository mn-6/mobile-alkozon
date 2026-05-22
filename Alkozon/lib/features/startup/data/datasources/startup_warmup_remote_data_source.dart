import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_config.dart';
import '../../../device_security/data/datasources/app_check_remote_data_source.dart';

class StartupWarmupRemoteDataSource {
  StartupWarmupRemoteDataSource()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: Duration(
            seconds: ApiConfig.isProduction ? 20 : 8,
          ),
          receiveTimeout: Duration(
            seconds: ApiConfig.isProduction ? 30 : 12,
          ),
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
            : const Duration(seconds: 4));
    final effectiveTimeout = timeout ??
        (ApiConfig.isLocal
            ? const Duration(seconds: 30)
            : const Duration(seconds: 90));
    final deadline = DateTime.now().add(effectiveTimeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final ready = await _probeBackend();
        if (ready) {
          await _submitAppCheckOnce();
          return;
        }
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        // Serwer odpowiedział (nawet 401/403) — backend żyje; logowanie może przejść dalej.
        if (status != null && status < 500) {
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

  Future<bool> _probeBackend() async {
    final products = await _dio.get(
      '/products',
      queryParameters: const {'page': 0, 'size': 1},
      options: Options(validateStatus: (_) => true),
    );
    return products.statusCode != null && products.statusCode! < 500;
  }

  Future<void> _submitAppCheckOnce() async {
    if (_appCheckSubmitted) {
      return;
    }
    _appCheckSubmitted = true;
    try {
      await _appCheckDataSource.submitAppCheck();
    } catch (error, stackTrace) {
      debugPrint('App-check pominięty (start aplikacji): $error');
      debugPrint('$stackTrace');
    }
  }
}
