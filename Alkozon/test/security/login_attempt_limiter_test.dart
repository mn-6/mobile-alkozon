import 'package:alkozon/core/security/login_attempt_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_attempt_storage.dart';

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

    test('lockoutMessage uses seconds when under one minute', () {
      const status = LoginAttemptStatus(
        allowed: false,
        remainingLockout: Duration(seconds: 45),
      );

      expect(status.lockoutMessage, contains('45'));
      expect(status.lockoutMessage, contains('s'));
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
