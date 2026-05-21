import 'package:alkozon/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:alkozon/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:alkozon/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepositoryImpl session', () {
    late AuthLocalDataSource local;
    late Dio apiDio;
    late Dio authDio;
    late AuthRepositoryImpl repository;

    setUp(() {
      local = AuthLocalDataSource.memory();
      apiDio = Dio(BaseOptions(baseUrl: 'http://test.api'));
      authDio = Dio(BaseOptions(baseUrl: 'http://test.api'));

      authDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/auth/refresh') {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'accessToken': 'new-access',
                    'refreshToken': 'new-refresh',
                    'firstName': 'Jan',
                    'lastName': 'Kowalski',
                  },
                ),
              );
              return;
            }
            if (options.path == '/auth/logout') {
              handler.resolve(
                Response(requestOptions: options, statusCode: 204),
              );
              return;
            }
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
              ),
            );
          },
        ),
      );

      repository = AuthRepositoryImpl(
        dio: apiDio,
        localDataSource: local,
        remoteDataSource: AuthRemoteDataSource(authDio),
      );
    });

    test('refreshSession updates stored tokens', () async {
      await local.writeTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );

      final refreshed = await repository.refreshSession();

      expect(refreshed, isTrue);
      expect(await local.readToken(), 'new-access');
      expect(await local.readRefreshToken(), 'new-refresh');
      expect(apiDio.options.headers['Authorization'], 'Bearer new-access');
    });

    test('logout revokes refresh on server and clears local session', () async {
      await local.writeTokens(
        accessToken: 'access',
        refreshToken: 'refresh-to-revoke',
      );
      apiDio.options.headers['Authorization'] = 'Bearer access';

      await repository.logout();

      expect(await local.readToken(), isNull);
      expect(await local.readRefreshToken(), isNull);
      expect(apiDio.options.headers.containsKey('Authorization'), isFalse);
    });

    test('refreshSession returns false when refresh token missing', () async {
      expect(await repository.refreshSession(), isFalse);
    });
  });
}
