import 'package:alkozon/core/security/login_attempt_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryAttemptStorage implements AttemptStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}

void main() {
  group('LoginAttemptLimiter', () {
    test('locks out after max failed attempts', () async {
      final storage = MemoryAttemptStorage();
      final limiter = LoginAttemptLimiter(storage: storage);

      for (var i = 0; i < LoginAttemptLimiter.maxAttempts; i++) {
        await limiter.recordFailure();
      }

      final status = await limiter.checkAllowed();
      expect(status.allowed, isFalse);
      expect(status.lockoutMessage, isNotNull);
    });

    test('lockoutMessage describes remaining time in minutes', () async {
      final storage = MemoryAttemptStorage();
      final limiter = LoginAttemptLimiter(storage: storage);

      for (var i = 0; i < LoginAttemptLimiter.maxAttempts; i++) {
        await limiter.recordFailure();
      }

      final status = await limiter.checkAllowed();
      expect(status.lockoutMessage, contains('min'));
    });

    test('recordSuccess clears failures', () async {
      final storage = MemoryAttemptStorage();
      final limiter = LoginAttemptLimiter(storage: storage);

      await limiter.recordFailure();
      await limiter.recordFailure();
      await limiter.recordSuccess();

      final status = await limiter.checkAllowed();
      expect(status.allowed, isTrue);
    });
  });
}
