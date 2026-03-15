import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:spectrum_app/shared/widgets/filter_popup.dart';
import 'package:spectrum_app/shared/widgets/place_card.dart';
import 'package:spectrum_app/shared/widgets/screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterPopup() {
    final catalogState = ref.read(catalogProvider);
    final filterOptions = ref.read(catalogFilterOptionsProvider);
    filterOptions.whenData((options) {
      showFSheet<void>(
        context: context,
        side: FLayout.btt,
        mainAxisMaxRatio: 0.8,
        builder: (sheetContext) => FilterPopup(
          filterGroups: options.toFilterGroups(),
          selectedFilters: catalogState.filters,
          onApply: (filters) {
            ref.read(catalogProvider.notifier).setFilters(filters);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);

    return Screen(
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
                    label: const Text('Catalogue'),
                    child: _BrowseTab(
                      searchController: _searchController,
                      catalogState: catalogState,
                      onSearchChanged: (query) {
                        setState(() {});
                        ref
                            .read(catalogProvider.notifier)
                            .searchDebounced(query);
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() {});
                        ref.read(catalogProvider.notifier).search('');
                      },
                      onFilterTap: _showFilterPopup,
                      onRefresh: () =>
                          ref.read(catalogProvider.notifier).refresh(),
                      onLoadMore: () =>
                          ref.read(catalogProvider.notifier).loadMore(),
                      onPlaceTap: (placeId) =>
                          context.push('/catalog/$placeId'),
                    ),
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
// Browse Tab
// ---------------------------------------------------------------------------

class _BrowseTab extends StatelessWidget {
  final TextEditingController searchController;
  final CatalogState catalogState;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onPlaceTap;

  const _BrowseTab({
    required this.searchController,
    required this.catalogState,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final places = catalogState.places;

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
                  hint: 'Search places...',
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
                activeCount: catalogState.activeFilterCount,
                onTap: onFilterTap,
              ),
            ],
          ),
        ),

        // Results count
        if (!catalogState.isLoading && places.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${places.length} result${places.length == 1 ? '' : 's'}',
                style: theme.typography.xs.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

        // Main content
        Expanded(
          child: catalogState.isLoading
              ? const Center(child: FCircularProgress())
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: places.isEmpty
                      ? const _EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No places found',
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
                            itemCount: places.length +
                                (catalogState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == places.length) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.all(AppSpacing.lg),
                                  child: Center(
                                      child: FCircularProgress()),
                                );
                              }

                              final place = places[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: PlaceCard(
                                  name: place.name,
                                  address: place.address,
                                  imageUrl: place.imageUrl,
                                  averageRating: place.averageRating,
                                  ratingCount: place.ratingCount,
                                  category: place.category,
                                  showRating: true,
                                  onTap: () => onPlaceTap(place.id),
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
// Saved Tab
// ---------------------------------------------------------------------------

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

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
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlacesProvider);
    final theme = context.theme;

    return savedAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Failed to load saved places.',
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
            title: 'No saved places',
            subtitle: 'Bookmark places from the catalogue to see them here.',
          );
        }

        final categories = grouped.keys.toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(savedPlacesProvider),
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
              final places = grouped[category]!;
              final icon =
                  _categoryIcons[category] ?? Icons.place_outlined;

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
                            '${places.length}',
                            style: theme.typography.xs.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Place cards
                  ...places.map(
                    (place) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppSpacing.md),
                      child: PlaceCard(
                        name: place.name,
                        address: place.address,
                        imageUrl: place.imageUrl,
                        averageRating: place.averageRating,
                        ratingCount: place.ratingCount,
                        category: place.category,
                        showRating: true,
                        onTap: () =>
                            context.push('/catalog/${place.id}'),
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
