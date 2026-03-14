# UI Refresh Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the entire frontend UI to match the original `ana/backup` branch design — colors, spacing, components, community page, home page, and navigation.

**Architecture:** Update the design system (colors, spacing), then rebuild shared components (app bar, cards), then update each screen to match the original. Add backend mock data for home page sections.

**Tech Stack:** Flutter/Dart, Hono/TypeScript (backend mock data)

---

## Chunk 1: Design System Foundation

### Task 1: Update Color Palette

**Files:**
- Modify: `frontend/lib/core/constants/app_colors.dart`

- [ ] **Step 1: Update AppColors to match ana/backup palette**

Replace the entire color palette to match the original design:

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF262CD9); // Blue
  static const Color secondary = Color(0xFFC8A9F2); // Light Purple
  static const Color tertiary = Color(0xFF6FC2FF); // Light Blue
  static const Color quaternary = Color(0xFF1E9A64); // Green

  // Accent colors
  static const Color accent1 = Color(0xFFD8032C); // Red
  static const Color accent2 = Color(0xFFF2A100); // Amber/Orange
  static const Color darkGray = Color(0xFF383838); // Dark Gray

  // Backgrounds
  static const Color background = Color(0xFFF4EFEA); // Warm cream
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFFFF3E0); // Light cream

  // Status
  static const Color error = Color(0xFFD8032C);
  static const Color success = Color(0xFF1E9A64);
  static const Color warning = Color(0xFFF2A100);
  static const Color info = Color(0xFF6FC2FF);

  // Text
  static const Color textPrimary = Color(0xFF383838);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textDisabled = Color(0xFFBDC3C7);
  static const Color textOnPrimary = Colors.white;

  // UI elements
  static const Color divider = Color(0xFFE8EAED);
  static const Color disabled = Color(0xFFE8EAED);
  static const Color overlay = Color(0x1F6FC2FF);

  // Card styling
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE8EAED);
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  static BoxBorder cardBorderStyle = Border.all(
    color: cardBorder,
    width: 1,
  );
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd frontend && flutter analyze lib/core/constants/app_colors.dart`

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/core/constants/app_colors.dart
git commit -m "refactor: update color palette to match original design"
```

### Task 2: Add Spacing Constants

**Files:**
- Create: `frontend/lib/core/constants/app_spacing.dart`

- [ ] **Step 1: Create spacing constants file**

```dart
class AppSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard screen padding used on all screens
  static const double screenPadding = 20;

  /// Standard section gap between major content sections
  static const double sectionGap = 25;

  /// Standard card content padding
  static const double cardPadding = 16;

  /// Standard border radius for cards
  static const double cardRadius = 16;

  /// Large border radius for cards/containers
  static const double cardRadiusLarge = 20;

  /// Standard border radius for badges/chips
  static const double badgeRadius = 12;
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/core/constants/app_spacing.dart
git commit -m "feat: add AppSpacing constants for consistent layout"
```

### Task 3: Update Forui Theme

**Files:**
- Modify: `frontend/lib/core/themes/forui_theme.dart`

- [ ] **Step 1: Update theme colors to match new palette**

Update the light theme to use the new `AppColors` values:
- `background` → `AppColors.background`
- `foreground` → `AppColors.textPrimary`
- `primary` → `AppColors.primary`
- `secondary` → `AppColors.secondary`
- `muted` → `Color(0xFFE8EAED)`
- `mutedForeground` → `AppColors.textSecondary`
- `destructive` → `AppColors.error`
- `error` → `AppColors.error`
- `card` → `AppColors.cardBackground`
- `border` → `AppColors.divider`

- [ ] **Step 2: Verify compile**

Run: `cd frontend && flutter analyze lib/core/themes/`

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/core/themes/forui_theme.dart
git commit -m "refactor: update Forui theme to use original color palette"
```

### Task 4: Update main.dart background

**Files:**
- Modify: `frontend/lib/main.dart`

- [ ] **Step 1: Ensure scaffold background uses AppColors.background**

The Material theme should set `scaffoldBackgroundColor` to `AppColors.background`.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/main.dart
git commit -m "refactor: set scaffold background to warm cream"
```

## Chunk 2: Shared Components

### Task 5: Reusable App Bar

**Files:**
- Create: `frontend/lib/shared/widgets/spectrum_app_bar.dart`
- Modify: `frontend/lib/shared/widgets/widgets.dart` (add export)

- [ ] **Step 1: Create SpectrumAppBar widget**

A reusable app bar matching the original design:
- Bell icon (leading) — no red dot, proper 16px padding from edge
- Title (center, bold)
- Settings gear (trailing), proper 16px padding from edge
- Background: transparent/surface, elevation: 0

```dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class SpectrumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final List<Widget>? extraActions;

  const SpectrumAppBar({
    super.key,
    required this.title,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          color: AppColors.textPrimary,
          onPressed: onNotificationsTap ?? () {},
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        ...?extraActions,
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            color: AppColors.textPrimary,
            onPressed: onSettingsTap ?? () {},
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Export from widgets barrel file**

Add `export 'spectrum_app_bar.dart';` to `widgets.dart`.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/shared/widgets/spectrum_app_bar.dart frontend/lib/shared/widgets/widgets.dart
git commit -m "feat: add reusable SpectrumAppBar widget"
```

### Task 6: Fix Bottom Navigation

**Files:**
- Modify: `frontend/lib/shared/widgets/main_navigation_shell.dart`

- [ ] **Step 1: Update colors and styling**

Change all `AppColors.cyan` references to `AppColors.primary` and `AppColors.textGray` to `AppColors.textSecondary`. The selected tab should use `AppColors.primary` (dark blue).

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/shared/widgets/main_navigation_shell.dart
git commit -m "refactor: update bottom nav to use new color palette"
```

## Chunk 3: Home Screen Rebuild

### Task 7: Rebuild Greeting Card

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/greeting_card.dart`

- [ ] **Step 1: Match original design**

White card with border + subtle shadow, 20px padding, 20px border radius. Contains:
- "Welcome back, {name}!" (24px, bold, textPrimary)
- Subtitle text (16px, textSecondary)
- Remove the user type badge (not in original)

Use `AppColors.cardBorderStyle`, `AppColors.cardShadow`, `AppSpacing` constants.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/greeting_card.dart
git commit -m "refactor: rebuild greeting card to match original design"
```

### Task 8: Rebuild Quick Actions Section

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/quick_actions_section.dart`

- [ ] **Step 1: Change from 4-column grid to 3-column row**

Match original: 3 equal-width cards in a Row, each with icon + label. White card with border + shadow, 16px padding, 16px border radius.

Cards: Support (primary), Suggest (secondary), Website (tertiary).

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/quick_actions_section.dart
git commit -m "refactor: rebuild quick actions to match original 3-column layout"
```

### Task 9: Rebuild Promotions Section

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/promotions_section.dart`

- [ ] **Step 1: Match original card design**

White cards (not gradient), 160x140, with border + shadow, 16px border radius. Each has:
- Discount badge (colored background 0.1 alpha, colored text, bold)
- Title (14px, w600, textPrimary)
- Store name (12px, textSecondary)

Section title: "Hottest Promotions" (20px, bold). Remove "View All" button.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/promotions_section.dart
git commit -m "refactor: rebuild promotions section to match original design"
```

### Task 10: Rebuild Places Section

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/places_section.dart`

- [ ] **Step 1: Match original card design**

White card, border + shadow, 16px padding, 16px border radius. Row layout:
- Left: 50x50 icon container (primary 0.1 bg, primary place icon)
- Center: name (16px, w600), address with location icon (13px), distance (13px)
- Right: circular "Get directions" button (40x40, primary 0.1 bg) + label (10px)

Section title: "Popular Places" (20px, bold). Remove "View All" button.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/places_section.dart
git commit -m "refactor: rebuild places section to match original design"
```

### Task 11: Rebuild Events Section

**Files:**
- Modify: `frontend/lib/features/home/presentation/widgets/events_section.dart`

- [ ] **Step 1: Match original card design**

White card (not gradient), border + shadow, 16px padding, 16px border radius. Row layout:
- Left: 50x50 icon container (primary 0.1 bg, event icon)
- Center: title (16px, w600), time + location row with icons (13px, textSecondary)
- Right: category badge (primary 0.1 bg, primary text, 12px border radius)

Section title: "Upcoming Events" (20px, bold). Remove "View All" button.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/presentation/widgets/events_section.dart
git commit -m "refactor: rebuild events section to match original design"
```

### Task 12: Update Home Screen

**Files:**
- Modify: `frontend/lib/features/home/presentation/screens/home_screen.dart`

- [ ] **Step 1: Use SpectrumAppBar and fix layout**

Replace the custom SliverAppBar with `SpectrumAppBar`. Use `AppColors.background` for scaffold. Use `AppSpacing.screenPadding` (20px) for body padding. Use `AppSpacing.sectionGap` (25px) between sections. Reorder sections to match original: Greeting → Promotions → Places → Events → Quick Actions.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/presentation/screens/home_screen.dart
git commit -m "refactor: rebuild home screen layout to match original design"
```

## Chunk 4: Community Page Rebuild

### Task 13: Rebuild Post Card

**Files:**
- Modify: `frontend/lib/features/community/presentation/widgets/post_card.dart`

- [ ] **Step 1: Match original discussion card design**

White card with border + shadow, 20px border radius, 16px padding. Structure:
- Header row: CircleAvatar (radius 20, primary 0.1 bg, primary initial) + author name (14px, w600) + timestamp (12px, textSecondary) + category badge (right-aligned, colored bg 0.1, colored text, 12px radius)
- Title (16px, w600, maxLines 2)
- Content preview (14px, textSecondary, height 1.4, maxLines 2)
- Optional image placeholder (if post has image): 150px height, primary 0.1 bg, 12px radius, with image icon + "Image" label
- Action row: heart icon + count, comment icon + count, share icon (right-aligned)

Category color function:
- Sensory → secondary (purple)
- Education → tertiary (light blue)
- Support → accent1 (red)
- Resources → quaternary (green)
- Daily Life → accent2 (amber)
- News → accent2 (amber)
- Social → primary (blue)
- General → textSecondary (gray)

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/community/presentation/widgets/post_card.dart
git commit -m "refactor: rebuild post card to match original design"
```

### Task 14: Rebuild New Discussion Modal

**Files:**
- Modify: `frontend/lib/features/community/presentation/widgets/new_discussion_modal.dart`

- [ ] **Step 1: Match original modal design**

Full-page bottom sheet (85% height), white bg, 20px top radius. Structure:
- Drag handle (40x4, gray, centered)
- Header: "Cancel" (left) + "New Discussion" (center, bold) + "Post" (right, primary color)
- Category section: label + Wrap of chips with border (selected: primary 0.1 bg + checkmark)
- Title field: label + TextField with cream bg (background color), 12px radius
- Content field: label + TextField (6 lines) with cream bg
- Add Image section: dotted border container with image icon + "Tap to add image" text

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/community/presentation/widgets/new_discussion_modal.dart
git commit -m "refactor: rebuild new discussion modal to match original design"
```

### Task 15: Update Feed Screen

**Files:**
- Modify: `frontend/lib/features/community/presentation/screens/feed_screen.dart`

- [ ] **Step 1: Update screen with SpectrumAppBar and fix styling**

Use `SpectrumAppBar` with title "Community". Update TabBar: `labelColor` and `indicatorColor` to `AppColors.primary`, `indicatorWeight: 3`. Update search bar to use original styling (cream background, 12px radius). Update FAB: `backgroundColor: AppColors.primary`, `shape: CircleBorder()`, `elevation: 6`. Update all color references from cyan/coral to new palette.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/community/presentation/screens/feed_screen.dart
git commit -m "refactor: update community feed to match original design"
```

### Task 16: Update Post Detail Screen

**Files:**
- Modify: `frontend/lib/features/community/presentation/screens/post_detail_screen.dart`

- [ ] **Step 1: Match original detail view**

Use bottom sheet style (like original) instead of full page navigation. Or keep full page but match styling:
- Author header: CircleAvatar (radius 25) + name + timestamp + category badge
- Title (20px, bold)
- Content (15px, height 1.5)
- Divider
- "Replies" header with count
- Reply cards: cream bg (background color), 12px radius, avatar (radius 16, secondary color), author + timestamp row, content, like button
- Reply input: cream bg TextField (25px radius) + circular send button (primary bg, white icon)

Update all colors from cyan to new palette.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/community/presentation/screens/post_detail_screen.dart
git commit -m "refactor: update post detail to match original design"
```

## Chunk 5: Backend Mock Data + Final Polish

### Task 17: Add Mock Dashboard Data

**Files:**
- Modify: `backend/src/routes/dashboard.ts`

- [ ] **Step 1: Return mock promotions, places, and events**

Instead of empty arrays, return:

```typescript
promotions: [
  { id: "p1", title: "50% Off Sensory Toys", store: "Learning Express", discount: "50%" },
  { id: "p2", title: "Free Therapy Session", store: "Wellness Center", discount: "FREE" },
  { id: "p3", title: "Buy 1 Get 1 Books", store: "Barnes & Noble", discount: "BOGO" },
],
places: [
  { id: "pl1", name: "Sensory Garden Park", address: "123 Oak Street", distance: "0.5 miles" },
  { id: "pl2", name: "Quiet Library Zone", address: "456 Main Avenue", distance: "1.2 miles" },
  { id: "pl3", name: "Therapy Center", address: "789 Wellness Blvd", distance: "2.0 miles" },
],
upcomingEvents: [
  { id: "e1", title: "Parent Support Group", time: "10:00 AM", location: "Community Center", category: "Support" },
  { id: "e2", title: "Art Therapy Session", time: "2:00 PM", location: "Creative Studio", category: "Therapy" },
],
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/routes/dashboard.ts
git commit -m "feat: add mock dashboard data for promotions, places, events"
```

### Task 18: Update Dashboard Domain Models

**Files:**
- Modify: `frontend/lib/features/home/domain/dashboard.dart`

- [ ] **Step 1: Update model fields to match new mock data**

Ensure `DashboardPromotion` has: id, title, store, discount.
Ensure `DashboardPlace` has: id, name, address, distance.
Ensure `DashboardEvent` has: id, title, time, location, category.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/domain/dashboard.dart
git commit -m "refactor: update dashboard models for mock data fields"
```

### Task 19: Update Dashboard Repository

**Files:**
- Modify: `frontend/lib/features/home/data/dashboard_repository.dart`

- [ ] **Step 1: Parse new mock data fields in response**

Update the parsing to handle the new promotions, places, and events fields.

- [ ] **Step 2: Commit**

```bash
git add frontend/lib/features/home/data/dashboard_repository.dart
git commit -m "refactor: update dashboard repository to parse mock data"
```

### Task 20: Final Cleanup — Remove Old Color References

**Files:**
- All files referencing old color names (cyan, coral, textDark, textGray, backgroundGray, navy, orange, yellow, purple)

- [ ] **Step 1: Search and replace old color references across all frontend files**

Run: `grep -r "AppColors\.\(cyan\|coral\|textDark\|textGray\|backgroundGray\|navy\|orange\|yellow\|purple\|backgroundLight\|textLight\)" frontend/lib/`

Replace each reference:
- `AppColors.cyan` → `AppColors.primary`
- `AppColors.coral` → `AppColors.accent1`
- `AppColors.textDark` → `AppColors.textPrimary`
- `AppColors.textGray` → `AppColors.textSecondary`
- `AppColors.backgroundGray` → `AppColors.background`
- `AppColors.navy` → `AppColors.darkGray`
- `AppColors.orange` → `AppColors.accent2`
- `AppColors.yellow` → `AppColors.warning`
- `AppColors.purple` → `AppColors.secondary`
- `AppColors.backgroundLight` → `AppColors.surfaceLight`
- `AppColors.textLight` → `AppColors.textOnPrimary`
- `AppColors.cardBackground` → `AppColors.cardBackground` (unchanged)
- `AppColors.border` → `AppColors.divider`

- [ ] **Step 2: Verify full app compiles**

Run: `cd frontend && flutter analyze`

- [ ] **Step 3: Commit**

```bash
git add -A frontend/lib/
git commit -m "refactor: replace all old color references with new palette"
```

### Task 21: Verify and Hot Restart

- [ ] **Step 1: Run flutter analyze to check for any errors**

Run: `cd frontend && flutter analyze`

- [ ] **Step 2: Verify backend serves mock data**

Run: `curl -s http://localhost:8790/api/dashboard -H "Authorization: Bearer <token>" | python3 -m json.tool`

Confirm promotions, places, and events are non-empty.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "feat: complete UI refresh matching original ana/backup design"
```
