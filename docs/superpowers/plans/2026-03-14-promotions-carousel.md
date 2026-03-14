# Promotions Carousel Migration Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the small horizontal card list in "Hottest Promotions" with a full-width carousel slider identical in behavior to sweenk's breaking news slider, but showing promotion content (brand logo, brand name, promotion title, time remaining).

**Architecture:** Port the `carousel_slider`-based carousel from sweenk-frontend, adapting the card content for promotions. The carousel needs edge-to-edge rendering (no screen padding), so it must be extracted from the current `SliverPadding` in home screen. The data model gets new fields for brand logo, expiry time, and background image.

**Tech Stack:** Flutter, `carousel_slider ^5.1.1`, Forui theme, Riverpod

---

## Key Differences from Sweenk Carousel

| Aspect | Sweenk (source) | Spectrum (target) |
|--------|-----------------|-------------------|
| Content | News title, time ago, source thumbnails | Brand logo + brand name, promotion title, time remaining |
| Time display | `timeago` (relative past) | Countdown (time left until expiry) |
| Images | `CustomImage` widget (sweenk-specific) | `CachedNetworkImage` (already in pubspec) |
| Theme | `context.isDark`, `context.themeColors` | `context.theme.colors` (Forui) |
| Custom widgets | `CustomText`, `IconLabel`, `ThumbnailGroup` | Standard Flutter + Forui widgets |

## Layout Change

Currently the `PromotionsSection` sits inside a `SliverPadding` with 20px horizontal padding. The carousel needs peek-through edges, so `PromotionsSection` must be pulled out into its own `SliverToBoxAdapter` — the section title keeps horizontal padding, but the carousel itself renders edge-to-edge.

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `frontend/pubspec.yaml` | Add `carousel_slider` dependency |
| Modify | `frontend/lib/features/home/domain/dashboard.dart` | Add `brandLogoUrl`, `imageUrl`, `expiresAt` to `DashboardPromotion` |
| Create | `frontend/lib/shared/widgets/promotion_carousel.dart` | Reusable carousel widget (ported from sweenk) |
| Modify | `frontend/lib/features/home/presentation/widgets/promotions_section.dart` | Swap ListView for `PromotionCarousel` |
| Modify | `frontend/lib/features/home/presentation/screens/home_screen.dart` | Move promotions out of `SliverPadding` for edge-to-edge carousel |
| Create | `frontend/test/shared/widgets/promotion_carousel_test.dart` | Widget tests for carousel |

---

## Chunk 1: Dependencies & Data Model

### Task 1: Add carousel_slider dependency

**Files:**
- Modify: `frontend/pubspec.yaml`

- [ ] **Step 1: Add the dependency**

In `frontend/pubspec.yaml`, under the `# UI/UX` comment block (after `flutter_animate`), add:

```yaml
  carousel_slider: ^5.1.1
```

- [ ] **Step 2: Install**

Run: `cd frontend && flutter pub get`
Expected: "Got dependencies!" with no errors

- [ ] **Step 3: Commit**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "chore: add carousel_slider dependency"
```

---

### Task 2: Extend DashboardPromotion model

**Files:**
- Modify: `frontend/lib/features/home/domain/dashboard.dart:84-105`
- Test: `frontend/test/features/home/domain/dashboard_test.dart`

- [ ] **Step 1: Write the failing test**

Create `frontend/test/features/home/domain/dashboard_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/home/domain/dashboard.dart';

void main() {
  group('DashboardPromotion', () {
    test('fromJson parses all fields including new ones', () {
      final json = {
        'id': 'promo-1',
        'title': '20% off therapy sessions',
        'store': 'Calm Center',
        'discount': '20% OFF',
        'brandLogoUrl': 'https://example.com/logo.png',
        'imageUrl': 'https://example.com/bg.jpg',
        'expiresAt': '2026-03-20T18:00:00.000Z',
      };

      final promo = DashboardPromotion.fromJson(json);

      expect(promo.id, 'promo-1');
      expect(promo.title, '20% off therapy sessions');
      expect(promo.store, 'Calm Center');
      expect(promo.discount, '20% OFF');
      expect(promo.brandLogoUrl, 'https://example.com/logo.png');
      expect(promo.imageUrl, 'https://example.com/bg.jpg');
      expect(promo.expiresAt, DateTime.utc(2026, 3, 20, 18));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'promo-2',
        'title': 'Free consultation',
        'store': 'Wellness Hub',
      };

      final promo = DashboardPromotion.fromJson(json);

      expect(promo.discount, isNull);
      expect(promo.brandLogoUrl, isNull);
      expect(promo.imageUrl, isNull);
      expect(promo.expiresAt, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/features/home/domain/dashboard_test.dart`
Expected: FAIL — `DashboardPromotion` doesn't have `brandLogoUrl`, `imageUrl`, or `expiresAt` fields.

- [ ] **Step 3: Update the model**

In `frontend/lib/features/home/domain/dashboard.dart`, replace the `DashboardPromotion` class (lines 84-105) with:

```dart
class DashboardPromotion {
  final String id;
  final String title;
  final String store;
  final String? discount;
  final String? brandLogoUrl;
  final String? imageUrl;
  final DateTime? expiresAt;

  const DashboardPromotion({
    required this.id,
    required this.title,
    required this.store,
    this.discount,
    this.brandLogoUrl,
    this.imageUrl,
    this.expiresAt,
  });

  factory DashboardPromotion.fromJson(Map<String, dynamic> json) {
    return DashboardPromotion(
      id: json['id'] as String,
      title: json['title'] as String,
      store: json['store'] as String,
      discount: json['discount'] as String?,
      brandLogoUrl: json['brandLogoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/features/home/domain/dashboard_test.dart`
Expected: PASS

- [ ] **Step 5: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/domain/dashboard.dart`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/home/domain/dashboard.dart frontend/test/features/home/domain/dashboard_test.dart
git commit -m "feat: add brandLogoUrl, imageUrl, expiresAt to DashboardPromotion"
```

---

## Chunk 2: Carousel Widget

### Task 3: Create PromotionCarousel widget

**Files:**
- Create: `frontend/lib/shared/widgets/promotion_carousel.dart`
- Test: `frontend/test/shared/widgets/promotion_carousel_test.dart`

This widget is a direct port of sweenk's `Carousel` (`/Users/lasharela/Development/sweenk/sweenk-frontend/lib/widgets/carousel/carousel.dart`) with these adaptations:

1. Uses `DashboardPromotion` instead of `CarouselItem`
2. Card content: brand logo circle + brand name (top-left over gradient), promotion title (bottom), time remaining badge (top-right)
3. Uses `CachedNetworkImage` instead of sweenk's `CustomImage`
4. Uses Forui theme (`context.theme.colors`) instead of sweenk theme
5. Time remaining calculated from `expiresAt` instead of `timeago`

- [ ] **Step 1: Write the widget test**

Create `frontend/test/shared/widgets/promotion_carousel_test.dart`:

```dart
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/shared/widgets/promotion_carousel.dart';
import 'package:spectrum_app/features/home/domain/dashboard.dart';

void main() {
  Widget buildTestWidget({required List<DashboardPromotion> promotions}) {
    return MaterialApp(
      builder: (context, child) => FTheme(
        data: FThemes.zinc.light,
        child: child!,
      ),
      home: Scaffold(
        body: PromotionCarousel(promotions: promotions),
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
          builder: (context, child) => FTheme(
            data: FThemes.zinc.light,
            child: child!,
          ),
          home: Scaffold(
            body: PromotionCarousel(
              promotions: promotions,
              onItemSelected: (id) => tappedId = id,
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && flutter test test/shared/widgets/promotion_carousel_test.dart`
Expected: FAIL — `PromotionCarousel` doesn't exist yet.

- [ ] **Step 3: Create the carousel widget**

Create `frontend/lib/shared/widgets/promotion_carousel.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../core/constants/app_spacing.dart';
import '../../features/home/domain/dashboard.dart';

class PromotionCarousel extends StatelessWidget {
  final List<DashboardPromotion> promotions;
  final void Function(String id)? onItemSelected;

  const PromotionCarousel({
    required this.promotions,
    this.onItemSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportFraction =
            (constraints.maxWidth - (24 + 12)) / constraints.maxWidth;

        return CarouselSlider.builder(
          itemCount: promotions.length,
          itemBuilder: (context, index, realIndex) {
            return _promotionCard(index, context);
          },
          options: CarouselOptions(
            height: 200,
            viewportFraction: viewportFraction,
            enableInfiniteScroll: false,
          ),
        );
      },
    );
  }

  Widget _promotionCard(int index, BuildContext context) {
    final promo = promotions[index];
    const borderRadius = 18.0;
    final colors = context.theme.colors;

    return GestureDetector(
      onTap: () => onItemSelected?.call(promo.id),
      child: Container(
        margin: EdgeInsets.only(
          left: index == 0 ? 0 : 8,
          right: index == promotions.length - 1 ? 0 : 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: colors.secondary,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image
            if (promo.imageUrl != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: promo.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.black.withAlpha(0),
                    ],
                    stops: const [0.0, 0.2, 1.0],
                  ),
                ),
              ),
            ),

            // Time remaining badge (top-right)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(promo.expiresAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom content: brand logo + name, promotion title
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand row: logo + name
                    Row(
                      children: [
                        _buildBrandLogo(promo),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            promo.store,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Promotion title
                    Text(
                      promo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo(DashboardPromotion promo) {
    const size = 28.0;

    if (promo.brandLogoUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: promo.brandLogoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _brandLogoFallback(promo, size),
        ),
      );
    }

    return _brandLogoFallback(promo, size);
  }

  Widget _brandLogoFallback(DashboardPromotion promo, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(51),
      ),
      alignment: Alignment.center,
      child: Text(
        promo.store.isNotEmpty ? promo.store[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return '';

    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Ending soon';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/shared/widgets/promotion_carousel_test.dart`
Expected: PASS

- [ ] **Step 5: Run dart analysis**

Run: `cd frontend && dart analyze lib/shared/widgets/promotion_carousel.dart`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/shared/widgets/promotion_carousel.dart frontend/test/shared/widgets/promotion_carousel_test.dart
git commit -m "feat: add PromotionCarousel widget ported from sweenk carousel"
```

---

## Chunk 3: Integration

### Task 4: Update PromotionsSection to use the carousel

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/promotions_section.dart`

- [ ] **Step 1: Replace the widget implementation**

Replace the entire contents of `promotions_section.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../../shared/widgets/promotion_carousel.dart';
import '../../domain/dashboard.dart';

class PromotionsSection extends StatelessWidget {
  final List<DashboardPromotion> promotions;
  final void Function(String id)? onItemSelected;

  const PromotionsSection({
    super.key,
    required this.promotions,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Hottest Promotions',
            style: typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (promotions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 32, color: colors.mutedForeground),
                    const SizedBox(height: 8),
                    Text(
                      'No promotions yet',
                      style: typography.sm.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          PromotionCarousel(
            promotions: promotions,
            onItemSelected: onItemSelected,
          ),
      ],
    );
  }
}
```

Key changes:
- The section title and empty state get horizontal padding (20px) internally
- The `PromotionCarousel` renders **without padding** so it can be edge-to-edge
- Added optional `onItemSelected` callback passthrough

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/widgets/promotions_section.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/promotions_section.dart
git commit -m "feat: replace promotion cards with carousel slider"
```

---

### Task 5: Move PromotionsSection out of SliverPadding for edge-to-edge rendering

**Files:**
- Modify: `frontend/lib/features/home/presentation/screens/home_screen.dart:96-107`

The carousel needs edge-to-edge width. Currently `PromotionsSection` is inside a `SliverPadding` with 20px horizontal padding. We need to extract it into its own `SliverToBoxAdapter` before the padded sliver.

- [ ] **Step 1: Update home_screen.dart**

Replace the `SliverPadding` section (lines 96-112) with:

```dart
              // Promotions — edge-to-edge (no horizontal padding)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.screenPadding,
                    bottom: AppSpacing.sectionGap,
                  ),
                  child: PromotionsSection(promotions: dashboard.promotions),
                ),
              ),
              // Remaining sections — with horizontal padding
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ).copyWith(bottom: AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    PlacesSection(places: dashboard.places),
                    const SizedBox(height: AppSpacing.sectionGap),
                    EventsSection(events: dashboard.upcomingEvents),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const QuickActionsSection(),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
```

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/screens/home_screen.dart`
Expected: No issues found

- [ ] **Step 3: Run all existing tests**

Run: `cd frontend && flutter test`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/home/presentation/screens/home_screen.dart
git commit -m "feat: move promotions section to edge-to-edge sliver for carousel"
```

---

## Chunk 4: Visual Verification

### Task 6: Verify with the running app

- [ ] **Step 1: Run the app**

Run: `cd frontend && flutter run`

- [ ] **Step 2: Visual checks**

Verify on the home screen:
1. "Hottest Promotions" title is visible with correct padding
2. Carousel slides are 200px tall with 18px border radius
3. Peek-through is visible on both sides (~12px)
4. Swiping between cards works smoothly
5. No infinite scroll (stops at first/last card)
6. Brand logo (or fallback initial) appears bottom-left
7. Brand name appears next to logo
8. Promotion title appears below brand name
9. Time remaining badge appears top-right
10. Empty state still shows "No promotions yet" card when list is empty
11. Other sections (Places, Events, Quick Actions) still render correctly below

- [ ] **Step 3: Final commit if any visual tweaks needed**

```bash
git add -A
git commit -m "fix: visual adjustments to promotion carousel"
```
