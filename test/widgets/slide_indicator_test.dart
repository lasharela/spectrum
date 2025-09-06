import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/widgets/slide_indicator.dart';
import 'package:spectrum/utils/app_colors.dart';

void main() {
  group('SlideIndicator', () {
    testWidgets('displays correct number of dots', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 0,
              totalSlides: 3,
            ),
          ),
        ),
      );

      // Should have 3 AnimatedContainer widgets (dots)
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('highlights current slide indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 1,
              totalSlides: 3,
            ),
          ),
        ),
      );

      final containers = tester
          .widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          )
          .toList();

      // First dot should be inactive (width 8)
      expect(containers[0].constraints?.maxWidth, equals(8));

      // Second dot should be active (width 24)
      expect(containers[1].constraints?.maxWidth, equals(24));

      // Third dot should be inactive (width 8)
      expect(containers[2].constraints?.maxWidth, equals(8));
    });

    testWidgets('uses correct colors for active and inactive dots',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 0,
              totalSlides: 3,
            ),
          ),
        ),
      );

      final containers = tester
          .widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          )
          .toList();

      // Active dot color
      final activeDecoration = containers[0].decoration as BoxDecoration;
      expect(activeDecoration.color, equals(AppColors.primary));

      // Inactive dot color
      final inactiveDecoration = containers[1].decoration as BoxDecoration;
      expect(
        inactiveDecoration.color,
        equals(AppColors.primary.withOpacity(0.3)),
      );
    });

    testWidgets('updates animation when current index changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 0,
              totalSlides: 3,
            ),
          ),
        ),
      );

      // Initially first dot is active
      var containers = tester
          .widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          )
          .toList();
      expect(containers[0].constraints?.maxWidth, equals(24));
      expect(containers[1].constraints?.maxWidth, equals(8));

      // Update to second slide
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 1,
              totalSlides: 3,
            ),
          ),
        ),
      );

      // Trigger animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      containers = tester
          .widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          )
          .toList();

      // After animation, second dot should be active
      await tester.pumpAndSettle();
      containers = tester
          .widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          )
          .toList();
      expect(containers[0].constraints?.maxWidth, equals(8));
      expect(containers[1].constraints?.maxWidth, equals(24));
    });

    testWidgets('handles different total slide counts',
        (WidgetTester tester) async {
      // Test with 5 slides
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 2,
              totalSlides: 5,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsNWidgets(5));

      // Test with 2 slides
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 0,
              totalSlides: 2,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsNWidgets(2));
    });

    testWidgets('dots have correct border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideIndicator(
              currentIndex: 0,
              totalSlides: 3,
            ),
          ),
        ),
      );

      final containers = tester
          .widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          )
          .toList();

      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, equals(BorderRadius.circular(4)));
      }
    });
  });
}
