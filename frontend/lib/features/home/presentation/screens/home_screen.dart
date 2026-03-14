import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
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
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load dashboard',
                    style: TextStyle(color: AppColors.textGray)),
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
            onRefresh: () =>
                ref.read(dashboardProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.all(20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      GreetingCard(
                        userName: dashboard.user.name,
                        userType: dashboard.user.userType,
                      ),
                      const SizedBox(height: 24),
                      const QuickActionsSection(),
                      const SizedBox(height: 32),
                      PromotionsSection(promotions: dashboard.promotions),
                      const SizedBox(height: 32),
                      PlacesSection(places: dashboard.places),
                      const SizedBox(height: 32),
                      EventsSection(events: dashboard.upcomingEvents),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.backgroundGray,
      elevation: 0,
      leading: IconButton(
        onPressed: () {},
        icon: Stack(
          children: [
            Icon(Icons.notifications_outlined, color: AppColors.textDark),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        AppStrings.appName,
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.settings_outlined, color: AppColors.textDark),
        ),
      ],
    );
  }
}
