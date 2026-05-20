import 'package:alkozon/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:alkozon/features/auth/domain/entities/login_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResponseMapper.mapLoginResponse', () {
    test('returns LoginRequiresTwoFactor when verification is required', () {
      final result = AuthResponseMapper.mapLoginResponse({
        'verificationRequired': true,
        'challengeId': 'ch-123',
        'expiresInSeconds': 300,
        'message': 'Wpisz kod z e-maila',
      });

      expect(result, isA<LoginRequiresTwoFactor>());
      final twoFactor = result as LoginRequiresTwoFactor;
      expect(twoFactor.challengeId, 'ch-123');
      expect(twoFactor.expiresInSeconds, 300);
      expect(twoFactor.message, 'Wpisz kod z e-maila');
    });

    test('returns LoginSuccess when tokens are nested', () {
      final result = AuthResponseMapper.mapLoginResponse({
        'tokens': {
          'accessToken': 'access-abc',
          'refreshToken': 'refresh-xyz',
        },
      });

      expect(result, isA<LoginSuccess>());
      expect((result as LoginSuccess).accessToken, 'access-abc');
    });

    test('returns LoginFailure for invalid payload', () {
      expect(AuthResponseMapper.mapLoginResponse(null), isA<LoginFailure>());
      expect(AuthResponseMapper.mapLoginResponse('text'), isA<LoginFailure>());
    });
  });

  group('AuthResponseMapper.mapTokenPayload', () {
    test('returns LoginFailure when tokens are missing', () {
      final result = AuthResponseMapper.mapTokenPayload({
        'accessToken': 'only-access',
      });

      expect(result, isA<LoginFailure>());
    });
  });

  group('AuthResponseMapper.mapProfile', () {
    test('maps user profile from JSON', () {
      final profile = AuthResponseMapper.mapProfile({
        'id': 3,
        'email': 'staff@alkozon.test',
        'role': 'STAFF',
        'firstName': 'Anna',
        'lastName': 'Nowak',
        'courier': false,
        'active': true,
      });

      expect(profile, isNotNull);
      expect(profile!.displayName, 'Anna Nowak');
      expect(profile.email, 'staff@alkozon.test');
    });
  });
}
