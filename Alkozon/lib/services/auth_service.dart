import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

class AuthService {
  static const String _apiUrl = ApiConfig.baseUrl;
  static const String _tokenKey = "jwt_access_token";
  static const String _refreshTokenKey = "jwt_refresh_token";
  static const String _deviceIdKey = "staff_device_id";
  static const String _firstNameKey = "user_first_name";
  static const String _lastNameKey = "user_last_name";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Logowanie pracownika: krok 1 (/auth/staff/login), krok 2 (/auth/staff/verify-device)
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    String? verificationCode,
    String? challengeId,
  }) async {
    try {
      final deviceId = await _getOrCreateDeviceId();

      if (verificationCode != null && verificationCode.trim().isNotEmpty) {
        if (challengeId == null || challengeId.isEmpty) {
          return {
            'success': false,
            'error': 'Brak challengeId do weryfikacji 2FA',
          };
        }

        final verifyResponse = await _dio.post(
          '/auth/staff/verify-device',
          data: {
            'challengeId': challengeId,
            'deviceId': deviceId,
            'code': verificationCode.trim(),
          },
        );

        if (verifyResponse.statusCode == 200) {
          return await _saveTokensFromResponse(verifyResponse.data);
        }

        return {'success': false, 'error': 'Błąd weryfikacji kodu 2FA'};
      }

      final response = await _dio.post(
        '/auth/staff/login',
        data: {'email': email, 'password': password, 'deviceId': deviceId},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        final requiresVerification =
            data is Map && data['verificationRequired'] == true;
        if (requiresVerification) {
          return {
            'success': false,
            'requires2fa': true,
            'challengeId': data['challengeId'],
            'expiresInSeconds': data['expiresInSeconds'],
            'message': data['message'] ?? 'Podaj kod weryfikacyjny z e-maila',
          };
        }

        if (data is Map && data['tokens'] is Map) {
          return await _saveTokensFromResponse(data['tokens']);
        }

        return await _saveTokensFromResponse(data);
      } else {
        return {'success': false, 'error': 'Błąd logowania'};
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map ? data['message'] : null;
      // Logowanie szczegółów błędu
      print('=== DIO ERROR ===');
      print('Type: ${e.type}');
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
      print('Message: ${e.message}');
      print('Error: ${e.error}');
      print('=================');
      return {
        'success': false,
        'error': message ?? 'Błąd połączenia z serwerem',
      };
    } catch (e) {
      print('=== UNEXPECTED ERROR: $e ===');
      return {'success': false, 'error': 'Nieoczekiwany błąd: $e'};
    }
  }

  Future<Map<String, dynamic>> _saveTokensFromResponse(dynamic rawData) async {
    if (rawData is! Map) {
      return {'success': false, 'error': 'Nieprawidłowa odpowiedź serwera'};
    }

    final accessToken = rawData['accessToken'] as String?;
    final refreshToken = rawData['refreshToken'] as String?;
    final firstName = rawData['firstName'] as String?;
    final lastName = rawData['lastName'] as String?;

    if (accessToken == null || refreshToken == null) {
      return {'success': false, 'error': 'Brak tokenów w odpowiedzi serwera'};
    }

    // Zapisz tokeny w bezpiecznym magazynie
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(key: _firstNameKey, value: firstName ?? '');
    await _secureStorage.write(key: _lastNameKey, value: lastName ?? '');

    // Ustaw token w domyślnym nagłówku dla kolejnych requestów
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';

    return {'success': true, 'accessToken': accessToken};
  }

  Future<String> _getOrCreateDeviceId() async {
    final saved = await _secureStorage.read(key: _deviceIdKey);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }

    final random = Random();
    final generated =
        'android-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(1 << 32)}';
    await _secureStorage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  Future<String> getDeviceId() async {
    return _getOrCreateDeviceId();
  }

  // Pobierz zapisany token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Wyloguj
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _firstNameKey);
    await _secureStorage.delete(key: _lastNameKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<String?> getCurrentUserFullName() async {
    final profile = await getCurrentUserProfile();
    if (profile != null) {
      return profile.displayName;
    }

    final storedFirst = (await _secureStorage.read(key: _firstNameKey))?.trim();
    final storedLast = (await _secureStorage.read(key: _lastNameKey))?.trim();
    final fullFromStorage = _joinNames(storedFirst, storedLast);
    if (fullFromStorage != null) {
      return fullFromStorage;
    }

    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (data is Map) {
        final first = (data['firstName'] as String?)?.trim();
        final last = (data['lastName'] as String?)?.trim();
        await _secureStorage.write(key: _firstNameKey, value: first ?? '');
        await _secureStorage.write(key: _lastNameKey, value: last ?? '');
        return _joinNames(first, last);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<CurrentUserProfile?> getCurrentUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return CurrentUserProfile.fromJson(data);
      }
      if (data is Map) {
        return CurrentUserProfile.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String? _joinNames(String? firstName, String? lastName) {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return null;
    return '$first $last'.trim();
  }

  // Sprawdź czy token istnieje
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Zdekoduj payload JWT i zwróć claims (bez weryfikacji podpisu)
  Map<String, dynamic>? decodeTokenClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // base64url → base64 standardowe (padding)
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

  // Pobierz email zalogowanego użytkownika z tokenu JWT
  Future<String?> getCurrentUserEmail() async {
    final token = await getToken();
    if (token == null) return null;
    final claims = decodeTokenClaims(token);
    return claims?['email'] as String?;
  }
}

class CurrentUserProfile {
  const CurrentUserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.courier,
    required this.active,
  });

  final int id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final bool courier;
  final bool active;

  factory CurrentUserProfile.fromJson(Map<String, dynamic> json) {
    return CurrentUserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      courier: json['courier'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
    );
  }

  String get displayName {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    final combined = '$first $last'.trim();
    return combined.isEmpty ? email : combined;
  }
}
