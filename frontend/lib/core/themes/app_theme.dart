import 'package:flutter/material.dart';

import 'forui_theme.dart';
import '../constants/app_colors.dart';

/// Material theme derived from the Forui theme for interoperability.
///
/// Uses [FThemeData.toApproximateMaterialTheme] to ensure Forui and Material
/// widgets share a consistent look based on the Spectrum original design palette.
class AppTheme {
  /// Light Material theme derived from the Forui light theme.
  static ThemeData get lightTheme =>
      AppForuiTheme.light.toApproximateMaterialTheme().copyWith(
        scaffoldBackgroundColor: AppColors.background,
      );

  /// Dark Material theme derived from the Forui dark theme.
  static ThemeData get darkTheme =>
      AppForuiTheme.dark.toApproximateMaterialTheme();
}
