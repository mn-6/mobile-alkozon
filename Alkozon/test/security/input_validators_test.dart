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

    test('verificationCodeError accepts 4 to 8 digits', () {
      expect(InputValidators.verificationCodeError('1234'), isNull);
      expect(InputValidators.verificationCodeError('12345678'), isNull);
      expect(InputValidators.verificationCodeError('123'), isNotNull);
      expect(InputValidators.verificationCodeError('123456789'), isNotNull);
    });

    test('emailError trims whitespace before validation', () {
      expect(InputValidators.emailError('  user@example.com  '), isNull);
    });
  });
}
