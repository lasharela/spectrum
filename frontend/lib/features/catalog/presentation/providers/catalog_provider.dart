import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/data/catalog_repository.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/catalog/domain/place.dart';

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
    ref.onDispose(() => _debounce?.cancel());
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
