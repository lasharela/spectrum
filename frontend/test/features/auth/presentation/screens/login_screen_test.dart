import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/auth/presentation/screens/login_screen.dart';

/// Helper to wrap a full-screen widget in MaterialApp + FTheme + ProviderScope.
///
/// Unlike the shared widget test helpers, this does NOT wrap in an extra
/// Scaffold because LoginScreen provides its own Scaffold.
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
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders Sign In button', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('renders Forgot Password link', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('renders Sign Up link', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('renders social login section', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Or continue with'), findsOneWidget);
    });
  });
}
