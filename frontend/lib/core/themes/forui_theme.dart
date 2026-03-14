import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import '../constants/app_colors.dart';

/// Forui theme configuration for Spectrum.
///
/// Uses Forui's built-in zinc theme as the base, only overriding the
/// primary color to match Spectrum's brand.
class AppForuiTheme {
  static FThemeData get light => FThemeData(
        touch: true,
        debugLabel: 'Spectrum Light',
        colors: FColors.zincLight.copyWith(
          primary: AppColors.primary,
          primaryForeground: const Color(0xFFFFFFFF),
          secondary: const Color(0xFFDDE3F8), // Light primary blue
          secondaryForeground: AppColors.primary,
          background: const Color(0xFFF3F6FA), // Soft blue tint
        ),
      );

  static FThemeData get dark => FThemeData(
        touch: true,
        debugLabel: 'Spectrum Dark',
        colors: FColors.zincDark.copyWith(
          primary: AppColors.primary,
          primaryForeground: const Color(0xFFFFFFFF),
        ),
      );
}
