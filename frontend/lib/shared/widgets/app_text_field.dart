import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A callback for building a prefix or suffix icon in [AppTextField].
///
/// Matches Forui's [FFieldIconBuilder] signature.
typedef AppTextFieldIconBuilder =
    Widget Function(BuildContext context, FTextFieldStyle style, Set<FTextFieldVariant> variants);

/// A shared text field widget wrapping Forui's [FTextField].
///
/// Supports an optional [label], [hint], and [isPassword] mode.
/// When [isPassword] is true, the field uses [FTextField.password] which
/// provides built-in obscure text toggling.
///
/// Enhanced with [error], [onChanged], [prefixBuilder], and [suffixBuilder].
class AppTextField extends StatelessWidget {
  /// The label displayed above the field.
  final String? label;

  /// The hint text shown when the field is empty.
  final String? hint;

  /// An optional external [TextEditingController].
  final TextEditingController? controller;

  /// Whether this field is a password field with obscured text.
  final bool isPassword;

  /// Whether the field is enabled.
  final bool enabled;

  /// Called when the user submits the field (e.g. presses done).
  final ValueChanged<String>? onSubmit;

  /// The keyboard type for the field.
  final TextInputType? keyboardType;

  /// An optional error widget displayed below the field.
  final Widget? error;

  /// Called whenever the text changes.
  ///
  /// Receives the current string value of the field.
  final ValueChanged<String>? onChanged;

  /// An optional builder for a widget rendered before the text input.
  ///
  /// Not used when [isPassword] is true.
  final AppTextFieldIconBuilder? prefixBuilder;

  /// An optional builder for a widget rendered after the text input.
  ///
  /// Ignored when [isPassword] is true, because [FTextField.password]
  /// provides its own built-in visibility toggle.
  final AppTextFieldIconBuilder? suffixBuilder;

  /// Creates an [AppTextField].
  const AppTextField({
    this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.onSubmit,
    this.keyboardType,
    this.error,
    this.onChanged,
    this.prefixBuilder,
    this.suffixBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = label != null ? Text(label!) : null;

    // Wrap onChanged (String) to match FTextFieldControl's onChange signature
    // (TextEditingValue).
    final controlOnChange = onChanged != null
        ? (TextEditingValue value) => onChanged!(value.text)
        : null;

    if (isPassword) {
      return FTextField.password(
        control: FTextFieldControl.managed(
          controller: controller,
          onChange: controlOnChange,
        ),
        label: labelWidget,
        hint: hint,
        enabled: enabled,
        onSubmit: onSubmit,
        keyboardType: keyboardType,
        error: error,
        // prefixBuilder and suffixBuilder are intentionally omitted for
        // password fields. FTextField.password uses a different builder
        // signature (FPasswordFieldIconBuilder) and manages its own
        // obscure-text toggle via suffixBuilder. Callers should not rely
        // on these for password fields.
      );
    }

    return FTextField(
      control: FTextFieldControl.managed(
        controller: controller,
        onChange: controlOnChange,
      ),
      label: labelWidget,
      hint: hint,
      enabled: enabled,
      onSubmit: onSubmit,
      keyboardType: keyboardType,
      error: error,
      prefixBuilder: prefixBuilder,
      suffixBuilder: suffixBuilder,
    );
  }
}
