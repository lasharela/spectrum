import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../constants/app_colors.dart';

/// Forui theme configuration for Spectrum.
///
/// Uses Forui's built-in zinc theme as the base, overriding
/// colors to match Spectrum's soft purple palette.
class AppForuiTheme {
  static FThemeData get light => FThemeData(
        touch: true,
        debugLabel: 'Spectrum Light',
        colors: FColors.zincLight.copyWith(
          primary: AppColors.primary,
          primaryForeground: const Color(0xFFFFFFFF),
          secondary: const Color(0xFFE8E0F4),
          secondaryForeground: AppColors.primary,
          background: AppColors.background,
        ),
      );

  static FThemeData get dark => FThemeData(
        touch: true,
        debugLabel: 'Spectrum Dark',
        colors: FColors.zincDark.copyWith(
          primary: AppColors.primary,
          primaryForeground: const Color(0xFFFFFFFF),
          secondary: const Color(0xFF332A52),
          secondaryForeground: const Color(0xFFF4F0F8),
        ),
      );
}
