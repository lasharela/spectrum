import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              // Category tag
              CategoryTag(category: post.category),
              const SizedBox(height: 8),
              // Content preview (max 3 lines)
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                _formatTimestamp(post.createdAt),
                style: TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: onDelete,
            color: AppColors.textGray,
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: post.liked ? Icons.favorite : Icons.favorite_border,
          label: '${post.likesCount}',
          color: post.liked ? AppColors.coral : AppColors.textGray,
          onTap: onLike,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.comment_outlined,
          label: '${post.commentsCount}',
          color: AppColors.textGray,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          color: AppColors.textGray,
        ),
      ],
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

/// Shared category color mapping — used by PostCard and PostDetailScreen
Color categoryColor(String category) {
  return switch (category) {
    'General' => AppColors.cyan,
    'Sensory' => AppColors.purple,
    'Education' => AppColors.navy,
    'Support' => AppColors.coral,
    'Resources' => AppColors.success,
    'Daily Life' => AppColors.orange,
    'News' => AppColors.yellow,
    'Social' => AppColors.cyan,
    _ => AppColors.textGray,
  };
}

/// Shared category tag widget — used by PostCard and PostDetailScreen
class CategoryTag extends StatelessWidget {
  final String category;

  const CategoryTag({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
