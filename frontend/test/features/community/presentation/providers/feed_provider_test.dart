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
}
