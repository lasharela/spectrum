import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/shared/widgets/image_list_card.dart';

/// Reusable place card for Catalog list and Home dashboard.
/// Shows image, name, address, optional rating, optional category tag.
class PlaceCard extends StatelessWidget {
  final String name;
  final String? address;
  final String? imageUrl;
  final double? averageRating;
  final int? ratingCount;
  final String? category;
  final bool showRating;
  final VoidCallback? onTap;

  const PlaceCard({
    super.key,
    required this.name,
    this.address,
    this.imageUrl,
    this.averageRating,
    this.ratingCount,
    this.category,
    this.showRating = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final details = <ImageListCardDetail>[
      if (address != null)
        ImageListCardDetail(icon: Icons.location_on_outlined, text: address!),
      if (showRating && averageRating != null && averageRating! > 0)
        ImageListCardDetail(
          icon: Icons.star,
          text:
              '${averageRating!.toStringAsFixed(1)} (${ratingCount ?? 0} reviews)',
        ),
    ];

    return ImageListCard(
      title: name,
      imageUrl: imageUrl,
      details: details,
      trailing: category != null
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
              ),
              child: Text(
                category!,
                style: context.theme.typography.xs.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
