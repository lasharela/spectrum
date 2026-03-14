import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: typography.lg.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => context.go('/community'),
                prefix: const Icon(Icons.support_agent),
                child: const Text('Support'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => context.go('/catalog'),
                prefix: const Icon(Icons.lightbulb_outline),
                child: const Text('Suggest'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FButton(
                variant: FButtonVariant.outline,
                onPress: () => context.go('/promotions'),
                prefix: const Icon(Icons.language),
                child: const Text('Website'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
