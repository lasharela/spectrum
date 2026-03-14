import 'package:flutter/material.dart';

import 'forui_theme.dart';

/// Material theme derived from the Forui theme for interoperability.
///
/// Uses [FThemeData.toApproximateMaterialTheme] to ensure Forui and Material
/// widgets share a consistent look based on the Spectrum cyan/coral palette.
class AppTheme {
  /// Light Material theme derived from the Forui light theme.
  static ThemeData get lightTheme =>
      AppForuiTheme.light.toApproximateMaterialTheme();

  /// Dark Material theme derived from the Forui dark theme.
  static ThemeData get darkTheme =>
      AppForuiTheme.dark.toApproximateMaterialTheme();
}
