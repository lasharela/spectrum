import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/auth/presentation/screens/login_screen.dart';

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

      expect(find.widgetWithText(FButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('renders Forgot Password ghost button', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('renders sign up ghost button', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(
          find.text("Don't have an account? Sign Up"), findsOneWidget);
    });
  });
}
