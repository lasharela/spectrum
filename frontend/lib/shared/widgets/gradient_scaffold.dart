import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../core/constants/app_colors.dart';

/// A scaffold with subtle, asymmetric blurred gradient blobs in the background.
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
        clipBehavior: Clip.hardEdge,
        children: [
          // Purple blob — top left
          Positioned(
            top: -60,
            left: -40,
            child: _Blob(
              size: 280,
              color: AppColors.gradientPurple.withValues(alpha: 0.5),
            ),
          ),
          // Amber blob — middle right
          Positioned(
            top: 340,
            right: -50,
            child: _Blob(
              size: 220,
              color: AppColors.gradientAmber.withValues(alpha: 0.35),
            ),
          ),
          // Rose blob — mid left
          Positioned(
            top: 180,
            left: -30,
            child: _Blob(
              size: 180,
              color: AppColors.gradientRose.withValues(alpha: 0.25),
            ),
          ),
          Positioned.fill(child: body),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
