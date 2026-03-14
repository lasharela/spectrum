import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/auth/presentation/screens/reset_password_screen.dart';

/// Helper to wrap a full-screen widget in MaterialApp + FTheme + ProviderScope.
Widget buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: child,
      ),
    ),
  );
}

void main() {
  group('ResetPasswordScreen', () {
    testWidgets('renders password fields "New Password" and "Confirm Password"',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ResetPasswordScreen(
            token: 'test-token',
            email: 'test@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('renders "Reset Password" button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ResetPasswordScreen(
            token: 'test-token',
            email: 'test@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('renders title "Reset Your Password"', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ResetPasswordScreen(
            token: 'test-token',
            email: 'test@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Your Password'), findsOneWidget);
    });
  });
}
