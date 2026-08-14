import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/media_type_helper.dart';
import 'shimmer_placeholders.dart';

/// Single source of truth for rendering a file preview (photo or video).
///
/// Video files are never fed into [CachedNetworkImage] directly — the
/// list/preview endpoints don't guarantee a JPEG frame for every video
/// (e.g. `thumbnail_path` can be empty), so a dark play-icon placeholder is
/// used instead of risking a decode failure on a raw video URL.
class MediaThumbnail extends StatelessWidget {
  final String mimeType;
  final String? thumbnailPath;
  // Stable cache identity (typically the file id). thumbnailPath itself is
  // often a pre-signed URL whose query/signature rotates on every server
  // response — using it as the cache key defeats CachedNetworkImage's disk
  // cache (every reload looks like a new image). Pass a stable id here so
  // repeat views of the same file hit the disk cache instead of re-downloading.
  final String? cacheKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Map<String, String>? httpHeaders;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final IconData fallbackIcon;
  final Color fallbackIconColor;
  final Color? fallbackBackgroundColor;
  final double fallbackIconSize;
  final bool showPlayBadge;
  final Color playBadgeColor;

  const MediaThumbnail({
    super.key,
    required this.mimeType,
    required this.thumbnailPath,
    this.cacheKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.httpHeaders,
    this.borderRadius,
    this.heroTag,
    this.fallbackIcon = Icons.insert_drive_file_rounded,
    this.fallbackIconColor = const Color(0xFF1A73E8),
    this.fallbackBackgroundColor,
    this.fallbackIconSize = 20,
    this.showPlayBadge = true,
    this.playBadgeColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    final isImg = MediaTypeHelper.isImage(mimeType);
    final isVid = MediaTypeHelper.isVideo(mimeType);
    final hasThumb = thumbnailPath != null && thumbnailPath!.isNotEmpty;

    Widget content;
    if ((isImg || isVid) && hasThumb) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: thumbnailPath!,
            cacheKey: (cacheKey != null && cacheKey!.isNotEmpty) ? cacheKey : null,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            httpHeaders: httpHeaders,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, __) => ShimmerThumbnail(
              width: width,
              height: height,
              borderRadius: borderRadius ?? BorderRadius.zero,
            ),
            errorWidget: (_, __, ___) => isVid
                ? _VideoPlaceholder(playBadgeColor: playBadgeColor, showBadge: showPlayBadge)
                : _fallbackBox(),
          ),
          if (isVid && showPlayBadge) _CenteredPlayBadge(color: playBadgeColor),
        ],
      );
    } else if (isVid) {
      content = _VideoPlaceholder(playBadgeColor: playBadgeColor, showBadge: showPlayBadge);
    } else {
      content = _fallbackBox();
    }

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }
    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }
    return SizedBox(width: width, height: height, child: content);
  }

  Widget _fallbackBox() {
    return Container(
      color: fallbackBackgroundColor ??
          fallbackIconColor.withValues(alpha: 0.12),
      child: Center(
        child: Icon(fallbackIcon, color: fallbackIconColor, size: fallbackIconSize),
      ),
    );
  }

}

/// Single play-badge style used everywhere a video is shown — whether over a
/// real thumbnail frame or over [_VideoPlaceholder]. Size scales with the
/// tile instead of being fixed, so it reads correctly from a 44px list tile
/// up to a full-width detail card.
class _CenteredPlayBadge extends StatelessWidget {
  final Color color;

  const _CenteredPlayBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final badgeSize = side.isFinite ? (side * 0.28).clamp(16.0, 32.0) : 24.0;
          return Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white.withValues(alpha: 0.92),
              size: badgeSize * 0.55,
            ),
          );
        },
      ),
    );
  }
}

/// "No frame available" video placeholder: dark gray gradient (not flat
/// black, so it doesn't read as broken/empty) + the same centered play badge
/// used over real frames, plus a small corner video icon — since there's no
/// frame here to make "this is a video" obvious on its own.
class _VideoPlaceholder extends StatelessWidget {
  final Color playBadgeColor;
  final bool showBadge;

  const _VideoPlaceholder({required this.playBadgeColor, required this.showBadge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF3A3A3E), const Color(0xFF232326)]
              : [const Color(0xFF4A4A4E), const Color(0xFF2E2E31)],
        ),
      ),
      child: Stack(
        children: [
          if (showBadge) _CenteredPlayBadge(color: playBadgeColor),
          Positioned(
            left: 4,
            top: 4,
            child: Icon(
              Icons.videocam_rounded,
              size: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
