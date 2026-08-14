import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_manager/photo_manager.dart';

/// Full-screen viewer for local device media files (images and videos)
class DeviceMediaViewerPage extends StatefulWidget {
  final List<({String url, String name, String fileId, String mimeType})>? files;
  final List<AssetEntity>? assets; // For lazy loading from device gallery
  final int initialIndex;

  const DeviceMediaViewerPage({
    super.key,
    this.files,
    this.assets,
    required this.initialIndex,
  }) : assert(files != null || assets != null, 'Either files or assets must be provided');

  /// Factory for lazy loading from AssetEntity list (FAST!)
  factory DeviceMediaViewerPage.fromAssets({
    required List<AssetEntity> assets,
    int initialIndex = 0,
  }) {
    return DeviceMediaViewerPage(
      assets: assets,
      initialIndex: initialIndex,
    );
  }

  @override
  State<DeviceMediaViewerPage> createState() => _DeviceMediaViewerPageState();
}

class _DeviceMediaViewerPageState extends State<DeviceMediaViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  // Cache for loaded file paths (lazy loaded on page change)
  final Map<int, String> _filePaths = {};
  final Set<int> _loadingPaths = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Preload initial and adjacent pages for smooth experience
    if (widget.assets != null) {
      _loadFilePath(widget.initialIndex);
      if (widget.initialIndex > 0) _loadFilePath(widget.initialIndex - 1);
      if (widget.initialIndex < _itemCount - 1) _loadFilePath(widget.initialIndex + 1);
    }
  }

  int get _itemCount => widget.files?.length ?? widget.assets?.length ?? 0;

  Future<void> _loadFilePath(int index) async {
    if (widget.assets == null) return;
    if (index < 0 || index >= widget.assets!.length) return;
    if (_filePaths.containsKey(index) || _loadingPaths.contains(index)) return;

    _loadingPaths.add(index);

    try {
      final asset = widget.assets![index];
      final file = await asset.file;
      final path = file?.path ?? '';

      if (mounted) {
        setState(() {
          _filePaths[index] = path;
          _loadingPaths.remove(index);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _filePaths[index] = '';
          _loadingPaths.remove(index);
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getFileName(int index) {
    if (widget.files != null) {
      return widget.files![index].name;
    } else if (widget.assets != null) {
      return widget.assets![index].title ?? 'Unknown';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _itemCount > 1
        ? '${_getFileName(_currentIndex)}  (${_currentIndex + 1}/$_itemCount)'
        : _getFileName(_currentIndex);

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
        itemCount: _itemCount,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);

          if (widget.assets != null) {
            _loadFilePath(index);
            if (index > 0) _loadFilePath(index - 1);
            if (index < _itemCount - 1) _loadFilePath(index + 1);
          }
        },
        itemBuilder: (ctx, index) => _buildPage(index),
      ),
    );
  }

  Widget _buildPage(int index) {
    if (widget.assets != null) {
      final asset = widget.assets![index];
      final filePath = _filePaths[index];
      final isLoading = _loadingPaths.contains(index);

      if (isLoading || filePath == null) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }

      if (filePath.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey, size: 64),
              SizedBox(height: 12),
              Text(
                'Файл не найден',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      final isVideo = asset.type == AssetType.video;

      if (isVideo) {
        return _DeviceVideoPlayerWidget(videoPath: filePath);
      }

      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            File(filePath),
            fit: BoxFit.contain,
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
        ),
      );
    }

    final item = widget.files![index];
    final isVideo = item.mimeType.toLowerCase().startsWith('video/');

    if (item.url.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey, size: 64),
            SizedBox(height: 12),
            Text(
              'Файл не найден',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (isVideo) {
      return _DeviceVideoPlayerWidget(videoPath: item.url);
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          File(item.url),
          fit: BoxFit.contain,
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
      ),
    );
  }
}

class _DeviceVideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const _DeviceVideoPlayerWidget({
    required this.videoPath,
  });

  @override
  State<_DeviceVideoPlayerWidget> createState() =>
      _DeviceVideoPlayerWidgetState();
}

class _DeviceVideoPlayerWidgetState extends State<_DeviceVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath));
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
                    curve: Curves.easeOut,
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