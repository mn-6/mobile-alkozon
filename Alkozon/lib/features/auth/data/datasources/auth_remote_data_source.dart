import 'package:dio/dio.dart';

import '../../domain/entities/login_result.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> staffLogin({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final response = await _dio.post(
      '/auth/staff/login',
      data: {'email': email, 'password': password, 'deviceId': deviceId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyDevice({
    required String challengeId,
    required String deviceId,
    required String code,
  }) async {
    final response = await _dio.post(
      '/auth/staff/verify-device',
      data: {
        'challengeId': challengeId,
        'deviceId': deviceId,
        'code': code,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final response = await _dio.get(
      '/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return Map<String, dynamic>.from(response.data as Map);
  }
}

class AuthResponseMapper {
  static LoginResult mapLoginResponse(dynamic data) {
    if (data is! Map) {
      return const LoginFailure('Nieprawidłowa odpowiedź serwera');
    }

    if (data['verificationRequired'] == true) {
      return LoginRequiresTwoFactor(
        challengeId: data['challengeId']?.toString() ?? '',
        expiresInSeconds: (data['expiresInSeconds'] as num?)?.toInt(),
        message:
            data['message'] as String? ?? 'Podaj kod weryfikacyjny z e-maila',
      );
    }

    final tokens = data['tokens'];
    final tokenPayload = tokens is Map ? tokens : data;
    return mapTokenPayload(tokenPayload);
  }

  static LoginResult mapTokenPayload(dynamic rawData) {
    if (rawData is! Map) {
      return const LoginFailure('Nieprawidłowa odpowiedź serwera');
    }

    final accessToken = rawData['accessToken'] as String?;
    final refreshToken = rawData['refreshToken'] as String?;
    if (accessToken == null || refreshToken == null) {
      return const LoginFailure('Brak tokenów w odpowiedzi serwera');
    }

    return LoginSuccess(accessToken: accessToken);
  }

  static UserProfile? mapProfile(Map<String, dynamic> json) {
    return UserProfileModel.fromJson(json).toEntity();
  }
}
