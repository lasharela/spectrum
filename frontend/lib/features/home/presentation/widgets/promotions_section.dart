import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../domain/dashboard.dart';

class PromotionsSection extends StatelessWidget {
  final List<DashboardPromotion> promotions;

  const PromotionsSection({super.key, required this.promotions});

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
              itemBuilder: (context, index) => _buildPromoCard(context, promotions[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildPromoCard(BuildContext context, DashboardPromotion promo) {
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
              FBadge(child: Text(promo.discount!)),
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
