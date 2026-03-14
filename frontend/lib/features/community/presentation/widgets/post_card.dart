import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onCommentTap;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onCommentTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final contentParts = _buildContentParts(post);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AuthorAvatar(name: post.author.name),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.name,
                          style: typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: typography.xs.copyWith(
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...[
                Text(
                  contentParts.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.lg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (contentParts.description.isNotEmpty)
                Text(
                  contentParts.description,
                  maxLines: post.imageUrl != null ? 3 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: typography.sm.copyWith(
                    color: colors.mutedForeground,
                    height: 1.45,
                  ),
                ),
              if (post.imageUrl case final imageUrl?) ...[
                const SizedBox(height: AppSpacing.md),
                _PostImage(imageUrl: imageUrl),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _ActionButton(
                    icon: post.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: '${post.likesCount}',
                    color: post.liked
                        ? AppColors.accent1
                        : colors.mutedForeground,
                    onPress: onLike,
                  ),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentsCount}',
                    color: colors.mutedForeground,
                    onPress: onCommentTap ?? onTap,
                  ),
                  const Spacer(),
                  if (post.category.isNotEmpty)
                    CategoryTag(category: post.category, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(dt);
  }
}

({String title, String description}) _buildContentParts(Post post) {
  return (title: post.title.trim(), description: post.content.trim());
}

Color categoryColor(String category) {
  return switch (category) {
    'Sensory' => AppColors.secondary,
    'Education' => AppColors.tertiary,
    'Support' => AppColors.accent1,
    'Resources' => AppColors.quaternary,
    'Daily Life' => AppColors.accent2,
    'News' => AppColors.accent2,
    'Social' => AppColors.primary,
    'General' => AppColors.textSecondary,
    _ => AppColors.textSecondary,
  };
}

class CategoryTag extends StatelessWidget {
  final String category;
  final bool compact;

  const CategoryTag({super.key, required this.category, this.compact = false});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Text(
        category,
        style: context.theme.typography.xs.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  final String imageUrl;

  const _PostImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.muted),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.image_outlined,
                  color: colors.mutedForeground,
                  size: 28,
                ),
              );
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.mutedForeground,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String name;

  const _AuthorAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return FAvatar.raw(
      size: 40,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPress;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: FButtonVariant.ghost,
      size: FButtonSizeVariant.sm,
      mainAxisSize: MainAxisSize.min,
      onPress: onPress,
      prefix: Icon(icon, color: color, size: 18),
      child: Text(
        label,
        style: context.theme.typography.xs.copyWith(color: color),
      ),
    );
  }
}
