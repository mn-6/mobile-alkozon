import 'package:alkozon/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForgotPassword', () {
    testWidgets('renders reset form labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPassword()),
      );

      expect(find.text('Resetowanie hasła'), findsOneWidget);
      expect(find.text('Zresetuj hasło'), findsOneWidget);
      expect(find.byIcon(Icons.lock_reset), findsOneWidget);
    });

    testWidgets('shows snackbar after submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPassword()),
      );

      await tester.tap(find.text('Zresetuj hasło'));
      await tester.pumpAndSettle();

      expect(
        find.text('Instrukcje zostały wysłane!'),
        findsOneWidget,
      );
    });

    testWidgets('pops route on back button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPassword(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });
  });
}
