import 'package:alkozon/features/auth/domain/entities/login_result.dart';
import 'package:alkozon/features/auth/domain/entities/user_profile.dart';
import 'package:alkozon/features/auth/domain/usecases/get_current_user_display_name_use_case.dart';
import 'package:alkozon/features/auth/domain/usecases/is_authenticated_use_case.dart';
import 'package:alkozon/features/auth/domain/usecases/login_use_case.dart';
import 'package:alkozon/features/auth/domain/usecases/logout_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
  });

  group('LoginUseCase', () {
    test('delegates login to repository', () async {
      repository.loginResult = const LoginSuccess(accessToken: 'token-abc');

      final result = await LoginUseCase(repository)(
        email: 'staff@alkozon.test',
        password: 'password123',
      );

      expect(result, isA<LoginSuccess>());
      expect((result as LoginSuccess).accessToken, 'token-abc');
    });

    test('forwards 2FA parameters', () async {
      repository.loginResult = const LoginRequiresTwoFactor(
        challengeId: 'ch-1',
      );

      final result = await LoginUseCase(repository)(
        email: 'staff@alkozon.test',
        password: 'password123',
        verificationCode: '123456',
        challengeId: 'ch-1',
      );

      expect(result, isA<LoginRequiresTwoFactor>());
    });
  });

  group('IsAuthenticatedUseCase', () {
    test('returns repository value', () async {
      repository.isAuthenticatedValue = true;
      expect(await IsAuthenticatedUseCase(repository)(), isTrue);

      repository.isAuthenticatedValue = false;
      expect(await IsAuthenticatedUseCase(repository)(), isFalse);
    });
  });

  group('LogoutUseCase', () {
    test('calls repository logout', () async {
      repository.isAuthenticatedValue = true;
      repository.accessToken = 'token';

      await LogoutUseCase(repository)();

      expect(repository.isAuthenticatedValue, isFalse);
      expect(repository.accessToken, isNull);
    });
  });

  group('GetCurrentUserDisplayNameUseCase', () {
    test('returns display name from profile', () async {
      repository.profile = const UserProfile(
        id: 1,
        email: 'jan@alkozon.test',
        role: 'STAFF',
        firstName: 'Jan',
        lastName: 'Kowalski',
        courier: false,
        active: true,
      );

      final name = await GetCurrentUserDisplayNameUseCase(repository)();
      expect(name, 'Jan Kowalski');
    });
  });
}
