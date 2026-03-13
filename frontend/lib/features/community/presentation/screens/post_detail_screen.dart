import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _commentController = TextEditingController();
  List<Comment> _comments = [];
  String? _nextCursor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = result.items;
        _nextCursor = result.nextCursor;
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final repo = ref.read(communityRepositoryProvider);
    final comment = await repo.addComment(
      widget.postId,
      content: _commentController.text.trim(),
    );
    setState(() {
      _comments.insert(0, comment);
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final post =
        feedState.posts.where((p) => p.id == widget.postId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      PostCard(
                        post: post,
                        onLike: () => ref
                            .read(feedProvider.notifier)
                            .toggleLike(post.id),
                      ),
                      const Divider(),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        ..._comments.map((c) => ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.cyan,
                                child: Text(
                                  c.author.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                c.author.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(c.content),
                            )),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            maxLength: 2000,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addComment,
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
    _commentController.dispose();
    super.dispose();
  }
}
