import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spectrum_app/features/community/data/community_repository.dart';
import 'package:spectrum_app/features/community/domain/post.dart';
import 'package:spectrum_app/shared/api/api_client.dart';

import '../../../helpers/mocks.dart';

/// A Dio interceptor that captures the last request and returns a canned response.
class _MockInterceptor extends Interceptor {
  RequestOptions? lastRequest;
  Object? responseData;

  _MockInterceptor({this.responseData});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    lastRequest = options;
    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: responseData,
    ));
  }
}

Map<String, dynamic> _samplePostJson({
  String id = 'p1',
  String title = 'Test Post',
}) {
  return {
    'id': id,
    'title': title,
    'content': 'Some content',
    'imageUrl': null,
    'tags': <String>['General'],
    'category': 'General',
    'authorId': 'u1',
    'author': {
      'id': 'u1',
      'name': 'Test User',
      'userType': 'parent',
    },
    'createdAt': '2025-01-01T00:00:00.000Z',
    'likesCount': 0,
    'commentsCount': 0,
    'liked': false,
  };
}

void main() {
  late Dio dio;
  late _MockInterceptor mockInterceptor;
  late ApiClient apiClient;
  late CommunityRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    // Clear default interceptors so our mock handles everything
    dio.interceptors.clear();

    mockInterceptor = _MockInterceptor(
      responseData: {
        'posts': [_samplePostJson()],
        'nextCursor': 'cursor-abc',
      },
    );
    dio.interceptors.add(mockInterceptor);

    apiClient = ApiClient(
      baseUrl: 'http://localhost',
      dio: dio,
      storage: MockSecureStorage(),
    );
    repository = CommunityRepository(apiClient);
  });

  group('CommunityRepository.getPosts', () {
    test('sends request to /api/posts with default limit', () async {
      await repository.getPosts();

      final req = mockInterceptor.lastRequest!;
      expect(req.path, '/api/posts');
      expect(req.queryParameters['limit'], 20);
    });

    test('passes query param as q when provided', () async {
      await repository.getPosts(query: 'autism');

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters['q'], 'autism');
    });

    test('does not pass q when query is null', () async {
      await repository.getPosts();

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters.containsKey('q'), false);
    });

    test('does not pass q when query is empty', () async {
      await repository.getPosts(query: '');

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters.containsKey('q'), false);
    });

    test('passes category param when provided', () async {
      await repository.getPosts(category: 'Education');

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters['category'], 'Education');
    });

    test('passes state and city params when provided', () async {
      await repository.getPosts(state: 'California', city: 'Los Angeles');

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters['state'], 'California');
      expect(req.queryParameters['city'], 'Los Angeles');
    });

    test('does not pass state or city when not provided', () async {
      await repository.getPosts();

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters.containsKey('state'), false);
      expect(req.queryParameters.containsKey('city'), false);
    });

    test('passes cursor when provided', () async {
      await repository.getPosts(cursor: 'abc123');

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters['cursor'], 'abc123');
    });

    test('passes authorId when provided', () async {
      await repository.getPosts(authorId: 'user-42');

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters['authorId'], 'user-42');
    });

    test('passes all query params together', () async {
      await repository.getPosts(
        cursor: 'cur1',
        limit: 10,
        query: 'help',
        category: 'Support',
        authorId: 'u5',
        state: 'Texas',
        city: 'Houston',
      );

      final req = mockInterceptor.lastRequest!;
      expect(req.queryParameters['cursor'], 'cur1');
      expect(req.queryParameters['limit'], 10);
      expect(req.queryParameters['q'], 'help');
      expect(req.queryParameters['category'], 'Support');
      expect(req.queryParameters['authorId'], 'u5');
      expect(req.queryParameters['state'], 'Texas');
      expect(req.queryParameters['city'], 'Houston');
    });
  });

  group('CommunityRepository.getPosts response parsing', () {
    test('parses posts list from response', () async {
      mockInterceptor.responseData = {
        'posts': [
          _samplePostJson(id: 'p1', title: 'First'),
          _samplePostJson(id: 'p2', title: 'Second'),
        ],
        'nextCursor': 'next-page',
      };

      final result = await repository.getPosts();

      expect(result.items, hasLength(2));
      expect(result.items[0], isA<Post>());
      expect(result.items[0].id, 'p1');
      expect(result.items[0].title, 'First');
      expect(result.items[1].id, 'p2');
      expect(result.items[1].title, 'Second');
    });

    test('parses nextCursor from response', () async {
      mockInterceptor.responseData = {
        'posts': [_samplePostJson()],
        'nextCursor': 'cursor-xyz',
      };

      final result = await repository.getPosts();
      expect(result.nextCursor, 'cursor-xyz');
    });

    test('handles null nextCursor when no more pages', () async {
      mockInterceptor.responseData = {
        'posts': [_samplePostJson()],
        'nextCursor': null,
      };

      final result = await repository.getPosts();
      expect(result.nextCursor, isNull);
    });

    test('parses empty posts list', () async {
      mockInterceptor.responseData = {
        'posts': <Map<String, dynamic>>[],
        'nextCursor': null,
      };

      final result = await repository.getPosts();
      expect(result.items, isEmpty);
      expect(result.nextCursor, isNull);
    });

    test('parses post fields correctly', () async {
      mockInterceptor.responseData = {
        'posts': [
          {
            'id': 'post-1',
            'title': 'My Title',
            'content': 'My Content',
            'imageUrl': 'https://example.com/img.jpg',
            'tags': ['Tag1', 'Tag2'],
            'category': 'Education',
            'authorId': 'author-1',
            'author': {
              'id': 'author-1',
              'name': 'Jane Doe',
              'image': 'https://example.com/avatar.jpg',
              'userType': 'professional',
            },
            'createdAt': '2025-06-15T10:30:00.000Z',
            'likesCount': 42,
            'commentsCount': 7,
            'liked': true,
          }
        ],
        'nextCursor': null,
      };

      final result = await repository.getPosts();
      final post = result.items.first;

      expect(post.id, 'post-1');
      expect(post.title, 'My Title');
      expect(post.content, 'My Content');
      expect(post.imageUrl, 'https://example.com/img.jpg');
      expect(post.tags, ['Tag1', 'Tag2']);
      expect(post.category, 'Education');
      expect(post.authorId, 'author-1');
      expect(post.author.name, 'Jane Doe');
      expect(post.author.image, 'https://example.com/avatar.jpg');
      expect(post.author.userType, 'professional');
      expect(post.likesCount, 42);
      expect(post.commentsCount, 7);
      expect(post.liked, true);
    });
  });
}
