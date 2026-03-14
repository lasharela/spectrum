import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/dashboard.dart';

class PromotionsSection extends StatelessWidget {
  final List<DashboardPromotion> promotions;

  const PromotionsSection({super.key, required this.promotions});

  static const _badgeColors = [
    AppColors.accent1, // Red
    AppColors.accent2, // Amber
    AppColors.primary, // Blue
  ];

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hottest Promotions',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        if (promotions.isEmpty)
          FCard.raw(
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
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final badgeColor = _badgeColors[index % _badgeColors.length];
                return _buildPromoCard(context, promotions[index], badgeColor);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPromoCard(BuildContext context, DashboardPromotion promo, Color badgeColor) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (promo.discount != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  promo.discount!,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (promo.discount != null)
              const SizedBox(height: 8),
            Text(
              promo.title,
              style: typography.sm.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              promo.store,
              style: typography.xs.copyWith(color: colors.mutedForeground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
