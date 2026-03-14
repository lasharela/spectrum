import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
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

    return Scaffold(
      backgroundColor: colors.background,
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
              // Gradient header area
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.gradientPurple,
                        AppColors.gradientRose,
                        AppColors.gradientAmber,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
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
                          // Top row: notification + avatar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, size: 24),
                                color: colors.foreground,
                                onPressed: () {},
                              ),
                              GestureDetector(
                                onTap: () => context.go('/profile'),
                                child: FAvatar.raw(size: 34),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Greeting text — no card
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
                ),
              ),
              // Content area
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    PromotionsSection(promotions: dashboard.promotions),
                    const SizedBox(height: AppSpacing.sectionGap),
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
