import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String tokenKey = 'jwt_access_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String deviceIdKey = 'staff_device_id';
  static const String firstNameKey = 'user_first_name';
  static const String lastNameKey = 'user_last_name';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: tokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<String?> readDeviceId() => _storage.read(key: deviceIdKey);

  Future<String?> readFirstName() => _storage.read(key: firstNameKey);

  Future<String?> readLastName() => _storage.read(key: lastNameKey);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
    String? firstName,
    String? lastName,
  }) async {
    await _storage.write(key: tokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
    await _storage.write(key: firstNameKey, value: firstName ?? '');
    await _storage.write(key: lastNameKey, value: lastName ?? '');
  }

  Future<void> writeDeviceId(String deviceId) =>
      _storage.write(key: deviceIdKey, value: deviceId);

  Future<void> clearSession() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: firstNameKey);
    await _storage.delete(key: lastNameKey);
  }
}
