import 'package:flutter/material.dart';

import 'forui_theme.dart';

/// Material theme derived from the Forui theme for interoperability.
class AppTheme {
  static ThemeData get lightTheme =>
      AppForuiTheme.light.toApproximateMaterialTheme();

  static ThemeData get darkTheme =>
      AppForuiTheme.dark.toApproximateMaterialTheme();
}
