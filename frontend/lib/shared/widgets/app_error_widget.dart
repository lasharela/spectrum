import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A widget that displays an error message with an optional retry button.
///
/// Uses [AppColors.error] for the error icon color. This is a plain
/// Material widget (not Forui-wrapped), used for error states.
class AppErrorWidget extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// An optional callback invoked when the retry button is tapped.
  /// If null, the retry button is not shown.
  final VoidCallback? onRetry;

  /// Creates an [AppErrorWidget].
  const AppErrorWidget({
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
