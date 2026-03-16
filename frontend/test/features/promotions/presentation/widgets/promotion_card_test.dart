import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';
import 'package:spectrum_app/features/promotions/presentation/widgets/promotion_card.dart';
import 'package:spectrum_app/shared/domain/author.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  final defaultAuthor = Author(
    id: 'author-1',
    name: 'Test User',
    userType: 'supporter',
  );

  Promotion makePromotion({
    String title = 'Buy One Get One Free',
    String store = 'Therapy Supplies Co',
    String category = 'Health',
    String? discount,
    DateTime? expiresAt,
    int likesCount = 5,
    bool liked = false,
    bool saved = false,
    bool claimed = false,
  }) {
    return Promotion(
      id: 'promo-1',
      title: title,
      category: category,
      discount: discount,
      store: store,
      expiresAt: expiresAt,
      validFrom: DateTime(2025, 1, 1),
      createdById: 'user-1',
      createdBy: defaultAuthor,
      likesCount: likesCount,
      liked: liked,
      saved: saved,
      claimed: claimed,
      createdAt: DateTime(2025, 1, 1),
    );
  }

  group('PromotionCard', () {
    testWidgets('renders promotion title', (tester) async {
      final promotion = makePromotion(title: 'Amazing Deal');

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amazing Deal'), findsOneWidget);
    });

    testWidgets('renders store name', (tester) async {
      final promotion = makePromotion(store: 'Wellness Shop');

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wellness Shop'), findsOneWidget);
    });

    testWidgets('renders discount badge when discount is not null',
        (tester) async {
      final promotion = makePromotion(discount: '20% OFF');

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('20% OFF'), findsOneWidget);
    });

    testWidgets('does not render discount badge when discount is null',
        (tester) async {
      final promotion = makePromotion(discount: null);

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      // No discount text should appear; title and store are the only texts
      // besides category and like count
      expect(find.text('20% OFF'), findsNothing);
    });

    testWidgets('renders timer badge when not permanent (expiresAt is set)',
        (tester) async {
      final promotion = makePromotion(
        expiresAt: DateTime.now().add(const Duration(days: 5)),
      );

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      // Timer badge should show timeRemaining, e.g. "5d left"
      expect(find.textContaining('d left'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('does not render timer badge when permanent (expiresAt is null)',
        (tester) async {
      final promotion = makePromotion(expiresAt: null);

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer_outlined), findsNothing);
      expect(find.byIcon(Icons.timer_off_outlined), findsNothing);
    });

    testWidgets('renders category label', (tester) async {
      final promotion = makePromotion(category: 'Education');

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Education'), findsOneWidget);
    });

    testWidgets('renders like count', (tester) async {
      final promotion = makePromotion(likesCount: 42);

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders Claim button when not claimed', (tester) async {
      final promotion = makePromotion(claimed: false);

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Claim'), findsOneWidget);
      expect(find.text('Claimed'), findsNothing);
    });

    testWidgets('renders Claimed badge when claimed', (tester) async {
      final promotion = makePromotion(claimed: true);

      await tester.pumpWidget(
        buildTestWidget(PromotionCard(promotion: promotion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Claimed'), findsOneWidget);
      expect(find.text('Claim'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
