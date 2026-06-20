import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
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
    // Preload full URL for initial page (and next page)
    _loadUrlForIndex(widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    if (mounted) {
      setState(() {
        // Only store if we got a real URL back
        if (fullUrl != null && fullUrl.isNotEmpty) {
          _fullUrls[item.fileId] = fullUrl;
        }
        _loading.remove(item.fileId);
      });
    }

    // Preload next page
    if (index + 1 < widget.files.length) {
      _loadUrlForIndex(index + 1);
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
          _loadUrlForIndex(index);
        },
        itemBuilder: (ctx, index) => _buildPage(index),
      ),
    );
  }

  Widget _buildPage(int index) {
    final item = widget.files[index];
    final isVideo = item.mimeType.toLowerCase().startsWith('video/');

    // Determine which URL to show:
    // 1. Full presigned URL if already loaded
    // 2. Thumbnail URL while loading (no blank screen / no flicker)
    final fullUrl = _fullUrls[item.fileId];
    final isFetchingFull = _loading.contains(item.fileId);

    // If we have neither full URL nor thumbnail — show spinner
    if (fullUrl == null && item.url.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Use full URL if ready, otherwise fall back to thumbnail
    final displayUrl = (fullUrl != null && fullUrl.isNotEmpty)
        ? fullUrl
        : item.url;

    // If it's a video, show video player
    if (isVideo && fullUrl != null && fullUrl.isNotEmpty) {
      return _VideoPlayerWidget(
        videoUrl: displayUrl,
        authToken: widget.authToken,
      );
    }

    final headers = _buildHeaders(displayUrl);

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main image — shows thumbnail first, then full seamlessly
            Image.network(
              displayUrl,
              headers: headers,
              fit: BoxFit.contain,
              gaplessPlayback: true, // KEY: prevents blank flash on URL switch
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const Column(
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

  const _VideoPlayerWidget({
    required this.videoUrl,
    this.authToken,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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
        setState(() => _isInitialized = true);
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey, size: 64),
            SizedBox(height: 12),
            Text(
              'Не удалось загрузить видео',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.blue,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}