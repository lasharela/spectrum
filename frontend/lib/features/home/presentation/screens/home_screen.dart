import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/spectrum_app_bar.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/greeting_card.dart';
import '../widgets/promotions_section.dart';
import '../widgets/places_section.dart';
import '../widgets/events_section.dart';
import '../widgets/quick_actions_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: context.theme.colors.background,
      appBar: SpectrumAppBar(
        title: 'Spectrum',
        onAvatarTap: () => context.go('/profile'),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Failed to load dashboard',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(dashboardProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GreetingCard(userName: dashboard.user.firstName),
                    const SizedBox(height: AppSpacing.sectionGap),
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
