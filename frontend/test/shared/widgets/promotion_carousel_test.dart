import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/shared/widgets/promotion_carousel.dart';
import 'package:spectrum_app/features/home/domain/dashboard.dart';

void main() {
  Widget buildTestWidget({required List<DashboardPromotion> promotions}) {
    return MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(
          body: PromotionCarousel(promotions: promotions),
        ),
      ),
    );
  }

  group('PromotionCarousel', () {
    testWidgets('renders nothing when promotions list is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(promotions: []));
      expect(find.byType(PromotionCarousel), findsOneWidget);
      // Carousel should not render
      expect(find.byType(CarouselSlider), findsNothing);
    });

    testWidgets('renders carousel with promotion items', (tester) async {
      final promotions = [
        DashboardPromotion(
          id: '1',
          title: 'Half price sessions',
          store: 'Therapy Center',
          brandLogoUrl: null,
          imageUrl: null,
          expiresAt: DateTime.now().add(const Duration(days: 2, hours: 5)),
        ),
        DashboardPromotion(
          id: '2',
          title: 'Free first visit',
          store: 'Wellness Clinic',
          brandLogoUrl: null,
          imageUrl: null,
          expiresAt: DateTime.now().add(const Duration(hours: 3)),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(promotions: promotions));
      await tester.pumpAndSettle();

      // Should show at least one promotion title
      expect(find.text('Half price sessions'), findsOneWidget);
      // Should show brand name
      expect(find.text('Therapy Center'), findsOneWidget);
    });

    testWidgets('shows "Expired" when expiresAt is in the past', (tester) async {
      final promotions = [
        DashboardPromotion(
          id: '1',
          title: 'Old promo',
          store: 'Some Store',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(promotions: promotions));
      await tester.pumpAndSettle();

      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('calls onItemSelected when card is tapped', (tester) async {
      String? tappedId;
      final promotions = [
        DashboardPromotion(
          id: 'tap-test',
          title: 'Tappable promo',
          store: 'Tap Store',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: FTheme(
            data: AppForuiTheme.light,
            child: Scaffold(
              body: PromotionCarousel(
                promotions: promotions,
                onItemSelected: (id) => tappedId = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tappable promo'));
      expect(tappedId, 'tap-test');
    });
  });
}
