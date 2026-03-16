import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_provider.dart';

class AdminCommunityView extends ConsumerWidget {
  const AdminCommunityView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(adminPostsProvider);

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(child: Text('No posts'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminPostsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (ctx, i) => _PostCard(post: posts[i]),
          ),
        );
      },
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Map<String, dynamic> post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleted = post['deletedAt'] != null;
    final author = post['author'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDeleted
          ? Theme.of(context)
              .colorScheme
              .errorContainer
              .withValues(alpha: 0.3)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post['title'] as String? ?? '(no title)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isDeleted)
                  Chip(
                    label: const Text('Deleted'),
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (author != null) Text('Author: ${author['name'] ?? ''}'),
            Text('Category: ${post['category'] ?? ''}'),
            if (isDeleted) Text('Deleted at: ${post['deletedAt']}'),
            const SizedBox(height: 12),
            if (isDeleted)
              FilledButton.tonal(
                onPressed: () => _restore(ref, context),
                child: const Text('Restore'),
              )
            else
              OutlinedButton(
                onPressed: () => _softDelete(ref, context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _softDelete(WidgetRef ref, BuildContext context) async {
    final id = post['id'] as String;
    final repo = ref.read(adminRepositoryProvider);
    final success = await repo.softDeletePost(id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
      ref.invalidate(adminPostsProvider);
    }
  }

  Future<void> _restore(WidgetRef ref, BuildContext context) async {
    final id = post['id'] as String;
    final repo = ref.read(adminRepositoryProvider);
    final success = await repo.restorePost(id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post restored')),
      );
      ref.invalidate(adminPostsProvider);
    }
  }
}
