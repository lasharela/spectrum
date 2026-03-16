import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum_app/features/catalog/domain/filter_option.dart';
import 'package:spectrum_app/features/events/data/events_repository.dart';
import 'package:spectrum_app/features/events/domain/event.dart';

// --- Filter Options Provider ---

final eventFilterOptionsProvider =
    FutureProvider<EventFilterOptions>((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  final categories = await repo.getEventCategories();
  return EventFilterOptions(categories: categories);
});

class EventFilterOptions {
  final List<FilterOption> categories;

  const EventFilterOptions({required this.categories});

  List<FilterGroup> toFilterGroups() => [
        FilterGroup(label: 'Category', options: categories),
        FilterGroup(label: 'Type', options: [
          const FilterOption(id: 'Online', name: 'Online'),
          const FilterOption(id: 'In-Person', name: 'In-Person'),
        ]),
        FilterGroup(label: 'Price', options: [
          const FilterOption(id: 'Free', name: 'Free'),
          const FilterOption(id: 'Paid', name: 'Paid'),
        ]),
      ];
}

// --- Events Feed Provider ---

class EventsState {
  final List<Event> events;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final Map<String, Set<String>> filters;

  const EventsState({
    this.events = const [],
    this.nextCursor,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.filters = const {},
  });

  int get activeFilterCount =>
      filters.values.fold(0, (sum, set) => sum + set.length);

  bool get hasActiveFilters => activeFilterCount > 0;

  EventsState copyWith({
    List<Event>? events,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    Map<String, Set<String>>? filters,
  }) {
    return EventsState(
      events: events ?? this.events,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
    );
  }
}

final eventsProvider =
    NotifierProvider<EventsNotifier, EventsState>(EventsNotifier.new);

class EventsNotifier extends Notifier<EventsState> {
  Timer? _debounce;

  @override
  EventsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadInitial);
    return const EventsState();
  }

  EventsRepository get _repo => ref.read(eventsRepositoryProvider);

  // Extract filter values from the generic map
  bool? get _isOnlineFilter {
    final typeFilter = state.filters['Type'];
    if (typeFilter == null || typeFilter.isEmpty) return null;
    if (typeFilter.contains('Online') && !typeFilter.contains('In-Person')) {
      return true;
    }
    if (typeFilter.contains('In-Person') && !typeFilter.contains('Online')) {
      return false;
    }
    return null; // both selected = no filter
  }

  bool? get _isFreeFilter {
    final priceFilter = state.filters['Price'];
    if (priceFilter == null || priceFilter.isEmpty) return null;
    if (priceFilter.contains('Free') && !priceFilter.contains('Paid')) {
      return true;
    }
    if (priceFilter.contains('Paid') && !priceFilter.contains('Free')) {
      return false;
    }
    return null;
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repo.getEvents(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: state.filters['Category'],
        isOnline: _isOnlineFilter,
        isFree: _isFreeFilter,
      );
      state = state.copyWith(
        events: result.items,
        nextCursor: result.nextCursor,
        isLoading: false,
      );
    } catch (e) {
      log('Failed to load events: $e');
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
      final result = await _repo.getEvents(
        cursor: state.nextCursor,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categories: state.filters['Category'],
        isOnline: _isOnlineFilter,
        isFree: _isFreeFilter,
      );
      state = state.copyWith(
        events: [...state.events, ...result.items],
        nextCursor: result.nextCursor,
        isLoadingMore: false,
      );
    } catch (e) {
      log('Failed to load more events: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setSaved(String eventId, {required bool saved}) {
    final index = state.events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final newList = List<Event>.from(state.events);
    newList[index] = state.events[index].copyWith(saved: saved);
    state = state.copyWith(events: newList);
  }

  void setRsvped(String eventId,
      {required bool rsvped, required int attendeeCount}) {
    final index = state.events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;
    final newList = List<Event>.from(state.events);
    newList[index] = state.events[index]
        .copyWith(rsvped: rsvped, attendeeCount: attendeeCount);
    state = state.copyWith(events: newList);
  }
}

// --- My Events Provider ---

final myEventsProvider =
    FutureProvider<List<Event>>((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  final result = await repo.getMyEvents();
  return result.items;
});

// --- Saved Events Provider ---

final savedEventsProvider =
    FutureProvider<Map<String, List<Event>>>((ref) async {
  final repo = ref.read(eventsRepositoryProvider);
  final events = await repo.getSavedEvents();
  final grouped = <String, List<Event>>{};
  for (final event in events) {
    grouped.putIfAbsent(event.category, () => []).add(event);
  }
  return grouped;
});
