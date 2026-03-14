import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/shared/widgets/app_button.dart';

/// Helper to wrap a widget in MaterialApp + FTheme for testing.
Widget buildTestApp(Widget child) {
  return MaterialApp(
    home: FTheme(
      data: AppForuiTheme.light,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AppButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppButton(
            label: 'Sign In',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildTestApp(
          AppButton(
            label: 'Tap Me',
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      );

      // The button should still render the label
      expect(find.text('Disabled'), findsOneWidget);

      // The underlying FButton should have a null onPress
      final fButton = tester.widget<FButton>(find.byType(FButton));
      expect(fButton.onPress, isNull);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppButton(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );
      await tester.pump();

      // Should show a CircularProgressIndicator
      expect(find.byType(FCircularProgress), findsOneWidget);
      // The label should be hidden when loading
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('renders with secondary variant', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppButton(
            label: 'Secondary',
            onPressed: () {},
            variant: AppButtonVariant.secondary,
          ),
        ),
      );

      expect(find.text('Secondary'), findsOneWidget);

      final fButton = tester.widget<FButton>(find.byType(FButton));
      expect(fButton.variant, FButtonVariant.secondary);
    });

    testWidgets('renders with outline variant', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppButton(
            label: 'Outline',
            onPressed: () {},
            variant: AppButtonVariant.outline,
          ),
        ),
      );

      expect(find.text('Outline'), findsOneWidget);

      final fButton = tester.widget<FButton>(find.byType(FButton));
      expect(fButton.variant, FButtonVariant.outline);
    });

    testWidgets('renders with ghost variant', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppButton(
            label: 'Ghost',
            onPressed: () {},
            variant: AppButtonVariant.ghost,
          ),
        ),
      );

      expect(find.text('Ghost'), findsOneWidget);

      final fButton = tester.widget<FButton>(find.byType(FButton));
      expect(fButton.variant, FButtonVariant.ghost);
    });

    testWidgets('disables button when isLoading is true', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          AppButton(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      final fButton = tester.widget<FButton>(find.byType(FButton));
      expect(fButton.onPress, isNull);
    });
  });
}
