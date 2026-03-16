import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/events/data/events_repository.dart';
import 'package:spectrum_app/features/events/domain/event.dart';
import 'package:spectrum_app/features/events/presentation/providers/events_provider.dart';
import 'package:spectrum_app/shared/widgets/screen.dart';

// --- Event Detail Provider ---

final eventDetailProvider =
    FutureProvider.family<Event?, String>((ref, id) async {
  final repo = ref.read(eventsRepositoryProvider);
  return repo.getEvent(id);
});

// --- Event Detail Screen ---

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Screen(
      body: eventAsync.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => const Center(child: Text('Failed to load event')),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }
          return _EventDetailContent(event: event);
        },
      ),
    );
  }
}

// --- Event Detail Content ---

class _EventDetailContent extends ConsumerStatefulWidget {
  final Event event;

  const _EventDetailContent({required this.event});

  @override
  ConsumerState<_EventDetailContent> createState() =>
      _EventDetailContentState();
}

class _EventDetailContentState extends ConsumerState<_EventDetailContent> {
  late bool _saved;
  late bool _rsvped;
  late int _attendeeCount;

  @override
  void initState() {
    super.initState();
    _saved = widget.event.saved;
    _rsvped = widget.event.rsvped;
    _attendeeCount = widget.event.attendeeCount;
  }

  void _toggleSave() {
    final event = widget.event;
    final nowSaved = !_saved;
    setState(() => _saved = nowSaved);

    final repo = ref.read(eventsRepositoryProvider);
    if (nowSaved) {
      repo.saveEvent(event.id);
    } else {
      repo.unsaveEvent(event.id);
    }

    ref.read(eventsProvider.notifier).setSaved(event.id, saved: nowSaved);
    ref.invalidate(savedEventsProvider);
  }

  void _toggleRsvp() {
    final event = widget.event;
    final nowRsvped = !_rsvped;
    final newCount = nowRsvped ? _attendeeCount + 1 : (_attendeeCount > 0 ? _attendeeCount - 1 : 0);
    setState(() {
      _rsvped = nowRsvped;
      _attendeeCount = newCount;
    });

    final repo = ref.read(eventsRepositoryProvider);
    if (nowRsvped) {
      repo.rsvp(event.id);
    } else {
      repo.cancelRsvp(event.id);
    }

    ref.read(eventsProvider.notifier).setRsvped(
          event.id,
          rsvped: nowRsvped,
          attendeeCount: newCount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = context.theme;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

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
              child: event.imageUrl != null
                  ? Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _IconPlaceholder(category: event.category),
                    )
                  : _IconPlaceholder(category: event.category),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. Badges row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // Category badge
              _Badge(
                text: event.category,
                color: AppColors.primary,
              ),
              // Online badge
              if (event.isOnline)
                const _Badge(
                  text: 'Online',
                  color: AppColors.info,
                ),
              // Price badge
              if (event.isFree)
                const _Badge(
                  text: 'FREE',
                  color: AppColors.success,
                )
              else if (event.price != null)
                _Badge(
                  text: event.price!,
                  color: AppColors.primary,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 3. Event title
          Text(
            event.title,
            style: theme.typography.xl.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 4. Organizer
          Text(
            'by ${event.organizer.name}',
            style: theme.typography.sm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 5. Date & time info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: theme.colors.card,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: dateFormat.format(event.startDate),
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  text: event.endDate != null
                      ? '${timeFormat.format(event.startDate)} – ${timeFormat.format(event.endDate!)}'
                      : timeFormat.format(event.startDate),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    icon: event.isOnline
                        ? Icons.computer_outlined
                        : Icons.location_on_outlined,
                    text: event.location!,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  icon: Icons.people_outlined,
                  text: '$_attendeeCount attendee${_attendeeCount == 1 ? '' : 's'}',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 6. Description
          if (event.description != null &&
              event.description!.isNotEmpty) ...[
            Text(
              event.description!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.foreground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // 7. RSVP button
          SizedBox(
            width: double.infinity,
            child: FButton(
              onPress: _toggleRsvp,
              prefix: Icon(
                _rsvped
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              child: Text(_rsvped ? 'Cancel RSVP' : 'RSVP'),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 8. Save button
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
              child: Text(_saved ? 'Saved' : 'Save Event'),
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Text(
        text,
        style: context.theme.typography.xs.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: context.theme.typography.sm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconPlaceholder extends StatelessWidget {
  final String category;

  const _IconPlaceholder({required this.category});

  static const _categoryIcons = <String, IconData>{
    'Workshop': Icons.build_outlined,
    'Support Group': Icons.groups_outlined,
    'Social': Icons.people_outlined,
    'Educational': Icons.school_outlined,
    'Recreation': Icons.sports_soccer_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category] ?? Icons.event_outlined;

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
