import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum/screens/welcome_screen.dart';
import 'package:spectrum/widgets/slide_indicator.dart';
import 'package:spectrum/widgets/custom_button.dart';

void main() {
  group('WelcomeScreen', () {
    testWidgets('displays welcome screen with all components',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
          },
        ),
      );

      // Check for Skip button
      expect(find.text('Skip'), findsOneWidget);

      // Check for first slide content
      expect(find.text('Welcome to Spectrum'), findsOneWidget);
      expect(
        find.textContaining('A supportive community platform'),
        findsOneWidget,
      );

      // Check for slide indicator
      expect(find.byType(SlideIndicator), findsOneWidget);

      // Check for Next button
      expect(find.text('Next'), findsOneWidget);
      expect(find.byType(CustomButton), findsOneWidget);
    });

    testWidgets('navigates through slides on Next button tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
          },
        ),
      );

      // Initially on first slide
      expect(find.text('Welcome to Spectrum'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next to go to second slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Check second slide content
      expect(find.text('Connect & Share'), findsOneWidget);
      expect(find.textContaining('Join a caring community'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next to go to third slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Check third slide content
      expect(find.text('Resources & Support'), findsOneWidget);
      expect(find.textContaining('Access valuable resources'), findsOneWidget);

      // Button should now say "Get Started"
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('can swipe between slides', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
          },
        ),
      );

      // Initially on first slide
      expect(find.text('Welcome to Spectrum'), findsOneWidget);

      // Swipe left to go to second slide
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Connect & Share'), findsOneWidget);

      // Swipe left to go to third slide
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Resources & Support'), findsOneWidget);
    });

    testWidgets('Skip button navigates to home', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Screen')),
          },
        ),
      );

      // Tap Skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should navigate to home
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('Get Started button navigates to home',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Screen')),
          },
        ),
      );

      // Navigate to last slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap Get Started button
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should navigate to home
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('slide indicator updates correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const WelcomeScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
          },
        ),
      );

      final slideIndicator = tester.widget<SlideIndicator>(
        find.byType(SlideIndicator),
      );

      // Initially on first slide
      expect(slideIndicator.currentIndex, equals(0));
      expect(slideIndicator.totalSlides, equals(3));

      // Go to second slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final slideIndicator2 = tester.widget<SlideIndicator>(
        find.byType(SlideIndicator),
      );
      expect(slideIndicator2.currentIndex, equals(1));

      // Go to third slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final slideIndicator3 = tester.widget<SlideIndicator>(
        find.byType(SlideIndicator),
      );
      expect(slideIndicator3.currentIndex, equals(2));
    });

    testWidgets('displays correct icons for each slide',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // First slide should have diversity icon
      expect(find.byIcon(Icons.diversity_3), findsOneWidget);

      // Go to second slide
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);

      // Go to third slide
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.support_rounded), findsOneWidget);
    });
  });
}
