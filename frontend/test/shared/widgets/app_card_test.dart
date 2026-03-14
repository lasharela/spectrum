import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/shared/widgets/app_card.dart';

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
  group('AppCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            child: Text('Card Content'),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            title: Text('Card Title'),
            child: Text('Card Body'),
          ),
        ),
      );

      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Card Body'), findsOneWidget);
    });

    testWidgets('renders with title and subtitle', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            title: Text('Title'),
            subtitle: Text('Subtitle'),
            child: Text('Body'),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestApp(
          AppCard(
            onTap: () => tapped = true,
            child: const Text('Tappable Card'),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Card'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('wraps content in FCard', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            child: Text('Wrapped'),
          ),
        ),
      );

      expect(find.byType(FCard), findsOneWidget);
    });

    testWidgets('does not crash without onTap', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppCard(
            child: Text('No Tap'),
          ),
        ),
      );

      // Tap should not cause any errors even without onTap
      await tester.tap(find.text('No Tap'));
      await tester.pumpAndSettle();

      expect(find.text('No Tap'), findsOneWidget);
    });
  });
}
