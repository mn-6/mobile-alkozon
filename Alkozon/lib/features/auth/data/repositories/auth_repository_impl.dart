import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../../../core/connectivity/connectivity_error.dart';
import '../../../../core/localization/user_message.dart';
import '../../domain/entities/forgot_password_result.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

typedef LogoutHook = Future<void> Function();

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required Dio dio,
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
    LogoutHook? onLogout,
  }) : _dio = dio,
       _local = localDataSource,
       _remote = remoteDataSource,
       _onLogout = onLogout;

  final Dio _dio;
  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;
  final LogoutHook? _onLogout;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
    String? verificationCode,
    String? challengeId,
  }) async {
    try {
      final deviceId = await getOrCreateDeviceId();

      if (verificationCode != null && verificationCode.trim().isNotEmpty) {
        if (challengeId == null || challengeId.isEmpty) {
          return const LoginFailure('Brak challengeId do weryfikacji 2FA');
        }

        final verifyData = await _remote.verifyDevice(
          challengeId: challengeId,
          deviceId: deviceId,
          code: verificationCode.trim(),
        );
        return _persistLogin(verifyData);
      }

      final data = await _remote.staffLogin(
        email: email,
        password: password,
        deviceId: deviceId,
      );
      final mapped = AuthResponseMapper.mapLoginResponse(data);
      if (mapped is LoginRequiresTwoFactor || mapped is LoginFailure) {
        return mapped;
      }
      if (mapped is LoginSuccess) {
        final tokenPayload =
            data['tokens'] is Map
                ? Map<String, dynamic>.from(data['tokens'] as Map)
                : data;
        return _persistLogin(tokenPayload);
      }
      return const LoginFailure('Błąd logowania');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map ? responseData['message'] : null;
      return LoginFailure(
        UserMessage.polish(message?.toString() ?? 'Błąd połączenia z serwerem'),
      );
    } catch (e) {
      return LoginFailure(UserMessage.fromError(e));
    }
  }

  @override
  Future<ForgotPasswordResult> requestPasswordReset({
    required String email,
  }) async {
    final trimmedEmail = email.trim();

    try {
      await _remote.requestPasswordReset(email: trimmedEmail);
      return const ForgotPasswordSuccess();
    } on DioException catch (error) {
      if (ConnectivityError.isConnectivityFailure(error)) {
        return ForgotPasswordFailure(
          UserMessage.fromError(error),
          cause: error,
        );
      }

      if (error.response != null) {
        return const ForgotPasswordSuccess();
      }

      return ForgotPasswordFailure(UserMessage.fromError(error), cause: error);
    } catch (error) {
      return ForgotPasswordFailure(UserMessage.fromError(error), cause: error);
    }
  }

  Future<LoginResult> _persistLogin(Map<String, dynamic> rawData) async {
    final mapped = AuthResponseMapper.mapTokenPayload(rawData);
    if (mapped is! LoginSuccess) {
      return mapped;
    }

    try {
      await _persistTokenResponse(rawData, accessToken: mapped.accessToken);
    } catch (_) {
      return const LoginFailure('Brak tokenów w odpowiedzi serwera');
    }
    return mapped;
  }

  Future<void> _persistTokenResponse(
    Map<String, dynamic> rawData, {
    String? accessToken,
  }) async {
    final resolvedAccess = accessToken ?? rawData['accessToken'] as String?;
    final refreshToken = rawData['refreshToken'] as String?;
    if (resolvedAccess == null ||
        resolvedAccess.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw StateError('Missing tokens in auth response');
    }

    await _local.writeTokens(
      accessToken: resolvedAccess,
      refreshToken: refreshToken,
      firstName: rawData['firstName'] as String?,
      lastName: rawData['lastName'] as String?,
    );
    _dio.options.headers['Authorization'] = 'Bearer $resolvedAccess';
  }

  @override
  Future<bool> refreshSession() async {
    final refreshToken = await _local.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final data = await _remote.refresh(refreshToken: refreshToken);
      await _persistTokenResponse(data);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearLocalSession();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearLocalSession() async {
    await _local.clearSession();
    _dio.options.headers.remove('Authorization');
  }

  @override
  Future<void> logout() async {
    await _onLogout?.call();

    final refreshToken = await _local.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _remote.logout(refreshToken: refreshToken);
      } catch (_) {
        // Lokalna sesja i tak jest czyszczona — sieć mogła paść.
      }
    }

    await _clearLocalSession();
  }

  @override
  Future<String?> getAccessToken() => _local.readToken();

  @override
  Future<String> getOrCreateDeviceId() async {
    final saved = await _local.readDeviceId();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }

    final random = Random();
    final generated =
        'android-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1 << 32)}';
    await _local.writeDeviceId(generated);
    return generated;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final data = await _remote.fetchCurrentUser(token);
      return AuthResponseMapper.mapProfile(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getCurrentUserFullName() async {
    final profile = await getCurrentUserProfile();
    if (profile != null) {
      return profile.displayName;
    }

    final first = (await _local.readFirstName())?.trim();
    final last = (await _local.readLastName())?.trim();
    final fromStorage = _joinNames(first, last);
    if (fromStorage != null) {
      return fromStorage;
    }

    final token = await getAccessToken();
    if (token == null) return null;

    try {
      final data = await _remote.fetchCurrentUser(token);
      final firstName = (data['firstName'] as String?)?.trim();
      final lastName = (data['lastName'] as String?)?.trim();
      await _local.writeTokens(
        accessToken: token,
        refreshToken: (await _local.readRefreshToken()) ?? '',
        firstName: firstName,
        lastName: lastName,
      );
      return _joinNames(firstName, lastName);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    final token = await getAccessToken();
    if (token == null) return null;
    final claims = decodeTokenClaims(token);
    return claims?['email'] as String?;
  }

  @override
  Map<String, dynamic>? decodeTokenClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? _joinNames(String? firstName, String? lastName) {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return null;
    return '$first $last'.trim();
  }
}
