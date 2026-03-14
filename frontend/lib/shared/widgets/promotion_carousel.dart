import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
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

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.black.withAlpha(0),
                    ],
                    stops: const [0.0, 0.2, 1.0],
                  ),
                ),
              ),
            ),

            // Time remaining badge (top-right)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeRemaining(promo.expiresAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom content: brand logo + name, promotion title
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand row: logo + name
                    Row(
                      children: [
                        _buildBrandLogo(promo),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            promo.store,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Promotion title
                    Text(
                      promo.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandLogo(DashboardPromotion promo) {
    const size = 28.0;

    if (promo.brandLogoUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: promo.brandLogoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _brandLogoFallback(promo, size),
        ),
      );
    }

    return _brandLogoFallback(promo, size);
  }

  Widget _brandLogoFallback(DashboardPromotion promo, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(51),
      ),
      alignment: Alignment.center,
      child: Text(
        promo.store.isNotEmpty ? promo.store[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
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
