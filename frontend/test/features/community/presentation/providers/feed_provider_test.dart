import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/community/presentation/providers/feed_provider.dart';

void main() {
  group('FeedState', () {
    test('default state has empty search and allDiscussions tab', () {
      const state = FeedState();
      expect(state.searchQuery, '');
      expect(state.showMyDiscussions, false);
      expect(state.posts, isEmpty);
      expect(state.isLoading, false);
    });

    test('copyWith updates searchQuery', () {
      const state = FeedState();
      final updated = state.copyWith(searchQuery: 'autism');
      expect(updated.searchQuery, 'autism');
    });

    test('copyWith updates showMyDiscussions', () {
      const state = FeedState();
      final updated = state.copyWith(showMyDiscussions: true);
      expect(updated.showMyDiscussions, true);
    });
  });

  group('FeedState.hasActiveFilters', () {
    test('returns false when no filters are set', () {
      const state = FeedState();
      expect(state.hasActiveFilters, false);
    });

    test('returns true when categoryFilter is set', () {
      const state = FeedState(categoryFilter: 'Education');
      expect(state.hasActiveFilters, true);
    });

    test('returns true when stateFilter is set', () {
      const state = FeedState(stateFilter: 'California');
      expect(state.hasActiveFilters, true);
    });

    test('returns true when cityFilter is set', () {
      const state = FeedState(cityFilter: 'Los Angeles');
      expect(state.hasActiveFilters, true);
    });

    test('returns true when multiple filters are set', () {
      const state = FeedState(
        categoryFilter: 'Education',
        stateFilter: 'California',
        cityFilter: 'Los Angeles',
      );
      expect(state.hasActiveFilters, true);
    });
  });

  group('FeedState.copyWith nullable closures', () {
    test('sets categoryFilter via closure', () {
      const state = FeedState();
      final updated = state.copyWith(categoryFilter: () => 'Sensory');
      expect(updated.categoryFilter, 'Sensory');
    });

    test('clears categoryFilter via null-returning closure', () {
      const state = FeedState(categoryFilter: 'Sensory');
      final updated = state.copyWith(categoryFilter: () => null);
      expect(updated.categoryFilter, isNull);
    });

    test('preserves categoryFilter when closure not provided', () {
      const state = FeedState(categoryFilter: 'Education');
      final updated = state.copyWith(searchQuery: 'test');
      expect(updated.categoryFilter, 'Education');
    });

    test('sets stateFilter via closure', () {
      const state = FeedState();
      final updated = state.copyWith(stateFilter: () => 'Texas');
      expect(updated.stateFilter, 'Texas');
    });

    test('clears stateFilter via null-returning closure', () {
      const state = FeedState(stateFilter: 'Texas');
      final updated = state.copyWith(stateFilter: () => null);
      expect(updated.stateFilter, isNull);
    });

    test('preserves stateFilter when closure not provided', () {
      const state = FeedState(stateFilter: 'Texas');
      final updated = state.copyWith(searchQuery: 'test');
      expect(updated.stateFilter, 'Texas');
    });

    test('sets cityFilter via closure', () {
      const state = FeedState();
      final updated = state.copyWith(cityFilter: () => 'Houston');
      expect(updated.cityFilter, 'Houston');
    });

    test('clears cityFilter via null-returning closure', () {
      const state = FeedState(cityFilter: 'Houston');
      final updated = state.copyWith(cityFilter: () => null);
      expect(updated.cityFilter, isNull);
    });

    test('preserves cityFilter when closure not provided', () {
      const state = FeedState(cityFilter: 'Houston');
      final updated = state.copyWith(searchQuery: 'test');
      expect(updated.cityFilter, 'Houston');
    });

    test('sets and clears all three filters together', () {
      const state = FeedState();
      final withFilters = state.copyWith(
        categoryFilter: () => 'Support',
        stateFilter: () => 'Florida',
        cityFilter: () => 'Miami',
      );
      expect(withFilters.categoryFilter, 'Support');
      expect(withFilters.stateFilter, 'Florida');
      expect(withFilters.cityFilter, 'Miami');
      expect(withFilters.hasActiveFilters, true);

      final cleared = withFilters.copyWith(
        categoryFilter: () => null,
        stateFilter: () => null,
        cityFilter: () => null,
      );
      expect(cleared.categoryFilter, isNull);
      expect(cleared.stateFilter, isNull);
      expect(cleared.cityFilter, isNull);
      expect(cleared.hasActiveFilters, false);
    });
  });
}
