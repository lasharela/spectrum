import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/community/domain/post.dart';

void main() {
  group('Post', () {
    test('fromJson parses category field', () {
      final json = {
        'id': '1',
        'title': 'Hello Title',
        'content': 'Hello',
        'imageUrl': 'https://example.com/post.jpg',
        'tags': <String>[],
        'category': 'Education',
        'authorId': 'u1',
        'author': {
          'id': 'u1',
          'name': 'Alice',
          'image': null,
          'userType': 'parent',
        },
        'createdAt': '2026-01-01T00:00:00.000Z',
        'likesCount': 0,
        'commentsCount': 0,
        'liked': false,
      };
      final post = Post.fromJson(json);
      expect(post.category, 'Education');
      expect(post.title, 'Hello Title');
      expect(post.imageUrl, 'https://example.com/post.jpg');
    });

    test('fromJson defaults category to General when absent', () {
      final json = {
        'id': '1',
        'title': 'Test Title',
        'content': 'Hello',
        'tags': <String>[],
        'authorId': 'u1',
        'author': {
          'id': 'u1',
          'name': 'Alice',
          'image': null,
          'userType': 'parent',
        },
        'createdAt': '2026-01-01T00:00:00.000Z',
        'likesCount': 0,
        'commentsCount': 0,
        'liked': false,
      };
      final post = Post.fromJson(json);
      expect(post.category, 'General');
    });

    test('copyWith preserves and updates category', () {
      final post = Post(
        id: '1',
        title: 'Test Title',
        content: 'Hello',
        tags: [],
        category: 'General',
        authorId: 'u1',
        author: const PostAuthor(id: 'u1', name: 'Alice', userType: 'parent'),
        createdAt: DateTime(2026),
        likesCount: 0,
        commentsCount: 0,
        liked: false,
      );
      final updated = post.copyWith(category: 'News');
      expect(updated.category, 'News');
      expect(post.category, 'General');
    });
  });
}
