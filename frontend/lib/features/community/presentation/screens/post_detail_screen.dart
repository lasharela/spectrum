import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/comment.dart';
import '../providers/feed_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _replyController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = result.items;
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addReply() async {
    if (_replyController.text.trim().isEmpty) return;
    final repo = ref.read(communityRepositoryProvider);
    final comment = await repo.addComment(
      widget.postId,
      content: _replyController.text.trim(),
    );
    setState(() {
      _comments.insert(0, comment);
      _replyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final post =
        feedState.posts.where((p) => p.id == widget.postId).firstOrNull;

    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Discussion')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Author header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.cyan,
                      child: Text(
                        post.author.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          Text(
                            DateFormat.yMMMd()
                                .add_jm()
                                .format(post.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category tag
                CategoryTag(category: post.category),
                const SizedBox(height: 12),
                // Full content
                Text(post.content, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 16),
                // Like/comment actions
                Row(
                  children: [
                    InkWell(
                      onTap: () => ref
                          .read(feedProvider.notifier)
                          .toggleLike(post.id),
                      child: Row(
                        children: [
                          Icon(
                            post.liked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: post.liked
                                ? AppColors.coral
                                : AppColors.textGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: TextStyle(color: AppColors.textGray),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Icon(Icons.comment_outlined,
                        size: 20, color: AppColors.textGray),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ],
                ),
                const Divider(height: 32),
                // Replies header
                const Text(
                  'Replies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Comment list
                if (_isLoadingComments)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No replies yet. Be the first!',
                        style: TextStyle(color: AppColors.textGray),
                      ),
                    ),
                  )
                else
                  ..._comments.map((c) => _ReplyCard(comment: c)),
              ],
            ),
          ),
          // Reply input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Add a reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      maxLength: 2000,
                      maxLines: null,
                      buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addReply,
                    icon: Icon(Icons.send, color: AppColors.cyan),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}

class _ReplyCard extends StatelessWidget {
  final Comment comment;

  const _ReplyCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.cyan,
            child: Text(
              comment.author.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMd().format(comment.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textGray),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
