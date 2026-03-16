# Phase 5 — Catalog Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Catalog feature (place directory with multi-dimension filtering, star ratings, saved places) following Community's clean architecture patterns.

**Architecture:** Feature-based clean architecture: Forui + Riverpod frontend with repository pattern, Hono + Prisma + D1 backend. Three sub-phases: 5a (Frontend UI with mock data), 5b (Backend), 5c (Wire up). Shared components (Author model, PaginatedResult, filter popup, place card) are extracted in 5a for reuse by Promotions later.

**Tech Stack:** Flutter, Forui, Riverpod, Dio, GoRouter (frontend); Hono, Prisma, D1, Zod, Vitest (backend)

**Spec:** `docs/superpowers/specs/2026-03-15-catalog-promotions-design.md`

---

## CRITICAL: Implementation Notes

**The code in this plan is reference-quality — implementers MUST verify Forui APIs against context7 docs before using them.** Key patterns to follow from the existing codebase:

### Forui API Patterns (check `feed_screen.dart` and `post_card.dart` for reference)

1. **FTabs**: Use `FTabs(expands: true, style: ..., control: FTabControl.lifted(...), children: [FTabEntry(label: ..., child: ...)])` — NOT `FTabs(tabs: [...])` or `content:`.
2. **FTextField**: Use `FTextField(control: FTextFieldControl.managed(controller: ..., onChange: ...), hint: ..., prefixBuilder: ..., suffixBuilder: ...)` — NOT `FTextField(controller: ..., onChange: ..., prefix: ...)`.
3. **FButton**: Use `FButton(onPress: ..., prefix: ..., child: ...)` with `variant: FButtonVariant.outline` — NOT `label:` or `style: FButtonStyle.outline`.
4. **FCheckbox**: Not used in existing codebase — verify exact API via context7 Forui docs before using. Fallback: use Material `CheckboxListTile` if Forui checkbox is incompatible.
5. **Screen wrapper**: Wrap screens in the app's `Screen(body: ...)` widget, matching `FeedScreen` pattern.

### Backend Patterns (check `community.ts` and `index.ts` for reference)

1. **Hono type**: Use `new Hono<{ Bindings: AppBindings; Variables: AppVariables }>()` — NOT `new Hono<AppContext>()`.
2. **Import extensions**: Always use `.js` extensions: `from "../middleware/session.js"` — NOT `from "../middleware/session"`.
3. **Cursor pagination**: Use Prisma's `cursor: { id: cursor }, skip: 1` pattern — NOT `where: { id: { lt: cursor } }`.
4. **Validation**: Use `zValidator("json", schema)` middleware pattern from `@hono/zod-validator` — NOT manual `schema.parse(await c.req.json())`.

### Other Fixes

- **Timer disposal**: Add `ref.onDispose(() => _debounce?.cancel())` in CatalogNotifier's `build()` method.
- **StarRatingInput**: Add `didUpdateWidget` override to update `_rating` when parent rebuilds with new value.
- **PlaceDetailScreen**: Use `Screen` widget wrapper instead of raw `Scaffold`.
- **Router**: Preserve `name: 'catalog'` on the route definition.
- **Import path**: Use `package:spectrum/shared/providers/api_provider.dart` — NOT `shared/providers/providers.dart`.
- **CommentAuthor→Author**: The backend comment endpoint doesn't return `userType`. The shared `Author.fromJson` defaults to `'supporter'` which handles this. Optionally update backend to include `userType` in comment author select.
- **JSON filter matching for ageGroups/specialNeeds**: The plan uses post-query filtering for simplicity. For production, implement `prisma.$queryRaw` with `json_each()` as documented in the design spec. Mark as TODO in code.

---

## Chunk 1: Shared Extractions + Domain Models (Phase 5a — Part 1)

### Task 1: Extract Shared Author Model

**Files:**
- Create: `frontend/lib/shared/domain/author.dart`
- Modify: `frontend/lib/features/community/domain/post.dart`
- Modify: `frontend/lib/features/community/domain/comment.dart`

- [ ] **Step 1: Create shared Author model**

Create `frontend/lib/shared/domain/author.dart`:

```dart
class Author {
  final String id;
  final String name;
  final String? image;
  final String userType;

  const Author({
    required this.id,
    required this.name,
    this.image,
    required this.userType,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      userType: json['userType'] as String? ?? 'supporter',
    );
  }
}
```

- [ ] **Step 2: Update Post to use shared Author**

In `frontend/lib/features/community/domain/post.dart`:
- Remove the `PostAuthor` class (lines 1-22)
- Add import: `import 'package:spectrum/shared/domain/author.dart';`
- Add typedef at top: `typedef PostAuthor = Author;`
- This preserves backward compatibility — all existing code that references `PostAuthor` still works

- [ ] **Step 3: Update Comment to use shared Author**

In `frontend/lib/features/community/domain/comment.dart`:
- Remove the `CommentAuthor` class definition
- Add import: `import 'package:spectrum/shared/domain/author.dart';`
- Add typedef: `typedef CommentAuthor = Author;`

- [ ] **Step 4: Run Dart analysis to verify no breakage**

```bash
cd frontend && dart analyze
```

Expected: No errors. Existing code referencing `PostAuthor` and `CommentAuthor` continues to work via typedefs.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/shared/domain/author.dart frontend/lib/features/community/domain/post.dart frontend/lib/features/community/domain/comment.dart
git commit -m "refactor: extract shared Author model from PostAuthor/CommentAuthor"
```

### Task 2: Extract Shared PaginatedResult

**Files:**
- Create: `frontend/lib/shared/domain/paginated_result.dart`
- Modify: `frontend/lib/features/community/data/community_repository.dart`

- [ ] **Step 1: Create shared PaginatedResult**

Create `frontend/lib/shared/domain/paginated_result.dart`:

```dart
class PaginatedResult<T> {
  final List<T> items;
  final String? nextCursor;

  const PaginatedResult({required this.items, this.nextCursor});
}
```

- [ ] **Step 2: Update community_repository.dart to use shared PaginatedResult**

In `frontend/lib/features/community/data/community_repository.dart`:
- Remove the `PaginatedResult` class definition (lines 5-10)
- Add import: `import 'package:spectrum/shared/domain/paginated_result.dart';`

- [ ] **Step 3: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/shared/domain/paginated_result.dart frontend/lib/features/community/data/community_repository.dart
git commit -m "refactor: extract shared PaginatedResult from community repository"
```

### Task 3: Create Catalog Domain Models

**Files:**
- Create: `frontend/lib/features/catalog/domain/place.dart`
- Create: `frontend/lib/features/catalog/domain/filter_option.dart`

- [ ] **Step 1: Create Place model**

Create `frontend/lib/features/catalog/domain/place.dart`:

```dart
import 'package:spectrum/shared/domain/author.dart';

class Place {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String? address;
  final String? imageUrl;
  final double averageRating;
  final int ratingCount;
  final List<String> tags;
  final List<String> ageGroups;
  final List<String> specialNeeds;
  final double? latitude;
  final double? longitude;
  final String ownerId;
  final Author owner;
  final bool saved;
  final int? userRating;
  final DateTime createdAt;

  const Place({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.address,
    this.imageUrl,
    this.averageRating = 0,
    this.ratingCount = 0,
    this.tags = const [],
    this.ageGroups = const [],
    this.specialNeeds = const [],
    this.latitude,
    this.longitude,
    required this.ownerId,
    required this.owner,
    this.saved = false,
    this.userRating,
    required this.createdAt,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'General',
      address: json['address'] as String?,
      imageUrl: json['imageUrl'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      ageGroups: (json['ageGroups'] as List?)?.cast<String>() ?? [],
      specialNeeds: (json['specialNeeds'] as List?)?.cast<String>() ?? [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ownerId: json['ownerId'] as String,
      owner: Author.fromJson(json['owner'] as Map<String, dynamic>),
      saved: json['saved'] as bool? ?? false,
      userRating: json['userRating'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Place copyWith({
    bool? saved,
    int? userRating,
    double? averageRating,
    int? ratingCount,
  }) {
    return Place(
      id: id,
      name: name,
      description: description,
      category: category,
      address: address,
      imageUrl: imageUrl,
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
      tags: tags,
      ageGroups: ageGroups,
      specialNeeds: specialNeeds,
      latitude: latitude,
      longitude: longitude,
      ownerId: ownerId,
      owner: owner,
      saved: saved ?? this.saved,
      userRating: userRating ?? this.userRating,
      createdAt: createdAt,
    );
  }
}
```

- [ ] **Step 2: Create FilterOption model**

Create `frontend/lib/features/catalog/domain/filter_option.dart`:

```dart
class FilterOption {
  final String id;
  final String name;
  final String? icon;

  const FilterOption({
    required this.id,
    required this.name,
    this.icon,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
    );
  }
}

class FilterGroup {
  final String label;
  final List<FilterOption> options;

  const FilterGroup({required this.label, required this.options});
}
```

- [ ] **Step 3: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/catalog/domain/
git commit -m "feat(catalog): add Place and FilterOption domain models"
```

### Task 4: Create Shared Filter Popup Widget

**Files:**
- Create: `frontend/lib/shared/widgets/filter_popup.dart`
- Modify: `frontend/lib/shared/widgets/widgets.dart`

This widget is used by both Catalog (3 filter groups) and Promotions (1 filter group). It shows a popup (not modal) with checkboxes grouped by label, a badge count on the trigger button, and Apply/Clear actions.

- [ ] **Step 1: Create filter popup widget**

Create `frontend/lib/shared/widgets/filter_popup.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/core/constants/app_colors.dart';
import 'package:spectrum/core/constants/app_spacing.dart';
import 'package:spectrum/features/catalog/domain/filter_option.dart';

class FilterPopup extends StatefulWidget {
  final List<FilterGroup> filterGroups;
  final Map<String, Set<String>> selectedFilters; // groupLabel -> set of selected option IDs
  final ValueChanged<Map<String, Set<String>>> onApply;

  const FilterPopup({
    super.key,
    required this.filterGroups,
    required this.selectedFilters,
    required this.onApply,
  });

  @override
  State<FilterPopup> createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  late Map<String, Set<String>> _selections;

  @override
  void initState() {
    super.initState();
    _selections = {
      for (final entry in widget.selectedFilters.entries)
        entry.key: Set<String>.from(entry.value),
    };
  }

  int get _totalSelected =>
      _selections.values.fold(0, (sum, set) => sum + set.length);

  void _toggleOption(String groupLabel, String optionId) {
    setState(() {
      final group = _selections.putIfAbsent(groupLabel, () => {});
      if (group.contains(optionId)) {
        group.remove(optionId);
      } else {
        group.add(optionId);
      }
    });
  }

  void _clearAll() {
    setState(() {
      for (final set in _selections.values) {
        set.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 480),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        color: theme.colorScheme.background,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearAll,
                    child: Text(
                      'Clear All',
                      style: theme.typography.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Scrollable filter groups
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < widget.filterGroups.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.xl),
                        _buildFilterGroup(widget.filterGroups[i], theme),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: FButton(
                  onPress: () {
                    widget.onApply(_selections);
                  },
                  label: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterGroup(FilterGroup group, FThemeData theme) {
    final selected = _selections[group.label] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.label,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: group.options.map((option) {
            final isSelected = selected.contains(option.id);
            return FCheckbox(
              label: Text(option.name),
              value: isSelected,
              onChange: (_) => _toggleOption(group.label, option.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Filter trigger button with badge count.
/// Place this next to the search bar.
class FilterTriggerButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const FilterTriggerButton({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasActive = activeCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : theme.colorScheme.background,
          borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
          border: Border.all(
            color: hasActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.tune,
                size: 20,
                color: hasActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (hasActive)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Export filter_popup from widgets barrel**

In `frontend/lib/shared/widgets/widgets.dart`, add:

```dart
export 'filter_popup.dart';
```

- [ ] **Step 3: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors. Check Forui docs via context7 if FCheckbox API differs.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/shared/widgets/filter_popup.dart frontend/lib/shared/widgets/widgets.dart
git commit -m "feat: add shared FilterPopup and FilterTriggerButton widgets"
```

### Task 5: Extract and Enhance Place Card

**Files:**
- Create: `frontend/lib/shared/widgets/place_card.dart`
- Modify: `frontend/lib/shared/widgets/widgets.dart`
- Modify: `frontend/lib/features/home/presentation/widgets/places_section.dart`

The existing `PlacesSection` uses `ImageListCard` directly. We extract a `PlaceCard` that enhances `ImageListCard` with optional rating display, then update `PlacesSection` to use it.

- [ ] **Step 1: Create shared PlaceCard widget**

Create `frontend/lib/shared/widgets/place_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/core/constants/app_colors.dart';
import 'package:spectrum/core/constants/app_spacing.dart';
import 'package:spectrum/shared/widgets/image_list_card.dart';

/// Reusable place card for Catalog list and Home dashboard.
/// Shows image, name, address, optional rating, optional category tag.
class PlaceCard extends StatelessWidget {
  final String name;
  final String? address;
  final String? imageUrl;
  final double? averageRating;
  final int? ratingCount;
  final String? category;
  final bool showRating;
  final VoidCallback? onTap;

  const PlaceCard({
    super.key,
    required this.name,
    this.address,
    this.imageUrl,
    this.averageRating,
    this.ratingCount,
    this.category,
    this.showRating = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final details = <ImageListCardDetail>[
      if (address != null)
        ImageListCardDetail(icon: Icons.location_on_outlined, text: address!),
      if (showRating && averageRating != null && averageRating! > 0)
        ImageListCardDetail(
          icon: Icons.star,
          text:
              '${averageRating!.toStringAsFixed(1)} (${ratingCount ?? 0} reviews)',
        ),
    ];

    return ImageListCard(
      title: name,
      imageUrl: imageUrl,
      details: details,
      trailing: category != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
              ),
              child: Text(
                category!,
                style: context.theme.typography.xs.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Export PlaceCard from widgets barrel**

In `frontend/lib/shared/widgets/widgets.dart`, add:

```dart
export 'place_card.dart';
```

- [ ] **Step 3: Update PlacesSection to use PlaceCard**

In `frontend/lib/features/home/presentation/widgets/places_section.dart`, replace the `ImageListCard` usage with `PlaceCard`:

- Add import: `import 'package:spectrum/shared/widgets/place_card.dart';`
- Replace the `ImageListCard(...)` call with:

```dart
PlaceCard(
  name: place.name,
  address: place.address,
  imageUrl: place.imageUrl,
  onTap: () => onPlaceSelected?.call(place.id),
)
```

- [ ] **Step 4: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/shared/widgets/place_card.dart frontend/lib/shared/widgets/widgets.dart frontend/lib/features/home/presentation/widgets/places_section.dart
git commit -m "feat: extract shared PlaceCard widget, update Home to use it"
```

---

## Chunk 2: Catalog Provider + Repository Mock (Phase 5a — Part 2)

### Task 6: Create Catalog Repository (Mock Data)

**Files:**
- Create: `frontend/lib/features/catalog/data/catalog_repository.dart`

The repository starts with mock data. In Phase 5c it will be wired to real API calls.

- [ ] **Step 1: Create catalog repository with mock data**

Create `frontend/lib/features/catalog/data/catalog_repository.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/catalog/domain/filter_option.dart';
import 'package:spectrum/features/catalog/domain/place.dart';
import 'package:spectrum/shared/domain/author.dart';
import 'package:spectrum/shared/domain/paginated_result.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository();
});

class CatalogRepository {
  // --- Mock Filter Options ---

  Future<List<FilterOption>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      FilterOption(id: '1', name: 'Sensory-Friendly', icon: 'spa'),
      FilterOption(id: '2', name: 'Indoor Playground', icon: 'sports_handball'),
      FilterOption(id: '3', name: 'Outdoor Playground', icon: 'park'),
      FilterOption(id: '4', name: 'Doctor', icon: 'medical_services'),
      FilterOption(id: '5', name: 'Dentist', icon: 'medical_information'),
      FilterOption(id: '6', name: 'Therapist', icon: 'psychology'),
      FilterOption(id: '7', name: 'After-School', icon: 'school'),
      FilterOption(id: '8', name: 'Education', icon: 'cast_for_education'),
      FilterOption(id: '9', name: 'Restaurant', icon: 'restaurant'),
    ];
  }

  Future<List<FilterOption>> getAgeGroups() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      FilterOption(id: '1', name: 'Infants (0-2)'),
      FilterOption(id: '2', name: 'Toddlers (2-4)'),
      FilterOption(id: '3', name: 'Preschool (4-6)'),
      FilterOption(id: '4', name: 'School Age (6-12)'),
      FilterOption(id: '5', name: 'Teens (12-18)'),
      FilterOption(id: '6', name: 'Adults (18+)'),
    ];
  }

  Future<List<FilterOption>> getSpecialNeeds() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      FilterOption(id: '1', name: 'Autism Specific'),
      FilterOption(id: '2', name: 'Wheelchair Accessible'),
      FilterOption(id: '3', name: 'Nonverbal Support'),
      FilterOption(id: '4', name: 'Sensory Processing'),
    ];
  }

  // --- Mock Places ---

  static final _mockAuthor = Author(
    id: 'owner-1',
    name: 'Spectrum Admin',
    userType: 'professional',
  );

  static final _mockPlaces = [
    Place(
      id: '1',
      name: 'Bay Area Discovery Museum',
      description: 'Interactive museum with sensory-friendly hours every Saturday morning. Quiet spaces available.',
      category: 'Sensory-Friendly',
      address: '557 McReynolds Rd, Sausalito, CA',
      averageRating: 4.7,
      ratingCount: 23,
      tags: ['museum', 'sensory-friendly', 'kids'],
      ageGroups: ['Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Autism Specific', 'Sensory Processing'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Place(
      id: '2',
      name: 'Golden Gate Park Playground',
      description: 'Accessible playground with rubber surfacing and sensory garden nearby.',
      category: 'Outdoor Playground',
      address: '320 Bowling Green Dr, San Francisco, CA',
      averageRating: 4.5,
      ratingCount: 41,
      tags: ['playground', 'outdoor', 'accessible'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Wheelchair Accessible', 'Autism Specific'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Place(
      id: '3',
      name: 'Dr. Sarah Chen — Developmental Pediatrics',
      description: 'Specializing in autism spectrum evaluation and support for children ages 2-18.',
      category: 'Doctor',
      address: '1200 El Camino Real, Suite 200, Palo Alto, CA',
      averageRating: 4.9,
      ratingCount: 67,
      tags: ['doctor', 'pediatrics', 'autism evaluation'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)', 'Teens (12-18)'],
      specialNeeds: ['Autism Specific'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Place(
      id: '4',
      name: 'Bright Futures ABA Therapy',
      description: 'Evidence-based ABA therapy center with individualized programs and parent training.',
      category: 'Therapist',
      address: '890 Market St, Suite 400, San Francisco, CA',
      averageRating: 4.6,
      ratingCount: 35,
      tags: ['therapy', 'ABA', 'parent training'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Autism Specific', 'Nonverbal Support'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Place(
      id: '5',
      name: 'The Sensory Café',
      description: 'Quiet dining environment with dim lighting, noise-canceling headphones available, and a picture menu.',
      category: 'Restaurant',
      address: '456 Valencia St, San Francisco, CA',
      averageRating: 4.3,
      ratingCount: 18,
      tags: ['restaurant', 'quiet dining', 'sensory-friendly'],
      ageGroups: ['Preschool (4-6)', 'School Age (6-12)', 'Teens (12-18)', 'Adults (18+)'],
      specialNeeds: ['Autism Specific', 'Sensory Processing'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Place(
      id: '6',
      name: 'Jump & Play Indoor Park',
      description: 'Sensory-friendly play sessions on Tuesday mornings. Trampolines, ball pits, and climbing walls.',
      category: 'Indoor Playground',
      address: '200 Industrial Way, San Carlos, CA',
      averageRating: 4.4,
      ratingCount: 29,
      tags: ['indoor', 'trampoline', 'sensory sessions'],
      ageGroups: ['Toddlers (2-4)', 'Preschool (4-6)', 'School Age (6-12)'],
      specialNeeds: ['Autism Specific', 'Sensory Processing'],
      ownerId: 'owner-1',
      owner: _mockAuthor,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  Future<PaginatedResult<Place>> getPlaces({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
    Set<String>? ageGroups,
    Set<String>? specialNeeds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = List<Place>.from(_mockPlaces);

    // Text search
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false) ||
        p.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }

    // Category filter
    if (categories != null && categories.isNotEmpty) {
      filtered = filtered.where((p) => categories.contains(p.category)).toList();
    }

    // Age group filter
    if (ageGroups != null && ageGroups.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.ageGroups.any((ag) => ageGroups.contains(ag))
      ).toList();
    }

    // Special needs filter
    if (specialNeeds != null && specialNeeds.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.specialNeeds.any((sn) => specialNeeds.contains(sn))
      ).toList();
    }

    return PaginatedResult(items: filtered, nextCursor: null);
  }

  Future<Place?> getPlace(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockPlaces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> ratePlace(String id, int score) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op. Real API will upsert rating.
  }

  Future<void> savePlace(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op
  }

  Future<void> unsavePlace(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op
  }

  Future<List<Place>> getSavedPlaces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: return first 2 places as "saved"
    return _mockPlaces.take(2).map((p) => Place(
      id: p.id,
      name: p.name,
      description: p.description,
      category: p.category,
      address: p.address,
      imageUrl: p.imageUrl,
      averageRating: p.averageRating,
      ratingCount: p.ratingCount,
      tags: p.tags,
      ageGroups: p.ageGroups,
      specialNeeds: p.specialNeeds,
      ownerId: p.ownerId,
      owner: p.owner,
      saved: true,
      createdAt: p.createdAt,
    )).toList();
  }
}
```

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/catalog/data/catalog_repository.dart
git commit -m "feat(catalog): add repository with mock data"
```

### Task 7: Create Catalog Provider

**Files:**
- Create: `frontend/lib/features/catalog/presentation/providers/catalog_provider.dart`

Follows the same Riverpod Notifier pattern as `feed_provider.dart`.

- [ ] **Step 1: Create catalog provider**

Create `frontend/lib/features/catalog/presentation/providers/catalog_provider.dart`:

```dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/catalog/data/catalog_repository.dart';
import 'package:spectrum/features/catalog/domain/filter_option.dart';
import 'package:spectrum/features/catalog/domain/place.dart';

// --- Filter Options Provider ---

final catalogFilterOptionsProvider =
    FutureProvider<CatalogFilterOptions>((ref) async {
  final repo = ref.read(catalogRepositoryProvider);
  final results = await Future.wait([
    repo.getCategories(),
    repo.getAgeGroups(),
    repo.getSpecialNeeds(),
  ]);
  return CatalogFilterOptions(
    categories: results[0],
    ageGroups: results[1],
    specialNeeds: results[2],
  );
});

class CatalogFilterOptions {
  final List<FilterOption> categories;
  final List<FilterOption> ageGroups;
  final List<FilterOption> specialNeeds;

  const CatalogFilterOptions({
    required this.categories,
    required this.ageGroups,
    required this.specialNeeds,
  });

  List<FilterGroup> toFilterGroups() => [
        FilterGroup(label: 'Categories', options: categories),
        FilterGroup(label: 'Age Groups', options: ageGroups),
        FilterGroup(label: 'Special Needs', options: specialNeeds),
      ];
}

// --- Catalog Feed Provider ---

class CatalogState {
  final List<Place> places;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final Map<String, Set<String>> filters; // groupLabel -> selected option names

  const CatalogState({
    this.places = const [],
    this.nextCursor,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filters = const {},
  });

  int get activeFilterCount =>
      filters.values.fold(0, (sum, set) => sum + set.length);

  bool get hasActiveFilters => activeFilterCount > 0;

  CatalogState copyWith({
    List<Place>? places,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    Map<String, Set<String>>? filters,
  }) {
    return CatalogState(
      places: places ?? this.places,
      nextCursor: nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
    );
  }
}

final catalogProvider =
    NotifierProvider<CatalogNotifier, CatalogState>(CatalogNotifier.new);

class CatalogNotifier extends Notifier<CatalogState> {
  Timer? _debounce;

  @override
  CatalogState build() {
    _loadInitial();
    return const CatalogState();
  }

  CatalogRepository get _repo => ref.read(catalogRepositoryProvider);

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.getPlaces(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: state.filters['Categories'],
        ageGroups: state.filters['Age Groups'],
        specialNeeds: state.filters['Special Needs'],
      );
      state = state.copyWith(
        places: result.items,
        nextCursor: result.nextCursor,
        isLoading: false,
      );
    } catch (e) {
      log('Failed to load catalog: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await _loadInitial();
  }

  void searchDebounced(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      search(query);
    });
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _loadInitial();
  }

  void setFilters(Map<String, Set<String>> filters) {
    state = state.copyWith(filters: filters);
    _loadInitial();
  }

  void clearFilters() {
    state = state.copyWith(filters: {});
    _loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.nextCursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repo.getPlaces(
        cursor: state.nextCursor,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: state.filters['Categories'],
        ageGroups: state.filters['Age Groups'],
        specialNeeds: state.filters['Special Needs'],
      );
      state = state.copyWith(
        places: [...state.places, ...result.items],
        nextCursor: result.nextCursor,
        isLoadingMore: false,
      );
    } catch (e) {
      log('Failed to load more catalog: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void toggleSave(String placeId) {
    final index = state.places.indexWhere((p) => p.id == placeId);
    if (index == -1) return;
    final place = state.places[index];
    final updated = place.copyWith(saved: !place.saved);
    final newList = List<Place>.from(state.places);
    newList[index] = updated;
    state = state.copyWith(places: newList);

    // Fire and forget
    if (updated.saved) {
      _repo.savePlace(placeId);
    } else {
      _repo.unsavePlace(placeId);
    }
  }
}

// --- Saved Places Provider ---

final savedPlacesProvider =
    FutureProvider<Map<String, List<Place>>>((ref) async {
  final repo = ref.read(catalogRepositoryProvider);
  final places = await repo.getSavedPlaces();
  final grouped = <String, List<Place>>{};
  for (final place in places) {
    grouped.putIfAbsent(place.category, () => []).add(place);
  }
  return grouped;
});
```

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/catalog/presentation/providers/catalog_provider.dart
git commit -m "feat(catalog): add CatalogNotifier, filter options, and saved places providers"
```

---

## Chunk 3: Catalog Screens (Phase 5a — Part 3)

### Task 8: Create Catalog Screen (Browse + Saved Tabs)

**Files:**
- Create: `frontend/lib/features/catalog/presentation/screens/catalog_screen.dart`

Follows the two-tab pattern from `feed_screen.dart`. Browse tab has search + filter popup + paginated list. Saved tab shows grouped places.

- [ ] **Step 1: Create catalog screen**

Create `frontend/lib/features/catalog/presentation/screens/catalog_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum/core/constants/app_colors.dart';
import 'package:spectrum/core/constants/app_spacing.dart';
import 'package:spectrum/features/catalog/domain/place.dart';
import 'package:spectrum/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:spectrum/shared/widgets/filter_popup.dart';
import 'package:spectrum/shared/widgets/place_card.dart';
import 'package:spectrum/shared/widgets/widgets.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterPopup() {
    final catalogState = ref.read(catalogProvider);
    final filterOptions = ref.read(catalogFilterOptionsProvider);

    filterOptions.whenData((options) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: FilterPopup(
            filterGroups: options.toFilterGroups(),
            selectedFilters: catalogState.filters,
            onApply: (filters) {
              ref.read(catalogProvider.notifier).setFilters(filters);
              Navigator.of(ctx).pop();
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FTabs(
      tabs: [
        FTabEntry(
          label: const Text('Catalogue'),
          content: _BrowseTab(
            searchController: _searchController,
            onFilterTap: _showFilterPopup,
          ),
        ),
        FTabEntry(
          label: const Text('Saved'),
          content: const _SavedTab(),
        ),
      ],
    );
  }
}

class _BrowseTab extends ConsumerWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterTap;

  const _BrowseTab({
    required this.searchController,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogProvider);
    final theme = context.theme;

    return Column(
      children: [
        // Search bar + filter button
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: FTextField(
                  controller: searchController,
                  hint: 'Search places...',
                  prefix: const Icon(Icons.search, size: 18),
                  suffix: searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.clear();
                            ref.read(catalogProvider.notifier).search('');
                          },
                          child: const Icon(Icons.clear, size: 18),
                        )
                      : null,
                  onChange: (value) {
                    ref.read(catalogProvider.notifier).searchDebounced(value);
                    // Trigger rebuild for suffix icon
                    (context as Element).markNeedsBuild();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilterTriggerButton(
                activeCount: state.activeFilterCount,
                onTap: onFilterTap,
              ),
            ],
          ),
        ),

        // Results count
        if (!state.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${state.places.length} Places Found',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(height: AppSpacing.sm),

        // Places list
        Expanded(
          child: state.isLoading
              ? const Center(child: FCircularProgress())
              : state.places.isEmpty
                  ? _EmptyState(
                      icon: Icons.search_off,
                      title: 'No places found',
                      subtitle: state.hasActiveFilters
                          ? 'Try adjusting your filters'
                          : 'Try a different search term',
                    )
                  : RefreshIndicator(
                      onRefresh: ref.read(catalogProvider.notifier).refresh,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification &&
                              notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200) {
                            ref.read(catalogProvider.notifier).loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: state.places.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.places.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: Center(child: FCircularProgress()),
                              );
                            }
                            final place = state.places[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: PlaceCard(
                                name: place.name,
                                address: place.address,
                                imageUrl: place.imageUrl,
                                averageRating: place.averageRating,
                                ratingCount: place.ratingCount,
                                category: place.category,
                                showRating: true,
                                onTap: () => context.push(
                                  '/catalog/${place.id}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlacesProvider);
    final theme = context.theme;

    return savedAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text('Failed to load saved places')),
      data: (grouped) {
        if (grouped.isEmpty) {
          return const _EmptyState(
            icon: Icons.bookmark_outline,
            title: 'No saved places yet',
            subtitle: 'Bookmark places to see them here',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final entry in grouped.entries) ...[
              // Category header
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.badgeRadius,
                        ),
                      ),
                      child: Icon(
                        Icons.place,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      entry.key,
                      style: theme.typography.base.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.badgeRadius,
                        ),
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: theme.typography.xs.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Place cards in this category
              ...entry.value.map(
                (place) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PlaceCard(
                    name: place.name,
                    address: place.address,
                    imageUrl: place.imageUrl,
                    averageRating: place.averageRating,
                    ratingCount: place.ratingCount,
                    category: place.category,
                    showRating: true,
                    onTap: () => context.push('/catalog/${place.id}'),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.typography.base.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.typography.sm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors. If Forui API differs (e.g. FTextField onChange vs onChanged), check Forui docs via context7 and adjust.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/catalog/presentation/screens/catalog_screen.dart
git commit -m "feat(catalog): add CatalogScreen with browse and saved tabs"
```

### Task 9: Create Place Detail Screen

**Files:**
- Create: `frontend/lib/features/catalog/presentation/screens/place_detail_screen.dart`

Follows `post_detail_screen.dart` pattern. Shows full place info, star rating, save button, get directions.

- [ ] **Step 1: Create place detail screen**

Create `frontend/lib/features/catalog/presentation/screens/place_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/core/constants/app_colors.dart';
import 'package:spectrum/core/constants/app_spacing.dart';
import 'package:spectrum/features/catalog/data/catalog_repository.dart';
import 'package:spectrum/features/catalog/domain/place.dart';
import 'package:spectrum/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final placeDetailProvider =
    FutureProvider.family<Place?, String>((ref, id) async {
  final repo = ref.read(catalogRepositoryProvider);
  return repo.getPlace(id);
});

class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailProvider(placeId));
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: placeAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(child: Text('Failed to load place')),
        data: (place) {
          if (place == null) {
            return const Center(child: Text('Place not found'));
          }
          return _PlaceDetailContent(place: place);
        },
      ),
    );
  }
}

class _PlaceDetailContent extends ConsumerWidget {
  final Place place;

  const _PlaceDetailContent({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Icon header
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: place.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    child: Image.network(
                      place.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _IconPlaceholder(),
                    ),
                  )
                : _IconPlaceholder(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Category tag
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
            ),
            child: Text(
              place.category,
              style: theme.typography.sm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            place.name,
            style: theme.typography.xl.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: AppSpacing.md),

          // Rating display
          Row(
            children: [
              ...List.generate(5, (index) {
                final starValue = index + 1;
                return Icon(
                  starValue <= place.averageRating.round()
                      ? Icons.star
                      : Icons.star_border,
                  color: AppColors.secondary,
                  size: 22,
                );
              }),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${place.averageRating.toStringAsFixed(1)} (${place.ratingCount} reviews)',
                style: theme.typography.sm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // User rating section
          Text(
            'Rate this place',
            style: theme.typography.sm.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StarRatingInput(
            currentRating: place.userRating ?? 0,
            onRate: (score) {
              ref.read(catalogRepositoryProvider).ratePlace(place.id, score);
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Description
          if (place.description != null) ...[
            Text(
              place.description!,
              style: theme.typography.base.copyWith(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Tags
          if (place.tags.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: place.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                  ),
                  child: Text(
                    tag,
                    style: theme.typography.xs.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Address + Directions
          if (place.address != null) ...[
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    place.address!,
                    style: theme.typography.sm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: () => _openDirections(place.address!),
                prefix: const Icon(Icons.directions, size: 18),
                label: const Text('Get Directions'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Save button
          SizedBox(
            width: double.infinity,
            child: FButton(
              style: FButtonStyle.outline,
              onPress: () {
                ref.read(catalogProvider.notifier).toggleSave(place.id);
              },
              prefix: Icon(
                place.saved ? Icons.bookmark : Icons.bookmark_outline,
                size: 18,
              ),
              label: Text(place.saved ? 'Saved' : 'Save Place'),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Future<void> _openDirections(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StarRatingInput extends StatefulWidget {
  final int currentRating;
  final ValueChanged<int> onRate;

  const _StarRatingInput({required this.currentRating, required this.onRate});

  @override
  State<_StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<_StarRatingInput> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.currentRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _rating = starValue);
            widget.onRate(starValue);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xxs),
            child: Icon(
              starValue <= _rating ? Icons.star : Icons.star_border,
              color: AppColors.secondary,
              size: 32,
            ),
          ),
        );
      }),
    );
  }
}

class _IconPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.place,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Check if url_launcher is in pubspec.yaml**

```bash
cd frontend && grep url_launcher pubspec.yaml
```

If not found, add it:

```bash
cd frontend && flutter pub add url_launcher
```

- [ ] **Step 3: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors. Check Forui docs via context7 for FButton.outline variant — may be `FButton.outline(...)` or `FButton(style: FButtonStyle.outline, ...)`.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/catalog/presentation/screens/place_detail_screen.dart frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "feat(catalog): add PlaceDetailScreen with rating, save, and directions"
```

### Task 10: Register Catalog Routes

**Files:**
- Modify: `frontend/lib/core/router/app_router.dart`

- [ ] **Step 1: Add catalog routes**

In `frontend/lib/core/router/app_router.dart`:

Add imports:
```dart
import 'package:spectrum/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:spectrum/features/catalog/presentation/screens/place_detail_screen.dart';
```

Find the existing `/catalog` placeholder route and replace it with:

```dart
GoRoute(
  path: '/catalog',
  builder: (context, state) => const CatalogScreen(),
  routes: [
    GoRoute(
      path: ':placeId',
      builder: (context, state) => PlaceDetailScreen(
        placeId: state.pathParameters['placeId']!,
      ),
    ),
  ],
),
```

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 3: Test the app compiles and runs**

```bash
cd frontend && flutter build ios --no-codesign 2>&1 | tail -5
```

Expected: Build succeeds. (Or use `flutter run` if a simulator is available.)

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/core/router/app_router.dart
git commit -m "feat(catalog): register catalog and place detail routes"
```

---

## Chunk 4: Backend — Schema, Filters, Seed (Phase 5b — Part 1)

### Task 11: Add Prisma Models for Catalog

**Files:**
- Modify: `backend/src/db/schema.prisma`

- [ ] **Step 1: Add filter option models and Organization enhancements to schema**

In `backend/src/db/schema.prisma`, add the following models after the existing Reaction model. Also add relations to the User model.

Add to User model relations:
```prisma
organizations Organization[]
ratings       Rating[]
savedItems    SavedItem[]
```

Add new models:
```prisma
model Organization {
  id            String   @id @default(cuid())
  name          String
  description   String?
  category      String
  address       String?
  phone         String?
  email         String?
  website       String?
  imageUrl      String?
  averageRating Float    @default(0)
  ratingCount   Int      @default(0)
  features      String   @default("[]")
  tags          String   @default("[]")
  ageGroups     String   @default("[]")
  specialNeeds  String   @default("[]")
  latitude      Float?
  longitude     Float?
  ownerId       String
  owner         User     @relation(fields: [ownerId], references: [id])
  ratings       Rating[]
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  @@index([createdAt])
}

model Rating {
  id             String       @id @default(cuid())
  userId         String
  user           User         @relation(fields: [userId], references: [id], onDelete: Cascade)
  organizationId String
  organization   Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  score          Int
  createdAt      DateTime     @default(now())
  updatedAt      DateTime     @updatedAt

  @@unique([userId, organizationId])
}

model SavedItem {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  itemType  String
  itemId    String
  createdAt DateTime @default(now())

  @@unique([userId, itemType, itemId])
  @@index([userId, itemType])
}

model CatalogCategory {
  id        String   @id @default(cuid())
  name      String   @unique
  icon      String?
  sortOrder Int      @default(0)
  updatedAt DateTime @updatedAt
}

model AgeGroup {
  id        String   @id @default(cuid())
  name      String   @unique
  sortOrder Int      @default(0)
  updatedAt DateTime @updatedAt
}

model SpecialNeed {
  id        String   @id @default(cuid())
  name      String   @unique
  sortOrder Int      @default(0)
  updatedAt DateTime @updatedAt
}
```

- [ ] **Step 2: Generate Prisma client**

```bash
pnpm --filter backend db:generate
```

Expected: Prisma client generated successfully.

- [ ] **Step 3: Push schema to D1**

```bash
pnpm --filter backend db:push
```

Expected: Schema pushed. If migration is needed instead, run `pnpm --filter backend db:migrate`.

- [ ] **Step 4: Commit**

```bash
git add backend/src/db/schema.prisma
git commit -m "feat(catalog): add Organization, Rating, SavedItem, and filter option Prisma models"
```

### Task 12: Create Seed Script for Filter Options

**Files:**
- Create: `backend/src/db/seed-filters.ts`

- [ ] **Step 1: Create seed script**

Create `backend/src/db/seed-filters.ts`:

```typescript
import { PrismaClient } from "@prisma/client";

// This script is run manually to seed filter option tables.
// Usage: npx tsx src/db/seed-filters.ts

const prisma = new PrismaClient();

async function main() {
  // Catalog Categories (from ana/backup)
  const categories = [
    { name: "Sensory-Friendly", icon: "spa", sortOrder: 1 },
    { name: "Indoor Playground", icon: "sports_handball", sortOrder: 2 },
    { name: "Outdoor Playground", icon: "park", sortOrder: 3 },
    { name: "Doctor", icon: "medical_services", sortOrder: 4 },
    { name: "Dentist", icon: "medical_information", sortOrder: 5 },
    { name: "Therapist", icon: "psychology", sortOrder: 6 },
    { name: "After-School", icon: "school", sortOrder: 7 },
    { name: "Education", icon: "cast_for_education", sortOrder: 8 },
    { name: "Restaurant", icon: "restaurant", sortOrder: 9 },
  ];

  for (const cat of categories) {
    await prisma.catalogCategory.upsert({
      where: { name: cat.name },
      update: { icon: cat.icon, sortOrder: cat.sortOrder },
      create: cat,
    });
  }

  // Age Groups
  const ageGroups = [
    { name: "Infants (0-2)", sortOrder: 1 },
    { name: "Toddlers (2-4)", sortOrder: 2 },
    { name: "Preschool (4-6)", sortOrder: 3 },
    { name: "School Age (6-12)", sortOrder: 4 },
    { name: "Teens (12-18)", sortOrder: 5 },
    { name: "Adults (18+)", sortOrder: 6 },
  ];

  for (const ag of ageGroups) {
    await prisma.ageGroup.upsert({
      where: { name: ag.name },
      update: { sortOrder: ag.sortOrder },
      create: ag,
    });
  }

  // Special Needs
  const specialNeeds = [
    { name: "Autism Specific", sortOrder: 1 },
    { name: "Wheelchair Accessible", sortOrder: 2 },
    { name: "Nonverbal Support", sortOrder: 3 },
    { name: "Sensory Processing", sortOrder: 4 },
  ];

  for (const sn of specialNeeds) {
    await prisma.specialNeed.upsert({
      where: { name: sn.name },
      update: { sortOrder: sn.sortOrder },
      create: sn,
    });
  }

  console.log("Filter options seeded successfully.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/db/seed-filters.ts
git commit -m "feat(catalog): add filter options seed script"
```

### Task 13: Create Filter Options Routes

**Files:**
- Create: `backend/src/routes/filters.ts`
- Modify: `backend/src/index.ts`

- [ ] **Step 1: Create filter routes**

Create `backend/src/routes/filters.ts`:

```typescript
import { Hono } from "hono";
import type { AppContext } from "../types/context";

export function filterRoutes() {
  const app = new Hono<AppContext>();

  app.get("/catalog-categories", async (c) => {
    const prisma = c.get("prisma");
    const categories = await prisma.catalogCategory.findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ categories });
  });

  app.get("/age-groups", async (c) => {
    const prisma = c.get("prisma");
    const ageGroups = await prisma.ageGroup.findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ ageGroups });
  });

  app.get("/special-needs", async (c) => {
    const prisma = c.get("prisma");
    const specialNeeds = await prisma.specialNeed.findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ specialNeeds });
  });

  return app;
}
```

- [ ] **Step 2: Mount filter routes in index.ts**

In `backend/src/index.ts`, add:

```typescript
import { filterRoutes } from "./routes/filters";
```

And in the route mounting section (after existing routes):

```typescript
app.route("/api/filters", filterRoutes());
```

- [ ] **Step 3: Run backend tests to verify no breakage**

```bash
pnpm test:backend
```

Expected: All existing tests pass.

- [ ] **Step 4: Commit**

```bash
git add backend/src/routes/filters.ts backend/src/index.ts
git commit -m "feat(catalog): add filter options API routes"
```

---

## Chunk 5: Backend — Catalog CRUD + Rating + Saved (Phase 5b — Part 2)

### Task 14: Create Catalog Routes

**Files:**
- Create: `backend/src/routes/catalog.ts`
- Modify: `backend/src/index.ts`

- [ ] **Step 1: Create catalog routes with Zod validation**

Create `backend/src/routes/catalog.ts`:

```typescript
import { Hono } from "hono";
import { z } from "zod";
import { sessionMiddleware, optionalSessionMiddleware } from "../middleware/session";
import type { AppContext } from "../types/context";

const createOrganizationSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  category: z.string().min(1),
  address: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email().optional(),
  website: z.string().url().optional(),
  imageUrl: z.string().url().optional(),
  tags: z.array(z.string()).max(10).default([]),
  ageGroups: z.array(z.string()).default([]),
  specialNeeds: z.array(z.string()).default([]),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
});

const updateOrganizationSchema = createOrganizationSchema.partial();

const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(50).default(20),
  q: z.string().optional(),
  category: z.string().optional(),
  ageGroup: z.string().optional(),
  specialNeed: z.string().optional(),
});

const ratingSchema = z.object({
  score: z.number().int().min(1).max(5),
});

export function catalogRoutes() {
  const app = new Hono<AppContext>();

  // List organizations (paginated, filterable)
  app.get("/", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const query = paginationSchema.parse(c.req.query());

    const where: any = {};

    // Text search
    if (query.q) {
      where.OR = [
        { name: { contains: query.q } },
        { description: { contains: query.q } },
      ];
    }

    // Category filter
    if (query.category) {
      where.category = query.category;
    }

    // Cursor pagination
    if (query.cursor) {
      where.id = { lt: query.cursor };
    }

    // Fetch limit + 1 to detect hasMore
    let organizations = await prisma.organization.findMany({
      where,
      take: query.limit + 1,
      orderBy: { createdAt: "desc" },
      include: {
        owner: { select: { id: true, name: true, image: true, userType: true } },
        ...(user ? {
          ratings: { where: { userId: user.id }, select: { score: true } },
        } : {}),
      },
    });

    const hasMore = organizations.length > query.limit;
    if (hasMore) organizations = organizations.slice(0, query.limit);
    const nextCursor = hasMore ? organizations[organizations.length - 1].id : null;

    // Check saved status if user is authenticated
    let savedIds = new Set<string>();
    if (user) {
      const saved = await prisma.savedItem.findMany({
        where: { userId: user.id, itemType: "catalog", itemId: { in: organizations.map(o => o.id) } },
        select: { itemId: true },
      });
      savedIds = new Set(saved.map(s => s.itemId));
    }

    // JSON filter for ageGroup and specialNeed (post-query for now)
    let filtered = organizations;
    if (query.ageGroup) {
      filtered = filtered.filter(o => {
        const groups = JSON.parse(o.ageGroups);
        return groups.includes(query.ageGroup);
      });
    }
    if (query.specialNeed) {
      filtered = filtered.filter(o => {
        const needs = JSON.parse(o.specialNeeds);
        return needs.includes(query.specialNeed);
      });
    }

    const places = filtered.map(o => ({
      id: o.id,
      name: o.name,
      description: o.description,
      category: o.category,
      address: o.address,
      imageUrl: o.imageUrl,
      averageRating: o.averageRating,
      ratingCount: o.ratingCount,
      tags: JSON.parse(o.tags),
      ageGroups: JSON.parse(o.ageGroups),
      specialNeeds: JSON.parse(o.specialNeeds),
      latitude: o.latitude,
      longitude: o.longitude,
      ownerId: o.ownerId,
      owner: o.owner,
      saved: savedIds.has(o.id),
      userRating: user && (o as any).ratings?.[0]?.score ?? null,
      createdAt: o.createdAt.toISOString(),
    }));

    return c.json({ places, nextCursor });
  });

  // Get single organization
  app.get("/:id", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const org = await prisma.organization.findUnique({
      where: { id },
      include: {
        owner: { select: { id: true, name: true, image: true, userType: true } },
        ...(user ? {
          ratings: { where: { userId: user.id }, select: { score: true } },
        } : {}),
      },
    });

    if (!org) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);

    let saved = false;
    if (user) {
      const savedItem = await prisma.savedItem.findUnique({
        where: { userId_itemType_itemId: { userId: user.id, itemType: "catalog", itemId: id } },
      });
      saved = !!savedItem;
    }

    return c.json({
      place: {
        id: org.id,
        name: org.name,
        description: org.description,
        category: org.category,
        address: org.address,
        imageUrl: org.imageUrl,
        averageRating: org.averageRating,
        ratingCount: org.ratingCount,
        tags: JSON.parse(org.tags),
        ageGroups: JSON.parse(org.ageGroups),
        specialNeeds: JSON.parse(org.specialNeeds),
        latitude: org.latitude,
        longitude: org.longitude,
        ownerId: org.ownerId,
        owner: org.owner,
        saved,
        userRating: user && (org as any).ratings?.[0]?.score ?? null,
        createdAt: org.createdAt.toISOString(),
      },
    });
  });

  // Create organization (professional/educator only)
  app.post("/", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");

    if (!["professional", "educator"].includes(user.userType)) {
      return c.json({ error: "Only professionals and educators can create catalog entries", code: "FORBIDDEN" }, 403);
    }

    const body = createOrganizationSchema.parse(await c.req.json());

    const org = await prisma.organization.create({
      data: {
        name: body.name,
        description: body.description,
        category: body.category,
        address: body.address,
        phone: body.phone,
        email: body.email,
        website: body.website,
        imageUrl: body.imageUrl,
        tags: JSON.stringify(body.tags),
        ageGroups: JSON.stringify(body.ageGroups),
        specialNeeds: JSON.stringify(body.specialNeeds),
        latitude: body.latitude,
        longitude: body.longitude,
        ownerId: user.id,
      },
      include: {
        owner: { select: { id: true, name: true, image: true, userType: true } },
      },
    });

    return c.json({
      place: {
        id: org.id,
        name: org.name,
        description: org.description,
        category: org.category,
        address: org.address,
        imageUrl: org.imageUrl,
        averageRating: org.averageRating,
        ratingCount: org.ratingCount,
        tags: JSON.parse(org.tags),
        ageGroups: JSON.parse(org.ageGroups),
        specialNeeds: JSON.parse(org.specialNeeds),
        latitude: org.latitude,
        longitude: org.longitude,
        ownerId: org.ownerId,
        owner: org.owner,
        saved: false,
        userRating: null,
        createdAt: org.createdAt.toISOString(),
      },
    }, 201);
  });

  // Update organization (owner only)
  app.put("/:id", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const existing = await prisma.organization.findUnique({ where: { id } });
    if (!existing) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);
    if (existing.ownerId !== user.id) return c.json({ error: "Forbidden", code: "FORBIDDEN" }, 403);

    const body = updateOrganizationSchema.parse(await c.req.json());

    const data: any = { ...body };
    if (body.tags) data.tags = JSON.stringify(body.tags);
    if (body.ageGroups) data.ageGroups = JSON.stringify(body.ageGroups);
    if (body.specialNeeds) data.specialNeeds = JSON.stringify(body.specialNeeds);

    await prisma.organization.update({ where: { id }, data });
    return c.json({ success: true });
  });

  // Delete organization (owner only)
  app.delete("/:id", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const existing = await prisma.organization.findUnique({ where: { id } });
    if (!existing) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);
    if (existing.ownerId !== user.id) return c.json({ error: "Forbidden", code: "FORBIDDEN" }, 403);

    await prisma.organization.delete({ where: { id } });
    return c.json({ success: true });
  });

  // Rate organization (upsert)
  app.put("/:id/rating", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");
    const body = ratingSchema.parse(await c.req.json());

    const org = await prisma.organization.findUnique({ where: { id } });
    if (!org) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);

    await prisma.$transaction(async (tx) => {
      // Upsert rating
      await tx.rating.upsert({
        where: { userId_organizationId: { userId: user.id, organizationId: id } },
        create: { userId: user.id, organizationId: id, score: body.score },
        update: { score: body.score },
      });

      // Recalculate average from all ratings
      const agg = await tx.rating.aggregate({
        where: { organizationId: id },
        _avg: { score: true },
        _count: { score: true },
      });

      await tx.organization.update({
        where: { id },
        data: {
          averageRating: agg._avg.score ?? 0,
          ratingCount: agg._count.score,
        },
      });
    });

    return c.json({ success: true });
  });

  return app;
}
```

- [ ] **Step 2: Mount catalog routes in index.ts**

In `backend/src/index.ts`:

```typescript
import { catalogRoutes } from "./routes/catalog";
```

```typescript
app.route("/api/catalog", catalogRoutes());
```

- [ ] **Step 3: Run backend tests**

```bash
pnpm test:backend
```

Expected: All existing tests pass.

- [ ] **Step 4: Commit**

```bash
git add backend/src/routes/catalog.ts backend/src/index.ts
git commit -m "feat(catalog): add catalog CRUD, rating, and listing routes"
```

### Task 15: Create Saved Items Routes

**Files:**
- Create: `backend/src/routes/saved.ts`
- Modify: `backend/src/index.ts`

- [ ] **Step 1: Create saved items routes**

Create `backend/src/routes/saved.ts`:

```typescript
import { Hono } from "hono";
import { z } from "zod";
import { sessionMiddleware } from "../middleware/session";
import type { AppContext } from "../types/context";

const saveItemSchema = z.object({
  itemType: z.enum(["catalog", "promotion"]),
  itemId: z.string().min(1),
});

export function savedRoutes() {
  const app = new Hono<AppContext>();

  // Save item
  app.put("/", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const body = saveItemSchema.parse(await c.req.json());

    await prisma.savedItem.upsert({
      where: {
        userId_itemType_itemId: {
          userId: user.id,
          itemType: body.itemType,
          itemId: body.itemId,
        },
      },
      create: {
        userId: user.id,
        itemType: body.itemType,
        itemId: body.itemId,
      },
      update: {},
    });

    return c.json({ success: true });
  });

  // Unsave item
  app.delete("/:itemType/:itemId", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const itemType = c.req.param("itemType");
    const itemId = c.req.param("itemId");

    await prisma.savedItem.deleteMany({
      where: { userId: user.id, itemType, itemId },
    });

    return c.json({ success: true });
  });

  // List saved items by type (grouped by category)
  app.get("/:itemType", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const itemType = c.req.param("itemType");

    const savedItems = await prisma.savedItem.findMany({
      where: { userId: user.id, itemType },
      orderBy: { createdAt: "desc" },
    });

    if (itemType === "catalog") {
      const orgIds = savedItems.map(s => s.itemId);
      const orgs = await prisma.organization.findMany({
        where: { id: { in: orgIds } },
        include: {
          owner: { select: { id: true, name: true, image: true, userType: true } },
          ratings: { where: { userId: user.id }, select: { score: true } },
        },
      });

      // Group by category
      const grouped: Record<string, any[]> = {};
      for (const org of orgs) {
        const category = org.category;
        if (!grouped[category]) grouped[category] = [];
        grouped[category].push({
          id: org.id,
          name: org.name,
          description: org.description,
          category: org.category,
          address: org.address,
          imageUrl: org.imageUrl,
          averageRating: org.averageRating,
          ratingCount: org.ratingCount,
          tags: JSON.parse(org.tags),
          ageGroups: JSON.parse(org.ageGroups),
          specialNeeds: JSON.parse(org.specialNeeds),
          latitude: org.latitude,
          longitude: org.longitude,
          ownerId: org.ownerId,
          owner: org.owner,
          saved: true,
          userRating: (org as any).ratings?.[0]?.score ?? null,
          createdAt: org.createdAt.toISOString(),
        });
      }

      // Look up category icons
      const categoryNames = Object.keys(grouped);
      const categories = await prisma.catalogCategory.findMany({
        where: { name: { in: categoryNames } },
      });
      const iconMap = Object.fromEntries(categories.map(c => [c.name, c.icon]));

      const groups = Object.entries(grouped).map(([category, items]) => ({
        category,
        icon: iconMap[category] ?? null,
        count: items.length,
        items,
      }));

      return c.json({ groups });
    }

    // Promotion saved items will be handled in Phase 7
    return c.json({ groups: [] });
  });

  return app;
}
```

- [ ] **Step 2: Mount saved routes in index.ts**

In `backend/src/index.ts`:

```typescript
import { savedRoutes } from "./routes/saved";
```

```typescript
app.route("/api/saved", savedRoutes());
```

- [ ] **Step 3: Run backend tests**

```bash
pnpm test:backend
```

Expected: All existing tests pass.

- [ ] **Step 4: Commit**

```bash
git add backend/src/routes/saved.ts backend/src/index.ts
git commit -m "feat: add shared saved items API routes"
```

---

## Chunk 6: Wire Frontend to Backend (Phase 5c)

### Task 16: Wire Catalog Repository to Real API

**Files:**
- Modify: `frontend/lib/features/catalog/data/catalog_repository.dart`

- [ ] **Step 1: Replace mock data with real API calls**

Rewrite `frontend/lib/features/catalog/data/catalog_repository.dart`:

```dart
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/catalog/domain/filter_option.dart';
import 'package:spectrum/features/catalog/domain/place.dart';
import 'package:spectrum/shared/api/api_client.dart';
import 'package:spectrum/shared/domain/paginated_result.dart';
import 'package:spectrum/shared/providers/providers.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.read(apiClientProvider));
});

class CatalogRepository {
  final ApiClient _api;

  CatalogRepository(this._api);

  // --- Filter Options ---

  Future<List<FilterOption>> getCategories() async {
    try {
      final response = await _api.get('/api/filters/catalog-categories');
      final data = response.data as Map<String, dynamic>;
      return (data['categories'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load categories: $e');
      return [];
    }
  }

  Future<List<FilterOption>> getAgeGroups() async {
    try {
      final response = await _api.get('/api/filters/age-groups');
      final data = response.data as Map<String, dynamic>;
      return (data['ageGroups'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load age groups: $e');
      return [];
    }
  }

  Future<List<FilterOption>> getSpecialNeeds() async {
    try {
      final response = await _api.get('/api/filters/special-needs');
      final data = response.data as Map<String, dynamic>;
      return (data['specialNeeds'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load special needs: $e');
      return [];
    }
  }

  // --- Places ---

  Future<PaginatedResult<Place>> getPlaces({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
    Set<String>? ageGroups,
    Set<String>? specialNeeds,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'q': search,
        if (categories != null && categories.isNotEmpty)
          'category': categories.first, // Backend supports single category for now
        if (ageGroups != null && ageGroups.isNotEmpty)
          'ageGroup': ageGroups.first,
        if (specialNeeds != null && specialNeeds.isNotEmpty)
          'specialNeed': specialNeeds.first,
      };

      final response = await _api.get('/api/catalog', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final places = (data['places'] as List)
          .map((j) => Place.fromJson(j as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        items: places,
        nextCursor: data['nextCursor'] as String?,
      );
    } catch (e) {
      log('Failed to load places: $e');
      return const PaginatedResult(items: []);
    }
  }

  Future<Place?> getPlace(String id) async {
    try {
      final response = await _api.get('/api/catalog/$id');
      final data = response.data as Map<String, dynamic>;
      return Place.fromJson(data['place'] as Map<String, dynamic>);
    } catch (e) {
      log('Failed to load place: $e');
      return null;
    }
  }

  Future<void> ratePlace(String id, int score) async {
    try {
      await _api.put('/api/catalog/$id/rating', data: {'score': score});
    } catch (e) {
      log('Failed to rate place: $e');
    }
  }

  Future<void> savePlace(String id) async {
    try {
      await _api.put('/api/saved', data: {'itemType': 'catalog', 'itemId': id});
    } catch (e) {
      log('Failed to save place: $e');
    }
  }

  Future<void> unsavePlace(String id) async {
    try {
      await _api.delete('/api/saved/catalog/$id');
    } catch (e) {
      log('Failed to unsave place: $e');
    }
  }

  Future<List<Place>> getSavedPlaces() async {
    try {
      final response = await _api.get('/api/saved/catalog');
      final data = response.data as Map<String, dynamic>;
      final groups = data['groups'] as List;
      final places = <Place>[];
      for (final group in groups) {
        final items = (group['items'] as List)
            .map((j) => Place.fromJson(j as Map<String, dynamic>))
            .toList();
        places.addAll(items);
      }
      return places;
    } catch (e) {
      log('Failed to load saved places: $e');
      return [];
    }
  }
}
```

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/catalog/data/catalog_repository.dart
git commit -m "feat(catalog): wire repository to real API endpoints"
```

### Task 17: Create OpenAPI Contract

**Files:**
- Create: `contracts/catalog.yaml`

- [ ] **Step 1: Create catalog OpenAPI contract**

Create `contracts/catalog.yaml` documenting the endpoints, request/response schemas. Follow the format of existing `contracts/community.yaml`.

```yaml
openapi: 3.1.0
info:
  title: Spectrum Catalog API
  version: 1.0.0

paths:
  /api/catalog:
    get:
      summary: List places
      parameters:
        - name: cursor
          in: query
          schema: { type: string }
        - name: limit
          in: query
          schema: { type: integer, minimum: 1, maximum: 50, default: 20 }
        - name: q
          in: query
          schema: { type: string }
        - name: category
          in: query
          schema: { type: string }
        - name: ageGroup
          in: query
          schema: { type: string }
        - name: specialNeed
          in: query
          schema: { type: string }
      responses:
        "200":
          description: Paginated list of places
          content:
            application/json:
              schema:
                type: object
                properties:
                  places:
                    type: array
                    items: { $ref: "#/components/schemas/Place" }
                  nextCursor:
                    type: string
                    nullable: true
    post:
      summary: Create place (professional/educator only)
      security: [{ bearer: [] }]
      requestBody:
        content:
          application/json:
            schema: { $ref: "#/components/schemas/CreatePlace" }
      responses:
        "201":
          description: Created place
          content:
            application/json:
              schema:
                type: object
                properties:
                  place: { $ref: "#/components/schemas/Place" }

  /api/catalog/{id}:
    get:
      summary: Get place details
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        "200":
          description: Place details
          content:
            application/json:
              schema:
                type: object
                properties:
                  place: { $ref: "#/components/schemas/Place" }
    put:
      summary: Update place (owner only)
      security: [{ bearer: [] }]
      responses:
        "200":
          description: Success
    delete:
      summary: Delete place (owner only)
      security: [{ bearer: [] }]
      responses:
        "200":
          description: Success

  /api/catalog/{id}/rating:
    put:
      summary: Rate place 1-5
      security: [{ bearer: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                score: { type: integer, minimum: 1, maximum: 5 }
              required: [score]
      responses:
        "200":
          description: Rating saved

  /api/filters/catalog-categories:
    get:
      summary: List catalog categories
      responses:
        "200":
          content:
            application/json:
              schema:
                type: object
                properties:
                  categories:
                    type: array
                    items: { $ref: "#/components/schemas/FilterOption" }

  /api/filters/age-groups:
    get:
      summary: List age groups
      responses:
        "200":
          content:
            application/json:
              schema:
                type: object
                properties:
                  ageGroups:
                    type: array
                    items: { $ref: "#/components/schemas/FilterOption" }

  /api/filters/special-needs:
    get:
      summary: List special needs
      responses:
        "200":
          content:
            application/json:
              schema:
                type: object
                properties:
                  specialNeeds:
                    type: array
                    items: { $ref: "#/components/schemas/FilterOption" }

  /api/saved:
    put:
      summary: Save item
      security: [{ bearer: [] }]
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                itemType: { type: string, enum: [catalog, promotion] }
                itemId: { type: string }
              required: [itemType, itemId]
      responses:
        "200":
          description: Saved

  /api/saved/{itemType}/{itemId}:
    delete:
      summary: Unsave item
      security: [{ bearer: [] }]
      responses:
        "200":
          description: Unsaved

  /api/saved/{itemType}:
    get:
      summary: List saved items grouped by category
      security: [{ bearer: [] }]
      responses:
        "200":
          content:
            application/json:
              schema:
                type: object
                properties:
                  groups:
                    type: array
                    items:
                      type: object
                      properties:
                        category: { type: string }
                        icon: { type: string, nullable: true }
                        count: { type: integer }
                        items: { type: array }

components:
  schemas:
    Place:
      type: object
      properties:
        id: { type: string }
        name: { type: string }
        description: { type: string, nullable: true }
        category: { type: string }
        address: { type: string, nullable: true }
        imageUrl: { type: string, nullable: true }
        averageRating: { type: number }
        ratingCount: { type: integer }
        tags: { type: array, items: { type: string } }
        ageGroups: { type: array, items: { type: string } }
        specialNeeds: { type: array, items: { type: string } }
        latitude: { type: number, nullable: true }
        longitude: { type: number, nullable: true }
        ownerId: { type: string }
        owner: { $ref: "#/components/schemas/Author" }
        saved: { type: boolean }
        userRating: { type: integer, nullable: true, minimum: 1, maximum: 5 }
        createdAt: { type: string, format: date-time }

    CreatePlace:
      type: object
      required: [name, category]
      properties:
        name: { type: string, maxLength: 200 }
        description: { type: string, maxLength: 5000 }
        category: { type: string }
        address: { type: string }
        imageUrl: { type: string, format: uri }
        tags: { type: array, items: { type: string }, maxItems: 10 }
        ageGroups: { type: array, items: { type: string } }
        specialNeeds: { type: array, items: { type: string } }

    Author:
      type: object
      properties:
        id: { type: string }
        name: { type: string }
        image: { type: string, nullable: true }
        userType: { type: string }

    FilterOption:
      type: object
      properties:
        id: { type: string }
        name: { type: string }
        icon: { type: string, nullable: true }

  securitySchemes:
    bearer:
      type: http
      scheme: bearer
```

- [ ] **Step 2: Commit**

```bash
git add contracts/catalog.yaml
git commit -m "feat(catalog): add OpenAPI contract for catalog and filter endpoints"
```

### Task 18: Final Verification

- [ ] **Step 1: Run full Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 2: Run backend tests**

```bash
pnpm test:backend
```

Expected: All tests pass.

- [ ] **Step 3: Verify app builds**

```bash
cd frontend && flutter build ios --no-codesign 2>&1 | tail -5
```

Expected: Build succeeds.

- [ ] **Step 4: Final commit if any outstanding changes**

```bash
git status
```

If clean, Phase 5 is complete.
