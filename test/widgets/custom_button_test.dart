import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/widgets/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('displays correct text', (WidgetTester tester) async {
      const buttonText = 'Test Button';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: buttonText,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('is disabled when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('applies custom width when provided',
        (WidgetTester tester) async {
      const customWidth = 200.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Custom Width',
              onPressed: () {},
              width: customWidth,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(CustomButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.width, equals(customWidth));
    });

    testWidgets('applies custom height when provided',
        (WidgetTester tester) async {
      const customHeight = 60.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Custom Height',
              onPressed: () {},
              height: customHeight,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(CustomButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.height, equals(customHeight));
    });

    testWidgets('default height is 48.0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Default Height',
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(CustomButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.height, equals(48.0));
    });
  });
}
