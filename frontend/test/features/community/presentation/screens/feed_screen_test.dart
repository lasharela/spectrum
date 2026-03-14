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
  final FeedState _initialState;

  _FakeFeedNotifier([FeedState? initialState])
      : _initialState = initialState ??
            FeedState(
              posts: [
                Post(
                  id: '1',
                  title: 'Best educational apps for kids on the spectrum',
                  content:
                      'Here are some apps that have worked great for my child.',
                  imageUrl: 'https://example.com/community-post.jpg',
                  tags: ['Apps'],
                  category: 'Education',
                  authorId: 'u1',
                  author: const PostAuthor(
                      id: 'u1', name: 'Alice', userType: 'parent'),
                  createdAt: DateTime.now(),
                  likesCount: 5,
                  commentsCount: 2,
                  liked: false,
                ),
              ],
            );

  @override
  FeedState build() {
    return _initialState;
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

    testWidgets('search input is visible in All Discussions tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(const FeedScreen(), overrides: testOverrides),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FTextField), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets(
        'shows active filter indicator (blue dot) when hasActiveFilters is true',
        (tester) async {
      final filteredOverrides = [
        feedProvider.overrideWith(
          () => _FakeFeedNotifier(
            FeedState(
              categoryFilter: 'Education',
              posts: [
                Post(
                  id: '1',
                  title: 'Test post',
                  content: 'Content',
                  tags: ['General'],
                  category: 'Education',
                  authorId: 'u1',
                  author: const PostAuthor(
                      id: 'u1', name: 'Alice', userType: 'parent'),
                  createdAt: DateTime.now(),
                  likesCount: 0,
                  commentsCount: 0,
                  liked: false,
                ),
              ],
            ),
          ),
        ),
        authProvider.overrideWith(() => _FakeAuthNotifier()),
      ];

      await tester.pumpWidget(
        buildTestApp(const FeedScreen(), overrides: filteredOverrides),
      );
      await tester.pumpAndSettle();

      // The blue dot is an 8x8 Container with BoxShape.circle
      // Find the filter button icon (tune_rounded) and verify the dot exists
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // The filter indicator is a small Container(8x8) with circle shape
      // inside a Stack alongside the filter button
      final dotFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          widget.constraints?.maxWidth == 8);
      expect(dotFinder, findsOneWidget);
    });

    testWidgets(
        'does not show active filter indicator when hasActiveFilters is false',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(const FeedScreen(), overrides: testOverrides),
      );
      await tester.pumpAndSettle();

      // The filter button should be present
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // But the blue dot indicator should NOT be present
      final dotFinder = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          widget.constraints?.maxWidth == 8);
      expect(dotFinder, findsNothing);
    });
  });
}
