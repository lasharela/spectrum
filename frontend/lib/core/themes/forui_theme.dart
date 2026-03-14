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
          background: AppColors.background,
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
