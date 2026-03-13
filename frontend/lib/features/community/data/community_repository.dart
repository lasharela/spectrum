import '../../../shared/api/api_client.dart';
import '../domain/post.dart';
import '../domain/comment.dart';

class PaginatedResult<T> {
  final List<T> items;
  final String? nextCursor;

  const PaginatedResult({required this.items, this.nextCursor});
}

class CommunityRepository {
  final ApiClient _api;

  CommunityRepository(this._api);

  Future<PaginatedResult<Post>> getPosts({
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _api.get('/api/posts', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final data = response.data as Map<String, dynamic>;
    final posts = (data['posts'] as List)
        .map((p) => Post.fromJson(p as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: posts,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Future<Post> createPost({
    required String content,
    List<String> tags = const [],
  }) async {
    final response = await _api.post('/api/posts', data: {
      'content': content,
      'tags': tags,
    });
    final data = response.data as Map<String, dynamic>;
    return Post.fromJson(data['post'] as Map<String, dynamic>);
  }

  Future<Post> getPost(String id) async {
    final response = await _api.get('/api/posts/$id');
    final data = response.data as Map<String, dynamic>;
    return Post.fromJson(data['post'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String id) async {
    await _api.delete('/api/posts/$id');
  }

  Future<PaginatedResult<Comment>> getComments(
    String postId, {
    String? cursor,
    int limit = 20,
  }) async {
    final response =
        await _api.get('/api/posts/$postId/comments', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final data = response.data as Map<String, dynamic>;
    final comments = (data['comments'] as List)
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: comments,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Future<Comment> addComment(
    String postId, {
    required String content,
  }) async {
    final response = await _api.post('/api/posts/$postId/comments', data: {
      'content': content,
    });
    final data = response.data as Map<String, dynamic>;
    return Comment.fromJson(data['comment'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/api/posts/$postId/comments/$commentId');
  }

  Future<({bool liked, int likesCount})> likePost(String postId) async {
    final response = await _api.put('/api/posts/$postId/reactions');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool,
      likesCount: data['likesCount'] as int,
    );
  }

  Future<({bool liked, int likesCount})> unlikePost(String postId) async {
    final response = await _api.delete('/api/posts/$postId/reactions');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool,
      likesCount: data['likesCount'] as int,
    );
  }
}
