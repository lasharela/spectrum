import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/promotions/data/promotions_repository.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';

// ---------------------------------------------------------------------------
// Filter Options
// ---------------------------------------------------------------------------

class PromotionFilterOptions {
  final List<FilterOption> categories;

  const PromotionFilterOptions({required this.categories});

  List<FilterGroup> toFilterGroups() => [
        FilterGroup(label: 'Categories', options: categories),
      ];
}

final promotionFilterOptionsProvider =
    FutureProvider<PromotionFilterOptions>((ref) async {
  final repo = ref.read(promotionsRepositoryProvider);
  final categories = await repo.getPromotionCategories();
  return PromotionFilterOptions(categories: categories);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

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
    bool clearNextCursor = false,
  }) {
    return PromotionsState(
      promotions: promotions ?? this.promotions,
      nextCursor:
          clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final promotionsProvider =
    NotifierProvider<PromotionsNotifier, PromotionsState>(
  PromotionsNotifier.new,
);

class PromotionsNotifier extends Notifier<PromotionsState> {
  Timer? _debounce;

  @override
  PromotionsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadInitial);
    return const PromotionsState();
  }

  PromotionsRepository get _repo => ref.read(promotionsRepositoryProvider);

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, clearNextCursor: true);
    try {
      final categories = state.filters['Categories'];
      final result = await _repo.getPromotions(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: categories,
      );
      state = state.copyWith(
        promotions: result.items,
        nextCursor: result.nextCursor,
        isLoading: false,
      );
    } catch (e) {
      log('PromotionsNotifier._loadInitial error: $e');
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
      final categories = state.filters['Categories'];
      final result = await _repo.getPromotions(
        cursor: state.nextCursor,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: categories,
      );
      state = state.copyWith(
        promotions: [...state.promotions, ...result.items],
        nextCursor: result.nextCursor,
        isLoadingMore: false,
      );
    } catch (e) {
      log('PromotionsNotifier.loadMore error: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> toggleLike(String promotionId) async {
    final idx = state.promotions.indexWhere((p) => p.id == promotionId);
    if (idx == -1) return;

    final current = state.promotions[idx];
    final nowLiked = !current.liked;
    final optimisticCount =
        nowLiked ? current.likesCount + 1 : (current.likesCount - 1).clamp(0, 999999);

    // Optimistic update
    final optimistic = List<Promotion>.from(state.promotions);
    optimistic[idx] = current.copyWith(
      liked: nowLiked,
      likesCount: optimisticCount,
    );
    state = state.copyWith(promotions: optimistic);

    try {
      if (nowLiked) {
        await _repo.likePromotion(promotionId);
      } else {
        await _repo.unlikePromotion(promotionId);
      }

      // Reconcile with server state
      final updated = await _repo.getPromotion(promotionId);
      if (updated == null) return;
      final reconciled = List<Promotion>.from(state.promotions);
      final newIdx = reconciled.indexWhere((p) => p.id == promotionId);
      if (newIdx != -1) {
        reconciled[newIdx] = updated;
        state = state.copyWith(promotions: reconciled);
      }
    } catch (e) {
      log('PromotionsNotifier.toggleLike error: $e');
      // Revert on error
      final reverted = List<Promotion>.from(state.promotions);
      final revertIdx = reverted.indexWhere((p) => p.id == promotionId);
      if (revertIdx != -1) {
        reverted[revertIdx] = current;
        state = state.copyWith(promotions: reverted);
      }
    }
  }

  Future<void> toggleSave(String promotionId) async {
    final idx = state.promotions.indexWhere((p) => p.id == promotionId);
    if (idx == -1) return;

    final current = state.promotions[idx];
    final nowSaved = !current.saved;

    // Optimistic update
    final optimistic = List<Promotion>.from(state.promotions);
    optimistic[idx] = current.copyWith(saved: nowSaved);
    state = state.copyWith(promotions: optimistic);

    try {
      if (nowSaved) {
        await _repo.savePromotion(promotionId);
      } else {
        await _repo.unsavePromotion(promotionId);
      }
      // Invalidate saved promotions cache
      ref.invalidate(savedPromotionsProvider);
    } catch (e) {
      log('PromotionsNotifier.toggleSave error: $e');
      // Revert on error
      final reverted = List<Promotion>.from(state.promotions);
      final revertIdx = reverted.indexWhere((p) => p.id == promotionId);
      if (revertIdx != -1) {
        reverted[revertIdx] = current;
        state = state.copyWith(promotions: reverted);
      }
    }
  }

  Future<void> claimPromotion(String promotionId) async {
    final idx = state.promotions.indexWhere((p) => p.id == promotionId);
    if (idx == -1) return;

    try {
      await _repo.claimPromotion(promotionId);
      final claimed = List<Promotion>.from(state.promotions);
      claimed[idx] = state.promotions[idx].copyWith(claimed: true);
      state = state.copyWith(promotions: claimed);
    } catch (e) {
      log('PromotionsNotifier.claimPromotion error: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Saved Promotions Provider
// ---------------------------------------------------------------------------

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
