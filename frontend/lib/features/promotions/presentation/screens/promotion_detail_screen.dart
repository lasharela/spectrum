import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/promotions/data/promotions_repository.dart';
import 'package:spectrum_app/features/promotions/domain/promotion.dart';
import 'package:spectrum_app/features/promotions/presentation/providers/promotions_provider.dart';
import 'package:spectrum_app/shared/widgets/screen.dart';


// ---------------------------------------------------------------------------
// Detail Provider
// ---------------------------------------------------------------------------

final promotionDetailProvider =
    FutureProvider.family<Promotion?, String>((ref, id) async {
  final repo = ref.read(promotionsRepositoryProvider);
  return repo.getPromotion(id);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PromotionDetailScreen extends ConsumerWidget {
  final String promotionId;

  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoAsync = ref.watch(promotionDetailProvider(promotionId));

    return Screen(
      body: promoAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => const Center(child: Text('Failed to load promotion')),
        data: (promo) {
          if (promo == null) {
            return const Center(child: Text('Promotion not found'));
          }
          return _PromotionDetailContent(promotion: promo);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _PromotionDetailContent extends ConsumerStatefulWidget {
  final Promotion promotion;

  const _PromotionDetailContent({required this.promotion});

  @override
  ConsumerState<_PromotionDetailContent> createState() =>
      _PromotionDetailContentState();
}

class _PromotionDetailContentState
    extends ConsumerState<_PromotionDetailContent> {
  late bool _liked;
  late int _likesCount;
  late bool _saved;
  late bool _claimed;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _liked = p.liked;
    _likesCount = p.likesCount;
    _saved = p.saved;
    _claimed = p.claimed;
  }

  void _toggleLike() {
    final nowLiked = !_liked;
    setState(() {
      _liked = nowLiked;
      _likesCount =
          nowLiked ? _likesCount + 1 : (_likesCount - 1).clamp(0, 999999);
    });
    ref.read(promotionsProvider.notifier).toggleLike(widget.promotion.id);
  }

  void _toggleSave() {
    setState(() => _saved = !_saved);
    ref.read(promotionsProvider.notifier).toggleSave(widget.promotion.id);
  }

  Future<void> _claim() async {
    if (_claimed) return;
    await ref
        .read(promotionsProvider.notifier)
        .claimPromotion(widget.promotion.id);
    setState(() => _claimed = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promotion;
    final theme = context.theme;
    final dateFormat = DateFormat('MMM d, yyyy');

    final isUrgent = p.expiresAt != null &&
        !p.isExpired &&
        p.expiresAt!.difference(DateTime.now()).inHours < 24;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header with discount overlay
          _ImageHeader(promotion: p),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand row
                Row(
                  children: [
                    FAvatar.raw(
                      size: 44,
                      child: Text(
                        p.store.isNotEmpty ? p.store[0].toUpperCase() : '?',
                        style: theme.typography.sm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.store,
                            style: theme.typography.lg.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            p.category,
                            style: theme.typography.xs.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  p.title,
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Countdown timer (prominent)
                if (!p.isPermanent) ...[
                  _CountdownTimer(
                    timeRemaining: p.timeRemaining,
                    isUrgent: isUrgent,
                    isExpired: p.isExpired,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Validity info card
                _ValidityCard(
                  promotion: p,
                  dateFormat: dateFormat,
                ),

                const SizedBox(height: AppSpacing.md),

                // Description
                if (p.description != null && p.description!.isNotEmpty) ...[
                  Text(
                    'About this deal',
                    style: theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    p.description!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Category tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                  ),
                  child: Text(
                    p.category,
                    style: theme.typography.xs.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Like / Save row
                Row(
                  children: [
                    // Like button
                    _DetailActionButton(
                      icon: _liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '$_likesCount',
                      color: _liked ? AppColors.accent1 : AppColors.textSecondary,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Save button
                    _DetailActionButton(
                      icon: _saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: _saved ? 'Saved' : 'Save',
                      color: _saved ? AppColors.primary : AppColors.textSecondary,
                      onTap: _toggleSave,
                    ),

                    // Link to catalog if organizationId is set
                    if (p.organizationId != null) ...[
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            context.push('/catalog/${p.organizationId}'),
                        icon: const Icon(Icons.storefront_outlined, size: 16),
                        label: const Text('View in Catalog'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: theme.typography.xs.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Full-width claim button
                SizedBox(
                  width: double.infinity,
                  child: _claimed
                      ? _ClaimedFullButton()
                      : FButton(
                          onPress: p.isExpired ? null : _claim,
                          child: const Text('Claim Deal'),
                        ),
                ),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ImageHeader extends StatelessWidget {
  final Promotion promotion;

  const _ImageHeader({required this.promotion});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image or placeholder
          if (promotion.imageUrl != null)
            Image.network(
              promotion.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _ImagePlaceholder(category: promotion.category),
            )
          else
            _ImagePlaceholder(category: promotion.category),

          // Discount badge overlay
          if (promotion.discount != null)
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  promotion.discount!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String category;

  const _ImagePlaceholder({required this.category});

  static const _icons = <String, IconData>{
    'Health & Wellness': Icons.favorite_outline_rounded,
    'Education': Icons.cast_for_education_outlined,
    'Entertainment': Icons.movie_outlined,
    'Food & Dining': Icons.restaurant_outlined,
    'Services': Icons.handshake_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[category] ?? Icons.local_offer_outlined;

    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          icon,
          size: 72,
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _CountdownTimer extends StatelessWidget {
  final String timeRemaining;
  final bool isUrgent;
  final bool isExpired;

  const _CountdownTimer({
    required this.timeRemaining,
    required this.isUrgent,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    Color bgColor;
    Color textColor;
    IconData icon;

    if (isExpired) {
      bgColor = AppColors.textDisabled.withValues(alpha: 0.12);
      textColor = AppColors.textSecondary;
      icon = Icons.timer_off_outlined;
    } else if (isUrgent) {
      bgColor = AppColors.warning.withValues(alpha: 0.12);
      textColor = AppColors.warning;
      icon = Icons.alarm_rounded;
    } else {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
      icon = Icons.timer_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: AppSpacing.sm),
          Text(
            timeRemaining,
            style: theme.typography.sm.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isUrgent) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              '— Act fast!',
              style: theme.typography.xs.copyWith(
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValidityCard extends StatelessWidget {
  final Promotion promotion;
  final DateFormat dateFormat;

  const _ValidityCard({required this.promotion, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius / 2),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _ValidityRow(
            icon: Icons.calendar_today_outlined,
            label: 'Valid from',
            value: dateFormat.format(promotion.validFrom),
          ),
          if (promotion.expiresAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.sm),
            _ValidityRow(
              icon: Icons.event_busy_outlined,
              label: 'Expires',
              value: dateFormat.format(promotion.expiresAt!),
              valueColor: promotion.isExpired
                  ? AppColors.error
                  : (promotion.expiresAt!.difference(DateTime.now()).inDays < 7
                      ? AppColors.warning
                      : null),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.sm),
            _ValidityRow(
              icon: Icons.all_inclusive_rounded,
              label: 'Duration',
              value: 'Permanent deal',
              valueColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _ValidityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ValidityRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.typography.xs.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.typography.xs.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colors.foreground,
          ),
        ),
      ],
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: theme.typography.xs.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimedFullButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius / 2),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Deal Claimed',
            style: theme.typography.sm.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
