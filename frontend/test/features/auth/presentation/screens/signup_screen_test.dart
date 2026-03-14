import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/auth/presentation/screens/signup_screen.dart';

/// Helper to wrap a full-screen widget in MaterialApp + FTheme + ProviderScope.
///
/// SignupScreen provides its own Scaffold, so no extra wrapping needed.
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
  group('SignupScreen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(buildTestApp(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('renders user type chips', (tester) async {
      await tester.pumpWidget(buildTestApp(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Person with Autism'), findsOneWidget);
      expect(find.text('Parent/Caregiver'), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
    });

    testWidgets('renders Sign Up button', (tester) async {
      await tester.pumpWidget(buildTestApp(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('renders already have an account text', (tester) async {
      await tester.pumpWidget(buildTestApp(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
