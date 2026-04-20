import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/config/app_config.dart';
import '../../profile/data/profile_repository.dart';
import '../../sync/presentation/auto_sync_settings_page.dart';
import '../../sync/auto_sync_service.dart';
import '../data/home_repository.dart';
import 'photo_viewer_page.dart';
import 'device_media_viewer_page.dart';
import '../../../main.dart';

class HomePage extends StatefulWidget {
  final void Function(String? folderId)? onFolderChanged;
  final VoidCallback? onNavigateToFiles;
  final VoidCallback? onNavigateToShared;
  final VoidCallback? onToggleFavourites;

  const HomePage({
    super.key,
    this.onFolderChanged,
    this.onNavigateToFiles,
    this.onNavigateToShared,
    this.onToggleFavourites,
  });

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _profileRepo = ProfileRepository();
  final _homeRepo = HomeRepository();
  Map<String, dynamic> _storageData = {};
  Map<String, dynamic> _statsData = {};
  List<AssetEntity> _recentGalleryFiles = [];
  String? _userName;
  bool _isLoading = true;

  // Pagination state
  AssetPathEntity? _galleryAlbum;
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMoreGalleryFiles = true;
  bool _isLoadingMore = false;

  // Prevent double-tap on gallery items
  bool _isOpeningGallery = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await SecureStorage.getFullName();
    try {
      final results = await Future.wait([
        _profileRepo.getStorageUsed(),
        _profileRepo.getContentStatistics(),
        _loadGalleryFiles(),
      ]);
      if (mounted) {
        setState(() {
          _userName = name;
          _storageData = results[0] as Map<String, dynamic>;
          _statsData = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }

      // Sinxronizatsiyani qayta tekshirish
      AutoSyncService().startAutoSync().catchError((e) {
        debugPrint('[HomePage] Auto-sync refresh error: $e');
      });
    } catch (_) {
      if (mounted) setState(() { _userName = name; _isLoading = false; });
    }
  }

  // Load initial gallery files with pagination support
  Future<void> _loadGalleryFiles() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common, // Get both images and videos
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );

    if (albums.isEmpty) return;

    // Reset pagination state
    _currentPage = 0;
    _hasMoreGalleryFiles = true;
    _recentGalleryFiles.clear();

    // Store album reference for pagination
    _galleryAlbum = albums.first;

    // Load first page
    await _loadMoreGalleryFiles();
  }

  // Load more gallery files (pagination)
  Future<void> _loadMoreGalleryFiles() async {
    if (_galleryAlbum == null || _isLoadingMore || !_hasMoreGalleryFiles) {
      return;
    }

    if (mounted) setState(() => _isLoadingMore = true);

    try {
      final start = _currentPage * _pageSize;
      final end = start + _pageSize;

      final assets = await _galleryAlbum!.getAssetListRange(
        start: start,
        end: end,
      );

      if (mounted) {
        setState(() {
          _recentGalleryFiles.addAll(assets);
          _currentPage++;
          _hasMoreGalleryFiles = assets.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreGalleryFiles = false;
        });
      }
    }
  }

  void reloadContent() => _loadData();

  String _fmt(dynamic b) {
    if (b == null) return '0 KB';
    final v = (b is num) ? b.toDouble() : double.tryParse(b.toString()) ?? 0;
    if (v >= 1073741824) return '${(v / 1073741824).toStringAsFixed(2)} GB';
    if (v >= 1048576) return '${(v / 1048576).toStringAsFixed(1)} MB';
    return '${(v / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 70,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${t.welcomeBack} 👋',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userName ?? t.profile,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
              onPressed: _loadData,
              tooltip: t.refresh,
            ),
            IconButton(
              icon: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: cs.onSurface,
              ),
              onPressed: () => ThemeNotifier.instance.toggle(),
              tooltip: t.theme,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildStorageBar(t),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, t),
                      const SizedBox(height: 24),
                      _buildRecentFilesSection(cs, t),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // Beautiful gradient storage card
  Widget _buildStorageBar(AppLocalizations t) {
    final used = _storageData['used_storage'];
    final limit = _storageData['storage_limit'];
    final percent = (_storageData['percent_used'] as num?)?.toDouble() ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1A73E8), const Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1A73E8)).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.myCloudStorage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(percent).toStringAsFixed(1)}% ${t.used}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_fmt(used)} ${t.used}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_fmt(limit)} ${t.total}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ColorScheme cs, AppLocalizations t) {
    final image = _statsData['image'] as Map<String, dynamic>? ?? {};
    final video = _statsData['video'] as Map<String, dynamic>? ?? {};
    final sharedByMe = _statsData['shared_by_me'] as Map<String, dynamic>? ?? {};
    final sharedWithMe = _statsData['shared_with_me'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            t.overallStats,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: 180,
                child: _StatCard(
                  icon: Icons.image_rounded,
                  iconColor: const Color(0xFF1A73E8),
                  label: t.images,
                  count: '${image['count'] ?? 0}',
                  subtitle: _fmt(image['size']),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                child: _StatCard(
                  icon: Icons.videocam_rounded,
                  iconColor: const Color(0xFFE53935),
                  label: t.videos,
                  count: '${video['count'] ?? 0}',
                  subtitle: _fmt(video['size']),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                child: _StatCard(
                  icon: Icons.share_rounded,
                  iconColor: Colors.green,
                  label: t.sharedByMe,
                  count: '${(sharedByMe['files'] ?? 0) + (sharedByMe['folders'] ?? 0)}',
                  subtitle: '${sharedByMe['users'] ?? 0} ${t.participants}',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                child: _StatCard(
                  icon: Icons.person_rounded,
                  iconColor: Colors.orange,
                  label: t.sharedWithMe,
                  count: '${(sharedWithMe['files'] ?? 0) + (sharedWithMe['folders'] ?? 0)}',
                  subtitle: '${sharedWithMe['users'] ?? 0} ${t.participants}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Recent files section
  Widget _buildRecentSection(ColorScheme cs, AppLocalizations t) {
    final image = _statsData['image'] as Map<String, dynamic>? ?? {};
    final video = _statsData['video'] as Map<String, dynamic>? ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.fileTypes,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateToFiles?.call(),
                child: Text(
                  t.viewAll,
                  style: const TextStyle(
                    color: Color(0xFF1A73E8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FileTypeCard(
                  icon: Icons.image_rounded,
                  label: t.images,
                  count: '${image['count'] ?? 0}',
                  size: _fmt(image['size']),
                  color: const Color(0xFF1A73E8),
                  isDark: isDark,
                  onTap: () => widget.onNavigateToFiles?.call(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FileTypeCard(
                  icon: Icons.videocam_rounded,
                  label: t.videos,
                  count: '${video['count'] ?? 0}',
                  size: _fmt(video['size']),
                  color: const Color(0xFFE53935),
                  isDark: isDark,
                  onTap: () => widget.onNavigateToFiles?.call(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // State variable for layout toggle
  bool _isGridView = true;

  // Recent files section with grid/list toggle - from device gallery
  Widget _buildRecentFilesSection(ColorScheme cs, AppLocalizations t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show nothing if no media files from gallery
    if (_recentGalleryFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.recentFiles,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: cs.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isGridView
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _recentGalleryFiles.length + (_hasMoreGalleryFiles ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Load more indicator at the end
                    if (index == _recentGalleryFiles.length) {
                      // Trigger loading more
                      if (_hasMoreGalleryFiles && !_isLoadingMore) {
                        Future.microtask(() => _loadMoreGalleryFiles());
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final asset = _recentGalleryFiles[index];
                    return _GalleryItemGrid(
                      index: index,
                      asset: asset,
                      isDark: isDark,
                      onTap: () => _openDeviceGallery(index),
                    );
                  },
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentGalleryFiles.length + (_hasMoreGalleryFiles ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Load more indicator at the end
                    if (index == _recentGalleryFiles.length) {
                      // Trigger loading more
                      if (_hasMoreGalleryFiles && !_isLoadingMore) {
                        Future.microtask(() => _loadMoreGalleryFiles());
                      }
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    final asset = _recentGalleryFiles[index];
                    return _GalleryItemList(
                      asset: asset,
                      isDark: isDark,
                      onTap: () => _openDeviceGallery(index),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // Open gallery viewer with device media files
  Future<void> _openDeviceGallery(int initialIndex) async {
    // Prevent double-tap: if already opening, ignore
    if (_isOpeningGallery) return;

    _isOpeningGallery = true;

    try {
      if (!mounted) return;

      // Pass AssetEntity list directly for lazy loading in viewer
      // Using named constructor directly
      final viewer = DeviceMediaViewerPage(
        assets: _recentGalleryFiles,
        initialIndex: initialIndex,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => viewer),
      );
    } finally {
      // Reset flag when navigation completes (user comes back)
      _isOpeningGallery = false;
    }
  }

  String? _normalizeUrl(String? raw) {
    if (raw == null || raw.isEmpty) return raw;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;

    final base = Uri.parse(AppConfig.instance.baseUrl);
    final origin = base.replace(path: '/', query: '', fragment: '');

    if (raw.startsWith('/media/') || raw.startsWith('/static/')) {
      return origin.resolve(raw).toString();
    }
    if (raw.startsWith('/api/')) {
      return origin.resolve(raw).toString();
    }
    if (raw.startsWith('/content/')) {
      return base.resolve(raw.substring(1)).toString();
    }
    if (raw.startsWith('/')) {
      return origin.resolve(raw).toString();
    }
    return base.resolve(raw).toString();
  }

  Future<void> _openGallery(List<dynamic> mediaFiles, String initialFileId) async {
    final authToken = await SecureStorage.getAccessToken();

    final files = mediaFiles.map((item) {
      final id = item['id']?.toString() ?? '';
      final mime = item['mime_type']?.toString() ?? '';
      final nameRaw = item['name']?.toString() ?? '';

      // Decode base64 values
      String decodedMime = mime;
      String decodedName = nameRaw;
      try {
        decodedMime = utf8.decode(base64.decode(mime));
        decodedName = utf8.decode(base64.decode(nameRaw));
      } catch (_) {}

      return (
        url: id.isNotEmpty ? '' : (_normalizeUrl(item['thumbnail_path']?.toString()) ?? ''),
        name: decodedName,
        fileId: id,
        mimeType: decodedMime,
      );
    }).toList();

    final idx = files.indexWhere((f) => f.fileId == initialFileId);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerPage(
          files: files,
          initialIndex: idx < 0 ? 0 : idx,
          authToken: authToken,
          onNeedFullUrl: (id) => _homeRepo.getPreviewUrl(id),
        ),
      ),
    );
  }

  // pCloud-style horizontal actions
  Widget _buildQuickActions(BuildContext context, AppLocalizations t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _QuickActionCard(
            icon: Icons.folder_rounded,
            label: t.myFiles,
            color: const Color(0xFF1A73E8),
            onTap: () => widget.onNavigateToFiles?.call(),
          ),
          const SizedBox(width: 8),
          _QuickActionCard(
            icon: Icons.sync_rounded,
            label: t.sync,
            color: const Color(0xFF9C27B0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AutoSyncSettingsPage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _QuickActionCard(
            icon: Icons.star_rounded,
            label: t.favourites,
            color: Colors.amber,
            onTap: () => widget.onToggleFavourites?.call(),
          ),
          const SizedBox(width: 8),
          _QuickActionCard(
            icon: Icons.people_rounded,
            label: t.shared,
            color: Colors.green,
            onTap: () => widget.onNavigateToShared?.call(),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String count;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── File Type Card ──────────────────────────────────────────────────────────

class _FileTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final String size;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FileTypeCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.size,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: isDark ? 0.2 : 0.1),
              color.withValues(alpha: isDark ? 0.1 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.filesLabel(count),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              size,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Action Card ───────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated Gallery Item ──────────────────────────────────────────────────

class _AnimatedGalleryItem extends StatefulWidget {
  final int index;
  final String imageUrl;
  final bool isDark;
  final VoidCallback onTap;

  const _AnimatedGalleryItem({
    required this.index,
    required this.imageUrl,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedGalleryItem> createState() => _AnimatedGalleryItemState();
}

class _AnimatedGalleryItemState extends State<_AnimatedGalleryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Staggered delay based on index (row-by-row animation)
    final delay = (widget.index ~/ 3) * 100 + (widget.index % 3) * 50;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: widget.isDark ? Colors.grey[800] : Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: widget.isDark ? Colors.grey[800] : Colors.grey[300],
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Gallery Item Grid (from device) ────────────────────────────────────────

class _GalleryItemGrid extends StatefulWidget {
  final int index;
  final AssetEntity asset;
  final bool isDark;
  final VoidCallback onTap;

  const _GalleryItemGrid({
    required this.index,
    required this.asset,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_GalleryItemGrid> createState() => _GalleryItemGridState();
}

class _GalleryItemGridState extends State<_GalleryItemGrid> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: FutureBuilder<Uint8List?>(
            future: widget.asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (_, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
                    if (widget.asset.type == AssetType.video)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEA4335),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.isDark ? Colors.white24 : Colors.black26,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Gallery Item List (from device) ────────────────────────────────────────

class _GalleryItemList extends StatelessWidget {
  final AssetEntity asset;
  final bool isDark;
  final VoidCallback onTap;

  const _GalleryItemList({
    required this.asset,
    required this.isDark,
    required this.onTap,
  });

  String _formatDate(DateTime date, AppLocalizations t) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${t.today} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return t.yesterday;
    } else if (difference.inDays < 7) {
      return t.daysAgo(difference.inDays);
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isVideo = asset.type == AssetType.video;
    final fileName = asset.title ?? 'Unknown';
    final fileDate = asset.createDateTime;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                  builder: (_, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          ),
                          if (isVideo)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEA4335),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      );
                    }
                    return Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(fileDate, AppLocalizations.of(context)!),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
