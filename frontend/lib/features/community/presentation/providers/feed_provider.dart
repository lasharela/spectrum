import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/community_repository.dart';
import '../../domain/post.dart';
import '../../../../shared/providers/api_provider.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.read(apiClientProvider));
});

class FeedState {
  final List<Post> posts;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;

  const FeedState({
    this.posts = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
  });

  FeedState copyWith({
    List<Post>? posts,
    String? Function()? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final feedProvider =
    NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    _loadInitial();
    return const FeedState(isLoading: true);
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getPosts();
      state = FeedState(posts: result.items, nextCursor: result.nextCursor);
    } catch (_) {
      state = const FeedState();
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.nextCursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getPosts(cursor: state.nextCursor);
      state = state.copyWith(
        posts: [...state.posts, ...result.items],
        nextCursor: () => result.nextCursor,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> createPost({
    required String content,
    List<String> tags = const [],
  }) async {
    final repo = ref.read(communityRepositoryProvider);
    final post = await repo.createPost(content: content, tags: tags);
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  Future<void> deletePost(String id) async {
    final repo = ref.read(communityRepositoryProvider);
    await repo.deletePost(id);
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != id).toList(),
    );
  }

  Future<void> toggleLike(String postId) async {
    final repo = ref.read(communityRepositoryProvider);
    final post = state.posts.firstWhere((p) => p.id == postId);
    final result =
        post.liked ? await repo.unlikePost(postId) : await repo.likePost(postId);
    state = state.copyWith(
      posts: state.posts.map((p) {
        if (p.id == postId) {
          return p.copyWith(
            liked: result.liked,
            likesCount: result.likesCount,
          );
        }
        return p;
      }).toList(),
    );
  }
}
