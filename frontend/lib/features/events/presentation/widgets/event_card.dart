import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/events/domain/event.dart';
import 'package:spectrum_app/shared/widgets/image_list_card.dart';

/// Reusable event card for Events list.
/// Shows image, title, date/time, location, and badges for online/free/price.
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final dateStr = dateFormat.format(event.startDate);
    final timeStr = timeFormat.format(event.startDate);

    final details = <ImageListCardDetail>[
      ImageListCardDetail(
        icon: Icons.calendar_today_outlined,
        text: '$dateStr at $timeStr',
      ),
      if (event.location != null)
        ImageListCardDetail(
          icon: event.isOnline ? Icons.computer_outlined : Icons.location_on_outlined,
          text: event.location!,
        ),
    ];

    return ImageListCard(
      title: event.title,
      imageUrl: event.imageUrl,
      details: details,
      trailing: _buildTrailing(context),
      onTap: onTap,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final typography = context.theme.typography;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Category badge
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
            event.category,
            style: typography.xs.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        // Price badge
        if (event.isFree)
          Text(
            'FREE',
            style: typography.xs.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (event.price != null)
          Text(
            event.price!,
            style: typography.xs.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
