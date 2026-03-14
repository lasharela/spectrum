import 'dart:ui';
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
        data: (dashboard) => Stack(
          children: [
            // Ambient blurred blobs for organic gradient
            // Purple blob — top left
            Positioned(
              top: -60,
              left: -40,
              child: _GradientBlob(
                size: 280,
                color: AppColors.gradientPurple.withValues(alpha: 0.5),
              ),
            ),
            // Amber blob — top right, slightly lower
            Positioned(
              top: 30,
              right: -60,
              child: _GradientBlob(
                size: 220,
                color: AppColors.gradientAmber.withValues(alpha: 0.35),
              ),
            ),
            // Rose blob — mid left
            Positioned(
              top: 180,
              left: -30,
              child: _GradientBlob(
                size: 180,
                color: AppColors.gradientRose.withValues(alpha: 0.25),
              ),
            ),
            RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
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
          ],
        ),
      ),
    );
  }
}

class _GradientBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GradientBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
