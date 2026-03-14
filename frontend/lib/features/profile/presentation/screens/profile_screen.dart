import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;

    return FScaffold(
      header: FHeader.nested(
        title: const Text(''),
        prefixes: [
          FHeaderAction.back(onPress: () => context.go('/home')),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            FAvatar.raw(size: 96),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'User',
              style: context.theme.typography.xl2.copyWith(
                fontWeight: FontWeight.w600,
                color: context.theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),
            FTileGroup(
              label: const Text('Account'),
              children: [
                FTile(
                  prefix: const Icon(FIcons.user),
                  title: const Text('Edit Profile'),
                  suffix: const Icon(FIcons.chevronRight),
                  onPress: () {},
                ),
                FTile(
                  prefix: const Icon(FIcons.bell),
                  title: const Text('Notifications'),
                  suffix: const Icon(FIcons.chevronRight),
                  onPress: () {},
                ),
                FTile(
                  prefix: const Icon(FIcons.shield),
                  title: const Text('Privacy'),
                  suffix: const Icon(FIcons.chevronRight),
                  onPress: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            FTileGroup(
              label: const Text('Support'),
              children: [
                FTile(
                  prefix: const Icon(FIcons.helpCircle),
                  title: const Text('Help & Support'),
                  suffix: const Icon(FIcons.chevronRight),
                  onPress: () {},
                ),
                FTile(
                  prefix: const Icon(FIcons.info),
                  title: const Text('About'),
                  suffix: const Icon(FIcons.chevronRight),
                  onPress: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FButton(
                variant: FButtonVariant.secondary,
                prefix: const Icon(FIcons.logOut),
                onPress: () async {
                  try {
                    await ref.read(authProvider.notifier).signOut();
                  } catch (_) {
                    // Ensure we navigate even if API call fails
                  }
                  if (context.mounted) context.go('/onboarding');
                },
                child: const Text('Sign Out'),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'Version 1.0.0',
              style: context.theme.typography.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              variant: FButtonVariant.ghost,
              onPress: () {},
              child: const Text('www.spectrum.app'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
