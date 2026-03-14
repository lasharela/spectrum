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
  group('AppTextField enhanced', () {
    testWidgets('renders error widget when error is provided', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppTextField(
            label: 'Email',
            error: Text('Invalid email'),
          ),
        ),
      );
      // Allow Forui to update the error state and run animations to completion.
      await tester.pumpAndSettle();

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('does not render error when error is null', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppTextField(
            label: 'Email',
          ),
        ),
      );

      expect(find.text('Invalid email'), findsNothing);
    });

    testWidgets('onChanged fires when text changes', (tester) async {
      String? capturedValue;

      await tester.pumpWidget(
        buildTestApp(
          AppTextField(
            label: 'Username',
            onChanged: (value) => capturedValue = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();

      expect(capturedValue, 'hello');
    });

    testWidgets('prefixBuilder renders an icon', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppTextField(
            label: 'Search',
            prefixBuilder: (context, style, variants) =>
                const Icon(Icons.search, key: Key('prefix_icon')),
          ),
        ),
      );

      expect(find.byKey(const Key('prefix_icon')), findsOneWidget);
    });

    testWidgets('suffixBuilder renders an icon', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppTextField(
            label: 'Username',
            suffixBuilder: (context, style, variants) =>
                const Icon(Icons.person, key: Key('suffix_icon')),
          ),
        ),
      );

      expect(find.byKey(const Key('suffix_icon')), findsOneWidget);
    });

    testWidgets('suffixBuilder is not passed to password field', (tester) async {
      // Password field should only use its own built-in obscure toggle.
      // Verify that a suffixBuilder provided by caller is ignored for
      // password fields (no exception thrown, field still renders).
      await tester.pumpWidget(
        buildTestApp(
          AppTextField(
            label: 'Password',
            isPassword: true,
            suffixBuilder: (context, style, variants) =>
                const Icon(Icons.person, key: Key('custom_suffix')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The custom suffix icon should NOT be present; password field
      // manages its own suffix.
      expect(find.byKey(const Key('custom_suffix')), findsNothing);
      // The underlying TextField must still render.
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
