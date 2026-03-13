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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: post.tags
                      .map((tag) => Chip(
                            label:
                                Text(tag, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
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
                DateFormat.yMMMd().add_jm().format(post.createdAt),
                style: TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            color: AppColors.textGray,
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onLike,
          child: Row(
            children: [
              Icon(
                post.liked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: post.liked ? AppColors.coral : AppColors.textGray,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likesCount}',
                style: TextStyle(color: AppColors.textGray, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Icon(Icons.comment_outlined, size: 20, color: AppColors.textGray),
            const SizedBox(width: 4),
            Text(
              '${post.commentsCount}',
              style: TextStyle(color: AppColors.textGray, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
