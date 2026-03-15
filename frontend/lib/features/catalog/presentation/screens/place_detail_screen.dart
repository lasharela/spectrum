import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/catalog/data/catalog_repository.dart';
import 'package:spectrum_app/features/catalog/domain/place.dart';
import 'package:spectrum_app/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:spectrum_app/shared/widgets/screen.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Place Detail Provider ---

final placeDetailProvider =
    FutureProvider.family<Place?, String>((ref, id) async {
  final repo = ref.read(catalogRepositoryProvider);
  return repo.getPlace(id);
});

// --- Place Detail Screen ---

class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailProvider(placeId));

    return Screen(
      body: placeAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => const Center(child: Text('Failed to load place')),
        data: (place) {
          if (place == null) {
            return const Center(child: Text('Place not found'));
          }
          return _PlaceDetailContent(place: place);
        },
      ),
    );
  }
}

// --- Place Detail Content ---

class _PlaceDetailContent extends ConsumerStatefulWidget {
  final Place place;

  const _PlaceDetailContent({required this.place});

  @override
  ConsumerState<_PlaceDetailContent> createState() =>
      _PlaceDetailContentState();
}

class _PlaceDetailContentState extends ConsumerState<_PlaceDetailContent> {
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _saved = widget.place.saved;
  }

  void _toggleSave() {
    final place = widget.place;
    final nowSaved = !_saved;
    setState(() => _saved = nowSaved);

    // API call
    final repo = ref.read(catalogRepositoryProvider);
    if (nowSaved) {
      repo.savePlace(place.id);
    } else {
      repo.unsavePlace(place.id);
    }

    // Sync catalog list + saved tab
    ref.read(catalogProvider.notifier).setSaved(place.id, saved: nowSaved);
    ref.invalidate(savedPlacesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = context.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image / Icon placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: place.imageUrl != null
                  ? Image.network(
                      place.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _IconPlaceholder(category: place.category),
                    )
                  : _IconPlaceholder(category: place.category),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. Category badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
            ),
            child: Text(
              place.category,
              style: theme.typography.xs.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 3. Place name
          Text(
            place.name,
            style: theme.typography.xl.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 4. Average rating display
          Row(
            children: [
              ...List.generate(5, (index) {
                final starValue = index + 1;
                return Icon(
                  starValue <= place.averageRating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: AppColors.secondary,
                );
              }),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${place.averageRating.toStringAsFixed(1)} (${place.ratingCount} ratings)',
                style: theme.typography.sm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 5. Rate this place
          Text(
            'Rate this place',
            style: theme.typography.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StarRatingInput(
            currentRating: place.userRating ?? 0,
            onRate: (score) {
              ref.read(catalogRepositoryProvider).ratePlace(place.id, score);
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // 6. Description
          if (place.description != null && place.description!.isNotEmpty) ...[
            Text(
              place.description!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.foreground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // 7. Tags
          if (place.tags.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: place.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.badgeRadius),
                  ),
                  child: Text(
                    tag,
                    style: theme.typography.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // 8. Address row
          if (place.address != null && place.address!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    place.address!,
                    style: theme.typography.sm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 9. Get Directions button
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: () => _openDirections(place.address!),
                prefix: const Icon(Icons.directions_outlined),
                child: const Text('Get Directions'),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // 10. Save Place button
          SizedBox(
            width: double.infinity,
            child: FButton(
              variant: FButtonVariant.outline,
              onPress: _toggleSave,
              prefix: Icon(
                _saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              child: Text(_saved ? 'Saved' : 'Save Place'),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// --- Star Rating Input ---

class _StarRatingInput extends StatefulWidget {
  final int currentRating;
  final ValueChanged<int> onRate;

  const _StarRatingInput({
    required this.currentRating,
    required this.onRate,
  });

  @override
  State<_StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<_StarRatingInput> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.currentRating;
  }

  @override
  void didUpdateWidget(covariant _StarRatingInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRating != widget.currentRating) {
      _rating = widget.currentRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _rating = starValue);
            widget.onRate(starValue);
          },
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xxs),
            child: Icon(
              starValue <= _rating
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 32,
              color: AppColors.secondary,
            ),
          ),
        );
      }),
    );
  }
}

// --- Icon Placeholder ---

class _IconPlaceholder extends StatelessWidget {
  final String category;

  const _IconPlaceholder({required this.category});

  static const _categoryIcons = <String, IconData>{
    'Sensory-Friendly': Icons.spa,
    'Indoor Playground': Icons.sports_handball,
    'Outdoor Playground': Icons.park,
    'Doctor': Icons.medical_services,
    'Dentist': Icons.medical_information,
    'Therapist': Icons.psychology,
    'After-School': Icons.school,
    'Education': Icons.cast_for_education,
    'Restaurant': Icons.restaurant,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category] ?? Icons.place_outlined;

    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// --- Helpers ---

Future<void> _openDirections(String address) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
