import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../core/constants/app_colors.dart';

/// Unified screen wrapper for all app screens.
///
/// Shows gradient blobs in the background by default.
/// Pass [isGradient] = false for a solid background.
class Screen extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool isGradient;
  final Widget? floatingActionButton;

  const Screen({
    super.key,
    required this.body,
    this.appBar,
    this.isGradient = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final content = isGradient ? _GradientBackground(child: body) : body;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: content,
    );
  }
}

class _GradientBackground extends StatelessWidget {
  final Widget child;

  const _GradientBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            IgnorePointer(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: -80,
                    left: -80,
                    width: 320,
                    height: 320,
                    child: _Blob(
                      color: AppColors.gradientPurple.withValues(alpha: 0.45),
                    ),
                  ),
                  Positioned(
                    top: 340,
                    right: -80,
                    width: 280,
                    height: 280,
                    child: _Blob(
                      color: AppColors.gradientAmber.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    top: 180,
                    left: -60,
                    width: 240,
                    height: 240,
                    child: _Blob(
                      color: AppColors.gradientRose.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
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
