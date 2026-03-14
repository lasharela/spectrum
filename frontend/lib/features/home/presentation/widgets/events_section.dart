import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../../shared/widgets/image_list_card.dart';
import '../../domain/dashboard.dart';

class EventsSection extends StatelessWidget {
  final List<DashboardEvent> events;

  const EventsSection({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Events',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.event_outlined, size: 32, color: colors.mutedForeground),
                  const SizedBox(height: 8),
                  Text(
                    'No upcoming events',
                    style: typography.sm.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          )
        else
          ...events.map((event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ImageListCard(
                  imageUrl: event.imageUrl,
                  fallbackIcon: Icons.event,
                  title: event.title,
                  details: [
                    ImageListCardDetail(icon: Icons.access_time, text: event.time),
                    ImageListCardDetail(icon: Icons.location_on, text: event.location),
                  ],
                  trailing: FBadge(child: Text(event.category)),
                ),
              )),
      ],
    );
  }
}
