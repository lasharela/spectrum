import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/features/community/domain/post.dart';
import 'package:spectrum_app/features/community/presentation/providers/feed_provider.dart';
import 'package:spectrum_app/features/community/presentation/screens/feed_screen.dart';
import 'package:spectrum_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:spectrum_app/features/auth/domain/user.dart';
import '../../../../helpers/test_utils.dart';

class _FakeFeedNotifier extends FeedNotifier {
  @override
  FeedState build() {
    return FeedState(
      posts: [
        Post(
          id: '1',
          title: 'Best educational apps for kids on the spectrum',
          content: 'Here are some apps that have worked great for my child.',
          imageUrl: 'https://example.com/community-post.jpg',
          tags: ['Apps'],
          category: 'Education',
          authorId: 'u1',
          author: const PostAuthor(id: 'u1', name: 'Alice', userType: 'parent'),
          createdAt: DateTime.now(),
          likesCount: 5,
          commentsCount: 2,
          liked: false,
        ),
      ],
    );
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

void main() {
  // Common overrides used by all tests
  final testOverrides = [
    feedProvider.overrideWith(() => _FakeFeedNotifier()),
    authProvider.overrideWith(() => _FakeAuthNotifier()),
  ];

  group('FeedScreen', () {
    testWidgets('renders All Discussions and My Discussions tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const FeedScreen(), overrides: testOverrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Discussions'), findsOneWidget);
      expect(find.text('My Discussions'), findsOneWidget);
    });

    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const FeedScreen(), overrides: testOverrides),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FTextField), findsOneWidget);
      expect(find.text('Search discussions...'), findsOneWidget);
    });

    testWidgets('renders post card with category tag', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const FeedScreen(), overrides: testOverrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('Education'), findsOneWidget);
      expect(
        find.text('Best educational apps for kids on the spectrum'),
        findsOneWidget,
      );
      expect(
        find.text('Here are some apps that have worked great for my child.'),
        findsOneWidget,
      );
    });

    testWidgets('renders FAB', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const FeedScreen(), overrides: testOverrides),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
