import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:spectrum_app/core/constants/app_colors.dart';
import 'package:spectrum_app/core/constants/app_spacing.dart';
import 'package:spectrum_app/features/promotions/presentation/providers/promotions_provider.dart';
import 'package:spectrum_app/features/promotions/presentation/widgets/promotion_card.dart';
import 'package:spectrum_app/shared/widgets/filter_popup.dart';
import 'package:spectrum_app/shared/widgets/screen.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  final _searchController = TextEditingController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final promotionsState = ref.read(promotionsProvider);
    final filterOptions = ref.read(promotionFilterOptionsProvider);
    filterOptions.whenData((options) {
      showFSheet<void>(
        context: context,
        side: FLayout.btt,
        mainAxisMaxRatio: 0.7,
        builder: (sheetContext) => FilterPopup(
          filterGroups: options.toFilterGroups(),
          selectedFilters: promotionsState.filters,
          onApply: (filters) {
            ref.read(promotionsProvider.notifier).setFilters(filters);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final promotionsState = ref.watch(promotionsProvider);

    return Screen(
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    borderSide: BorderSide(color: AppColors.primary, width: 3),
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
                    label: const Text('Browse'),
                    child: _BrowseTab(
                      searchController: _searchController,
                      promotionsState: promotionsState,
                      onSearchChanged: (query) {
                        setState(() {});
                        ref
                            .read(promotionsProvider.notifier)
                            .searchDebounced(query);
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        setState(() {});
                        ref.read(promotionsProvider.notifier).search('');
                      },
                      onFilterTap: _showFilterSheet,
                      onRefresh: () =>
                          ref.read(promotionsProvider.notifier).refresh(),
                      onLoadMore: () =>
                          ref.read(promotionsProvider.notifier).loadMore(),
                      onPromotionTap: (id) =>
                          context.push('/promotions/$id'),
                      onLike: (id) =>
                          ref.read(promotionsProvider.notifier).toggleLike(id),
                      onSave: (id) =>
                          ref.read(promotionsProvider.notifier).toggleSave(id),
                      onClaim: (id) =>
                          ref.read(promotionsProvider.notifier).claimPromotion(id),
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
  final PromotionsState promotionsState;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onPromotionTap;
  final ValueChanged<String> onLike;
  final ValueChanged<String> onSave;
  final ValueChanged<String> onClaim;

  const _BrowseTab({
    required this.searchController,
    required this.promotionsState,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onPromotionTap,
    required this.onLike,
    required this.onSave,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final promotions = promotionsState.promotions;

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
                  hint: 'Search promotions...',
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
                              color: style.iconStyle.resolve(variants).color,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterTriggerButton(
                activeCount: promotionsState.activeFilterCount,
                onTap: onFilterTap,
              ),
            ],
          ),
        ),

        // Results count
        if (!promotionsState.isLoading && promotions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${promotions.length} deal${promotions.length == 1 ? '' : 's'}',
                style: theme.typography.xs.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

        // Main content
        Expanded(
          child: promotionsState.isLoading
              ? const Center(child: FCircularProgress())
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: promotions.isEmpty
                      ? const _EmptyState(
                          icon: Icons.local_offer_outlined,
                          title: 'No promotions found',
                          subtitle: 'Try adjusting your search or filters.',
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
                            itemCount: promotions.length +
                                (promotionsState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == promotions.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Center(child: FCircularProgress()),
                                );
                              }

                              final promo = promotions[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: PromotionCard(
                                  promotion: promo,
                                  onTap: () => onPromotionTap(promo.id),
                                  onLike: () => onLike(promo.id),
                                  onSave: () => onSave(promo.id),
                                  onClaim: () => onClaim(promo.id),
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
    'Health & Wellness': Icons.favorite_outline_rounded,
    'Education': Icons.cast_for_education_outlined,
    'Entertainment': Icons.movie_outlined,
    'Food & Dining': Icons.restaurant_outlined,
    'Services': Icons.handshake_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPromotionsProvider);
    final theme = context.theme;

    return savedAsync.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Failed to load saved promotions.',
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
            title: 'No saved promotions',
            subtitle: 'Save deals from Browse to see them here.',
          );
        }

        final categories = grouped.keys.toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(savedPromotionsProvider),
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
              final promotions = grouped[category]!;
              final icon = _categoryIcons[category] ?? Icons.local_offer_outlined;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catIndex > 0) const SizedBox(height: AppSpacing.lg),

                  // Category header
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: AppColors.primary),
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.badgeRadius),
                          ),
                          child: Text(
                            '${promotions.length}',
                            style: theme.typography.xs.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Promotion cards
                  ...promotions.map(
                    (promo) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: PromotionCard(
                        promotion: promo,
                        onTap: () => context.push('/promotions/${promo.id}'),
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
        Icon(icon, size: 64, color: theme.colors.mutedForeground),
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
