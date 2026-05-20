import 'package:alkozon/core/security/input_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidators', () {
    test('emailError rejects invalid addresses', () {
      expect(InputValidators.emailError(''), isNotNull);
      expect(InputValidators.emailError('bad'), isNotNull);
      expect(InputValidators.emailError('user@example.com'), isNull);
    });

    test('passwordError enforces minimum length', () {
      expect(InputValidators.passwordError(''), isNotNull);
      expect(InputValidators.passwordError('short'), isNotNull);
      expect(InputValidators.passwordError('longenough'), isNull);
    });

    test('verificationCodeError accepts digit codes', () {
      expect(InputValidators.verificationCodeError(''), isNotNull);
      expect(InputValidators.verificationCodeError('abc'), isNotNull);
      expect(InputValidators.verificationCodeError('123456'), isNull);
    });
  });
}
