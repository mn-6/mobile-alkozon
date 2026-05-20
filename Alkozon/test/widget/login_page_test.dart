import 'package:alkozon/core/security/login_attempt_limiter.dart';
import 'package:alkozon/features/auth/domain/entities/login_result.dart';
import 'package:alkozon/features/auth/domain/usecases/login_use_case.dart';
import 'package:alkozon/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/memory_attempt_storage.dart';

void main() {
  late FakeAuthRepository authRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authRepository = FakeAuthRepository();
  });

  Widget buildSubject({
    required FakeAuthRepository repository,
    Future<void> Function(BuildContext context)? onLoginSuccess,
  }) {
    return MaterialApp(
      home: LoginPage(
        loginUseCase: LoginUseCase(repository),
        loginAttemptLimiter: LoginAttemptLimiter(
          storage: MemoryAttemptStorage(),
        ),
        onLoginSuccess: onLoginSuccess ?? (_) async {},
      ),
    );
  }

  Future<void> enterCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
  }

  Future<void> tapPrimaryButton(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
  }

  group('LoginPage', () {
    Future<void> pumpLogin(WidgetTester tester, Widget widget) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }

    testWidgets('shows email validation error for invalid input', (tester) async {
      await pumpLogin(tester, buildSubject(repository: authRepository));

      await enterCredentials(tester, email: 'bad', password: 'longpassword');
      await tapPrimaryButton(tester, 'Zaloguj się');
      await tester.pumpAndSettle();

      expect(find.text('Nieprawidłowy format adresu e-mail'), findsOneWidget);
    });

    testWidgets('shows password validation error when too short', (tester) async {
      await pumpLogin(tester, buildSubject(repository: authRepository));

      await enterCredentials(
        tester,
        email: 'user@example.com',
        password: 'short',
      );
      await tapPrimaryButton(tester, 'Zaloguj się');
      await tester.pumpAndSettle();

      expect(
        find.text('Hasło musi mieć co najmniej 8 znaków'),
        findsOneWidget,
      );
    });

    testWidgets('shows server error message on LoginFailure', (tester) async {
      authRepository.loginResult =
          const LoginFailure('Nieprawidłowy login lub hasło');

      await pumpLogin(tester, buildSubject(repository: authRepository));
      await enterCredentials(
        tester,
        email: 'user@example.com',
        password: 'password123',
      );
      await tapPrimaryButton(tester, 'Zaloguj się');
      await tester.pumpAndSettle();

      expect(find.text('Nieprawidłowy login lub hasło'), findsOneWidget);
    });

    testWidgets('shows 2FA field after LoginRequiresTwoFactor', (tester) async {
      authRepository.loginResult = const LoginRequiresTwoFactor(
        challengeId: 'ch-test',
        message: 'Wpisz kod z e-maila',
      );

      await pumpLogin(tester, buildSubject(repository: authRepository));
      await enterCredentials(
        tester,
        email: 'user@example.com',
        password: 'password123',
      );
      await tapPrimaryButton(tester, 'Zaloguj się');
      await tester.pumpAndSettle();

      expect(find.text('Kod 2FA'), findsOneWidget);
      expect(find.text('Zweryfikuj kod'), findsOneWidget);
      expect(find.text('Wpisz kod z e-maila'), findsWidgets);
    });

    testWidgets('invokes onLoginSuccess after LoginSuccess', (tester) async {
      authRepository.loginResult = const LoginSuccess(accessToken: 'ok-token');
      var successCalled = false;

      await pumpLogin(
        tester,
        buildSubject(
          repository: authRepository,
          onLoginSuccess: (_) async {
            successCalled = true;
          },
        ),
      );
      await enterCredentials(
        tester,
        email: 'user@example.com',
        password: 'password123',
      );
      await tapPrimaryButton(tester, 'Zaloguj się');
      await tester.pumpAndSettle();

      expect(successCalled, isTrue);
    });

    testWidgets('loads cached email from SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({
        'cached_login_email': 'cached@alkozon.test',
      });

      await pumpLogin(tester, buildSubject(repository: authRepository));

      expect(find.text('cached@alkozon.test'), findsOneWidget);
    });
  });
}
