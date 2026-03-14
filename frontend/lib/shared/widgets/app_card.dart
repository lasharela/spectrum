import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A shared card widget wrapping Forui's [FCard].
///
/// Supports optional [title], [subtitle], and [onTap] callback.
/// When [onTap] is provided, the card is wrapped in a [GestureDetector].
class AppCard extends StatelessWidget {
  /// The card's title widget.
  final Widget? title;

  /// The card's subtitle widget.
  final Widget? subtitle;

  /// The main content of the card.
  final Widget? child;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Creates an [AppCard].
  const AppCard({
    this.title,
    this.subtitle,
    this.child,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final card = FCard(
      title: title,
      subtitle: subtitle,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
