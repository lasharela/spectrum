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
    final backgroundColor = context.theme.colors.background;

    return ClipRect(
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.gradientPurple.withValues(alpha: 0.16),
                          AppColors.gradientAmber.withValues(alpha: 0.08),
                          backgroundColor.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.22, 0.55],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -96,
                    left: -84,
                    width: 340,
                    height: 340,
                    child: _Blob(
                      color: AppColors.gradientPurple.withValues(alpha: 0.58),
                    ),
                  ),
                  Positioned(
                    top: 170,
                    left: -40,
                    width: 260,
                    height: 260,
                    child: _Blob(
                      color: AppColors.gradientRose.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    top: 96,
                    right: -96,
                    width: 332,
                    height: 332,
                    child: _Blob(
                      color: AppColors.gradientAmber.withValues(alpha: 0.52),
                    ),
                  ),
                  Positioned(
                    top: 48,
                    right: 32,
                    width: 118,
                    height: 118,
                    child: _Blob(
                      color: AppColors.secondary.withValues(alpha: 0.22),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.58,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              backgroundColor.withValues(alpha: 0),
                              backgroundColor.withValues(alpha: 0.72),
                              backgroundColor,
                            ],
                            stops: const [0, 0.62, 1],
                          ),
                        ),
                      ),
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
