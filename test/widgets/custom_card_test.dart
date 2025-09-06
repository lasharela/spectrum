import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/widgets/custom_card.dart';

void main() {
  group('CustomCard', () {
    testWidgets('displays child widget', (WidgetTester tester) async {
      const childText = 'Card Content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text(childText),
            ),
          ),
        ),
      );

      expect(find.text(childText), findsOneWidget);
    });

    testWidgets('applies default padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(CustomCard),
              matching: find.byType(Padding),
            )
            .last,
      );

      expect(padding.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('applies custom padding when provided',
        (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(24.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              padding: customPadding,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(CustomCard),
              matching: find.byType(Padding),
            )
            .last,
      );

      expect(padding.padding, equals(customPadding));
    });

    testWidgets('applies custom margin when provided',
        (WidgetTester tester) async {
      const customMargin = EdgeInsets.all(20.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              margin: customMargin,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(
        find.descendant(
          of: find.byType(CustomCard),
          matching: find.byType(Card),
        ),
      );

      expect(card.margin, equals(customMargin));
    });

    testWidgets('applies custom background color when provided',
        (WidgetTester tester) async {
      const customColor = Colors.blue;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              backgroundColor: customColor,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(
        find.descendant(
          of: find.byType(CustomCard),
          matching: find.byType(Card),
        ),
      );

      expect(card.color, equals(customColor));
    });

    testWidgets('calls onTap when provided and tapped',
        (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              onTap: () {
                wasTapped = true;
              },
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('is not tappable when onTap is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Non-tappable Card'),
            ),
          ),
        ),
      );

      // Should not find InkWell when onTap is null
      expect(
        find.descendant(
          of: find.byType(CustomCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('wraps in InkWell when onTap is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              onTap: () {},
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(CustomCard),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    });
  });
}
