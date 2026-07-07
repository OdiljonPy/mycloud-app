import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_localizer.dart';
import '../../../core/utils/media_type_helper.dart';
import '../data/download_repository.dart';
import 'package:video_player/video_player.dart';

class PhotoViewerPage extends StatefulWidget {
  final List<({String url, String name, String fileId, String mimeType})> files;
  final int initialIndex;
  final String? authToken;
  final Future<String?> Function(String fileId)? onNeedFullUrl;

  const PhotoViewerPage({
    super.key,
    required this.files,
    this.initialIndex = 0,
    this.authToken,
    this.onNeedFullUrl,
  });

  /// Convenience factory for opening a single image (backward compatible).
  factory PhotoViewerPage.single({
    required String imageUrl,
    required String fileName,
    String? authToken,
    String fileId = '',
    String mimeType = 'image/jpeg',
  }) {
    return PhotoViewerPage(
      files: [(url: imageUrl, name: fileName, fileId: fileId, mimeType: mimeType)],
      initialIndex: 0,
      authToken: authToken,
    );
  }

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  // Neighbors preloaded/precached on both sides of the current page so
  // swiping in either direction is instant instead of loading from scratch.
  static const _preloadRadius = 2;

  late PageController _pageController;
  late int _currentIndex;

  // fileId → full presigned URL (loaded from /preview/)
  final Map<String, String> _fullUrls = {};
  // fileIds currently being fetched
  final Set<String> _loading = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _preloadWindow(widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Cache key for the full-resolution image — distinct from the thumbnail's
  // cache key (plain fileId, used by MediaThumbnail in the list) so the full
  // download never collides with — or is masked by — the cached thumbnail.
  String _fullCacheKey(String fileId) => '${fileId}_full';

  void _preloadWindow(int centerIndex) {
    for (var offset = -_preloadRadius; offset <= _preloadRadius; offset++) {
      _loadUrlForIndex(centerIndex + offset);
    }
  }

  Future<void> _loadUrlForIndex(int index) async {
    if (index < 0 || index >= widget.files.length) return;
    final item = widget.files[index];

    // No fileId — thumbnail url is used as-is, nothing to fetch
    if (item.fileId.isEmpty) return;

    // Already loaded or in progress
    if (_fullUrls.containsKey(item.fileId)) return;
    if (_loading.contains(item.fileId)) return;

    if (mounted) setState(() => _loading.add(item.fileId));

    final fullUrl = await widget.onNeedFullUrl?.call(item.fileId);

    if (mounted &&
        fullUrl != null &&
        fullUrl.isNotEmpty &&
        !MediaTypeHelper.isVideo(item.mimeType)) {
      // Warm the actual image bytes into cache — fetching the URL alone
      // doesn't decode/store pixels, so without this the swipe still stalls
      // on first paint even though the URL was "preloaded".
      unawaited(precacheImage(
        CachedNetworkImageProvider(
          fullUrl,
          cacheKey: _fullCacheKey(item.fileId),
          headers: _buildHeaders(fullUrl),
        ),
        context,
      ));
    }

    if (mounted) {
      setState(() {
        // Only store if we got a real URL back
        if (fullUrl != null && fullUrl.isNotEmpty) {
          _fullUrls[item.fileId] = fullUrl;
        }
        _loading.remove(item.fileId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFile = widget.files[_currentIndex];
    final titleText = widget.files.length > 1
        ? '${currentFile.name}  (${_currentIndex + 1}/${widget.files.length})'
        : currentFile.name;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          titleText,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.files.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _preloadWindow(index);
        },
        itemBuilder: (ctx, index) => _buildPage(index),
      ),
    );
  }

  Widget _buildPage(int index) {
    final item = widget.files[index];
    final isVideo = MediaTypeHelper.isVideo(item.mimeType);
    final hasFullUrl = _fullUrls[item.fileId]?.isNotEmpty ?? false;
    final fullUrl = _fullUrls[item.fileId];

    // Video never gets fed to Image.network — its thumbnail may be the raw
    // video URL itself (list endpoint doesn't guarantee a JPEG frame), so
    // show a spinner until the real, playable URL is ready.
    if (isVideo && !hasFullUrl) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // If we have neither full URL nor thumbnail — show spinner
    if (fullUrl == null && item.url.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Use full URL if ready, otherwise fall back to thumbnail
    final displayUrl = hasFullUrl ? fullUrl! : item.url;
    final isFetchingFull = _loading.contains(item.fileId);

    // If it's a video, show video player
    if (isVideo && hasFullUrl) {
      final player = _VideoPlayerWidget(
        videoUrl: displayUrl,
        authToken: widget.authToken,
        fileId: item.fileId,
        fileName: item.name,
      );
      return item.fileId.isNotEmpty
          ? Hero(tag: 'file_hero_${item.fileId}', child: player)
          : player;
    }

    final headers = _buildHeaders(displayUrl);
    // Thumbnail phase reuses the list's thumbnail cache entry (plain fileId)
    // so it paints instantly from disk; the full-res phase uses a distinct
    // key so it gets its own cache entry and survives closing/reopening the
    // viewer instead of re-downloading every time.
    final cacheKey = item.fileId.isEmpty
        ? null
        : (hasFullUrl ? _fullCacheKey(item.fileId) : item.fileId);

    final viewer = InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main image — shows thumbnail first, then full seamlessly
            CachedNetworkImage(
              imageUrl: displayUrl,
              cacheKey: cacheKey,
              httpHeaders: headers,
              fit: BoxFit.contain,
              useOldImageOnUrlChange: true, // prevents blank flash on URL switch
              fadeInDuration: Duration.zero,
              progressIndicatorBuilder: (_, __, progress) => Center(
                child: CircularProgressIndicator(
                  value: progress.progress,
                  color: Colors.white,
                ),
              ),
              errorWidget: (_, __, ___) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Не удалось загрузить изображение',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              // Decode at the physical screen resolution — best quality the
              // display can show without holding full multi-MP originals in RAM
              memCacheWidth: (MediaQuery.of(context).size.width *
                      MediaQuery.of(context).devicePixelRatio)
                  .round(),
            ),

            // Small loading indicator in corner while fetching full resolution
            // (only shown when thumbnail is visible and full URL is loading)
            if (isFetchingFull && item.url.isNotEmpty)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return item.fileId.isNotEmpty
        ? Hero(tag: 'file_hero_${item.fileId}', child: viewer)
        : viewer;
  }

  Map<String, String> _buildHeaders(String url) {
    if (widget.authToken == null) return {};
    final uri = Uri.tryParse(url);
    if (uri == null) return {};
    final apiHost = Uri.parse(AppConfig.instance.baseUrl).host;
    if (uri.host == apiHost) {
      return {'Authorization': 'Bearer ${widget.authToken}'};
    }
    // Pre-signed MinIO links must NOT include Authorization header.
    return {};
  }
}

// Video Player Widget
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? authToken;
  final String? fileId;
  final String? fileName;

  const _VideoPlayerWidget({
    required this.videoUrl,
    this.authToken,
    this.fileId,
    this.fileName,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isDownloading = false;
  Timer? _hideTimer;
  final _downloadRepo = DownloadRepository();

  Future<void> _download() async {
    final fileId = widget.fileId;
    if (fileId == null || fileId.isEmpty || _isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      await _downloadRepo.downloadFile(
        fileId: fileId,
        fileName: widget.fileName ?? fileId,
      );
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.fileSaved(widget.fileName ?? fileId))),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _startHideTimer();
  }

  void _seekBy(Duration offset) {
    final target = _controller.value.position + offset;
    final duration = _controller.value.duration;
    _controller.seekTo(
      target < Duration.zero
          ? Duration.zero
          : (target > duration ? duration : target),
    );
    _startHideTimer();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
  }

  Map<String, String> _buildHeaders() {
    if (widget.authToken == null) return {};
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri == null) return {};
    final apiHost = Uri.parse(AppConfig.instance.baseUrl).host;

    // Only add Authorization header for API host, not for MinIO presigned URLs
    if (uri.host == apiHost) {
      return {'Authorization': 'Bearer ${widget.authToken}'};
    }
    return {};
  }

  Future<void> _initializeVideo() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      final headers = _buildHeaders();

      _controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: headers,
      );

      await _controller.initialize();
      if (mounted) {
        _controller.addListener(_onControllerUpdate);
        setState(() => _isInitialized = true);
        _controller.play();
        _startHideTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      final t = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 64),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                t.videoFormatNotSupported,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            if (widget.fileId != null && widget.fileId!.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _isDownloading ? null : _download,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(t.download,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final value = _controller.value;

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Center controls: -10s / play-pause / +10s (YouTube-style)
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundControlButton(
                    icon: Icons.replay_5_rounded,
                    size: 32,
                    onTap: () => _seekBy(const Duration(seconds: -5)),
                  ),
                  const SizedBox(width: 36),
                  _RoundControlButton(
                    icon: value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 48,
                    onTap: _togglePlay,
                  ),
                  const SizedBox(width: 36),
                  _RoundControlButton(
                    icon: Icons.forward_5_rounded,
                    size: 32,
                    onTap: () => _seekBy(const Duration(seconds: 5)),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar: current/total time + scrubbable progress
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            _fmtDuration(value.position),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            _fmtDuration(value.duration),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: const VideoProgressColors(
                          playedColor: Colors.blue,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _RoundControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}