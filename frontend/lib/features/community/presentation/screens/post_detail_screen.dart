import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import '../../domain/comment.dart';
import '../../domain/post.dart';
import '../providers/feed_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/screen.dart';
import '../widgets/post_card.dart';

// --- Post Detail Provider ---

final postDetailProvider =
    FutureProvider.family<Post?, String>((ref, id) async {
  final repo = ref.read(communityRepositoryProvider);
  return repo.getPost(id);
});

// --- Post Detail Screen ---

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return Screen(
      body: postAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => const Center(child: Text('Failed to load discussion')),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('Discussion not found'));
          }
          return _PostDetailContent(post: post);
        },
      ),
    );
  }
}

// --- Post Detail Content ---

class _PostDetailContent extends ConsumerStatefulWidget {
  final Post post;

  const _PostDetailContent({required this.post});

  @override
  ConsumerState<_PostDetailContent> createState() => _PostDetailContentState();
}

class _PostDetailContentState extends ConsumerState<_PostDetailContent> {
  final _replyController = TextEditingController();
  late bool _liked;
  late int _likesCount;
  List<Comment> _comments = [];
  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.liked;
    _likesCount = widget.post.likesCount;
    _loadComments();
  }

  Future<void> _loadComments() async {
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getComments(widget.post.id);
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

  Future<void> _toggleLike() async {
    final repo = ref.read(communityRepositoryProvider);
    final wasLiked = _liked;
    // Optimistic update
    setState(() {
      _liked = !wasLiked;
      _likesCount += wasLiked ? -1 : 1;
    });

    try {
      final result = wasLiked
          ? await repo.unlikePost(widget.post.id)
          : await repo.likePost(widget.post.id);
      if (mounted) {
        setState(() {
          _liked = result.liked;
          _likesCount = result.likesCount;
        });
      }
    } catch (_) {
      // Revert on error
      if (mounted) {
        setState(() {
          _liked = wasLiked;
          _likesCount += wasLiked ? 1 : -1;
        });
      }
    }

    // Sync feed list
    try {
      ref.read(feedProvider.notifier).toggleLike(widget.post.id);
    } catch (_) {}
  }

  Future<void> _addReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final repo = ref.read(communityRepositoryProvider);
    try {
      final comment = await repo.addComment(
        widget.post.id,
        content: text,
      );
      if (mounted) {
        setState(() {
          _comments.insert(0, comment);
          _replyController.clear();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = context.theme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero image (if exists) or category icon placeholder
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: post.imageUrl != null
                        ? Image.network(
                            post.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _CategoryPlaceholder(category: post.category),
                          )
                        : _CategoryPlaceholder(category: post.category),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 2. Category badge
                CategoryTag(category: post.category),

                const SizedBox(height: AppSpacing.md),

                // 3. Post title
                Text(
                  post.title,
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 4. Author row
                Row(
                  children: [
                    FAvatar.raw(
                      size: 40,
                      child: Center(
                        child: Text(
                          post.author.name.isEmpty
                              ? '?'
                              : post.author.name[0].toUpperCase(),
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.name,
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.yMMMd()
                                .add_jm()
                                .format(post.createdAt),
                            style: theme.typography.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // 5. Full content
                Text(
                  post.content,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 6. Tags
                if (post.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: post.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colors.muted,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.badgeRadius),
                        ),
                        child: Text(
                          tag,
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 7. Like button
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    variant:
                        _liked ? FButtonVariant.primary : FButtonVariant.outline,
                    onPress: _toggleLike,
                    prefix: Icon(
                      _liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    child: Text(
                      _liked
                          ? 'Liked ($_likesCount)'
                          : 'Like ($_likesCount)',
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 8. Replies section header
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Replies (${_comments.length})',
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 9. Comments list
                if (_isLoadingComments)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(child: FCircularProgress()),
                  )
                else if (_comments.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: theme.colors.mutedForeground
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No replies yet. Be the first!',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._comments.map((c) => _ReplyCard(comment: c)),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),

        // 10. Sticky reply input
        _ReplyInput(
          controller: _replyController,
          onSend: _addReply,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }
}

// --- Category Placeholder ---

class _CategoryPlaceholder extends StatelessWidget {
  final String category;

  const _CategoryPlaceholder({required this.category});

  static const _categoryIcons = <String, IconData>{
    'General': Icons.forum_outlined,
    'Sensory': Icons.spa_outlined,
    'Education': Icons.school_outlined,
    'Support': Icons.volunteer_activism_outlined,
    'Resources': Icons.library_books_outlined,
    'Daily Life': Icons.wb_sunny_outlined,
    'News': Icons.newspaper_outlined,
    'Social': Icons.people_outline,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category] ?? Icons.forum_outlined;

    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// --- Reply Card ---

class _ReplyCard extends StatelessWidget {
  final Comment comment;

  const _ReplyCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FAvatar.raw(
            size: 32,
            child: Center(
              child: Text(
                comment.author.name.isEmpty
                    ? '?'
                    : comment.author.name[0].toUpperCase(),
                style: theme.typography.xs.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author.name,
                      style: theme.typography.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat.yMMMd().format(comment.createdAt),
                      style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  comment.content,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reply Input ---

class _ReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ReplyInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          top: BorderSide(color: theme.colors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: FTextField(
                control: FTextFieldControl.managed(
                  controller: controller,
                ),
                hint: 'Add a reply...',
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FButton(
              onPress: onSend,
              size: FButtonSizeVariant.sm,
              child: const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
