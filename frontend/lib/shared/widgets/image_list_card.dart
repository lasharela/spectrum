import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A card with an image on the left and text content on the right.
///
/// The image fills the card height and clips to match the card's
/// left-side border radius. Used for places, events, and similar list items.
class ImageListCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final List<ImageListCardDetail> details;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ImageListCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.details = const [],
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final borderRadius = context.theme.style.borderRadius.lg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: borderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left: image filling card height
              SizedBox(
                width: 100,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _buildFallback(colors),
                      )
                    : _buildFallback(colors),
              ),
              // Right: text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: typography.md.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ...details.map((detail) => Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Icon(detail.icon, size: 13, color: colors.mutedForeground),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    detail.text,
                                    style: typography.sm.copyWith(color: colors.mutedForeground),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              // Optional trailing widget
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(FColors colors) {
    return ColoredBox(
      color: colors.muted,
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 28),
      ),
    );
  }
}

/// A detail row shown below the title in an [ImageListCard].
class ImageListCardDetail {
  final IconData icon;
  final String text;

  const ImageListCardDetail({required this.icon, required this.text});
}
