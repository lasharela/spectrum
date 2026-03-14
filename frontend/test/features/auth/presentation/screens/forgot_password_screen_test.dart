import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/auth/presentation/screens/forgot_password_screen.dart';

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
  group('ForgotPasswordScreen', () {
    testWidgets('renders email field and "Send Reset Instructions" button',
        (tester) async {
      await tester.pumpWidget(buildTestApp(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Send Reset Instructions'), findsOneWidget);
    });

    testWidgets('renders title "Forgot Password?" and description containing "reset link"',
        (tester) async {
      await tester.pumpWidget(buildTestApp(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(
        find.textContaining('reset link'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Back to Login" text', (tester) async {
      await tester.pumpWidget(buildTestApp(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Back to Login'), findsOneWidget);
    });
  });
}
