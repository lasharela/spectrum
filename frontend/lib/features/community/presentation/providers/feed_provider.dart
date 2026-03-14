import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/community_repository.dart';
import '../../domain/post.dart';
import '../../../../shared/providers/api_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.read(apiClientProvider));
});

class FeedState {
  final List<Post> posts;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String searchQuery;
  final bool showMyDiscussions;

  const FeedState({
    this.posts = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.searchQuery = '',
    this.showMyDiscussions = false,
  });

  FeedState copyWith({
    List<Post>? posts,
    String? Function()? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? searchQuery,
    bool? showMyDiscussions,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      showMyDiscussions: showMyDiscussions ?? this.showMyDiscussions,
    );
  }
}

final feedProvider =
    NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    Future.microtask(_loadInitial);
    return const FeedState(isLoading: true);
  }

  String? get _currentUserId {
    try {
      return ref.read(authProvider).valueOrNull?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getPosts(
        query: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        authorId: state.showMyDiscussions ? _currentUserId : null,
      );
      state = state.copyWith(
        posts: result.items,
        nextCursor: () => result.nextCursor,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadInitial();
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, isLoading: true);
    await _loadInitial();
  }

  Future<void> setTab({required bool myDiscussions}) async {
    state = state.copyWith(showMyDiscussions: myDiscussions, isLoading: true);
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.nextCursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getPosts(
        cursor: state.nextCursor,
        query: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        authorId: state.showMyDiscussions ? _currentUserId : null,
      );
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
    String category = 'General',
  }) async {
    final repo = ref.read(communityRepositoryProvider);
    final post = await repo.createPost(
      content: content,
      tags: tags,
      category: category,
    );
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
