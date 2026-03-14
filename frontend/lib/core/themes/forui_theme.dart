import 'package:flutter/services.dart';

import 'package:forui/forui.dart';

import '../constants/app_colors.dart';

/// Forui theme configuration for Spectrum using the original design palette.
///
/// Provides [light] and [dark] [FThemeData] instances that map Spectrum's
/// design tokens to Forui's color system.
class AppForuiTheme {
  /// Light theme using Spectrum's original design palette.
  static FThemeData get light => FThemeData(
        touch: true,
        debugLabel: 'Spectrum Light',
        colors: const FColors(
          brightness: Brightness.light,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          barrier: Color(0x33000000),
          background: AppColors.background,
          foreground: AppColors.textPrimary,
          primary: AppColors.primary,
          primaryForeground: Color(0xFFFFFFFF),
          secondary: AppColors.secondary,
          secondaryForeground: Color(0xFFFFFFFF),
          muted: Color(0xFFE8EAED),
          mutedForeground: AppColors.textSecondary,
          destructive: AppColors.error,
          destructiveForeground: Color(0xFFFFFFFF),
          error: AppColors.error,
          errorForeground: Color(0xFFFFFFFF),
          card: AppColors.cardBackground,
          border: AppColors.divider,
        ),
      );

  /// Dark theme using Spectrum's original design palette.
  static FThemeData get dark => FThemeData(
        touch: true,
        debugLabel: 'Spectrum Dark',
        colors: FColors(
          brightness: Brightness.dark,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          barrier: const Color(0x7A000000),
          background: const Color(0xFF121212),
          foreground: const Color(0xFFFAFAFA),
          primary: AppColors.primary,
          primaryForeground: const Color(0xFF000000),
          secondary: AppColors.secondary,
          secondaryForeground: const Color(0xFFFFFFFF),
          muted: const Color(0xFF262626),
          mutedForeground: const Color(0xFFA1A1A1),
          destructive: AppColors.error,
          destructiveForeground: const Color(0xFFFFFFFF),
          error: AppColors.error,
          errorForeground: const Color(0xFFFFFFFF),
          card: const Color(0xFF1E1E1E),
          border: const Color(0x1AFFFFFF),
        ),
      );
}
