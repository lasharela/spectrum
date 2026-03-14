import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Variants for [AppButton] that map to Forui's [FButtonVariant].
enum AppButtonVariant {
  /// Primary filled button (default).
  primary,

  /// Secondary filled button.
  secondary,

  /// Outline/bordered button.
  outline,

  /// Ghost/text-only button.
  ghost,
}

/// A shared button widget wrapping Forui's [FButton].
///
/// Supports primary, secondary, outline, and ghost variants.
/// Provides an [isLoading] state that disables the button and shows
/// a [FCircularProgress] spinner instead of the label.
class AppButton extends StatelessWidget {
  /// The button label text.
  final String label;

  /// Called when the button is pressed. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// The visual variant of the button.
  final AppButtonVariant variant;

  /// Whether the button is in a loading state.
  /// When true, the button is disabled and shows a spinner.
  final bool isLoading;

  /// Creates an [AppButton].
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fVariant = switch (variant) {
      AppButtonVariant.primary => FButtonVariant.primary,
      AppButtonVariant.secondary => FButtonVariant.secondary,
      AppButtonVariant.outline => FButtonVariant.outline,
      AppButtonVariant.ghost => FButtonVariant.ghost,
    };

    return FButton(
      variant: fVariant,
      onPress: isLoading ? null : onPressed,
      child: isLoading ? const FCircularProgress() : Text(label),
    );
  }
}
