import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/promotions_section.dart';
import '../widgets/places_section.dart';
import '../widgets/events_section.dart';
import '../widgets/quick_actions_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Screen(
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.destructive),
                const SizedBox(height: 16),
                Text(
                  'Failed to load dashboard',
                  style: typography.sm.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: 16),
                FButton(
                  variant: FButtonVariant.destructive,
                  size: FButtonSizeVariant.sm,
                  mainAxisSize: MainAxisSize.min,
                  onPress: () => ref.read(dashboardProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (dashboard) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    12,
                    AppSpacing.screenPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${dashboard.user.firstName}!',
                        style: typography.xl.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Here's what's happening today",
                        style: typography.sm.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Promotions — edge-to-edge (no horizontal padding)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.screenPadding,
                    bottom: AppSpacing.sectionGap,
                  ),
                  child: PromotionsSection(promotions: dashboard.promotions),
                ),
              ),
              // Remaining sections — with horizontal padding
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ).copyWith(bottom: AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    PlacesSection(places: dashboard.places),
                    const SizedBox(height: AppSpacing.sectionGap),
                    EventsSection(events: dashboard.upcomingEvents),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const QuickActionsSection(),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
