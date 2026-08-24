import 'package:flutter/material.dart';

import 'media_thumbnail.dart';

/// Compact, caption-less grid card for photo/video files — used wherever a
/// gallery-style grid of media is shown (Home's recent files section, the
/// Files screen's media tiles). Favourite/overflow controls are drawn as
/// small translucent circle badges over the thumbnail instead of a text row
/// below it, since the thumbnail alone identifies a photo/video.
class MediaGridCard extends StatelessWidget {
  final String mimeType;
  final String? thumbnailPath;
  final String? cacheKey;
  final Map<String, String>? httpHeaders;
  final bool isFavourite;
  final bool isSelected;
  final bool isSelectionMode;
  final String? heroTag;
  final BorderRadius borderRadius;
  final Color playBadgeColor;
  final VoidCallback onTap;
  final VoidCallback? onSelectTap;
  final VoidCallback? onFavouriteTap;
  final VoidCallback? onMenuTap;

  const MediaGridCard({
    super.key,
    required this.mimeType,
    required this.thumbnailPath,
    required this.onTap,
    this.cacheKey,
    this.httpHeaders,
    this.isFavourite = false,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.heroTag,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.playBadgeColor = const Color(0x99000000),
    this.onSelectTap,
    this.onFavouriteTap,
    this.onMenuTap,
  });

  static Widget _badge(Widget child, {Color color = const Color(0x66000000)}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: isSelectionMode ? onSelectTap : onTap,
        onLongPress: onSelectTap,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaThumbnail(
                mimeType: mimeType,
                thumbnailPath: thumbnailPath,
                cacheKey: cacheKey,
                httpHeaders: httpHeaders,
                memCacheWidth: 300,
                memCacheHeight: 300,
                heroTag: heroTag,
                fallbackIcon: Icons.image_rounded,
                fallbackIconColor: const Color(0xFF34A853),
                fallbackBackgroundColor:
                    const Color(0xFF34A853).withValues(alpha: 0.08),
                playBadgeColor: playBadgeColor,
              ),
              if (isSelected)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 14),
                  ),
                ),
              if (!isSelectionMode && onFavouriteTap != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onFavouriteTap,
                    child: _badge(
                      Icon(
                        isFavourite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              if (!isSelectionMode && onMenuTap != null)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onMenuTap,
                    child: _badge(
                      const Icon(Icons.more_vert_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
