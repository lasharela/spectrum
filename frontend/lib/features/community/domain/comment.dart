import 'package:spectrum_app/shared/domain/author.dart';

typedef CommentAuthor = Author;

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
