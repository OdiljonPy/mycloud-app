import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps shimmer placeholder shapes with theme-aware base/highlight colors.
class ShimmerBase extends StatelessWidget {
  final Widget child;
  const ShimmerBase({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE5E5EA),
      highlightColor:
          isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F7),
      child: child,
    );
  }
}

/// Self-contained shimmer box for use as a `CachedNetworkImage` placeholder
/// (unlike [ShimmerBox], it doesn't need an ancestor [ShimmerBase]).
class ShimmerThumbnail extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const ShimmerThumbnail({
    super.key,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBase(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
    );
  }
}

/// Placeholder row shaped like a file/folder list item: leading avatar
/// square + title line + subtitle line.
class FileRowShimmer extends StatelessWidget {
  const FileRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen shimmer list for a files/folders screen's initial load.
class FilesListShimmer extends StatelessWidget {
  final int itemCount;
  const FilesListShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ShimmerBase(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (_, __) => const FileRowShimmer(),
      ),
    );
  }
}

/// Placeholder card shaped like a shared-user list row: leading round
/// avatar + title line + subtitle line.
class UserRowShimmer extends StatelessWidget {
  const UserRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          ShimmerBox(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 90, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserListShimmer extends StatelessWidget {
  final int itemCount;
  const UserListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerBase(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (_, __) => const UserRowShimmer(),
      ),
    );
  }
}

/// Placeholder matching the home screen's storage summary card.
class StorageCardShimmer extends StatelessWidget {
  const StorageCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerBase(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 100, height: 16),
              SizedBox(height: 8),
              ShimmerBox(width: 160, height: 12),
              SizedBox(height: 16),
              ShimmerBox(width: double.infinity, height: 60),
              SizedBox(height: 12),
              ShimmerBox(width: double.infinity, height: 46),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder grid matching the home screen's recent-files gallery.
class GalleryGridShimmer extends StatelessWidget {
  final int itemCount;
  const GalleryGridShimmer({super.key, this.itemCount = 9});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerBase(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: itemCount,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
