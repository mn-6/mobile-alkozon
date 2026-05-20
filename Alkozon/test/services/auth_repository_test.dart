import 'dart:convert';

import 'package:alkozon/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:alkozon/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:alkozon/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepositoryImpl.decodeTokenClaims', () {
    late AuthRepositoryImpl repository;

    setUp(() {
      repository = AuthRepositoryImpl(
        dio: Dio(),
        localDataSource: AuthLocalDataSource(),
        remoteDataSource: AuthRemoteDataSource(Dio()),
      );
    });

    test('returns email claim from valid JWT payload', () {
      final payload = base64Url.encode(
        utf8.encode('{"email":"staff@alkozon.test","sub":"1"}'),
      );
      final token = 'header.$payload.signature';

      final claims = repository.decodeTokenClaims(token);
      expect(claims, isNotNull);
      expect(claims!['email'], 'staff@alkozon.test');
    });

    test('returns null for malformed token', () {
      expect(repository.decodeTokenClaims('not-a-jwt'), isNull);
      expect(repository.decodeTokenClaims('a.b'), isNull);
    });
  });
}
