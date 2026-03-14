import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class SpectrumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final List<Widget>? extraActions;

  const SpectrumAppBar({
    super.key,
    required this.title,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          color: AppColors.textPrimary,
          onPressed: onNotificationsTap ?? () {},
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        ...?extraActions,
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            color: AppColors.textPrimary,
            onPressed: onSettingsTap ?? () {},
          ),
        ),
      ],
    );
  }
}
