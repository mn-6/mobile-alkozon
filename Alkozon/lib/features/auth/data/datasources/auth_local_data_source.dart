import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({FlutterSecureStorage? storage, Map<String, String>? memoryStore})
    : _memory = memoryStore,
      _storage = memoryStore == null
          ? (storage ?? const FlutterSecureStorage())
          : null;

  factory AuthLocalDataSource.memory() =>
      AuthLocalDataSource(memoryStore: <String, String>{});

  static const String tokenKey = 'jwt_access_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String deviceIdKey = 'staff_device_id';
  static const String firstNameKey = 'user_first_name';
  static const String lastNameKey = 'user_last_name';

  final FlutterSecureStorage? _storage;
  final Map<String, String>? _memory;

  Future<String?> readToken() => _read(tokenKey);

  Future<String?> readRefreshToken() => _read(refreshTokenKey);

  Future<String?> readDeviceId() => _read(deviceIdKey);

  Future<String?> readFirstName() => _read(firstNameKey);

  Future<String?> readLastName() => _read(lastNameKey);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
    String? firstName,
    String? lastName,
  }) async {
    await _write(tokenKey, accessToken);
    await _write(refreshTokenKey, refreshToken);
    await _write(firstNameKey, firstName ?? '');
    await _write(lastNameKey, lastName ?? '');
  }

  Future<void> writeDeviceId(String deviceId) => _write(deviceIdKey, deviceId);

  Future<void> clearSession() async {
    await _delete(tokenKey);
    await _delete(refreshTokenKey);
    await _delete(firstNameKey);
    await _delete(lastNameKey);
  }

  FlutterSecureStorage get _secureStorage {
    final storage = _storage;
    if (storage == null) {
      throw StateError('Brak magazynu bezpiecznego (tryb testowy w pamięci).');
    }
    return storage;
  }

  Future<String?> _read(String key) {
    if (_memory != null) {
      return Future.value(_memory[key]);
    }
    return _secureStorage.read(key: key);
  }

  Future<void> _write(String key, String value) {
    if (_memory != null) {
      _memory[key] = value;
      return Future.value();
    }
    return _secureStorage.write(key: key, value: value);
  }

  Future<void> _delete(String key) {
    if (_memory != null) {
      _memory.remove(key);
      return Future.value();
    }
    return _secureStorage.delete(key: key);
  }
}
