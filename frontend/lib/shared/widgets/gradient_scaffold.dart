import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../core/constants/app_colors.dart';

/// A scaffold with subtle, asymmetric gradient blobs in the background.
///
/// Use this as the main wrapper for screens instead of plain [Scaffold]
/// to get a consistent ambient gradient across the app.
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Purple blob — top left
          Positioned(
            top: -80,
            left: -80,
            width: 320,
            height: 320,
            child: _Blob(color: AppColors.gradientPurple.withValues(alpha: 0.45)),
          ),
          // Amber blob — middle right
          Positioned(
            top: 340,
            right: -80,
            width: 280,
            height: 280,
            child: _Blob(color: AppColors.gradientAmber.withValues(alpha: 0.3)),
          ),
          // Rose blob — mid left
          Positioned(
            top: 180,
            left: -60,
            width: 240,
            height: 240,
            child: _Blob(color: AppColors.gradientRose.withValues(alpha: 0.2)),
          ),
          Positioned.fill(child: body),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;

  const _Blob({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
