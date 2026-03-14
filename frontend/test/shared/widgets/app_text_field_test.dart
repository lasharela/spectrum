import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/shared/widgets/app_text_field.dart';

/// Helper to wrap a widget in MaterialApp + FTheme for testing.
Widget buildTestApp(Widget child) {
  return MaterialApp(
    home: FTheme(
      data: AppForuiTheme.light,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('AppTextField', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppTextField(
            label: 'Email',
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestApp(
          AppTextField(
            label: 'Username',
            controller: controller,
          ),
        ),
      );

      // Find the underlying TextField and enter text
      await tester.enterText(find.byType(TextField), 'testuser');
      await tester.pumpAndSettle();

      expect(controller.text, 'testuser');
    });

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppTextField(
            label: 'Email',
            hint: 'Enter your email',
          ),
        ),
      );

      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('obscures text when isPassword is true', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppTextField(
            label: 'Password',
            isPassword: true,
          ),
        ),
      );

      // When isPassword is true, we use FTextField.password which sets
      // obscureText. We can verify the TextField has obscureText enabled.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('does not obscure text by default', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppTextField(
            label: 'Username',
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);
    });

    testWidgets('renders without label when label is null', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppTextField(),
        ),
      );

      // Should render the FTextField without crashing
      expect(find.byType(FTextField), findsOneWidget);
    });
  });
}
