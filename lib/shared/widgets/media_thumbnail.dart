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
  final bool centeredPlayIcon;
  final Color playBadgeColor;

  const MediaThumbnail({
    super.key,
    required this.mimeType,
    required this.thumbnailPath,
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
    this.centeredPlayIcon = false,
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
            errorWidget: (_, __, ___) =>
                isVid ? const _VideoPlaceholder() : _fallbackBox(),
          ),
          if (isVid && showPlayBadge) _playBadge(),
        ],
      );
    } else if (isVid) {
      content = const _VideoPlaceholder();
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

  Widget _playBadge() {
    if (centeredPlayIcon) {
      return Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: playBadgeColor, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
        ),
      );
    }
    return Positioned(
      right: 2,
      bottom: 2,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: playBadgeColor, shape: BoxShape.circle),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 10),
      ),
    );
  }
}

/// Standard "no frame available" video placeholder: adaptive dark
/// background + centered play icon (Telegram/WhatsApp/Google Photos style).
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFF1C1C1E),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final iconSize = side.isFinite ? side * 0.4 : 28.0;
          return Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: iconSize.clamp(16.0, 40.0),
            ),
          );
        },
      ),
    );
  }
}
