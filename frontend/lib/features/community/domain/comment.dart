class CommentAuthor {
  final String id;
  final String name;
  final String? image;

  const CommentAuthor({
    required this.id,
    required this.name,
    this.image,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
    );
  }
}

class Comment {
  final String id;
  final String content;
  final String authorId;
  final CommentAuthor author;
  final String postId;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.author,
    required this.postId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      author: CommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
      postId: json['postId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
