import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../../shared/widgets/promotion_carousel.dart';
import '../../domain/dashboard.dart';

class PromotionsSection extends StatelessWidget {
  final List<DashboardPromotion> promotions;
  final void Function(String id)? onItemSelected;

  const PromotionsSection({
    super.key,
    required this.promotions,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Hottest Promotions',
            style: typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (promotions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FCard.raw(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.local_offer_outlined, size: 32, color: colors.mutedForeground),
                    const SizedBox(height: 8),
                    Text(
                      'No promotions yet',
                      style: typography.sm.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          PromotionCarousel(
            promotions: promotions,
            onItemSelected: onItemSelected,
          ),
      ],
    );
  }
}
