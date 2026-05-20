import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AttemptStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureAttemptStorage implements AttemptStorage {
  SecureAttemptStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class LoginAttemptLimiter {
  LoginAttemptLimiter({AttemptStorage? storage})
    : _storage = storage ?? SecureAttemptStorage();

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  static const String _failCountKey = 'login_fail_count';
  static const String _lockoutUntilKey = 'login_lockout_until_ms';

  final AttemptStorage _storage;

  Future<LoginAttemptStatus> checkAllowed() async {
    final lockoutUntilMs = int.tryParse(
      await _storage.read(_lockoutUntilKey) ?? '',
    );
    if (lockoutUntilMs != null) {
      final lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutUntilMs);
      if (DateTime.now().isBefore(lockoutUntil)) {
        return LoginAttemptStatus(
          allowed: false,
          remainingLockout: lockoutUntil.difference(DateTime.now()),
        );
      }
      await _clearLockout();
    }

    final failCount =
        int.tryParse(await _storage.read(_failCountKey) ?? '') ?? 0;
    if (failCount >= maxAttempts) {
      await _startLockout();
      return LoginAttemptStatus(
        allowed: false,
        remainingLockout: lockoutDuration,
      );
    }

    return const LoginAttemptStatus(allowed: true);
  }

  Future<void> recordFailure() async {
    final status = await checkAllowed();
    if (!status.allowed) {
      return;
    }

    final failCount =
        int.tryParse(await _storage.read(_failCountKey) ?? '') ?? 0;
    final next = failCount + 1;
    await _storage.write(_failCountKey, next.toString());

    if (next >= maxAttempts) {
      await _startLockout();
    }
  }

  Future<void> recordSuccess() async {
    await _storage.delete(_failCountKey);
    await _storage.delete(_lockoutUntilKey);
  }

  Future<void> _startLockout() async {
    final until = DateTime.now().add(lockoutDuration);
    await _storage.write(
      _lockoutUntilKey,
      until.millisecondsSinceEpoch.toString(),
    );
    await _storage.write(_failCountKey, '0');
  }

  Future<void> _clearLockout() async {
    await _storage.delete(_lockoutUntilKey);
    await _storage.delete(_failCountKey);
  }
}

class LoginAttemptStatus {
  const LoginAttemptStatus({
    required this.allowed,
    this.remainingLockout,
  });

  final bool allowed;
  final Duration? remainingLockout;

  String? get lockoutMessage {
    if (allowed || remainingLockout == null) {
      return null;
    }
    final minutes = remainingLockout!.inMinutes;
    final seconds = remainingLockout!.inSeconds % 60;
    if (minutes > 0) {
      return 'Zbyt wiele nieudanych prób logowania. Spróbuj ponownie za $minutes min.';
    }
    return 'Zbyt wiele nieudanych prób logowania. Spróbuj ponownie za $seconds s.';
  }
}
