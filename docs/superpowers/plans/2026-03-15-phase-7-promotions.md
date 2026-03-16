# Phase 7 — Promotions Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Promotions feature (promotion directory with category filtering, countdown timers, like/save/claim actions, saved promotions) following Community's clean architecture patterns. Reuses shared components established by Phase 5 (Catalog): Author model, PaginatedResult, FilterPopup, FilterOption/FilterGroup, saved items routes.

**Architecture:** Feature-based clean architecture: Forui + Riverpod frontend with repository pattern, Hono + Prisma + D1 backend. Three sub-phases: 7a (Frontend UI with mock data), 7b (Backend), 7c (Wire up). Shared components from Phase 5 are imported directly — no duplication.

**Tech Stack:** Flutter, Forui, Riverpod, Dio, GoRouter (frontend); Hono, Prisma, D1, Zod, Vitest (backend)

**Spec:** `docs/superpowers/specs/2026-03-15-catalog-promotions-design.md`

---

## CRITICAL: Implementation Notes

**Same notes as Phase 5 plan apply here.** The code is reference-quality — verify Forui APIs against context7 docs before using.

### Forui API Patterns (check `feed_screen.dart` and `post_card.dart` for reference)

1. **FTabs**: Use `FTabs(expands: true, style: ..., control: FTabControl.lifted(...), children: [FTabEntry(label: ..., child: ...)])` — NOT `FTabs(tabs: [...])` or `content:`.
2. **FTextField**: Use `FTextField(control: FTextFieldControl.managed(controller: ..., onChange: ...), hint: ..., prefixBuilder: ..., suffixBuilder: ...)` — NOT `FTextField(controller: ..., onChange: ..., prefix: ...)`.
3. **FButton**: Use `FButton(onPress: ..., prefix: ..., child: ...)` with `variant: FButtonVariant.outline` — NOT `label:` or `style: FButtonStyle.outline`.
4. **Screen wrapper**: Wrap screens in the app's `Screen(body: ...)` widget, matching `FeedScreen` pattern.

### Backend Patterns (check `community.ts` and `index.ts` for reference)

1. **Hono type**: Use `new Hono<{ Bindings: AppBindings; Variables: AppVariables }>()` — NOT `new Hono<AppContext>()`.
2. **Import extensions**: Always use `.js` extensions: `from "../middleware/session.js"`.
3. **Cursor pagination**: Use Prisma's `cursor: { id: cursor }, skip: 1` pattern.
4. **Validation**: Use `zValidator("json", schema)` middleware from `@hono/zod-validator`.

### Other

- **Timer disposal**: Add `ref.onDispose(() => _debounce?.cancel())` in PromotionsNotifier.
- **Import path**: Use `package:spectrum/shared/providers/api_provider.dart` — NOT `shared/providers/providers.dart`.
- **Router**: Preserve `name: 'promotions'` on the route definition.
- **Detail screen**: Use `Screen(appBar: ..., body: ...)` widget wrapper — NOT raw `Scaffold`. Raw Scaffold loses the gradient background.
- **copyWith nextCursor**: Use `String? Function()? nextCursor` pattern from `FeedState.copyWith` — NOT plain `String? nextCursor`. The simple approach can't distinguish "keep current" from "set to null", breaking pagination termination.
- **toggleSave error handling**: Add try/catch with revert logic (same pattern as `toggleLike`) — fire-and-forget without revert leaves UI out of sync on failure.
- **Seed script**: Phase 5 creates `backend/src/db/seed-filters.ts`. If that file doesn't exist yet, check for `backend/src/db/seed.ts` and add there instead.
- **intl package**: Verify `intl` is in `pubspec.yaml` before using `DateFormat`. It should already be there from Phase 3.
- **Multi-select category filter**: MVP sends only the first selected category to the API. Document as TODO for multi-select support later.

### Phase 5 Prerequisite Verification

Before starting ANY task in this plan, verify Phase 5 artifacts exist:

```bash
cd frontend && dart analyze 2>&1 | head -5
ls -la lib/shared/domain/author.dart lib/shared/domain/paginated_result.dart lib/shared/widgets/filter_popup.dart lib/features/catalog/domain/filter_option.dart
```

If any are missing, Phase 5 must be completed first.

---

**Prerequisites:** Phase 5 (Catalog) must be complete. The following shared components exist:
- `frontend/lib/shared/domain/author.dart` — Author model
- `frontend/lib/shared/domain/paginated_result.dart` — PaginatedResult<T>
- `frontend/lib/shared/widgets/filter_popup.dart` — FilterPopup + FilterTriggerButton
- `frontend/lib/features/catalog/domain/filter_option.dart` — FilterOption + FilterGroup
- `backend/src/routes/saved.ts` — Saved items API routes (PUT /api/saved, DELETE /api/saved/:itemType/:itemId, GET /api/saved/:itemType)
- `backend/src/routes/filters.ts` — Filter options routes (to be extended)
- `frontend/lib/shared/widgets/promotion_carousel.dart` — Existing `_formatTimeRemaining` pattern to reuse

---

## Chunk 1: Domain Models + Provider + Repository Mock (Phase 7a — Part 1)

### Task 1: Create Promotion Domain Model

**Files:**
- Create: `frontend/lib/features/promotions/domain/promotion.dart`

- [ ] **Step 1: Create Promotion model**

Create `frontend/lib/features/promotions/domain/promotion.dart`:

```dart
import 'package:spectrum/shared/domain/author.dart';

class Promotion {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? discount;
  final String store;
  final String? brandLogoUrl;
  final String? imageUrl;
  final DateTime? expiresAt;
  final DateTime validFrom;
  final String? organizationId;
  final String createdById;
  final Author createdBy;
  final int likesCount;
  final bool liked;
  final bool saved;
  final bool claimed;
  final DateTime createdAt;

  const Promotion({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.discount,
    required this.store,
    this.brandLogoUrl,
    this.imageUrl,
    this.expiresAt,
    required this.validFrom,
    this.organizationId,
    required this.createdById,
    required this.createdBy,
    this.likesCount = 0,
    this.liked = false,
    this.saved = false,
    this.claimed = false,
    required this.createdAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'General',
      discount: json['discount'] as String?,
      store: json['store'] as String,
      brandLogoUrl: json['brandLogoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      validFrom: DateTime.parse(json['validFrom'] as String),
      organizationId: json['organizationId'] as String?,
      createdById: json['createdById'] as String,
      createdBy: Author.fromJson(json['createdBy'] as Map<String, dynamic>),
      likesCount: json['likesCount'] as int? ?? 0,
      liked: json['liked'] as bool? ?? false,
      saved: json['saved'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Promotion copyWith({
    bool? liked,
    int? likesCount,
    bool? saved,
    bool? claimed,
  }) {
    return Promotion(
      id: id,
      title: title,
      description: description,
      category: category,
      discount: discount,
      store: store,
      brandLogoUrl: brandLogoUrl,
      imageUrl: imageUrl,
      expiresAt: expiresAt,
      validFrom: validFrom,
      organizationId: organizationId,
      createdById: createdById,
      createdBy: createdBy,
      likesCount: likesCount ?? this.likesCount,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      claimed: claimed ?? this.claimed,
      createdAt: createdAt,
    );
  }

  /// Whether this is a permanent promotion (no expiry).
  bool get isPermanent => expiresAt == null;

  /// Whether this promotion has expired.
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Format the time remaining for display.
  /// Reuses the pattern from PromotionCarousel._formatTimeRemaining.
  String get timeRemaining {
    if (expiresAt == null) return '';
    final now = DateTime.now();
    final diff = expiresAt!.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Ending soon';
  }
}
```

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors. Promotion model imports shared Author from Phase 5.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/promotions/domain/promotion.dart
git commit -m "feat(promotions): add Promotion domain model with countdown helper"
```

### Task 2: Create Promotions Repository (Mock Data)

**Files:**
- Create: `frontend/lib/features/promotions/data/promotions_repository.dart`

The repository starts with mock data. In Phase 7c it will be wired to real API calls.

- [ ] **Step 1: Create promotions repository with mock data**

Create `frontend/lib/features/promotions/data/promotions_repository.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/catalog/domain/filter_option.dart';
import 'package:spectrum/features/promotions/domain/promotion.dart';
import 'package:spectrum/shared/domain/author.dart';
import 'package:spectrum/shared/domain/paginated_result.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  return PromotionsRepository();
});

class PromotionsRepository {
  // --- Mock Filter Options ---

  Future<List<FilterOption>> getPromotionCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      FilterOption(id: '1', name: 'Health & Wellness', icon: 'health_and_safety'),
      FilterOption(id: '2', name: 'Education', icon: 'school'),
      FilterOption(id: '3', name: 'Entertainment', icon: 'theater_comedy'),
      FilterOption(id: '4', name: 'Food & Dining', icon: 'restaurant'),
      FilterOption(id: '5', name: 'Services', icon: 'miscellaneous_services'),
    ];
  }

  // --- Mock Promotions ---

  static final _mockAuthor = Author(
    id: 'promo-owner-1',
    name: 'Spectrum Partners',
    userType: 'professional',
  );

  static final _mockPromotions = [
    Promotion(
      id: 'p1',
      title: 'Free Initial Consultation for ABA Therapy',
      description:
          'Book a free 30-minute consultation with our certified ABA therapists. '
          'We specialize in working with children on the autism spectrum, providing '
          'individualized behavior plans and parent training.',
      category: 'Health & Wellness',
      discount: 'FREE',
      store: 'Bright Futures ABA',
      brandLogoUrl: null,
      imageUrl: null,
      expiresAt: DateTime.now().add(const Duration(days: 14)),
      validFrom: DateTime.now().subtract(const Duration(days: 7)),
      organizationId: '4',
      createdById: 'promo-owner-1',
      createdBy: _mockAuthor,
      likesCount: 42,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Promotion(
      id: 'p2',
      title: '20% Off Sensory-Friendly Dining Experience',
      description:
          'Enjoy our quiet dining experience with dim lighting, noise-canceling '
          'headphones available, and a picture menu. Valid for dine-in only.',
      category: 'Food & Dining',
      discount: '20% OFF',
      store: 'The Sensory Café',
      brandLogoUrl: null,
      imageUrl: null,
      expiresAt: DateTime.now().add(const Duration(hours: 5)),
      validFrom: DateTime.now().subtract(const Duration(days: 3)),
      organizationId: '5',
      createdById: 'promo-owner-1',
      createdBy: _mockAuthor,
      likesCount: 18,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Promotion(
      id: 'p3',
      title: 'Back-to-School Special: Sensory Kit Bundle',
      description:
          'Complete sensory kit with fidget tools, noise-canceling earmuffs, '
          'weighted lap pad, and visual schedule cards. Perfect for the new school year.',
      category: 'Education',
      discount: '30% OFF',
      store: 'Spectrum Supplies',
      brandLogoUrl: null,
      imageUrl: null,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      validFrom: DateTime.now().subtract(const Duration(days: 5)),
      createdById: 'promo-owner-1',
      createdBy: _mockAuthor,
      likesCount: 67,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Promotion(
      id: 'p4',
      title: 'Family Movie Night — Sensory Screening',
      description:
          'Monthly sensory-friendly movie screenings with reduced volume, '
          'brighter lights, and freedom to move around. All families welcome.',
      category: 'Entertainment',
      discount: null,
      store: 'Bay Cinema',
      brandLogoUrl: null,
      imageUrl: null,
      expiresAt: null, // Permanent promotion
      validFrom: DateTime.now().subtract(const Duration(days: 60)),
      createdById: 'promo-owner-1',
      createdBy: _mockAuthor,
      likesCount: 95,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Promotion(
      id: 'p5',
      title: 'Free Developmental Screening for Ages 2-5',
      description:
          'Quick 15-minute developmental screening to identify early signs of '
          'autism. No referral needed. Walk-ins welcome on Wednesdays.',
      category: 'Health & Wellness',
      discount: 'FREE',
      store: 'Bay Area Discovery Center',
      brandLogoUrl: null,
      imageUrl: null,
      expiresAt: null, // Permanent promotion
      validFrom: DateTime.now().subtract(const Duration(days: 90)),
      organizationId: '1',
      createdById: 'promo-owner-1',
      createdBy: _mockAuthor,
      likesCount: 124,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Promotion(
      id: 'p6',
      title: 'Home Organization Service — Autism-Friendly Spaces',
      description:
          'Professional organizer specializing in creating structured, calming '
          'environments for children with autism. Includes visual labels and zones.',
      category: 'Services',
      discount: '15% OFF',
      store: 'Calm Spaces Co.',
      brandLogoUrl: null,
      imageUrl: null,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      validFrom: DateTime.now().subtract(const Duration(days: 2)),
      createdById: 'promo-owner-1',
      createdBy: _mockAuthor,
      likesCount: 31,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<PaginatedResult<Promotion>> getPromotions({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = List<Promotion>.from(_mockPromotions);

    // Text search
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              (p.description?.toLowerCase().contains(q) ?? false) ||
              p.store.toLowerCase().contains(q))
          .toList();
    }

    // Category filter
    if (categories != null && categories.isNotEmpty) {
      filtered =
          filtered.where((p) => categories.contains(p.category)).toList();
    }

    // Hide expired promotions (same as backend will do)
    filtered = filtered.where((p) => !p.isExpired).toList();

    return PaginatedResult(items: filtered, nextCursor: null);
  }

  Future<Promotion?> getPromotion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockPromotions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<({bool liked, int likesCount})> likePromotion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final promo = _mockPromotions.firstWhere((p) => p.id == id);
    return (liked: true, likesCount: promo.likesCount + 1);
  }

  Future<({bool liked, int likesCount})> unlikePromotion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final promo = _mockPromotions.firstWhere((p) => p.id == id);
    return (liked: false, likesCount: promo.likesCount - 1);
  }

  Future<void> claimPromotion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op. Real API will record claim.
  }

  Future<void> savePromotion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op
  }

  Future<void> unsavePromotion(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: no-op
  }

  Future<List<Promotion>> getSavedPromotions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: return first 2 promotions as "saved"
    return _mockPromotions
        .take(2)
        .map((p) => Promotion(
              id: p.id,
              title: p.title,
              description: p.description,
              category: p.category,
              discount: p.discount,
              store: p.store,
              brandLogoUrl: p.brandLogoUrl,
              imageUrl: p.imageUrl,
              expiresAt: p.expiresAt,
              validFrom: p.validFrom,
              organizationId: p.organizationId,
              createdById: p.createdById,
              createdBy: p.createdBy,
              likesCount: p.likesCount,
              saved: true,
              createdAt: p.createdAt,
            ))
        .toList();
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
git add frontend/lib/features/promotions/data/promotions_repository.dart
git commit -m "feat(promotions): add repository with mock data"
```

### Task 3: Create Promotions Provider

**Files:**
- Create: `frontend/lib/features/promotions/presentation/providers/promotions_provider.dart`

Follows the same Riverpod Notifier pattern as `catalog_provider.dart` and `feed_provider.dart`.

- [ ] **Step 1: Create promotions provider**

Create `frontend/lib/features/promotions/presentation/providers/promotions_provider.dart`:

```dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/catalog/domain/filter_option.dart';
import 'package:spectrum/features/promotions/data/promotions_repository.dart';
import 'package:spectrum/features/promotions/domain/promotion.dart';

// --- Filter Options Provider ---

final promotionFilterOptionsProvider =
    FutureProvider<PromotionFilterOptions>((ref) async {
  final repo = ref.read(promotionsRepositoryProvider);
  final categories = await repo.getPromotionCategories();
  return PromotionFilterOptions(categories: categories);
});

class PromotionFilterOptions {
  final List<FilterOption> categories;

  const PromotionFilterOptions({required this.categories});

  List<FilterGroup> toFilterGroups() => [
        FilterGroup(label: 'Categories', options: categories),
      ];
}

// --- Promotions Feed Provider ---

class PromotionsState {
  final List<Promotion> promotions;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final Map<String, Set<String>> filters; // groupLabel -> selected option names

  const PromotionsState({
    this.promotions = const [],
    this.nextCursor,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filters = const {},
  });

  int get activeFilterCount =>
      filters.values.fold(0, (sum, set) => sum + set.length);

  bool get hasActiveFilters => activeFilterCount > 0;

  PromotionsState copyWith({
    List<Promotion>? promotions,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    Map<String, Set<String>>? filters,
  }) {
    return PromotionsState(
      promotions: promotions ?? this.promotions,
      nextCursor: nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
    );
  }
}

final promotionsProvider =
    NotifierProvider<PromotionsNotifier, PromotionsState>(
        PromotionsNotifier.new);

class PromotionsNotifier extends Notifier<PromotionsState> {
  Timer? _debounce;

  @override
  PromotionsState build() {
    ref.onDispose(() => _debounce?.cancel());
    _loadInitial();
    return const PromotionsState();
  }

  PromotionsRepository get _repo => ref.read(promotionsRepositoryProvider);

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.getPromotions(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: state.filters['Categories'],
      );
      state = state.copyWith(
        promotions: result.items,
        nextCursor: result.nextCursor,
        isLoading: false,
      );
    } catch (e) {
      log('Failed to load promotions: $e');
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
      final result = await _repo.getPromotions(
        cursor: state.nextCursor,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: state.filters['Categories'],
      );
      state = state.copyWith(
        promotions: [...state.promotions, ...result.items],
        nextCursor: result.nextCursor,
        isLoadingMore: false,
      );
    } catch (e) {
      log('Failed to load more promotions: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleLike(String promotionId) async {
    final index = state.promotions.indexWhere((p) => p.id == promotionId);
    if (index == -1) return;
    final promo = state.promotions[index];

    // Optimistic update
    final updatedPromo = promo.copyWith(
      liked: !promo.liked,
      likesCount: promo.liked ? promo.likesCount - 1 : promo.likesCount + 1,
    );
    final newList = List<Promotion>.from(state.promotions);
    newList[index] = updatedPromo;
    state = state.copyWith(promotions: newList);

    try {
      final result = promo.liked
          ? await _repo.unlikePromotion(promotionId)
          : await _repo.likePromotion(promotionId);

      // Reconcile with server response
      final reconciledPromo = updatedPromo.copyWith(
        liked: result.liked,
        likesCount: result.likesCount,
      );
      final reconciledList = List<Promotion>.from(state.promotions);
      final reconciledIndex =
          reconciledList.indexWhere((p) => p.id == promotionId);
      if (reconciledIndex != -1) {
        reconciledList[reconciledIndex] = reconciledPromo;
        state = state.copyWith(promotions: reconciledList);
      }
    } catch (e) {
      // Revert on error
      final revertList = List<Promotion>.from(state.promotions);
      final revertIndex = revertList.indexWhere((p) => p.id == promotionId);
      if (revertIndex != -1) {
        revertList[revertIndex] = promo;
        state = state.copyWith(promotions: revertList);
      }
    }
  }

  void toggleSave(String promotionId) {
    final index = state.promotions.indexWhere((p) => p.id == promotionId);
    if (index == -1) return;
    final promo = state.promotions[index];
    final updated = promo.copyWith(saved: !promo.saved);
    final newList = List<Promotion>.from(state.promotions);
    newList[index] = updated;
    state = state.copyWith(promotions: newList);

    // Fire and forget
    if (updated.saved) {
      _repo.savePromotion(promotionId);
    } else {
      _repo.unsavePromotion(promotionId);
    }
  }

  Future<void> claimPromotion(String promotionId) async {
    final index = state.promotions.indexWhere((p) => p.id == promotionId);
    if (index == -1) return;
    final promo = state.promotions[index];
    if (promo.claimed) return; // Already claimed

    try {
      await _repo.claimPromotion(promotionId);
      final updated = promo.copyWith(claimed: true);
      final newList = List<Promotion>.from(state.promotions);
      newList[index] = updated;
      state = state.copyWith(promotions: newList);
    } catch (e) {
      log('Failed to claim promotion: $e');
    }
  }
}

// --- Saved Promotions Provider ---

final savedPromotionsProvider =
    FutureProvider<Map<String, List<Promotion>>>((ref) async {
  final repo = ref.read(promotionsRepositoryProvider);
  final promotions = await repo.getSavedPromotions();
  final grouped = <String, List<Promotion>>{};
  for (final promo in promotions) {
    grouped.putIfAbsent(promo.category, () => []).add(promo);
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
git add frontend/lib/features/promotions/presentation/providers/promotions_provider.dart
git commit -m "feat(promotions): add PromotionsNotifier, filter options, and saved promotions providers"
```

---

## Chunk 2: Promotion Card + Screens (Phase 7a — Part 2)

### Task 4: Create Promotion Card Widget

**Files:**
- Create: `frontend/lib/features/promotions/presentation/widgets/promotion_card.dart`

The promotion card shows: discount badge (top-left pill), brand logo + store name, title, countdown timer, like/save/claim action buttons row.

- [ ] **Step 1: Create promotion card widget**

Create `frontend/lib/features/promotions/presentation/widgets/promotion_card.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:spectrum/core/constants/app_colors.dart';
import 'package:spectrum/core/constants/app_spacing.dart';
import 'package:spectrum/features/promotions/domain/promotion.dart';

class PromotionCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onClaim;

  const PromotionCard({
    super.key,
    required this.promotion,
    this.onTap,
    this.onLike,
    this.onSave,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return GestureDetector(
      onTap: onTap,
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: discount badge + brand logo + store name
              Row(
                children: [
                  // Discount badge
                  if (promotion.discount != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.badgeRadius),
                      ),
                      child: Text(
                        promotion.discount!,
                        style: typography.xs.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  // Brand logo
                  FAvatar.raw(
                    size: 28,
                    child: promotion.brandLogoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: promotion.brandLogoUrl!,
                            fit: BoxFit.cover,
                            width: 28,
                            height: 28,
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                promotion.store.isNotEmpty
                                    ? promotion.store[0].toUpperCase()
                                    : '?',
                                style: typography.xs.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              promotion.store.isNotEmpty
                                  ? promotion.store[0].toUpperCase()
                                  : '?',
                              style: typography.xs.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      promotion.store,
                      style: typography.xs.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                promotion.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: typography.base.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Countdown timer (only for non-permanent promos)
              if (!promotion.isPermanent) ...[
                _CountdownBadge(promotion: promotion),
                const SizedBox(height: AppSpacing.xs),
              ],

              // Action buttons row: Like + Save + Claim
              Row(
                children: [
                  _ActionButton(
                    icon: promotion.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${promotion.likesCount}',
                    color: promotion.liked
                        ? AppColors.accent1
                        : colors.mutedForeground,
                    onPress: onLike,
                  ),
                  _ActionButton(
                    icon: promotion.saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: promotion.saved ? 'Saved' : 'Save',
                    color: promotion.saved
                        ? AppColors.primary
                        : colors.mutedForeground,
                    onPress: onSave,
                  ),
                  const Spacer(),
                  if (!promotion.claimed)
                    FButton(
                      size: FButtonSizeVariant.sm,
                      onPress: onClaim,
                      child: const Text('Claim'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.badgeRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Claimed',
                            style: typography.xs.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final Promotion promotion;

  const _CountdownBadge({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final timeText = promotion.timeRemaining;
    if (timeText.isEmpty) return const SizedBox.shrink();

    // Use warning color for urgent promos (< 24h)
    final isUrgent = promotion.expiresAt != null &&
        promotion.expiresAt!.difference(DateTime.now()).inHours < 24;

    final color = isUrgent ? AppColors.accent1 : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: typography.xs.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPress;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: FButtonVariant.ghost,
      size: FButtonSizeVariant.sm,
      mainAxisSize: MainAxisSize.min,
      onPress: onPress,
      prefix: Icon(icon, color: color, size: 18),
      child: Text(
        label,
        style: context.theme.typography.xs.copyWith(color: color),
      ),
    );
  }
}
```

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors. Check Forui docs via context7 if FButton size/variant APIs differ.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/promotions/presentation/widgets/promotion_card.dart
git commit -m "feat(promotions): add PromotionCard widget with discount badge, countdown, and actions"
```

### Task 5: Create Promotions Screen (Browse + Saved Tabs)

**Files:**
- Create: `frontend/lib/features/promotions/presentation/screens/promotions_screen.dart`

Follows the two-tab pattern from `catalog_screen.dart` and `feed_screen.dart`. Browse tab has search + filter popup (1 group: Promotion Categories) + paginated list. Saved tab shows grouped promotions.

- [ ] **Step 1: Create promotions screen**

Create `frontend/lib/features/promotions/presentation/screens/promotions_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum/core/constants/app_colors.dart';
import 'package:spectrum/core/constants/app_spacing.dart';
import 'package:spectrum/features/promotions/domain/promotion.dart';
import 'package:spectrum/features/promotions/presentation/providers/promotions_provider.dart';
import 'package:spectrum/features/promotions/presentation/widgets/promotion_card.dart';
import 'package:spectrum/shared/widgets/filter_popup.dart';
import 'package:spectrum/shared/widgets/screen.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterPopup() {
    final promoState = ref.read(promotionsProvider);
    final filterOptions = ref.read(promotionFilterOptionsProvider);

    filterOptions.whenData((options) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: FilterPopup(
            filterGroups: options.toFilterGroups(),
            selectedFilters: promoState.filters,
            onApply: (filters) {
              ref.read(promotionsProvider.notifier).setFilters(filters);
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

    return Screen(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: FTabs(
          expands: true,
          style: FTabsStyle(
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            labelTextStyle: FVariants.from(
              theme.typography.sm.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colors.mutedForeground,
              ),
              variants: {
                [.selected]: TextStyleDelta.delta(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              },
            ),
            indicatorDecoration: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primary, width: 3),
            ),
            indicatorSize: FTabBarIndicatorSize.label,
            height: theme.tabsStyle.height,
            spacing: 0,
            focusedOutlineStyle: theme.tabsStyle.focusedOutlineStyle,
          ),
          children: [
            FTabEntry(
              label: const Text('Browse'),
              child: _BrowseTab(
                searchController: _searchController,
                onFilterTap: _showFilterPopup,
              ),
            ),
            FTabEntry(
              label: const Text('Saved'),
              child: const _SavedTab(),
            ),
          ],
        ),
      ),
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
    final state = ref.watch(promotionsProvider);
    final theme = context.theme;

    return Column(
      children: [
        // Search bar + filter button
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: searchController,
                    onChange: (value) {
                      ref
                          .read(promotionsProvider.notifier)
                          .searchDebounced(value.text);
                    },
                  ),
                  hint: 'Search promotions...',
                  prefixBuilder: (context, style, variants) => Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: IconTheme(
                      data: style.iconStyle.resolve(variants),
                      child: const Icon(Icons.search_rounded),
                    ),
                  ),
                  suffixBuilder: searchController.text.isEmpty
                      ? null
                      : (context, style, variants) => IconButton(
                            onPressed: () {
                              searchController.clear();
                              ref
                                  .read(promotionsProvider.notifier)
                                  .search('');
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: style.iconStyle.resolve(variants).color,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${state.promotions.length} Offers Found',
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Promotions list
        Expanded(
          child: state.isLoading
              ? const Center(child: FCircularProgress())
              : state.promotions.isEmpty
                  ? _EmptyState(
                      icon: Icons.local_offer_outlined,
                      title: 'No promotions found',
                      subtitle: state.hasActiveFilters
                          ? 'Try adjusting your filters'
                          : 'Try a different search term',
                    )
                  : RefreshIndicator(
                      onRefresh:
                          ref.read(promotionsProvider.notifier).refresh,
                      child:
                          NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification &&
                              notification.metrics.extentAfter < 200) {
                            ref
                                .read(promotionsProvider.notifier)
                                .loadMore();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            0,
                            AppSpacing.sm,
                            0,
                            96,
                          ),
                          itemCount: state.promotions.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.promotions.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: Center(
                                    child: FCircularProgress()),
                              );
                            }
                            final promo = state.promotions[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: PromotionCard(
                                promotion: promo,
                                onTap: () => context.push(
                                  '/promotions/${promo.id}',
                                ),
                                onLike: () => ref
                                    .read(promotionsProvider.notifier)
                                    .toggleLike(promo.id),
                                onSave: () => ref
                                    .read(promotionsProvider.notifier)
                                    .toggleSave(promo.id),
                                onClaim: () => ref
                                    .read(promotionsProvider.notifier)
                                    .claimPromotion(promo.id),
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
    final savedAsync = ref.watch(savedPromotionsProvider);
    final theme = context.theme;

    return savedAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) =>
          const Center(child: Text('Failed to load saved promotions')),
      data: (grouped) {
        if (grouped.isEmpty) {
          return const _EmptyState(
            icon: Icons.bookmark_outline,
            title: 'No saved offers yet',
            subtitle: 'Bookmark promotions to see them here',
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
                        Icons.local_offer,
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
              // Promotion cards in this category
              ...entry.value.map(
                (promo) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PromotionCard(
                    promotion: promo,
                    onTap: () =>
                        context.push('/promotions/${promo.id}'),
                    onLike: () => ref
                        .read(promotionsProvider.notifier)
                        .toggleLike(promo.id),
                    onSave: () => ref
                        .read(promotionsProvider.notifier)
                        .toggleSave(promo.id),
                    onClaim: () => ref
                        .read(promotionsProvider.notifier)
                        .claimPromotion(promo.id),
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
          Icon(icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style:
                theme.typography.base.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.typography.sm
                .copyWith(color: AppColors.textSecondary),
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

Expected: No errors. If Forui FTabs API differs (e.g. `tabs:` vs `children:`, `content` vs `child`), check Forui docs via context7 and adjust.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/promotions/presentation/screens/promotions_screen.dart
git commit -m "feat(promotions): add PromotionsScreen with browse and saved tabs"
```

### Task 6: Create Promotion Detail Screen

**Files:**
- Create: `frontend/lib/features/promotions/presentation/screens/promotion_detail_screen.dart`

Shows full promotion info with: image + discount badge overlay, brand logo + store name, title, full description, countdown timer, validity info, like/save/claim actions, link to catalog place if organizationId is set.

- [ ] **Step 1: Create promotion detail screen**

Create `frontend/lib/features/promotions/presentation/screens/promotion_detail_screen.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spectrum/core/constants/app_colors.dart';
import 'package:spectrum/core/constants/app_spacing.dart';
import 'package:spectrum/features/promotions/data/promotions_repository.dart';
import 'package:spectrum/features/promotions/domain/promotion.dart';
import 'package:spectrum/features/promotions/presentation/providers/promotions_provider.dart';

final promotionDetailProvider =
    FutureProvider.family<Promotion?, String>((ref, id) async {
  final repo = ref.read(promotionsRepositoryProvider);
  return repo.getPromotion(id);
});

class PromotionDetailScreen extends ConsumerWidget {
  final String promotionId;

  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoAsync = ref.watch(promotionDetailProvider(promotionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: promoAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) =>
            const Center(child: Text('Failed to load promotion')),
        data: (promo) {
          if (promo == null) {
            return const Center(child: Text('Promotion not found'));
          }
          return _PromotionDetailContent(promotion: promo);
        },
      ),
    );
  }
}

class _PromotionDetailContent extends ConsumerWidget {
  final Promotion promotion;

  const _PromotionDetailContent({required this.promotion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header with discount badge overlay
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: promotion.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius),
                        child: CachedNetworkImage(
                          imageUrl: promotion.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _IconPlaceholder(),
                        ),
                      )
                    : _IconPlaceholder(),
              ),
              if (promotion.discount != null)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.badgeRadius),
                    ),
                    child: Text(
                      promotion.discount!,
                      style: theme.typography.sm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Brand logo + store name
          Row(
            children: [
              FAvatar.raw(
                size: 36,
                child: promotion.brandLogoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: promotion.brandLogoUrl!,
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(
                            promotion.store.isNotEmpty
                                ? promotion.store[0].toUpperCase()
                                : '?',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          promotion.store.isNotEmpty
                              ? promotion.store[0].toUpperCase()
                              : '?',
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  promotion.store,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            promotion.title,
            style: theme.typography.xl.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Countdown timer (prominent display)
          if (!promotion.isPermanent) ...[
            _DetailCountdown(promotion: promotion),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Validity info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Valid from ${DateFormat.yMMMd().format(promotion.validFrom)}',
                      style: theme.typography.sm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      promotion.isPermanent
                          ? Icons.all_inclusive
                          : Icons.event,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      promotion.isPermanent
                          ? 'No expiration'
                          : 'Expires ${DateFormat.yMMMd().format(promotion.expiresAt!)}',
                      style: theme.typography.sm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Full description
          if (promotion.description != null) ...[
            Text(
              promotion.description!,
              style: theme.typography.base.copyWith(
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Category tag
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppSpacing.badgeRadius),
            ),
            child: Text(
              promotion.category,
              style: theme.typography.sm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: () {
                    ref
                        .read(promotionsProvider.notifier)
                        .toggleLike(promotion.id);
                  },
                  prefix: Icon(
                    promotion.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: promotion.liked
                        ? AppColors.accent1
                        : null,
                  ),
                  child: Text(
                      '${promotion.likesCount} ${promotion.liked ? "Liked" : "Like"}'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FButton(
                  variant: FButtonVariant.outline,
                  onPress: () {
                    ref
                        .read(promotionsProvider.notifier)
                        .toggleSave(promotion.id);
                  },
                  prefix: Icon(
                    promotion.saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                  ),
                  child: Text(promotion.saved ? 'Saved' : 'Save'),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Claim button
          SizedBox(
            width: double.infinity,
            child: promotion.claimed
                ? FButton(
                    variant: FButtonVariant.outline,
                    onPress: null,
                    prefix: Icon(Icons.check_circle,
                        size: 18, color: AppColors.success),
                    child: Text(
                      'Already Claimed',
                      style: TextStyle(color: AppColors.success),
                    ),
                  )
                : FButton(
                    onPress: () {
                      ref
                          .read(promotionsProvider.notifier)
                          .claimPromotion(promotion.id);
                    },
                    prefix: const Icon(Icons.redeem, size: 18),
                    child: const Text('Claim Offer'),
                  ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Link to organization (catalog place)
          if (promotion.organizationId != null) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => context.push(
                  '/catalog/${promotion.organizationId}'),
              child: Row(
                children: [
                  Icon(Icons.store, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'View in Catalog',
                      style: theme.typography.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _DetailCountdown extends StatelessWidget {
  final Promotion promotion;

  const _DetailCountdown({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final timeText = promotion.timeRemaining;

    final isUrgent = promotion.expiresAt != null &&
        promotion.expiresAt!.difference(DateTime.now()).inHours < 24;

    final bgColor = isUrgent
        ? AppColors.accent1.withValues(alpha: 0.1)
        : AppColors.secondary.withValues(alpha: 0.1);
    final textColor = isUrgent ? AppColors.accent1 : AppColors.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 24, color: textColor),
          const SizedBox(width: AppSpacing.md),
          Text(
            timeText,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
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
          Icons.local_offer,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
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
git add frontend/lib/features/promotions/presentation/screens/promotion_detail_screen.dart
git commit -m "feat(promotions): add PromotionDetailScreen with countdown, actions, and catalog link"
```

### Task 7: Register Promotions Routes

**Files:**
- Modify: `frontend/lib/core/router/app_router.dart`

- [ ] **Step 1: Add promotions routes**

In `frontend/lib/core/router/app_router.dart`:

Add imports:
```dart
import 'package:spectrum/features/promotions/presentation/screens/promotions_screen.dart';
import 'package:spectrum/features/promotions/presentation/screens/promotion_detail_screen.dart';
```

Find the existing `/promotions` placeholder route:
```dart
          GoRoute(
            path: '/promotions',
            name: 'promotions',
            builder: (context, state) => const Screen(
              body: Center(child: Text('Promotions — coming in Phase 7')),
            ),
          ),
```

Replace it with:
```dart
          GoRoute(
            path: '/promotions',
            name: 'promotions',
            builder: (context, state) => const PromotionsScreen(),
            routes: [
              GoRoute(
                path: ':promotionId',
                builder: (context, state) => PromotionDetailScreen(
                  promotionId: state.pathParameters['promotionId']!,
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
git commit -m "feat(promotions): register promotions and promotion detail routes"
```

---

## Chunk 3: Backend — Prisma Models + Routes + Seed (Phase 7b)

### Task 8: Add Prisma Models for Promotions

**Files:**
- Modify: `backend/src/db/schema.prisma`

- [ ] **Step 1: Add Promotion model and related models to schema**

In `backend/src/db/schema.prisma`, add the following. Also add relations to the User model.

Add to User model relations (after existing relations):
```prisma
promotions         Promotion[]
promotionReactions PromotionReaction[]
promotionClaims    PromotionClaim[]
```

Note: `savedItems SavedItem[]` and `organizations Organization[]` and `ratings Rating[]` were already added in Phase 5.

Add new models after the existing models:

```prisma
model Promotion {
  id             String              @id @default(cuid())
  title          String
  description    String?
  category       String
  discount       String?
  store          String
  brandLogoUrl   String?
  imageUrl       String?
  expiresAt      DateTime?
  validFrom      DateTime            @default(now())
  organizationId String?
  createdById    String
  createdBy      User                @relation(fields: [createdById], references: [id])
  likesCount     Int                 @default(0)
  reactions      PromotionReaction[]
  claims         PromotionClaim[]
  createdAt      DateTime            @default(now())
  updatedAt      DateTime            @updatedAt

  @@index([createdAt])
}

model PromotionReaction {
  id          String    @id @default(cuid())
  authorId    String
  author      User      @relation(fields: [authorId], references: [id], onDelete: Cascade)
  promotionId String
  promotion   Promotion @relation(fields: [promotionId], references: [id], onDelete: Cascade)
  createdAt   DateTime  @default(now())

  @@unique([authorId, promotionId])
}

model PromotionClaim {
  id          String    @id @default(cuid())
  userId      String
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  promotionId String
  promotion   Promotion @relation(fields: [promotionId], references: [id], onDelete: Cascade)
  createdAt   DateTime  @default(now())

  @@unique([userId, promotionId])
}

model PromotionCategory {
  id        String   @id @default(cuid())
  name      String   @unique
  icon      String?
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
git commit -m "feat(promotions): add Promotion, PromotionReaction, PromotionClaim, and PromotionCategory Prisma models"
```

### Task 9: Seed Promotion Categories

**Files:**
- Modify: `backend/src/db/seed-filters.ts`

- [ ] **Step 1: Add promotion categories to existing seed script**

In `backend/src/db/seed-filters.ts`, add the following inside the `main()` function, after the existing Special Needs section:

```typescript
  // Promotion Categories (from ana/backup)
  const promotionCategories = [
    { name: "Health & Wellness", icon: "health_and_safety", sortOrder: 1 },
    { name: "Education", icon: "school", sortOrder: 2 },
    { name: "Entertainment", icon: "theater_comedy", sortOrder: 3 },
    { name: "Food & Dining", icon: "restaurant", sortOrder: 4 },
    { name: "Services", icon: "miscellaneous_services", sortOrder: 5 },
  ];

  for (const pc of promotionCategories) {
    await prisma.promotionCategory.upsert({
      where: { name: pc.name },
      update: { icon: pc.icon, sortOrder: pc.sortOrder },
      create: pc,
    });
  }

  console.log("Promotion categories seeded successfully.");
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/db/seed-filters.ts
git commit -m "feat(promotions): add promotion categories to seed script"
```

### Task 10: Add Promotion Categories to Filter Routes

**Files:**
- Modify: `backend/src/routes/filters.ts`

- [ ] **Step 1: Add promotion-categories endpoint**

In `backend/src/routes/filters.ts`, add a new route after the existing `/special-needs` route:

```typescript
  app.get("/promotion-categories", async (c) => {
    const prisma = c.get("prisma");
    const categories = await prisma.promotionCategory.findMany({
      orderBy: { sortOrder: "asc" },
    });
    return c.json({ categories });
  });
```

- [ ] **Step 2: Run backend tests**

```bash
pnpm test:backend
```

Expected: All existing tests pass.

- [ ] **Step 3: Commit**

```bash
git add backend/src/routes/filters.ts
git commit -m "feat(promotions): add promotion-categories filter endpoint"
```

### Task 11: Create Promotions Routes

**Files:**
- Create: `backend/src/routes/promotions.ts`
- Modify: `backend/src/index.ts`

- [ ] **Step 1: Create promotions routes with Zod validation**

Create `backend/src/routes/promotions.ts`:

```typescript
import { Hono } from "hono";
import { z } from "zod";
import { sessionMiddleware, optionalSessionMiddleware } from "../middleware/session.js";
import type { AppBindings, AppVariables } from "../types/context.js";

const createPromotionSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  category: z.string().min(1),
  discount: z.string().max(50).optional(),
  store: z.string().min(1).max(200),
  brandLogoUrl: z.string().url().optional(),
  imageUrl: z.string().url().optional(),
  expiresAt: z.string().datetime().optional(),
  validFrom: z.string().datetime().optional(),
  organizationId: z.string().optional(),
});

const updatePromotionSchema = createPromotionSchema.partial();

const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  q: z.string().optional(),
  category: z.string().optional(),
});

export function promotionRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // GET / - list promotions (paginated, hides expired)
  app.get("/", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user") as any;
    const query = paginationSchema.parse({
      cursor: c.req.query("cursor"),
      limit: c.req.query("limit"),
      q: c.req.query("q"),
      category: c.req.query("category"),
    });

    const now = new Date();
    const where: any = {
      validFrom: { lte: now },
      OR: [
        { expiresAt: null },
        { expiresAt: { gt: now } },
      ],
    };

    // Text search
    if (query.q) {
      where.AND = [
        {
          OR: [
            { title: { contains: query.q } },
            { description: { contains: query.q } },
            { store: { contains: query.q } },
          ],
        },
      ];
    }

    // Category filter
    if (query.category) {
      where.category = query.category;
    }

    const promotions = await prisma.promotion.findMany({
      where,
      take: query.limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      orderBy: { createdAt: "desc" },
      include: {
        createdBy: { select: { id: true, name: true, image: true, userType: true } },
        ...(user ? {
          reactions: { where: { authorId: user.id }, select: { id: true } },
          claims: { where: { userId: user.id }, select: { id: true } },
        } : {}),
      },
    });

    const hasMore = promotions.length > query.limit;
    const results = hasMore ? promotions.slice(0, query.limit) : promotions;
    const nextCursor = hasMore ? results[results.length - 1].id : null;

    // Check saved status if user is authenticated
    let savedIds = new Set<string>();
    if (user) {
      const saved = await prisma.savedItem.findMany({
        where: { userId: user.id, itemType: "promotion", itemId: { in: results.map((p: any) => p.id) } },
        select: { itemId: true },
      });
      savedIds = new Set(saved.map((s: any) => s.itemId));
    }

    return c.json({
      promotions: results.map((p: any) => ({
        id: p.id,
        title: p.title,
        description: p.description,
        category: p.category,
        discount: p.discount,
        store: p.store,
        brandLogoUrl: p.brandLogoUrl,
        imageUrl: p.imageUrl,
        expiresAt: p.expiresAt?.toISOString() ?? null,
        validFrom: p.validFrom.toISOString(),
        organizationId: p.organizationId,
        createdById: p.createdById,
        createdBy: p.createdBy,
        likesCount: p.likesCount,
        liked: (p.reactions?.length ?? 0) > 0,
        saved: savedIds.has(p.id),
        claimed: (p.claims?.length ?? 0) > 0,
        createdAt: p.createdAt.toISOString(),
      })),
      nextCursor,
    });
  });

  // GET /:id - get single promotion
  app.get("/:id", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user") as any;
    const id = c.req.param("id");

    const promo = await prisma.promotion.findUnique({
      where: { id },
      include: {
        createdBy: { select: { id: true, name: true, image: true, userType: true } },
        ...(user ? {
          reactions: { where: { authorId: user.id }, select: { id: true } },
          claims: { where: { userId: user.id }, select: { id: true } },
        } : {}),
      },
    });

    if (!promo) {
      return c.json({ error: "Promotion not found", code: "NOT_FOUND" }, 404);
    }

    let saved = false;
    if (user) {
      const savedItem = await prisma.savedItem.findUnique({
        where: { userId_itemType_itemId: { userId: user.id, itemType: "promotion", itemId: id } },
      });
      saved = !!savedItem;
    }

    return c.json({
      promotion: {
        id: promo.id,
        title: promo.title,
        description: promo.description,
        category: promo.category,
        discount: promo.discount,
        store: promo.store,
        brandLogoUrl: promo.brandLogoUrl,
        imageUrl: promo.imageUrl,
        expiresAt: promo.expiresAt?.toISOString() ?? null,
        validFrom: promo.validFrom.toISOString(),
        organizationId: promo.organizationId,
        createdById: promo.createdById,
        createdBy: promo.createdBy,
        likesCount: promo.likesCount,
        liked: ((promo as any).reactions?.length ?? 0) > 0,
        saved,
        claimed: ((promo as any).claims?.length ?? 0) > 0,
        createdAt: promo.createdAt.toISOString(),
      },
    });
  });

  // POST / - create promotion (any authenticated user)
  app.post("/", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const body = createPromotionSchema.parse(await c.req.json());

    const promo = await prisma.promotion.create({
      data: {
        title: body.title,
        description: body.description,
        category: body.category,
        discount: body.discount,
        store: body.store,
        brandLogoUrl: body.brandLogoUrl,
        imageUrl: body.imageUrl,
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : null,
        validFrom: body.validFrom ? new Date(body.validFrom) : new Date(),
        organizationId: body.organizationId,
        createdById: user.id,
      },
      include: {
        createdBy: { select: { id: true, name: true, image: true, userType: true } },
      },
    });

    return c.json(
      {
        promotion: {
          id: promo.id,
          title: promo.title,
          description: promo.description,
          category: promo.category,
          discount: promo.discount,
          store: promo.store,
          brandLogoUrl: promo.brandLogoUrl,
          imageUrl: promo.imageUrl,
          expiresAt: promo.expiresAt?.toISOString() ?? null,
          validFrom: promo.validFrom.toISOString(),
          organizationId: promo.organizationId,
          createdById: promo.createdById,
          createdBy: promo.createdBy,
          likesCount: 0,
          liked: false,
          saved: false,
          claimed: false,
          createdAt: promo.createdAt.toISOString(),
        },
      },
      201
    );
  });

  // PUT /:id - update promotion (owner only)
  app.put("/:id", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const existing = await prisma.promotion.findUnique({ where: { id } });
    if (!existing) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);
    if (existing.createdById !== user.id) return c.json({ error: "Forbidden", code: "FORBIDDEN" }, 403);

    const body = updatePromotionSchema.parse(await c.req.json());

    const data: any = { ...body };
    if (body.expiresAt !== undefined) {
      data.expiresAt = body.expiresAt ? new Date(body.expiresAt) : null;
    }
    if (body.validFrom !== undefined) {
      data.validFrom = new Date(body.validFrom);
    }

    await prisma.promotion.update({ where: { id }, data });
    return c.json({ success: true });
  });

  // DELETE /:id - delete promotion (owner only)
  app.delete("/:id", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const existing = await prisma.promotion.findUnique({ where: { id } });
    if (!existing) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);
    if (existing.createdById !== user.id) return c.json({ error: "Forbidden", code: "FORBIDDEN" }, 403);

    await prisma.promotion.delete({ where: { id } });
    return c.json({ success: true });
  });

  // PUT /:id/reactions - like a promotion
  app.put("/:id/reactions", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const promo = await prisma.promotion.findUnique({ where: { id } });
    if (!promo) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);

    const existing = await prisma.promotionReaction.findUnique({
      where: { authorId_promotionId: { authorId: user.id, promotionId: id } },
    });

    if (existing) {
      return c.json({ liked: true, likesCount: promo.likesCount });
    }

    const updated = await prisma.$transaction(async (tx: any) => {
      await tx.promotionReaction.create({
        data: { authorId: user.id, promotionId: id },
      });
      return tx.promotion.update({
        where: { id },
        data: { likesCount: { increment: 1 } },
      });
    });

    return c.json({ liked: true, likesCount: updated.likesCount });
  });

  // DELETE /:id/reactions - unlike a promotion
  app.delete("/:id/reactions", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const promo = await prisma.promotion.findUnique({ where: { id } });
    if (!promo) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);

    const existing = await prisma.promotionReaction.findUnique({
      where: { authorId_promotionId: { authorId: user.id, promotionId: id } },
    });

    if (!existing) {
      return c.json({ liked: false, likesCount: promo.likesCount });
    }

    const updated = await prisma.$transaction(async (tx: any) => {
      await tx.promotionReaction.delete({
        where: { authorId_promotionId: { authorId: user.id, promotionId: id } },
      });
      return tx.promotion.update({
        where: { id },
        data: { likesCount: { decrement: 1 } },
      });
    });

    return c.json({ liked: false, likesCount: updated.likesCount });
  });

  // POST /:id/claim - claim a promotion
  app.post("/:id/claim", sessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const user = c.get("user");
    const id = c.req.param("id");

    const promo = await prisma.promotion.findUnique({ where: { id } });
    if (!promo) return c.json({ error: "Not found", code: "NOT_FOUND" }, 404);

    // Check if already claimed
    const existing = await prisma.promotionClaim.findUnique({
      where: { userId_promotionId: { userId: user.id, promotionId: id } },
    });

    if (existing) {
      return c.json({ claimed: true, message: "Already claimed" });
    }

    await prisma.promotionClaim.create({
      data: { userId: user.id, promotionId: id },
    });

    return c.json({ claimed: true }, 201);
  });

  return app;
}
```

- [ ] **Step 2: Mount promotions routes in index.ts**

In `backend/src/index.ts`:

Add import:
```typescript
import { promotionRoutes } from "./routes/promotions.js";
```

Add route mount (after existing route mounts):
```typescript
app.route("/api/promotions", promotionRoutes());
```

- [ ] **Step 3: Update saved routes to handle promotion itemType**

In `backend/src/routes/saved.ts`, find the section that handles `itemType === "catalog"` and add a handler for promotions after the catalog block.

After the `if (itemType === "catalog") { ... }` block, add:

```typescript
    if (itemType === "promotion") {
      const promoIds = savedItems.map(s => s.itemId);
      const promos = await prisma.promotion.findMany({
        where: { id: { in: promoIds } },
        include: {
          createdBy: { select: { id: true, name: true, image: true, userType: true } },
          reactions: { where: { authorId: user.id }, select: { id: true } },
          claims: { where: { userId: user.id }, select: { id: true } },
        },
      });

      // Group by category
      const grouped: Record<string, any[]> = {};
      for (const promo of promos) {
        const category = promo.category;
        if (!grouped[category]) grouped[category] = [];
        grouped[category].push({
          id: promo.id,
          title: promo.title,
          description: promo.description,
          category: promo.category,
          discount: promo.discount,
          store: promo.store,
          brandLogoUrl: promo.brandLogoUrl,
          imageUrl: promo.imageUrl,
          expiresAt: promo.expiresAt?.toISOString() ?? null,
          validFrom: promo.validFrom.toISOString(),
          organizationId: promo.organizationId,
          createdById: promo.createdById,
          createdBy: promo.createdBy,
          likesCount: promo.likesCount,
          liked: ((promo as any).reactions?.length ?? 0) > 0,
          saved: true,
          claimed: ((promo as any).claims?.length ?? 0) > 0,
          createdAt: promo.createdAt.toISOString(),
        });
      }

      // Look up category icons
      const categoryNames = Object.keys(grouped);
      const categories = await prisma.promotionCategory.findMany({
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
```

- [ ] **Step 4: Run backend tests**

```bash
pnpm test:backend
```

Expected: All existing tests pass.

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/promotions.ts backend/src/index.ts backend/src/routes/saved.ts
git commit -m "feat(promotions): add promotions CRUD, reactions, claims routes and saved handler"
```

---

## Chunk 4: Wire Up + Home Carousel Integration + OpenAPI (Phase 7c)

### Task 12: Wire Promotions Repository to Real API

**Files:**
- Modify: `frontend/lib/features/promotions/data/promotions_repository.dart`

- [ ] **Step 1: Replace mock data with real API calls**

Rewrite `frontend/lib/features/promotions/data/promotions_repository.dart`:

```dart
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/catalog/domain/filter_option.dart';
import 'package:spectrum/features/promotions/domain/promotion.dart';
import 'package:spectrum/shared/domain/paginated_result.dart';
import 'package:spectrum/shared/providers/api_provider.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  return PromotionsRepository(ref.read(apiClientProvider));
});

class PromotionsRepository {
  final dynamic _api;

  PromotionsRepository(this._api);

  // --- Filter Options ---

  Future<List<FilterOption>> getPromotionCategories() async {
    try {
      final response = await _api.get('/api/filters/promotion-categories');
      final data = response.data as Map<String, dynamic>;
      return (data['categories'] as List)
          .map((j) => FilterOption.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Failed to load promotion categories: $e');
      return [];
    }
  }

  // --- Promotions ---

  Future<PaginatedResult<Promotion>> getPromotions({
    String? cursor,
    int limit = 20,
    String? search,
    Set<String>? categories,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (search != null && search.isNotEmpty) 'q': search,
        if (categories != null && categories.isNotEmpty)
          'category': categories.first,
      };

      final response =
          await _api.get('/api/promotions', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final promotions = (data['promotions'] as List)
          .map((j) => Promotion.fromJson(j as Map<String, dynamic>))
          .toList();
      return PaginatedResult(
        items: promotions,
        nextCursor: data['nextCursor'] as String?,
      );
    } catch (e) {
      log('Failed to load promotions: $e');
      return const PaginatedResult(items: []);
    }
  }

  Future<Promotion?> getPromotion(String id) async {
    try {
      final response = await _api.get('/api/promotions/$id');
      final data = response.data as Map<String, dynamic>;
      return Promotion.fromJson(data['promotion'] as Map<String, dynamic>);
    } catch (e) {
      log('Failed to load promotion: $e');
      return null;
    }
  }

  Future<({bool liked, int likesCount})> likePromotion(String id) async {
    final response = await _api.put('/api/promotions/$id/reactions');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool,
      likesCount: data['likesCount'] as int,
    );
  }

  Future<({bool liked, int likesCount})> unlikePromotion(String id) async {
    final response = await _api.delete('/api/promotions/$id/reactions');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool,
      likesCount: data['likesCount'] as int,
    );
  }

  Future<void> claimPromotion(String id) async {
    try {
      await _api.post('/api/promotions/$id/claim');
    } catch (e) {
      log('Failed to claim promotion: $e');
      rethrow;
    }
  }

  Future<void> savePromotion(String id) async {
    try {
      await _api.put('/api/saved',
          data: {'itemType': 'promotion', 'itemId': id});
    } catch (e) {
      log('Failed to save promotion: $e');
    }
  }

  Future<void> unsavePromotion(String id) async {
    try {
      await _api.delete('/api/saved/promotion/$id');
    } catch (e) {
      log('Failed to unsave promotion: $e');
    }
  }

  Future<List<Promotion>> getSavedPromotions() async {
    try {
      final response = await _api.get('/api/saved/promotion');
      final data = response.data as Map<String, dynamic>;
      final groups = data['groups'] as List;
      final promotions = <Promotion>[];
      for (final group in groups) {
        final items = (group['items'] as List)
            .map((j) => Promotion.fromJson(j as Map<String, dynamic>))
            .toList();
        promotions.addAll(items);
      }
      return promotions;
    } catch (e) {
      log('Failed to load saved promotions: $e');
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
git add frontend/lib/features/promotions/data/promotions_repository.dart
git commit -m "feat(promotions): wire repository to real API endpoints"
```

### Task 13: Connect Home Carousel Tap to Promotion Detail

**Files:**
- Modify: `frontend/lib/features/home/presentation/screens/home_screen.dart` (or wherever `PromotionCarousel.onItemSelected` is wired)

- [ ] **Step 1: Wire onItemSelected to navigate to promotion detail**

In the home screen file where `PromotionCarousel` is used, find the `onItemSelected` callback and ensure it navigates to the promotion detail screen:

```dart
PromotionCarousel(
  promotions: dashboardData.promotions,
  onItemSelected: (id) => context.push('/promotions/$id'),
),
```

If `onItemSelected` is already set to navigate, verify the route matches `/promotions/:promotionId`. If it was previously `null` or pointed to a placeholder, update it.

- [ ] **Step 2: Run Dart analysis**

```bash
cd frontend && dart analyze
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/features/home/presentation/screens/home_screen.dart
git commit -m "feat(promotions): wire home carousel tap to promotion detail screen"
```

### Task 14: Create OpenAPI Contract

**Files:**
- Create: `contracts/promotions.yaml`

- [ ] **Step 1: Create promotions OpenAPI contract**

Create `contracts/promotions.yaml` documenting the endpoints, request/response schemas. Follow the format of existing `contracts/catalog.yaml`.

```yaml
openapi: 3.1.0
info:
  title: Spectrum Promotions API
  version: 1.0.0

paths:
  /api/promotions:
    get:
      summary: List promotions (hides expired, paginates)
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
      responses:
        "200":
          description: Paginated list of promotions
          content:
            application/json:
              schema:
                type: object
                properties:
                  promotions:
                    type: array
                    items: { $ref: "#/components/schemas/Promotion" }
                  nextCursor:
                    type: string
                    nullable: true
    post:
      summary: Create promotion (any authenticated user)
      security: [{ bearer: [] }]
      requestBody:
        content:
          application/json:
            schema: { $ref: "#/components/schemas/CreatePromotion" }
      responses:
        "201":
          description: Created promotion
          content:
            application/json:
              schema:
                type: object
                properties:
                  promotion: { $ref: "#/components/schemas/Promotion" }

  /api/promotions/{id}:
    get:
      summary: Get promotion details
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string }
      responses:
        "200":
          description: Promotion details
          content:
            application/json:
              schema:
                type: object
                properties:
                  promotion: { $ref: "#/components/schemas/Promotion" }
    put:
      summary: Update promotion (owner only)
      security: [{ bearer: [] }]
      responses:
        "200":
          description: Success
    delete:
      summary: Delete promotion (owner only)
      security: [{ bearer: [] }]
      responses:
        "200":
          description: Success

  /api/promotions/{id}/reactions:
    put:
      summary: Like a promotion
      security: [{ bearer: [] }]
      responses:
        "200":
          content:
            application/json:
              schema:
                type: object
                properties:
                  liked: { type: boolean }
                  likesCount: { type: integer }
    delete:
      summary: Unlike a promotion
      security: [{ bearer: [] }]
      responses:
        "200":
          content:
            application/json:
              schema:
                type: object
                properties:
                  liked: { type: boolean }
                  likesCount: { type: integer }

  /api/promotions/{id}/claim:
    post:
      summary: Claim a promotion
      security: [{ bearer: [] }]
      responses:
        "201":
          content:
            application/json:
              schema:
                type: object
                properties:
                  claimed: { type: boolean }

  /api/filters/promotion-categories:
    get:
      summary: List promotion categories
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

components:
  schemas:
    Promotion:
      type: object
      properties:
        id: { type: string }
        title: { type: string }
        description: { type: string, nullable: true }
        category: { type: string }
        discount: { type: string, nullable: true }
        store: { type: string }
        brandLogoUrl: { type: string, nullable: true }
        imageUrl: { type: string, nullable: true }
        expiresAt: { type: string, format: date-time, nullable: true }
        validFrom: { type: string, format: date-time }
        organizationId: { type: string, nullable: true }
        createdById: { type: string }
        createdBy: { $ref: "#/components/schemas/Author" }
        likesCount: { type: integer }
        liked: { type: boolean }
        saved: { type: boolean }
        claimed: { type: boolean }
        createdAt: { type: string, format: date-time }

    CreatePromotion:
      type: object
      required: [title, category, store]
      properties:
        title: { type: string, maxLength: 200 }
        description: { type: string, maxLength: 5000 }
        category: { type: string }
        discount: { type: string, maxLength: 50 }
        store: { type: string, maxLength: 200 }
        brandLogoUrl: { type: string, format: uri }
        imageUrl: { type: string, format: uri }
        expiresAt: { type: string, format: date-time }
        validFrom: { type: string, format: date-time }
        organizationId: { type: string }

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
git add contracts/promotions.yaml
git commit -m "feat(promotions): add OpenAPI contract for promotions endpoints"
```

### Task 15: Final Verification

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

If clean, Phase 7 is complete.
