import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/config/app_config.dart';
import '../../../core/utils/plan_localizer.dart';
import '../../../core/utils/format_bytes.dart';
import '../../profile/data/profile_repository.dart';
import '../../payment/data/repository/payment_repository.dart';
import '../../payment/data/models/payment_models.dart';
import '../../payment/presentation/pages/subscription_page.dart';
import '../../sync/presentation/auto_sync_settings_page.dart';
import '../../sync/auto_sync_service.dart';
import '../../sync/data/gallery_service.dart';
import '../data/home_repository.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import 'photo_viewer_page.dart';
import '../../../main.dart';
import '../../../shared/widgets/shimmer_placeholders.dart';
import '../../../shared/widgets/media_thumbnail.dart';
import '../../../core/utils/page_transitions.dart';

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
  final _paymentRepo = PaymentRepository();
  Map<String, dynamic> _storageData = {};
  Map<String, dynamic> _usageData = {};
  final List<GalleryFile> _backendGalleryFiles = [];
  CurrentSubscription? _subscription;
  List<Plan> _plans = [];
  String? _userName;
  bool _isLoading = true;
  // Guards against overlapping _loadData() calls (refresh button spam,
  // pull-to-refresh, return-from-subscription) — separate from _isLoading,
  // which only tracks the initial-load shimmer and must stay false after that.
  bool _isFetchingData = false;

  // Pagination state
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreGalleryFiles = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAuthToken();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadAuthToken() async {
    final token = await SecureStorage.getAccessToken();
    if (mounted) setState(() => _authToken = token);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreGalleryFiles) {
        _loadMoreBackendGalleryFiles();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<CurrentSubscription?> _loadSubscriptionSilently() async {
    try {
      return await _paymentRepo.getCurrentSubscription();
    } catch (e) {
      if (kDebugMode) debugPrint('[HomePage] getCurrentSubscription failed: $e');
      return null;
    }
  }

  Future<List<Plan>> _loadPlansSilently() async {
    try {
      return await _paymentRepo.getPlans();
    } catch (e) {
      if (kDebugMode) debugPrint('[HomePage] getPlans failed: $e');
      return [];
    }
  }

  Plan? _findNextPlan() {
    final sub = _subscription;
    if (sub == null || sub.planId == null || _plans.isEmpty) return null;
    final pool = _plans.where((p) => p.billingPeriod == sub.billingPeriod).toList();
    final sorted = (pool.isNotEmpty ? pool : [..._plans])
      ..sort((a, b) => a.storage.compareTo(b.storage));
    final idx = sorted.indexWhere((p) => p.id == sub.planId);
    if (idx == -1 || idx >= sorted.length - 1) return null;
    return sorted[idx + 1];
  }

  Future<void> _loadData() async {
    if (_isFetchingData) return;
    _isFetchingData = true;
    try {
      final name = await SecureStorage.getFullName();
      try {
        final results = await Future.wait([
          _profileRepo.getStorageUsed(),
          _profileRepo.getStorageUsage(),
          _loadBackendGalleryFiles(),
          _loadSubscriptionSilently(),
          _loadPlansSilently(),
        ]);
        if (mounted) {
          setState(() {
            _userName = name;
            _storageData = results[0] as Map<String, dynamic>;
            _usageData = (results[1] as Map<String, dynamic>?) ?? {};
            _subscription = results[3] as CurrentSubscription?;
            _plans = results[4] as List<Plan>;
            _isLoading = false;
          });
        }

        // Sinxronizatsiyani qayta tekshirish — faqat foydalanuvchi
        // auto-sync'ni yoqqan bo'lsa (o'chirilgan holatda jim boshlanib
        // ketmasligi kerak)
        if (await AutoSyncService().isAutoSyncEnabled()) {
          AutoSyncService().startAutoSync().catchError((e) {
            debugPrint('[HomePage] Auto-sync refresh error: $e');
          });
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[HomePage] _loadData failed: $e');
        if (mounted) setState(() { _userName = name; _isLoading = false; });
      }
    } finally {
      _isFetchingData = false;
    }
  }

  Future<void> _loadBackendGalleryFiles() async {
    // A load-more (scroll pagination) is already in flight — resetting and
    // clearing the list now would race with its in-progress addAll() and
    // can drop or duplicate results once it resolves.
    if (_isLoadingMore) return;

    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    _currentPage = 1;
    _hasMoreGalleryFiles = true;
    _backendGalleryFiles.clear();

    await _loadMoreBackendGalleryFiles();
  }

  Future<void> _loadMoreBackendGalleryFiles() async {
    if (_isLoadingMore || !_hasMoreGalleryFiles) {
      return;
    }

    if (mounted) setState(() => _isLoadingMore = true);

    try {
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _isLoadingMore = false);
        return;
      }

      final galleryService = GalleryService(
        baseUrl: AppConfig.instance.baseUrl,
        token: token,
      );

      final response = await galleryService.getGalleryPaginated(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        // Defensive dedup: offset-based pagination can repeat an item across
        // pages if the gallery changed between requests (upload mid-scroll).
        final existingIds = _backendGalleryFiles.map((f) => f.id).toSet();
        final newFiles =
            response.results.where((f) => existingIds.add(f.id)).toList();
        setState(() {
          _backendGalleryFiles.addAll(newFiles);
          _currentPage++;
          // A short page (fewer results than requested) means the server
          // has no more data even if `next` says otherwise — stops pagination
          // instead of firing one more (empty) request forever.
          _hasMoreGalleryFiles =
              response.next != null && response.results.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('[HomePage] Load backend gallery failed: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreGalleryFiles = false;
        });
      }
    }
  }

  void reloadContent() => _loadData();

  String _fmt(dynamic b) => formatBytes(b, AppLocalizations.of(context)!);

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
            const NotificationBellButton(),
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
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await _loadData();
          },
          child: _isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 8),
                    StorageCardShimmer(),
                    SizedBox(height: 24),
                    GalleryGridShimmer(),
                  ],
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildStorageSection(t),
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

  Widget _buildStorageSection(AppLocalizations t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final innerBg = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF5F5F7);
    final borderColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final textSecondary = isDark ? Colors.white54 : Colors.black45;

    final used = _storageData['used_storage'];
    final limit = _storageData['storage_limit'];
    final percent = (_storageData['percent_used'] as num?)?.toDouble() ?? 0;
    final images = _usageData['images'];
    final videos = _usageData['videos'];

    final sub = _subscription;
    final hasActive = sub != null && sub.planId != null;
    final nextPlan = _findNextPlan();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.storage,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.storageSubtitle,
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: innerBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storage_rounded,
                              color: Color(0xFF1A73E8), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.storageUsedOfLimit(_fmt(used), _fmt(limit)),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${percent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            color: borderColor,
                          ),
                          FractionallySizedBox(
                            widthFactor: (percent / 100).clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF22C55E), Color(0xFFF97316)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUsageTile(
                            Icons.image_outlined,
                            t.images,
                            _fmt(images),
                            const Color(0xFF10B981),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildUsageTile(
                            Icons.videocam_outlined,
                            t.videos,
                            _fmt(videos),
                            const Color(0xFFF59E0B),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.of(context)
                      .push(slideUpRoute(const SubscriptionPage()))
                      .then((_) {
                    if (mounted) _loadData();
                  }),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    nextPlan != null
                        ? t.upgradeToPlan(PlanLocalizer.localize(nextPlan.name, t))
                        : hasActive
                            ? t.changePlan
                            : t.choosePlan,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageTile(
      IconData icon, String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45)),
                Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isGridView = true;

  Map<String, List<GalleryFile>> _groupFilesByDate() {
    final t = AppLocalizations.of(context)!;
    final Map<String, List<GalleryFile>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final file in _backendGalleryFiles) {
      if (file.capturedAt == null) continue;

      try {
        final fileDate = DateTime.parse(file.capturedAt!);
        final fileDateOnly = DateTime(fileDate.year, fileDate.month, fileDate.day);

        String dateKey;
        if (fileDateOnly == today) {
          dateKey = t.today;
        } else if (fileDateOnly == yesterday) {
          dateKey = t.yesterday;
        } else {
          dateKey = '${fileDate.day} ${_getMonthName(fileDate.month)}';
        }

        grouped.putIfAbsent(dateKey, () => []);
        grouped[dateKey]!.add(file);
      } catch (e) {
        if (kDebugMode) debugPrint('[HomePage] group-by-date skip file: $e');
        continue;
      }
    }

    return grouped;
  }

  String _getMonthName(int month) {
    const months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
      'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'
    ];
    return months[month - 1];
  }

  // Recent files section with grid/list toggle - from backend gallery
  Widget _buildRecentFilesSection(ColorScheme cs, AppLocalizations t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_backendGalleryFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedFiles = _groupFilesByDate();

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

          ...groupedFiles.entries.map((entry) {
            final dateLabel = entry.key;
            final files = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                _isGridView
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        addAutomaticKeepAlives: false,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final globalIndex = _backendGalleryFiles.indexOf(file);
                          return _BackendGalleryItemGrid(
                            index: globalIndex,
                            file: file,
                            isDark: isDark,
                            authToken: _authToken,
                            onTap: () => _openBackendGallery(globalIndex),
                          );
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        addAutomaticKeepAlives: false,
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final globalIndex = _backendGalleryFiles.indexOf(file);
                          return _BackendGalleryItemList(
                            file: file,
                            isDark: isDark,
                            authToken: _authToken,
                            onTap: () => _openBackendGallery(globalIndex),
                          );
                        },
                      ),
                const SizedBox(height: 16),
              ],
            );
          }),

          if (_isLoadingMore)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openBackendGallery(int initialIndex) async {
    if (!mounted) return;

    final files = _backendGalleryFiles;

    if (files.isEmpty || initialIndex >= files.length) return;

    final mediaFiles = files.map((file) => {
      'id': file.id,
      'mime_type': file.mimeType,
      'name': file.name,
      'thumbnail_path': file.thumbnailPath,
    }).toList();

    await _openGallery(mediaFiles, files[initialIndex].id);
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

      String decodedMime = mime;
      String decodedName = nameRaw;
      try {
        decodedMime = utf8.decode(base64.decode(mime));
        decodedName = utf8.decode(base64.decode(nameRaw));
      } catch (e) {
        if (kDebugMode) debugPrint('[HomePage] base64 decode failed: $e');
      }

      return (
        url: _normalizeUrl(item['thumbnail_path']?.toString()) ?? '',
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
              slideUpRoute(const AutoSyncSettingsPage()),
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

// ─── Backend Gallery Item Grid ──────────────────────────────────────────────

class _BackendGalleryItemGrid extends StatelessWidget {
  final int index;
  final GalleryFile file;
  final bool isDark;
  final String? authToken;
  final VoidCallback onTap;

  const _BackendGalleryItemGrid({
    required this.index,
    required this.file,
    required this.isDark,
    required this.authToken,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = file.thumbnailPath ?? '';
    final normalizedUrl = _normalizeUrl(thumbnailUrl, context);

    return GestureDetector(
      onTap: onTap,
      child: MediaThumbnail(
        mimeType: file.mimeType,
        thumbnailPath: normalizedUrl,
        cacheKey: file.id,
        borderRadius: BorderRadius.circular(12),
        httpHeaders:
            authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
        fallbackIcon: Icons.image_not_supported_rounded,
        fallbackIconColor: isDark ? Colors.grey[600]! : Colors.grey[400]!,
        fallbackBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        fallbackIconSize: 32,
        memCacheWidth: 300,
        memCacheHeight: 300,
        playBadgeColor: const Color(0xFFEA4335),
      ),
    );
  }

  String _normalizeUrl(String? raw, BuildContext context) {
    if (raw == null || raw.isEmpty) return '';
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
}

// ─── Backend Gallery Item List ──────────────────────────────────────────────

class _BackendGalleryItemList extends StatelessWidget {
  final GalleryFile file;
  final bool isDark;
  final String? authToken;
  final VoidCallback onTap;

  const _BackendGalleryItemList({
    required this.file,
    required this.isDark,
    required this.authToken,
    required this.onTap,
  });

  String _formatDate(String? dateStr, AppLocalizations t) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
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
    } catch (e) {
      if (kDebugMode) debugPrint('[HomePage] date format failed: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final thumbnailUrl = file.thumbnailPath ?? '';
    final normalizedUrl = _normalizeUrl(thumbnailUrl, context);

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
            MediaThumbnail(
              mimeType: file.mimeType,
              thumbnailPath: normalizedUrl,
              cacheKey: file.id,
              width: 60,
              height: 60,
              memCacheWidth: 180,
              memCacheHeight: 180,
              borderRadius: BorderRadius.circular(8),
              httpHeaders:
                  authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
              fallbackIcon: Icons.image_not_supported_rounded,
              fallbackIconColor: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              fallbackBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              fallbackIconSize: 24,
              playBadgeColor: const Color(0xFFEA4335),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
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
                    _formatDate(file.capturedAt, t),
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

  String _normalizeUrl(String? raw, BuildContext context) {
    if (raw == null || raw.isEmpty) return '';
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
}