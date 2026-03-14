import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A widget that displays a loading indicator with an optional message.
///
/// Uses [AppColors.cyan] for the progress indicator color. This is a plain
/// Material widget (not Forui-wrapped), used for loading states.
class AppLoadingWidget extends StatelessWidget {
  /// An optional message to display below the loading indicator.
  final String? message;

  /// Creates an [AppLoadingWidget].
  const AppLoadingWidget({
    this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
