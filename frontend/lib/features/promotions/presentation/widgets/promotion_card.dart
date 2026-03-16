import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';

class PromotionCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onClaim;

  const PromotionCard({
    super.key,
    required this.promotion,
    this.onTap,
    this.onLike,
    this.onSave,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isUrgent = promotion.expiresAt != null &&
        !promotion.isExpired &&
        promotion.expiresAt!.difference(DateTime.now()).inHours < 24;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [AppColors.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: [discount] [timer] ... [category]
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  if (promotion.discount != null) ...[
                    _DiscountBadge(label: promotion.discount!),
                    if (!promotion.isPermanent)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                  if (!promotion.isPermanent)
                    _TimerBadge(
                      label: promotion.timeRemaining,
                      isUrgent: isUrgent,
                      isExpired: promotion.isExpired,
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                    ),
                    child: Text(
                      promotion.category,
                      style: theme.typography.xs.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Store row
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  FAvatar.raw(
                    size: 28,
                    child: Text(
                      promotion.store.isNotEmpty
                          ? promotion.store[0].toUpperCase()
                          : '?',
                      style: theme.typography.xs.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      promotion.store,
                      style: theme.typography.xs.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Text(
                promotion.title,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.foreground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Action row: like + save + claim
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // Like button
                  _LikeButton(
                    liked: promotion.liked,
                    count: promotion.likesCount,
                    onTap: onLike,
                  ),

                  const SizedBox(width: AppSpacing.xxs),

                  // Save button
                  _SaveButton(
                    saved: promotion.saved,
                    onTap: onSave,
                  ),

                  const Spacer(),

                  // Claim button or Claimed badge
                  if (promotion.claimed)
                    _ClaimedBadge()
                  else
                    _ClaimButton(onTap: onClaim),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _DiscountBadge extends StatelessWidget {
  final String label;

  const _DiscountBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final String label;
  final bool isUrgent;
  final bool isExpired;

  const _TimerBadge({
    required this.label,
    required this.isUrgent,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    Color bgColor;
    Color textColor;

    if (isExpired) {
      bgColor = AppColors.textDisabled.withValues(alpha: 0.15);
      textColor = AppColors.textSecondary;
    } else if (isUrgent) {
      bgColor = AppColors.warning.withValues(alpha: 0.15);
      textColor = AppColors.warning;
    } else {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired
                ? Icons.timer_off_outlined
                : Icons.timer_outlined,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.typography.xs.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final int count;
  final VoidCallback? onTap;

  const _LikeButton({
    required this.liked,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: liked ? AppColors.accent1 : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '$count',
              style: theme.typography.xs.copyWith(
                color: liked ? AppColors.accent1 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback? onTap;

  const _SaveButton({required this.saved, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 18,
          color: saved ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ClaimButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return FButton(
      onPress: onTap,
      child: const Text('Claim'),
    );
  }
}

class _ClaimedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'Claimed',
            style: theme.typography.xs.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
