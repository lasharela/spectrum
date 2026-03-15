import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../../../shared/widgets/place_card.dart';
import '../../domain/dashboard.dart';

class PlacesSection extends StatelessWidget {
  final List<DashboardPlace> places;

  const PlacesSection({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Places',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        if (places.isEmpty)
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.place_outlined, size: 32, color: colors.mutedForeground),
                  const SizedBox(height: 8),
                  Text(
                    'No places listed yet',
                    style: typography.sm.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          )
        else
          ...places.map((place) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlaceCard(
                  name: place.name,
                  address: place.address,
                  imageUrl: place.imageUrl,
                ),
              )),
      ],
    );
  }
}
