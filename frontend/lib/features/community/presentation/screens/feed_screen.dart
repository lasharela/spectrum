import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: feedState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(feedProvider.notifier).refresh(),
              child: feedState.posts.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text('No posts yet. Be the first!'),
                        ),
                      ],
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.extentAfter < 200) {
                          ref.read(feedProvider.notifier).loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: feedState.posts.length +
                            (feedState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == feedState.posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final post = feedState.posts[index];
                          return PostCard(
                            post: post,
                            onTap: () =>
                                context.push('/community/post/${post.id}'),
                            onLike: () => ref
                                .read(feedProvider.notifier)
                                .toggleLike(post.id),
                            onDelete: post.authorId == currentUser?.id
                                ? () => _confirmDelete(context, ref, post.id)
                                : null,
                          );
                        },
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePost(context, ref),
        backgroundColor: AppColors.cyan,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(feedProvider.notifier).deletePost(postId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreatePost(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              maxLength: 5000,
              decoration: const InputDecoration(
                hintText: 'Share something with the community...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref.read(feedProvider.notifier).createPost(
                          content: controller.text.trim(),
                        );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Post'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
