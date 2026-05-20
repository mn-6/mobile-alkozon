import 'package:alkozon/core/security/signing_cert_verifier.dart';
import 'package:alkozon/core/security/signing_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SigningCertVerifier', () {
    test('normalizes colons and case', () {
      expect(
        SigningCertVerifier.normalizeSha256(
          'E1:B1:78:30:39:9A:95:2B:8F:F9:05:02:3D:5D:C9:8F:0A:20:2C:BB',
        ),
        'e1b17830399a952b8ff905023d5dc98f0a202cbb',
      );
    });

    test('accepts built-in debug fingerprint', () {
      const fingerprint =
          'e1b17830399a952b8ff905023d5dc98f0a202cbb18941beb06000717341ac7f6';
      expect(
        SigningCertVerifier.isAllowed(
          fingerprint,
          SigningConfig.allowedSigningCertSha256,
        ),
        isTrue,
      );
    });

    test('rejects unknown fingerprint', () {
      expect(
        SigningCertVerifier.isAllowed(
          'deadbeef',
          SigningConfig.allowedSigningCertSha256,
        ),
        isFalse,
      );
    });
  });
}
