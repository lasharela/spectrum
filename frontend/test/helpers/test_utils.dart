import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:spectrum_app/core/themes/forui_theme.dart';

/// Wraps a widget with MaterialApp + FTheme + ProviderScope for testing.
Widget buildTestApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: FTheme(
        data: AppForuiTheme.light,
        child: Scaffold(body: child),
      ),
    ),
  );
}
