# Home Page ForUI Migration Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all custom Container/TextStyle widgets on the home page with ForUI components (FCard, FBadge, FButton, theme typography/colors), add image-left cards for places/events, and wire background color through ForUI theme for dark mode readiness.

**Architecture:** Update ForUI theme to include background color (`#F5F5F5`). Replace each home section widget one at a time, using ForUI components directly. Create one new shared widget (`ImageListCard`) for the image-left card pattern used by places and events. Add `imageUrl` field to dashboard models.

**Tech Stack:** Flutter, ForUI (`forui` package), Riverpod

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `frontend/lib/core/themes/forui_theme.dart` | Modify | Add background color to theme |
| `frontend/lib/features/home/domain/dashboard.dart` | Modify | Add `imageUrl` to `DashboardPlace` and `DashboardEvent` |
| `frontend/lib/shared/widgets/image_list_card.dart` | Create | Reusable image-left card widget using ForUI elements |
| `frontend/lib/shared/widgets/widgets.dart` | Modify | Export new `image_list_card.dart` |
| `frontend/lib/features/home/presentation/widgets/greeting_card.dart` | Modify | Replace with FCard |
| `frontend/lib/features/home/presentation/widgets/promotions_section.dart` | Modify | Replace with FCard + FBadge |
| `frontend/lib/features/home/presentation/widgets/places_section.dart` | Modify | Use ImageListCard |
| `frontend/lib/features/home/presentation/widgets/events_section.dart` | Modify | Use ImageListCard + FBadge |
| `frontend/lib/features/home/presentation/widgets/quick_actions_section.dart` | Modify | Replace with FButton |
| `frontend/lib/features/home/presentation/screens/home_screen.dart` | Modify | Use theme background color |
| `frontend/test/features/home/presentation/screens/home_screen_test.dart` | Modify | Update tests for new widget types |

---

## Task 1: Update ForUI Theme — Background Color

**Files:**
- Modify: `frontend/lib/core/themes/forui_theme.dart`

- [ ] **Step 1: Update light theme background**

```dart
// In forui_theme.dart, update the light getter:
static FThemeData get light => FThemeData(
      touch: true,
      debugLabel: 'Spectrum Light',
      colors: FColors.zincLight.copyWith(
        primary: AppColors.primary,
        primaryForeground: const Color(0xFFFFFFFF),
        background: const Color(0xFFF5F5F5),
        border: AppColors.primary,
      ),
    );
```

- [ ] **Step 2: Update HomeScreen to use theme background**

In `frontend/lib/features/home/presentation/screens/home_screen.dart`, replace:
```dart
backgroundColor: AppColors.background,
```
with:
```dart
backgroundColor: context.theme.colors.background,
```

Add `import 'package:forui/forui.dart';` if not already present.

- [ ] **Step 3: Run dart analysis**

Run: `cd frontend && dart analyze lib/core/themes/forui_theme.dart lib/features/home/presentation/screens/home_screen.dart`
Expected: No issues found

- [ ] **Step 4: Run existing tests**

Run: `cd frontend && flutter test test/features/home/`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/core/themes/forui_theme.dart frontend/lib/features/home/presentation/screens/home_screen.dart
git commit -m "refactor: wire background color through ForUI theme"
```

---

## Task 2: Add imageUrl to Dashboard Models

**Files:**
- Modify: `frontend/lib/features/home/domain/dashboard.dart`

- [ ] **Step 1: Add imageUrl to DashboardPlace**

```dart
class DashboardPlace {
  final String id;
  final String name;
  final String address;
  final String distance;
  final String? imageUrl;

  const DashboardPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    this.imageUrl,
  });

  factory DashboardPlace.fromJson(Map<String, dynamic> json) {
    return DashboardPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      distance: json['distance'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
```

- [ ] **Step 2: Add imageUrl to DashboardEvent**

```dart
class DashboardEvent {
  final String id;
  final String title;
  final String time;
  final String location;
  final String category;
  final String? imageUrl;

  const DashboardEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.location,
    required this.category,
    this.imageUrl,
  });

  factory DashboardEvent.fromJson(Map<String, dynamic> json) {
    return DashboardEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
```

- [ ] **Step 3: Add placeholder imageUrl to backend mock data**

In `backend/src/routes/dashboard.ts`, update the `places` and `upcomingEvents` arrays:

```typescript
      places: [
        { id: "pl1", name: "Sensory Garden Park", address: "123 Oak Street", distance: "0.5 miles", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Park" },
        { id: "pl2", name: "Quiet Library Zone", address: "456 Main Avenue", distance: "1.2 miles", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Library" },
        { id: "pl3", name: "Therapy Center", address: "789 Wellness Blvd", distance: "2.0 miles", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Therapy" },
      ],
      upcomingEvents: [
        { id: "e1", title: "Parent Support Group", time: "10:00 AM", location: "Community Center", category: "Support", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Support" },
        { id: "e2", title: "Art Therapy Session", time: "2:00 PM", location: "Creative Studio", category: "Therapy", imageUrl: "https://placehold.co/160x160/e2e8f0/64748b?text=Art" },
      ],
```

- [ ] **Step 4: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/domain/dashboard.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/home/domain/dashboard.dart backend/src/routes/dashboard.ts
git commit -m "feat: add imageUrl field to DashboardPlace and DashboardEvent"
```

---

## Task 3: Create ImageListCard Shared Widget

**Files:**
- Create: `frontend/lib/shared/widgets/image_list_card.dart`
- Modify: `frontend/lib/shared/widgets/widgets.dart`

- [ ] **Step 1: Create ImageListCard widget**

This is a card with a square image on the left (~80px) that fills the card height, clipped to match border radius on left corners only. Text content on the right uses ForUI typography/colors. Optional trailing widget for badges or action buttons.

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A card with a square image on the left and text content on the right.
///
/// The image fills the card height and clips to match the card's
/// left-side border radius. Used for places, events, and similar list items.
class ImageListCard extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final String title;
  final List<ImageListCardDetail> details;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ImageListCard({
    super.key,
    this.imageUrl,
    required this.fallbackIcon,
    required this.title,
    this.details = const [],
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final borderRadius = context.theme.style.borderRadius.lg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: borderRadius,
          border: Border.all(color: colors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left: square image
              SizedBox(
                width: 80,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _buildFallback(colors),
                      )
                    : _buildFallback(colors),
              ),
              // Right: text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: typography.md.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ...details.map((detail) => Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Icon(detail.icon, size: 13, color: colors.mutedForeground),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    detail.text,
                                    style: typography.sm.copyWith(color: colors.mutedForeground),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              // Optional trailing widget
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(FColors colors) {
    return Container(
      color: colors.secondary,
      child: Center(
        child: Icon(fallbackIcon, color: colors.secondaryForeground, size: 28),
      ),
    );
  }
}

/// A detail row shown below the title in an [ImageListCard].
class ImageListCardDetail {
  final IconData icon;
  final String text;

  const ImageListCardDetail({required this.icon, required this.text});
}
```

- [ ] **Step 2: Export from widgets barrel**

In `frontend/lib/shared/widgets/widgets.dart`, add:
```dart
export 'image_list_card.dart';
```

- [ ] **Step 3: Run dart analysis**

Run: `cd frontend && dart analyze lib/shared/widgets/image_list_card.dart`
Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/shared/widgets/image_list_card.dart frontend/lib/shared/widgets/widgets.dart
git commit -m "feat: add ImageListCard shared widget using ForUI elements"
```

---

## Task 4: Migrate GreetingCard to FCard

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/greeting_card.dart`

- [ ] **Step 1: Replace GreetingCard implementation**

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class GreetingCard extends StatelessWidget {
  final String userName;

  const GreetingCard({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      title: Text('Welcome back, $userName!'),
      subtitle: const Text("Here's what's happening today"),
    );
  }
}
```

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/widgets/greeting_card.dart`
Expected: No issues found

- [ ] **Step 3: Run tests**

Run: `cd frontend && flutter test test/features/home/`
Expected: All tests pass (test checks for `textContaining('Welcome back')`)

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/greeting_card.dart
git commit -m "refactor: migrate GreetingCard to FCard"
```

---

## Task 5: Migrate PromotionsSection to FCard + FBadge

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/promotions_section.dart`

- [ ] **Step 1: Replace PromotionsSection implementation**

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../domain/dashboard.dart';

class PromotionsSection extends StatelessWidget {
  final List<DashboardPromotion> promotions;

  const PromotionsSection({super.key, required this.promotions});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hottest Promotions',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        if (promotions.isEmpty)
          FCard.raw(
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
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: promotions.length,
              itemBuilder: (context, index) => _buildPromoCard(context, promotions[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildPromoCard(BuildContext context, DashboardPromotion promo) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (promo.discount != null)
              FBadge(child: Text(promo.discount!)),
            if (promo.discount != null)
              const SizedBox(height: 8),
            Text(
              promo.title,
              style: typography.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              promo.store,
              style: typography.xs.copyWith(color: colors.mutedForeground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/widgets/promotions_section.dart`
Expected: No issues found

- [ ] **Step 3: Run tests**

Run: `cd frontend && flutter test test/features/home/`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/promotions_section.dart
git commit -m "refactor: migrate PromotionsSection to FCard and FBadge"
```

---

## Task 6: Migrate PlacesSection to ImageListCard

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/places_section.dart`

- [ ] **Step 1: Replace PlacesSection implementation**

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../../shared/widgets/image_list_card.dart';
import '../../domain/dashboard.dart';

class PlacesSection extends StatelessWidget {
  final List<DashboardPlace> places;

  const PlacesSection({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Places',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        if (places.isEmpty)
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.place_outlined, size: 32, color: colors.mutedForeground),
                  const SizedBox(height: 8),
                  Text(
                    'No places listed yet',
                    style: typography.sm.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          )
        else
          ...places.map((place) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ImageListCard(
                  imageUrl: place.imageUrl,
                  fallbackIcon: Icons.place,
                  title: place.name,
                  details: [
                    ImageListCardDetail(icon: Icons.location_on, text: place.address),
                    ImageListCardDetail(icon: Icons.directions_walk, text: place.distance),
                  ],
                  trailing: Icon(Icons.directions, color: colors.primary, size: 20),
                ),
              )),
      ],
    );
  }
}
```

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/widgets/places_section.dart`
Expected: No issues found

- [ ] **Step 3: Run tests**

Run: `cd frontend && flutter test test/features/home/`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/places_section.dart
git commit -m "refactor: migrate PlacesSection to ImageListCard"
```

---

## Task 7: Migrate EventsSection to ImageListCard + FBadge

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/events_section.dart`

- [ ] **Step 1: Replace EventsSection implementation**

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../../shared/widgets/image_list_card.dart';
import '../../domain/dashboard.dart';

class EventsSection extends StatelessWidget {
  final List<DashboardEvent> events;

  const EventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.event_outlined, size: 32, color: colors.mutedForeground),
                  const SizedBox(height: 8),
                  Text(
                    'No upcoming events',
                    style: typography.sm.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          )
        else
          ...events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ImageListCard(
                  imageUrl: event.imageUrl,
                  fallbackIcon: Icons.event,
                  title: event.title,
                  details: [
                    ImageListCardDetail(icon: Icons.access_time, text: event.time),
                    ImageListCardDetail(icon: Icons.location_on, text: event.location),
                  ],
                  trailing: FBadge(child: Text(event.category)),
                ),
              )),
      ],
    );
  }
}
```

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/widgets/events_section.dart`
Expected: No issues found

- [ ] **Step 3: Run tests**

Run: `cd frontend && flutter test test/features/home/`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/events_section.dart
git commit -m "refactor: migrate EventsSection to ImageListCard and FBadge"
```

---

## Task 8: Migrate QuickActionsSection to FButton

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/quick_actions_section.dart`

- [ ] **Step 1: Replace QuickActionsSection implementation**

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => context.go('/community'),
                prefix: const Icon(Icons.support_agent),
                child: const Text('Support'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => context.go('/catalog'),
                prefix: const Icon(Icons.lightbulb_outline),
                child: const Text('Suggest'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => context.go('/promotions'),
                prefix: const Icon(Icons.language),
                child: const Text('Website'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/widgets/quick_actions_section.dart`
Expected: No issues found

- [ ] **Step 3: Run tests**

Run: `cd frontend && flutter test test/features/home/`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/quick_actions_section.dart
git commit -m "refactor: migrate QuickActionsSection to FButton"
```

---

## Task 9: Clean Up — Remove AppColors from Home Screen

**Files:**
- Modify: `frontend/lib/features/home/presentation/screens/home_screen.dart`

- [ ] **Step 1: Replace error state in home_screen.dart**

Replace the `error:` callback body with:

```dart
error: (error, _) {
  final colors = context.theme.colors;
  final typography = context.theme.typography;
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: colors.destructive),
        const SizedBox(height: 16),
        Text(
          'Failed to load dashboard',
          style: typography.sm.copyWith(color: colors.mutedForeground),
        ),
        const SizedBox(height: 16),
        FButton(
          onPress: () => ref.read(dashboardProvider.notifier).refresh(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
},
```

Remove the `AppColors` and `AppSpacing` imports if no longer used anywhere in the file (check that `SpectrumAppBar` doesn't need them — it has its own imports).

- [ ] **Step 2: Run dart analysis**

Run: `cd frontend && dart analyze lib/features/home/presentation/screens/home_screen.dart`
Expected: No issues found

- [ ] **Step 3: Run all home tests**

Run: `cd frontend && flutter test test/features/home/`
Expected: All tests pass

- [ ] **Step 4: Update home_screen_test.dart if needed**

If any widget type assertions changed (e.g., `ElevatedButton` → `FButton`), update the test matchers.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/home/
git commit -m "refactor: remove AppColors from home screen, use ForUI theme"
```

---

## Task 10: Final Verification

- [ ] **Step 1: Run full dart analysis**

Run: `cd frontend && dart analyze`
Expected: No issues found

- [ ] **Step 2: Run all tests**

Run: `cd frontend && flutter test`
Expected: All tests pass

- [ ] **Step 3: Visual check**

Run: `cd frontend && flutter run`
Verify: Background is light gray, cards are white with ForUI styling, places/events show image placeholder (or fallback icon), promotions have FBadge, quick actions are FButton.
