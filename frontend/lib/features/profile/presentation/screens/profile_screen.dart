import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Screen(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              FHeader.nested(
                title: const Text('Account'),
                prefixes: [
                  FHeaderAction.back(onPress: () => context.go('/home')),
                ],
              ),
              const SizedBox(height: 24),
              FAvatar.raw(size: 96),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'User',
                style: typography.xl2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              if (user?.state != null || user?.city != null) ...[
                const SizedBox(height: 4),
                Text(
                  [user?.city, user?.state].where((s) => s != null).join(', '),
                  style: typography.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    FTileGroup(
                      label: const Text('Account'),
                      children: [
                        FTile(
                          prefix: const Icon(FIcons.user),
                          title: const Text('Edit Profile'),
                          suffix: const Icon(FIcons.chevronRight),
                          onPress: () => context.push('/profile/edit'),
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
                        variant: FButtonVariant.destructive,
                        prefix: const Icon(FIcons.logOut),
                        onPress: () async {
                          await ref.read(authProvider.notifier).signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'Version 1.0.0',
                      style: typography.xs.copyWith(
                        color: colors.mutedForeground,
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
            ],
          ),
        ),
      ),
    );
  }
}
