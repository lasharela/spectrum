class PostAuthor {
  final String id;
  final String name;
  final String? image;
  final String userType;

  const PostAuthor({
    required this.id,
    required this.name,
    this.image,
    required this.userType,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      userType: json['userType'] as String,
    );
  }
}

class Post {
  final String id;
  final String content;
  final List<String> tags;
  final String category;
  final String authorId;
  final PostAuthor author;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool liked;

  const Post({
    required this.id,
    required this.content,
    required this.tags,
    this.category = 'General',
    required this.authorId,
    required this.author,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.liked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      content: json['content'] as String,
      tags: (json['tags'] as List).cast<String>(),
      category: json['category'] as String? ?? 'General',
      authorId: json['authorId'] as String,
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      liked: json['liked'] as bool? ?? false,
    );
  }

  Post copyWith({String? category, int? likesCount, int? commentsCount, bool? liked}) {
    return Post(
      id: id,
      content: content,
      tags: tags,
      category: category ?? this.category,
      authorId: authorId,
      author: author,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      liked: liked ?? this.liked,
    );
  }
}
