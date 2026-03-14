import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/community/domain/post.dart';
import 'package:spectrum_app/features/community/domain/comment.dart';
import 'package:spectrum_app/features/community/data/community_repository.dart';
import 'package:spectrum_app/features/community/presentation/providers/feed_provider.dart';
import 'package:spectrum_app/features/community/presentation/screens/post_detail_screen.dart';
import 'package:spectrum_app/shared/api/api_client.dart';

class _FakeFeedNotifier extends FeedNotifier {
  @override
  FeedState build() {
    return FeedState(
      posts: [
        Post(
          id: 'post-1',
          content: 'Full post content for detail view',
          tags: [],
          category: 'Support',
          authorId: 'u1',
          author: const PostAuthor(
            id: 'u1',
            name: 'Bob',
            userType: 'parent',
          ),
          createdAt: DateTime(2026, 1, 15),
          likesCount: 3,
          commentsCount: 1,
          liked: true,
        ),
      ],
    );
  }
}

/// Fake CommunityRepository that returns empty comments
class _FakeCommunityRepository extends CommunityRepository {
  _FakeCommunityRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<PaginatedResult<Comment>> getComments(
    String postId, {
    String? cursor,
    int limit = 20,
  }) async {
    return const PaginatedResult(items: []);
  }
}

void main() {
  // Common overrides
  final testOverrides = [
    feedProvider.overrideWith(() => _FakeFeedNotifier()),
    communityRepositoryProvider.overrideWithValue(_FakeCommunityRepository()),
  ];

  group('PostDetailScreen', () {
    testWidgets('renders post content and reply input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides,
          child: const MaterialApp(
            home: PostDetailScreen(postId: 'post-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Full post content for detail view'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      // Reply input field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows Replies header', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides,
          child: const MaterialApp(
            home: PostDetailScreen(postId: 'post-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replies'), findsOneWidget);
    });
  });
}
