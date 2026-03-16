import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/events/domain/event.dart';
import 'package:spectrum_app/features/events/presentation/providers/events_provider.dart';
import 'package:spectrum_app/features/events/presentation/widgets/event_card.dart';
import 'package:spectrum_app/features/events/presentation/widgets/create_event_modal.dart';
import 'package:spectrum_app/shared/widgets/filter_popup.dart';
import 'package:spectrum_app/shared/widgets/screen.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _searchController = TextEditingController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateEvent() {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: 0.9,
      builder: (_) => const CreateEventModal(),
    );
  }

  void _showFilterPopup() {
    final eventsState = ref.read(eventsProvider);
    final filterOptions = ref.read(eventFilterOptionsProvider);
    filterOptions.whenData((options) {
      showFSheet<void>(
        context: context,
        side: FLayout.btt,
        mainAxisMaxRatio: 0.8,
        builder: (sheetContext) => FilterPopup(
          filterGroups: options.toFilterGroups(),
          selectedFilters: eventsState.filters,
          onApply: (filters) {
            ref.read(eventsProvider.notifier).setFilters(filters);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);

    return Screen(
      floatingActionButton: FloatingActionButton(
        heroTag: 'events_create',
        onPressed: _showCreateEvent,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: FTabs(
                expands: true,
                style: FTabsStyle(
                  decoration: const BoxDecoration(),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  labelTextStyle: FVariants.from(
                    context.theme.typography.sm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.theme.colors.mutedForeground,
                    ),
                    variants: {
                      [.selected]: TextStyleDelta.delta(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    },
                  ),
                  indicatorDecoration: const UnderlineTabIndicator(
                    borderSide:
                        BorderSide(color: AppColors.primary, width: 3),
                  ),
                  indicatorSize: FTabBarIndicatorSize.label,
                  height: context.theme.tabsStyle.height,
                  spacing: 0,
                  focusedOutlineStyle:
                      context.theme.tabsStyle.focusedOutlineStyle,
                ),
                control: FTabControl.lifted(
                  index: _tabIndex,
                  onChange: (index) => setState(() => _tabIndex = index),
                ),
                children: [
                  FTabEntry(
                    label: const Text('Upcoming'),
                    child: _UpcomingTab(
                      searchController: _searchController,
                      eventsState: eventsState,
                      onSearchChanged: (query) {
                        setState(() {});
                        ref
                            .read(eventsProvider.notifier)
                            .searchDebounced(query);
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() {});
                        ref.read(eventsProvider.notifier).search('');
                      },
                      onFilterTap: _showFilterPopup,
                      onRefresh: () =>
                          ref.read(eventsProvider.notifier).refresh(),
                      onLoadMore: () =>
                          ref.read(eventsProvider.notifier).loadMore(),
                      onEventTap: (eventId) =>
                          context.push('/events/$eventId'),
                    ),
                  ),
                  FTabEntry(
                    label: const Text('My Events'),
                    child: const _MyEventsTab(),
                  ),
                  FTabEntry(
                    label: const Text('Saved'),
                    child: const _SavedTab(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming Tab
// ---------------------------------------------------------------------------

class _UpcomingTab extends StatelessWidget {
  final TextEditingController searchController;
  final EventsState eventsState;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onEventTap;

  const _UpcomingTab({
    required this.searchController,
    required this.eventsState,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final events = eventsState.events;

    return Column(
      children: [
        // Search bar + filter button
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: searchController,
                    onChange: (value) => onSearchChanged(value.text),
                  ),
                  hint: 'Search events...',
                  prefixBuilder: (context, style, variants) => Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: IconTheme(
                      data: style.iconStyle.resolve(variants),
                      child: const Icon(Icons.search_rounded),
                    ),
                  ),
                  suffixBuilder: searchController.text.isEmpty
                      ? null
                      : (context, style, variants) => IconButton(
                            onPressed: onClearSearch,
                            icon: Icon(
                              Icons.close_rounded,
                              color:
                                  style.iconStyle.resolve(variants).color,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterTriggerButton(
                activeCount: eventsState.activeFilterCount,
                onTap: onFilterTap,
              ),
            ],
          ),
        ),

        // Results count
        if (!eventsState.isLoading && events.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${events.length} event${events.length == 1 ? '' : 's'}',
                style: theme.typography.xs.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

        // Main content
        Expanded(
          child: eventsState.isLoading
              ? const Center(child: FCircularProgress())
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: events.isEmpty
                      ? const _EmptyState(
                          icon: Icons.event_busy_rounded,
                          title: 'No events found',
                          subtitle:
                              'Try adjusting your search or filters.',
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification &&
                                notification.metrics.extentAfter < 200) {
                              onLoadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              AppSpacing.sm,
                              0,
                              96,
                            ),
                            itemCount: events.length +
                                (eventsState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == events.length) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.all(AppSpacing.lg),
                                  child: Center(
                                      child: FCircularProgress()),
                                );
                              }

                              final event = events[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: EventCard(
                                  event: event,
                                  onTap: () => onEventTap(event.id),
                                ),
                              );
                            },
                          ),
                        ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// My Events Tab
// ---------------------------------------------------------------------------

class _MyEventsTab extends ConsumerWidget {
  const _MyEventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEventsAsync = ref.watch(myEventsProvider);

    return myEventsAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Failed to load your events.',
            style: context.theme.typography.sm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_note_rounded,
            title: 'No events created yet',
            subtitle: 'Events you create will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myEventsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.md,
              0,
              96,
            ),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MyEventCard(event: event),
              );
            },
          ),
        );
      },
    );
  }
}

/// Card for "My Events" tab — shows event with status badge.
class _MyEventCard extends StatelessWidget {
  final Event event;

  const _MyEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventCard(
          event: event,
          onTap: () => context.push('/events/${event.id}'),
        ),
        if (event.status != 'approved')
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              top: AppSpacing.xxs,
            ),
            child: _StatusBadge(status: event.status),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        label = 'Pending approval';
      case 'rejected':
        color = AppColors.error;
        label = 'Rejected';
      default:
        color = AppColors.success;
        label = 'Approved';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
      ),
      child: Text(
        label,
        style: context.theme.typography.xs.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved Tab
// ---------------------------------------------------------------------------

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  static const _categoryIcons = <String, IconData>{
    'Workshop': Icons.build_outlined,
    'Support Group': Icons.groups_outlined,
    'Social': Icons.people_outlined,
    'Educational': Icons.school_outlined,
    'Recreation': Icons.sports_soccer_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedEventsProvider);
    final theme = context.theme;

    return savedAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Failed to load saved events.',
            style: theme.typography.sm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      data: (grouped) {
        if (grouped.isEmpty) {
          return const _EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved events',
            subtitle: 'Bookmark events to see them here.',
          );
        }

        final categories = grouped.keys.toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(savedEventsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.md,
              0,
              96,
            ),
            itemCount: categories.length,
            itemBuilder: (context, catIndex) {
              final category = categories[catIndex];
              final events = grouped[category]!;
              final icon =
                  _categoryIcons[category] ?? Icons.event_outlined;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catIndex > 0)
                    const SizedBox(height: AppSpacing.lg),

                  // Category header
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          category,
                          style: theme.typography.sm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.badgeRadius),
                          ),
                          child: Text(
                            '${events.length}',
                            style: theme.typography.xs.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Event cards
                  ...events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.md),
                      child: EventCard(
                        event: event,
                        onTap: () =>
                            context.push('/events/${event.id}'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: 96),
        Icon(
          icon,
          size: 64,
          color: theme.colors.mutedForeground,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.typography.lg.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
