import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../features/home/domain/dashboard.dart';

class PromotionCarousel extends StatelessWidget {
  final List<DashboardPromotion> promotions;
  final void Function(String id)? onItemSelected;

  const PromotionCarousel({
    required this.promotions,
    this.onItemSelected,
    super.key,
  });

  static const _badgeColors = [
    AppColors.accent1,
    AppColors.accent2,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    if (promotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportFraction =
            (constraints.maxWidth - (24 + 12)) / constraints.maxWidth;

        return CarouselSlider.builder(
          itemCount: promotions.length,
          itemBuilder: (context, index, realIndex) {
            return _promotionCard(index, context);
          },
          options: CarouselOptions(
            height: 200,
            viewportFraction: viewportFraction,
            enableInfiniteScroll: false,
          ),
        );
      },
    );
  }

  Widget _promotionCard(int index, BuildContext context) {
    final promo = promotions[index];
    const borderRadius = 18.0;
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final badgeColor = _badgeColors[index % _badgeColors.length];

    return GestureDetector(
      onTap: () => onItemSelected?.call(promo.id),
      child: Container(
        margin: EdgeInsets.only(
          left: index == 0 ? 0 : 8,
          right: index == promotions.length - 1 ? 0 : 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: colors.secondary,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image
            if (promo.imageUrl != null)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: promo.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // Subtle gradient — only bottom portion
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(180),
                      Colors.black.withAlpha(60),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.6],
                  ),
                ),
              ),
            ),

            // Top-left: brand logo + name
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FAvatar.raw(
                    size: 28,
                    child: promo.brandLogoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: promo.brandLogoUrl!,
                            fit: BoxFit.cover,
                            width: 28,
                            height: 28,
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                promo.store.isNotEmpty
                                    ? promo.store[0].toUpperCase()
                                    : '?',
                                style: typography.xs.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              promo.store.isNotEmpty
                                  ? promo.store[0].toUpperCase()
                                  : '?',
                              style: typography.xs.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    promo.store,
                    style: typography.xs.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Top-right: time remaining badge
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(promo.expiresAt),
                      style: typography.xs.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom: title + discount badge
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        promo.title,
                        style: typography.sm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (promo.discount != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.badgeRadius),
                        ),
                        child: Text(
                          promo.discount!,
                          style: typography.xs.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return '';

    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'Ending soon';
  }
}
