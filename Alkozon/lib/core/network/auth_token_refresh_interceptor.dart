import 'package:dio/dio.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';

/// Retries API calls after [AuthRepository.refreshSession] on HTTP 401.
class AuthTokenRefreshInterceptor extends QueuedInterceptor {
  AuthTokenRefreshInterceptor(this._authRepository);

  final AuthRepository _authRepository;

  static const _skipRefreshPaths = {
    '/auth/refresh',
    '/auth/logout',
    '/auth/staff/login',
    '/auth/staff/verify-device',
    '/auth/login',
    '/auth/register',
    '/auth/guest',
    '/security/app-check',
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.uri.path;
    final normalizedPath = path.startsWith('/api') ? path.substring(4) : path;

    if (statusCode != 401 || _shouldSkip(normalizedPath)) {
      handler.next(err);
      return;
    }

    final refreshed = await _authRepository.refreshSession();
    if (!refreshed) {
      handler.next(err);
      return;
    }

    try {
      final accessToken = await _authRepository.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        handler.next(err);
        return;
      }

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $accessToken';

      final dio = Dio(
        BaseOptions(
          baseUrl: retryOptions.baseUrl,
          connectTimeout: retryOptions.connectTimeout,
          receiveTimeout: retryOptions.receiveTimeout,
        ),
      );

      final response = await dio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (retryError) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: retryError,
        ),
      );
    }
  }

  bool _shouldSkip(String path) {
    for (final skip in _skipRefreshPaths) {
      if (path == skip || path.endsWith(skip)) {
        return true;
      }
    }
    return false;
  }
}
