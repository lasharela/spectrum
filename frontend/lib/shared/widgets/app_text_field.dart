import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A shared text field widget wrapping Forui's [FTextField].
///
/// Supports an optional [label], [hint], and [isPassword] mode.
/// When [isPassword] is true, the field uses [FTextField.password] which
/// provides built-in obscure text toggling.
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

  /// Creates an [AppTextField].
  const AppTextField({
    this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.onSubmit,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = label != null ? Text(label!) : null;

    if (isPassword) {
      return FTextField.password(
        control: FTextFieldControl.managed(controller: controller),
        label: labelWidget,
        hint: hint,
        enabled: enabled,
        onSubmit: onSubmit,
        keyboardType: keyboardType,
      );
    }

    return FTextField(
      control: FTextFieldControl.managed(controller: controller),
      label: labelWidget,
      hint: hint,
      enabled: enabled,
      onSubmit: onSubmit,
      keyboardType: keyboardType,
    );
  }
}
