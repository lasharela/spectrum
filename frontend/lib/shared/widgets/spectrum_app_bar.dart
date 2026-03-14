import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../core/constants/app_spacing.dart';

class SpectrumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;
  final List<Widget>? extraActions;

  const SpectrumAppBar({
    super.key,
    required this.title,
    this.onNotificationsTap,
    this.onAvatarTap,
    this.extraActions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return AppBar(
      backgroundColor: colors.background,
      elevation: 0.5,
      shadowColor: Colors.black26,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 24),
          color: colors.foreground,
          onPressed: onNotificationsTap ?? () {},
        ),
      ),
      title: Text(
        title,
        style: typography.lg.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.foreground,
        ),
      ),
      actions: [
        ...?extraActions,
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAvatarTap ?? () {},
            child: FAvatar.raw(size: 34),
          ),
        ),
      ],
    );
  }
}
