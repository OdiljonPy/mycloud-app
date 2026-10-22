import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../data/home_repository.dart';
import '../data/download_repository.dart';
import '../data/models/folder_model.dart';
import '../data/models/file_model.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/thumbnail_cache_manager.dart';
import '../../../core/utils/error_localizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/storage/secure_storage.dart';
import 'package:cloud_app/features/home/presentation/move_destination_screen.dart';
import '../../upload/presentation/upload_page.dart';
import 'photo_viewer_page.dart';
import '../../../core/providers/favourites_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../share/presentation/bloc/share_bloc.dart';
import '../../share/data/repository/share_repository_impl.dart';
import '../../share/data/remote/share_remote_data_source_impl.dart';
import '../../share/presentation/widgets/share_dialog.dart';
import '../../profile/data/profile_repository.dart';
import '../../../shared/widgets/shimmer_placeholders.dart';
import '../../../shared/widgets/staggered_list_item.dart';
import '../../../shared/widgets/media_thumbnail.dart';
import '../../../shared/widgets/media_grid_card.dart';
import '../../../core/utils/media_type_helper.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/utils/safe_action_mixin.dart';
import '../../../core/utils/navigation_guard.dart';


enum _FilterType { all, images, videos }

class FilesPage extends StatefulWidget {
  final void Function(String? folderId)? onFolderChanged;
  final HomeRepository? repository;
  // MainPage owns system back when Files is one of its persistent tabs.
  final bool handleSystemBack;

  const FilesPage({super.key, this.onFolderChanged, this.repository,
    this.handleSystemBack = true});

  @override
  State<FilesPage> createState() => FilesPageState();
}

class FilesPageState extends State<FilesPage> with SafeActionMixin<FilesPage> {
  late final _repo = widget.repository ?? HomeRepository();
  final _downloadRepo = DownloadRepository();
  final _profileRepo = ProfileRepository();

  List<FolderModel> _folders = [];
  List<FileModel> _files = [];
  List<FileModel> _dateOrderedFiles = [];
  bool _isLoading = false;
  int _contentRevision = 0;
  String? _loadingFolderId;
  bool _reloadAfterLoad = false;
  Timer? _staggerTimer;
  Object? _error;
  bool _isGrid = true;
  String? _authToken;


  // Progress ticks many times/sec — kept outside setState so per-chunk
  // updates rebuild only the affected _FileTile, not the whole page.
  final Map<String, ValueNotifier<({double progress, int received})>>
      _downloadNotifiers = {};

  final List<({String id, String name, bool isSync})> _breadcrumb = [];
  final List<({String id, String name, bool isSync})> _savedBreadcrumb = [];
  // Snapshot of the folder view we were in before entering favourites —
  // lets "back" pop to it from memory instead of re-fetching the root.
  List<FileModel>? _savedFiles;
  List<FolderModel>? _savedFolders;
  int? _savedPage;
  bool? _savedHasNextPage;
  int? _savedTotalFilesCount;

  bool _showFavourites = false;
  _FilterType _activeFilter = _FilterType.all;

  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  final ScrollController _scrollController = ScrollController();
  // True only for the brief window right after a full-screen load — gates
  // the staggered fade-in so it never replays for scroll/pagination reveals.
  bool _staggerActive = false;

  bool get _isSelectionMode =>
      _selectedFiles.isNotEmpty || _selectedFolders.isNotEmpty;
  final Set<String> _selectedFiles = {};
  final Set<String> _selectedFolders = {};

  List<Map<String, dynamic>> _pinnedFolders = [];
  int _folderPage = 0;
  int _totalFilesCount = 0;
  late final ShareBloc _shareBloc;
  bool get _isSyncFolder =>
      _breadcrumb.isNotEmpty && _breadcrumb.last.isSync;

  String _fmt(dynamic b) {
    if (b == null) return '0 KB';
    final v = (b is num) ? b.toDouble() : double.tryParse(b.toString()) ?? 0;
    if (v >= 1073741824) return '${(v / 1073741824).toStringAsFixed(2)} GB';
    if (v >= 1048576) return '${(v / 1048576).toStringAsFixed(1)} MB';
    return '${(v / 1024).toStringAsFixed(0)} KB';
  }

  Future<void> _toggleFavourite(FileModel file) async {
    HapticFeedback.lightImpact();
    try {
      await FavouritesProvider.instance.toggleFavourite(file);
    } catch (_) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.favouriteUpdateFailed)),
      );
    }
  }

  bool _selectedFavouritesAllMarked() {
    if (_selectedFiles.isEmpty) return false;
    final selected = _files.where((f) => _selectedFiles.contains(f.id));
    return selected.isNotEmpty && selected.every((f) => f.isFavourite);
  }

  void _bulkToggleFavourites() {
    if (_selectedFiles.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final selected =
        _files.where((f) => _selectedFiles.contains(f.id)).toList();
    final removing = _selectedFavouritesAllMarked();
    final targets = selected.where((f) => f.isFavourite == removing).toList();

    setState(() {
      _selectedFiles.clear();
      _selectedFolders.clear();
    });

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.alreadyInFavourites)),
      );
      return;
    }

    for (final f in targets) {
      _toggleFavourite(f);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            removing ? l10n.removedFromFavourites : l10n.addedToFavourites),
      ),
    );
  }

  Widget _buildPaginationRow({
    required int page,
    required bool isLastPage,
    required ValueChanged<int> onPageChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: page == 0 ? null : () => onPageChanged(page - 1),
        ),
        Text('${page + 1}',
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isLastPage ? null : () => onPageChanged(page + 1),
        ),
      ],
    );
  }

  String? _getPinId(String folderId) {
    for (final pin in _pinnedFolders) {
      final folder = pin['folder'];
      if (folder is FolderModel && folder.id == folderId) {
        return pin['pinId'] as String?;
      }
    }
    return null;
  }

  Future<void> _pinFolder(FolderModel folder) async {
    final t = AppLocalizations.of(context)!;
    if (_pinnedFolders.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.maxPinnedFolders)),
        );
      }
      return;
    }
    if (_getPinId(folder.id) != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.alreadyPinned)),
        );
      }
      return;
    }
    final newPin = {'pinId': folder.id, 'folder': folder};
    setState(() => _pinnedFolders = [..._pinnedFolders, newPin]);
    try {
      await _repo.pinFolder(folder.id);
    } on AppException catch (e) {
      setState(() => _pinnedFolders =
          _pinnedFolders.where((p) => p['pinId'] != folder.id).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!))));
      }
    }
  }

  Future<void> _unpinFolder(String pinId) async {
    final backup = List<Map<String, dynamic>>.from(_pinnedFolders);
    setState(() =>
    _pinnedFolders =
        _pinnedFolders.where((p) => p['pinId'] != pinId).toList());
    try {
      await _repo.unpinFolder(pinId);
    } on AppException catch (e) {
      setState(() => _pinnedFolders = backup);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!))));
      }
    }
  }

  void _toggleFolderSelection(String id) {
    if (_folders.any((f) => f.id == id && f.isSync)) return;
    setState(() {
      if (_selectedFolders.contains(id)) {
        _selectedFolders.remove(id);
      } else {
        _selectedFolders.add(id);
      }
    });
  }

  void _toggleFileSelection(String id) {
    setState(() {
      if (_selectedFiles.contains(id)) {
        _selectedFiles.remove(id);
      } else {
        _selectedFiles.add(id);
      }
    });
  }

  String? get _currentFolderId =>
      _breadcrumb.isEmpty ? null : _breadcrumb.last.id;

  List<FileModel> get _displayFiles {
    final source =
    _showFavourites ? FavouritesProvider.instance.favouriteFiles : _files;
    final syncedSource = source
        .map((f) => f.copyWith(
      isFavourite: FavouritesProvider.instance.isFavourite(f.id),
    ))
        .toList();
    if (_activeFilter == _FilterType.all) return syncedSource;
    return syncedSource
        .where((f) => _matchesFilter(f, _activeFilter))
        .toList();
  }

  List<FolderModel> get _displayFolders => _showFavourites ? [] : _folders;

  bool _matchesFilter(FileModel f, _FilterType filter) {
    switch (filter) {
      case _FilterType.images:
        return MediaTypeHelper.isImage(f.mimeType);
      case _FilterType.videos:
        return MediaTypeHelper.isVideo(f.mimeType);
      case _FilterType.all:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    FavouritesProvider.instance.loadFavourites();
    _loadContent();
    _loadAuthToken();
    _scrollController.addListener(_onScroll);
    _shareBloc = ShareBloc(
      ShareRepositoryImpl(
        ShareRemoteDataSourceImpl(DioClient.instance),
      ),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && !_loadMoreFailed && _hasNextPage && !_showFavourites) _loadMoreContent();
    }
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _scrollController.dispose();
    _shareBloc.close();
    for (final n in _downloadNotifiers.values) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAuthToken() async {
    final token = await SecureStorage.getAccessToken();
    if (mounted) setState(() => _authToken = token);
  }



  bool _isOpeningFile = false;

  Future<void> _openFileViewer(FileModel file) async {
    if (_isOpeningFile || !isCurrentPage(context)) return;
    _isOpeningFile = true;
    try {
    final mime = file.mimeType.toLowerCase();

    if (MediaTypeHelper.isImage(mime) || MediaTypeHelper.isVideo(mime)) {
      final allMediaFiles = _displayFiles
          .where((f) =>
              MediaTypeHelper.isImage(f.mimeType) ||
              MediaTypeHelper.isVideo(f.mimeType))
          .toList();

      final idx = allMediaFiles.indexWhere((f) => f.id == file.id);

      if (!mounted) return;

      await pushPageOnce(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoViewerPage(
            files: allMediaFiles
                .map((f) => (
                  url: f.thumbnailPath ?? '',
                  name: f.name,
                  fileId: f.id,
                  mimeType: f.mimeType,
                ))
                .toList(),
            initialIndex: idx < 0 ? 0 : idx,
            authToken: _authToken,
            onNeedFullUrl: (fileId) => _repo.getPreviewUrl(fileId),
          ),
        ),
      );
    }
    } finally {
      if (mounted) setState(() => _isOpeningFile = false);
    }
  }

  bool _ownsContentRequest(int revision, String? folderId) =>
      mounted && revision == _contentRevision &&
      folderId == _currentFolderId && !_showFavourites;

  List<FolderModel> _markSyncFolders(Iterable<FolderModel> folders) {
    final marked = folders.map((folder) =>
      !folder.isSync && (folder.name == '📱 Sync' || folder.name == 'Sync')
        ? folder.copyWith(isSync: true) : folder).toList();
    return [...marked.where((f) => f.isSync), ...marked.where((f) => !f.isSync)];
  }

  void _invalidateContentRequests() {
    _contentRevision++;
    _reloadAfterLoad = false;
    _isLoading = false;
    _isLoadingMore = false;
    _loadMoreFailed = false;
    _loadingFolderId = null;
    _staggerTimer?.cancel();
  }

  Future<void> _loadContent() async {
    if (!mounted) return;
    if (_showFavourites) {
      // A mutation invalidates the saved folder snapshot, not the favourites view.
      _savedFiles = null;
      return;
    }
    final folderId = _currentFolderId;
    if (_isLoading && _loadingFolderId == folderId) {
      _reloadAfterLoad = true;
      return;
    }
    final revision = ++_contentRevision;
    _loadingFolderId = folderId;
    _reloadAfterLoad = false;
    _staggerTimer?.cancel();
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
      _error = null;
      _currentPage = 1;
      _hasNextPage = false;
    });
    try {
      final result = await _repo.getContent(parentId: folderId, page: 1);
      if (!_ownsContentRequest(revision, folderId)) return;
      List<Map<String, dynamic>> pinned = [];
      try {
        pinned = await _repo.getPinnedFolders();
      } catch (e) {
        if (kDebugMode) debugPrint('[FilesPage] getPinnedFolders failed: $e');
      }
      if (!_ownsContentRequest(revision, folderId)) return;
      final loadedFiles = result['files'] as List<FileModel>;
      setState(() {
        _folders = _markSyncFolders(result['folders'] as List<FolderModel>);
        _files = _isSyncFolder ? _sortByCaptureDate(loadedFiles) : loadedFiles;
        _recomputeDateOrder();
        _hasNextPage = result['hasNext'] as bool;
        _pinnedFolders = pinned;
        _totalFilesCount = result['totalCount'] as int? ?? _files.length;
        _staggerActive = true;
      });
      _staggerTimer = Timer(const Duration(milliseconds: 600), () {
        if (_ownsContentRequest(revision, folderId)) {
          setState(() => _staggerActive = false);
        }
      });
      _precacheThumbnails();
    } catch (e) {
      if (!_ownsContentRequest(revision, folderId)) return;
      setState(() => _error = e);
    } finally {
      if (_ownsContentRequest(revision, folderId)) {
        setState(() => _isLoading = false);
        if (_reloadAfterLoad) {
          _reloadAfterLoad = false;
          unawaited(_loadContent());
        }
      }
    }
  }

  Future<void> _loadMoreContent() async {
    if (!mounted || _isLoading || _isLoadingMore || !_hasNextPage || _showFavourites) return;
    final revision = _contentRevision;
    final folderId = _currentFolderId;
    final nextPage = _currentPage + 1;
    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });
    try {
      final result = await _repo.getContent(parentId: folderId, page: nextPage);
      if (!_ownsContentRequest(revision, folderId)) return;
      final fileIds = _files.map((f) => f.id).toSet();
      final folderIds = _folders.map((f) => f.id).toSet();
      final newFiles = (result['files'] as List<FileModel>)
          .where((f) => fileIds.add(f.id)).toList();
      final newFolders = (result['folders'] as List<FolderModel>)
          .where((f) => folderIds.add(f.id));
      setState(() {
        _files.addAll(newFiles);
        _folders = _markSyncFolders([..._folders, ...newFolders]);
        if (_isSyncFolder) _files = _sortByCaptureDate(_files);
        _recomputeDateOrder();
        _currentPage = nextPage;
        _hasNextPage = result['hasNext'] as bool;
        _totalFilesCount = result['totalCount'] as int? ?? _totalFilesCount;
      });
    } catch (e) {
      if (!mounted) return;
      if (!_ownsContentRequest(revision, folderId)) return;
      setState(() => _loadMoreFailed = true);
      if (e is AppException && e.statusCode == 404) {
        setState(() => _hasNextPage = false);
      } else if (isCurrentPage(context)) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ErrorLocalizer.forException(e, t)),
          action: SnackBarAction(label: t.retry, onPressed: () {
            if (_ownsContentRequest(revision, folderId)) _loadMoreContent();
          }),
        ));
      }
    } finally {
      if (_ownsContentRequest(revision, folderId)) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  // Warms the image cache for the first screenful so thumbnails are
  // already decoded by the time the user scrolls to them.
  void _precacheThumbnails() {
    for (final f in _files.take(8)) {
      final thumb = f.thumbnailPath;
      if (thumb == null || thumb.isEmpty) continue;
      precacheImage(
        CachedNetworkImageProvider(
          thumb,
          // Must match MediaThumbnail's key (file.id, null when empty) so the
          // precached entry is the one the grid/list actually reads back.
          cacheKey: f.id.isNotEmpty ? f.id : null,
          cacheManager: ThumbnailCacheManager.instance,
        ),
        context,
      );
    }
  }

  void reloadContent() => _loadContent();

  // Same reset performed by tapping "Home" in the breadcrumb (see
  // _buildBreadcrumb) — exposed here so the bottom-nav "Files" tab can pop
  // back to root when tapped while already deep inside nested folders.
  void resetToRoot() {
    final needsReload = _showFavourites || _breadcrumb.isNotEmpty;
    setState(() {
      if (_showFavourites) {
        _exitFavourites(restore: false);
      } else {
        _breadcrumb.clear();
        _folderPage = 0;
        _activeFilter = _FilterType.all;
      }
    });
    if (needsReload) {
      widget.onFolderChanged?.call(null);
      _loadContent();
    }
  }

  bool handleBackNavigation() {
    if (_isSelectionMode) {
      setState(() { _selectedFiles.clear(); _selectedFolders.clear(); });
      return true;
    }
    if (_showFavourites) {
      bool needsReload = false;
      setState(() {
        needsReload = _exitFavourites(restore: true);
      });
      if (needsReload) _loadContent();
      return true;
    }
    if (_breadcrumb.isNotEmpty) {
      setState(() {
        _breadcrumb.removeLast();
        _folderPage = 0;
      });
      widget.onFolderChanged
          ?.call(_breadcrumb.isEmpty ? null : _breadcrumb.last.id);
      _loadContent();
      return true;
    }
    return false;
  }

  void toggleFavourites() {
    if (_showFavourites) return;
    setState(_enterFavourites);
  }

  Future<void> _openUploadPage() async {
    await runNavigationOnce<void>(context, () async {
      final currentFolder = _currentFolderId;
      await Navigator.push<void>(context, slideUpRoute(
        UploadPage(parentId: currentFolder, onUploadComplete: () async {
          await Future.delayed(const Duration(seconds: 2));
          _loadContent();
        }), settings: const RouteSettings(name: 'upload'),
      ));
      if (mounted) _loadContent();
    });
  }

  Future<void> _pickAndUploadFiles() async {
    await runNavigationOnce<void>(context, () async {
      final currentFolder = _currentFolderId;
      final selectedFiles = await ImagePicker().pickMultipleMedia();
      if (!mounted || !isCurrentPage(context) || selectedFiles.isEmpty) return;
      final files = <PlatformFile>[];
      for (final xFile in selectedFiles) {
        files.add(PlatformFile(name: xFile.name,
          size: await File(xFile.path).length(), path: xFile.path));
      }
      if (!mounted || !isCurrentPage(context) || files.isEmpty) return;
      await Navigator.push<void>(context, slideUpRoute(
        UploadPage(parentId: currentFolder, initialFiles: files,
          onUploadComplete: () async {
            await Future.delayed(const Duration(seconds: 2));
            _loadContent();
          }), settings: const RouteSettings(name: 'upload'),
      ));
      if (mounted) _loadContent();
    });
  }

  void _openFolder(FolderModel folder) {
    // Pinned folders (e.g. Sync) are reachable from any depth, not just
    // root — tapping the one we're already inside (or one already on the
    // stack, via a pin shortcut) must not re-append it as a new segment.
    final existingIndex = _breadcrumb.indexWhere((b) => b.id == folder.id);
    if (existingIndex != -1 && existingIndex == _breadcrumb.length - 1) {
      return; // already viewing this folder
    }

    setState(() {
      if (existingIndex != -1) {
        _breadcrumb.removeRange(existingIndex + 1, _breadcrumb.length);
      } else {
        _breadcrumb.add((id: folder.id, isSync: folder.isSync, name: folder.name));
      }
      _showFavourites = false;
      _activeFilter = _FilterType.all;
      _folderPage = 0;
    });
    widget.onFolderChanged?.call(folder.id);
    _loadContent();
  }


  void _navigateTo(int index) {
    if (index >= _breadcrumb.length) return;
    if (index < 0) {
      if (_breadcrumb.isEmpty) return;
      setState(() {
        _breadcrumb.clear();
        _folderPage = 0;
      });
      widget.onFolderChanged?.call(null);
    } else {
      if (index == _breadcrumb.length - 1) return;
      setState(() {
        _breadcrumb.removeRange(index + 1, _breadcrumb.length);
        _folderPage = 0;
      });
      widget.onFolderChanged?.call(_breadcrumb[index].id);
    }
    _loadContent();
  }

  /// Snapshots the current folder view before switching to favourites, so
  /// leaving favourites can restore it from memory (browser-back semantics).
  void _enterFavourites() {
    final canSave = !_isLoading;
    _savedBreadcrumb
      ..clear()
      ..addAll(_breadcrumb);
    _savedFiles = canSave ? List.of(_files) : null;
    _savedFolders = List.of(_folders);
    _savedPage = _currentPage;
    _savedHasNextPage = _hasNextPage;
    _savedTotalFilesCount = _totalFilesCount;
    _invalidateContentRequests();
    _error = null;
    _breadcrumb.clear();
    _showFavourites = true;
    _activeFilter = _FilterType.all;
  }

  /// Leaves favourites. If [restore] is true and a snapshot exists, pops
  /// back to the pre-favourites folder view without refetching. Otherwise
  /// (explicit "home" navigation, or no snapshot to restore) resets to root
  /// and returns true so the caller knows it must call [_loadContent].
  bool _exitFavourites({required bool restore}) {
    final canRestore = restore && _savedFiles != null;
    _invalidateContentRequests();
    _error = null;
    _breadcrumb.clear();
    if (restore) _breadcrumb.addAll(_savedBreadcrumb);
    if (canRestore) {
      _files = _savedFiles!;
      _folders = _savedFolders!;
      _currentPage = _savedPage!;
      _hasNextPage = _savedHasNextPage!;
      _totalFilesCount = _savedTotalFilesCount ?? _files.length;
    } else {
      _folderPage = 0;
    }
    _savedBreadcrumb.clear();
    _savedFiles = null;
    _savedFolders = null;
    _savedPage = null;
    _savedHasNextPage = null;
    _savedTotalFilesCount = null;
    _showFavourites = false;
    _activeFilter = _FilterType.all;
    return !canRestore;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final t = AppLocalizations.of(ctx)!;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.filter,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterChip(
                      label: t.all,
                      icon: Icons.apps_rounded,
                      isActive: _activeFilter == _FilterType.all,
                      onTap: () {
                        setState(() => _activeFilter = _FilterType.all);
                        Navigator.pop(ctx);
                      },
                    ),
                    _FilterChip(
                      label: t.photos,
                      icon: Icons.image_rounded,
                      isActive: _activeFilter == _FilterType.images,
                      onTap: () {
                        setState(() => _activeFilter = _FilterType.images);
                        Navigator.pop(ctx);
                      },
                    ),
                    _FilterChip(
                      label: t.videos,
                      icon: Icons.videocam_rounded,
                      isActive: _activeFilter == _FilterType.videos,
                      onTap: () {
                        setState(() => _activeFilter = _FilterType.videos);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final t = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.create_new_folder,
                          color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(t.newFolder,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: t.folderName,
                    hintStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                    prefixIcon:
                    const Icon(Icons.folder, color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(t.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;
                          Navigator.pop(ctx);
                          safeAction(() async {
                            try {
                              final newFolder = await _repo.createFolder(
                                name: name,
                                parentId: _currentFolderId,
                              );
                              _openFolder(newFolder);
                            } on AppException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(t.create,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minVerticalPadding: 0,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color == Colors.red ? Colors.red : onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showInfoDialog({
    required String id,
    required String type,
    required String name,
    required String previewUrl,
    required Color iconColor,
    required IconData icon,
    String mimeType = '',
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => InfoBottomSheet(
        id: id,
        type: type,
        name: name,
        previewUrl: previewUrl,
        iconColor: iconColor,
        icon: icon,
        mimeType: mimeType,
        fetchInfo: () => _profileRepo.getContentInfo(id: id, type: type),
        fmt: _fmt,
      ),
    );
  }

  void _showFolderMenu(FolderModel folder) {
    final t = AppLocalizations.of(context)!;
    final isSyncF = folder.isSync;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(top: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_rounded,
                          color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          folder.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildBottomSheetItem(
                  icon: Icons.folder_open,
                  color: Colors.blue,
                  title: t.open,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openFolder(folder);
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.info_outline_rounded,
                  color: Colors.blueGrey,
                  title: t.details,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInfoDialog(
                      id: folder.id,
                      type: 'folder',
                      name: folder.name,
                      previewUrl: '',
                      iconColor: Colors.amber,
                      icon: Icons.folder_rounded,
                    );
                  },
                ),
                if (!isSyncF) ...[
                  _buildBottomSheetItem(
                    icon: Icons.share_rounded,
                    color: Colors.green,
                    title: t.share,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showShareDialog(fileIds: [], folderIds: [folder.id]);
                    },
                  ),
                  _buildBottomSheetItem(
                    icon: Icons.drive_file_rename_outline,
                    color: Colors.orange,
                    title: t.rename,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showRenameDialog(
                        currentName: folder.name,
                        onRename: (newName) => safeAction(() async {
                          try {
                            await _repo.renameItem(
                                type: 'folder', id: folder.id, name: newName);
                            if (!mounted) return;
                            setState(() {
                              final idx = _folders
                                  .indexWhere((f) => f.id == folder.id);
                              if (idx != -1) {
                                _folders[idx] =
                                    _folders[idx].copyWith(name: newName);
                              }
                            });
                          } on AppException catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }),
                      );
                    },
                  ),
                  _buildBottomSheetItem(
                    icon: Icons.arrow_forward_rounded,
                    color: Colors.blue,
                    title: t.move,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final result = await pushPageOnce<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MoveDestinationScreen(
                            selectedFiles: const [],
                            selectedFolders: [folder.id],
                            currentFolderId: _currentFolderId,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadContent();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.successfullyMoved),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                  _buildBottomSheetItem(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    title: t.delete,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showDeleteConfirmDialog(
                        itemName: folder.name,
                        onConfirm: () => safeAction(() async {
                          final idx = _folders.indexOf(folder);
                          if (idx == -1) return;
                          setState(() => _folders.removeAt(idx));
                          try {
                            await _repo.deleteItem(
                                type: 'folder', id: folder.id);
                          } on AppException catch (e) {
                            if (!mounted) return;
                            setState(() => _folders.insert(idx, folder));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }),
                      );
                    },
                  ),
                  Builder(
                    builder: (_) {
                      final pinId = _getPinId(folder.id);
                      final isPinned = pinId != null;
                      return _buildBottomSheetItem(
                        icon: Icons.push_pin_outlined,
                        color: isPinned ? Colors.orange : Colors.blueGrey,
                        title: isPinned ? t.unpinLabel : t.pinLabel,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (isPinned) {
                            _unpinFolder(pinId);
                          } else {
                            _pinFolder(folder);
                          }
                        },
                      );
                    },
                  ),
                ],
                if (isSyncF)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.syncFolderReadOnly,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _icon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.startsWith('video/')) return Icons.videocam_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _color(String mime) {
    if (mime.startsWith('image/')) return const Color(0xFF34A853);
    if (mime.startsWith('video/')) return const Color(0xFFEA4335);
    return const Color(0xFF1A73E8);
  }

  void _showFileMenu(FileModel file) {
    final t = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(top: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _color(file.mimeType).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_icon(file.mimeType),
                            color: _color(file.mimeType), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              file.formattedSize,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildBottomSheetItem(
                  icon: file.isFavourite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: file.isFavourite ? Colors.amber : Colors.grey,
                  title: file.isFavourite
                      ? t.removeFromFavourites
                      : t.addToFavourites,
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleFavourite(file);
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.download_rounded,
                  color: Colors.blue,
                  title: t.download,
                  onTap: () {
                    Navigator.pop(ctx);
                    _startDownload(file);
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.remove_red_eye_outlined,
                  color: Colors.purple,
                  title: t.preview,
                  onTap: () {
                    Navigator.pop(ctx);
                    _openFileViewer(file);
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.info_outline_rounded,
                  color: Colors.blueGrey,
                  title: t.details,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInfoDialog(
                      id: file.id,
                      type: 'file',
                      name: file.name,
                      previewUrl: file.thumbnailPath ?? '',
                      iconColor: _color(file.mimeType),
                      icon: _icon(file.mimeType),
                      mimeType: file.mimeType,
                    );
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.drive_file_rename_outline,
                  color: Colors.orange,
                  title: t.rename,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameDialog(
                      currentName: file.name,
                      onRename: (newName) => safeAction(() async {
                        try {
                          await _repo.renameItem(
                              type: 'file', id: file.id, name: newName);
                          if (!mounted) return;
                          setState(() {
                            final idx =
                                _files.indexWhere((f) => f.id == file.id);
                            if (idx != -1) {
                              _files[idx] = _files[idx].copyWith(name: newName);
                            }
                          });
                          FavouritesProvider.instance
                              .renameFile(file.id, newName);
                        } on AppException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)),
                                backgroundColor: Colors.red),
                          );
                        }
                      }),
                    );
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.arrow_forward_rounded,
                  color: Colors.blue,
                  title: t.move,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final result = await pushPageOnce<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MoveDestinationScreen(
                          selectedFiles: [file.id],
                          selectedFolders: const [],
                          currentFolderId: _currentFolderId,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadContent();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.successfullyMoved),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.share_rounded,
                  color: Colors.green,
                  title: t.share,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showShareDialog(fileIds: [file.id], folderIds: []);
                  },
                ),
                _buildBottomSheetItem(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  title: t.delete,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirmDialog(
                      itemName: file.name,
                      onConfirm: () => safeAction(() async {
                        final idx = _files.indexOf(file);
                        if (idx == -1) return;
                        setState(() {
                          _files.removeAt(idx);
                          _totalFilesCount =
                              (_totalFilesCount - 1).clamp(0, 1 << 31);
                        });
                        try {
                          await _repo.deleteItem(type: 'file', id: file.id);
                        } on AppException catch (e) {
                          if (!mounted) return;
                          setState(() {
                            _files.insert(idx, file);
                            _totalFilesCount++;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)),
                                backgroundColor: Colors.red),
                          );
                        }
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameDialog({
    required String currentName,
    required Future<void> Function(String) onRename,
  }) {
    final controller = TextEditingController(text: currentName);
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.surface,
        title: Text(t.rename, style: TextStyle(color: cs.onSurface)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: t.newNameHint,
            hintStyle:
            TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == currentName) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              onRename(newName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
            Text(t.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog({
    required String itemName,
    required Future<void> Function() onConfirm,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.surface,
        title: Text(t.deleteConfirm, style: TextStyle(color: cs.onSurface)),
        content: Text(
          t.deleteConfirmMessage(itemName),
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
            Text(t.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavouritesProvider.instance,
      builder: (context, _) {
        return PopScope(
          canPop: !widget.handleSystemBack ||
              (_breadcrumb.isEmpty && !_showFavourites && !_isSelectionMode),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop || !widget.handleSystemBack) return;
            handleBackNavigation();
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    HapticFeedback.lightImpact();
                    await _loadContent();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(child: _buildBreadcrumb()),
                      if (_isLoading)
                        const SliverFillRemaining(
                          child: FilesListShimmer(),
                        )
                      else if (_error != null)
                        SliverFillRemaining(child: _buildError())
                      else if (FavouritesProvider.instance.isLoading &&
                            _showFavourites)
                          const SliverFillRemaining(
                            child:
                            Center(child: CircularProgressIndicator()),
                          )
                        else if (_showFavourites &&
                              FavouritesProvider
                                  .instance.favouriteFiles.isEmpty)
                            SliverFillRemaining(
                                child: _buildEmptyFavourites())
                          else if (!_showFavourites &&
                                _displayFolders.isEmpty &&
                                _displayFiles.isEmpty)
                              SliverFillRemaining(child: _buildEmpty())
                            else
                              SliverPadding(
                                padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 16,
                                    bottom: 160),
                                sliver: SliverMainAxisGroup(
                                  slivers: _buildContentSlivers(),
                                ),
                              ),
                    ],
                  ),
                ),
                _buildBottomActionBar(),
              ],
            ),
            floatingActionButton: _buildFABs(),
          ),
        );
      },
    );
  }

  Widget _buildFABs() {
    if (_isSelectionMode || _isSyncFolder) return const SizedBox.shrink();
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        heroTag: 'upload_fab',
        onPressed: _openUploadPage,
        backgroundColor: Colors.blue,
        elevation: 4,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.cloud_upload_rounded,
            color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final t = AppLocalizations.of(context)!;
    final allSelected = _selectedFiles.length == _files.length &&
        _selectedFolders.length == _folders.length &&
        (_files.isNotEmpty || _folders.isNotEmpty);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: _isSelectionMode ? 16 : -160,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.80),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.only(
                left: 8, right: 8, top: 10, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close, color: textColor, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _selectedFiles.clear();
                            _selectedFolders.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.selectedCount(_selectedFiles.length +
                            _selectedFolders.length),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (allSelected) {
                              _selectedFiles.clear();
                              _selectedFolders.clear();
                            } else {
                              _selectedFiles
                                  .addAll(_files.map((f) => f.id));
                              _selectedFolders
                                  .addAll(_folders
                                      .where((f) => !f.isSync)
                                      .map((f) => f.id));
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          allSelected ? t.deselectAll : t.selectAll,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.10),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionItem(
                      icon: Icons.star_rounded,
                      label: _selectedFavouritesAllMarked()
                          ? t.removeFromFavourites
                          : t.addToFavourites,
                      iconColor: textColor,
                      textColor: textColor,
                      onTap: _bulkToggleFavourites,
                    ),
                    _buildActionItem(
                      icon: Icons.download_rounded,
                      label: t.download,
                      iconColor: textColor,
                      textColor: textColor,
                      onTap: () {
                        for (var id in _selectedFiles) {
                          final f =
                          _files.firstWhere((e) => e.id == id);
                          _startDownload(f);
                        }
                        setState(() {
                          _selectedFiles.clear();
                          _selectedFolders.clear();
                        });
                      },
                    ),
                    _buildActionItem(
                      icon: Icons.share_rounded,
                      label: t.share,
                      iconColor: Colors.green,
                      textColor: textColor,
                      onTap: () {
                        final fileIds = _selectedFiles.toList();
                        final folderIds = _selectedFolders
                            .where((id) => !_folders.any((f) => f.id == id && f.isSync))
                            .toList();
                        setState(() {
                          _selectedFiles.clear();
                          _selectedFolders.clear();
                        });
                        _showShareDialog(
                            fileIds: fileIds, folderIds: folderIds);
                      },
                    ),
                    _buildActionItem(
                      icon: Icons.drive_file_move_rounded,
                      label: t.move,
                      iconColor: textColor,
                      textColor: textColor,
                      onTap: () async {
                        final result = await pushPageOnce<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MoveDestinationScreen(
                              selectedFiles: _selectedFiles.toList(),
                              selectedFolders: _selectedFolders
                                  .where((id) => !_folders.any((f) => f.id == id && f.isSync))
                                  .toList(),
                              currentFolderId: _currentFolderId,
                            ),
                          ),
                        );
                        if (result == true) {
                          setState(() {
                            _selectedFiles.clear();
                            _selectedFolders.clear();
                          });
                          _loadContent();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.successfullyMoved),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                    _buildActionItem(
                      icon: Icons.delete_rounded,
                      label: t.delete,
                      iconColor: Colors.red.shade400,
                      textColor: textColor,
                      onTap: () {
                        _showDeleteConfirmDialog(
                          itemName: t.deleteItems(_selectedFiles.length +
                              _selectedFolders.length),
                          onConfirm: () => safeAction(() async {
                            final removedFileIds = _selectedFiles.toList();
                            final removedFolderIds = _selectedFolders
                                .where((id) => !_folders.any((f) => f.id == id && f.isSync))
                                .toList();
                            final filesSnapshot = List<FileModel>.from(_files);
                            final foldersSnapshot =
                                List<FolderModel>.from(_folders);
                            setState(() {
                              _files.removeWhere(
                                  (f) => removedFileIds.contains(f.id));
                              _folders.removeWhere(
                                  (f) => removedFolderIds.contains(f.id));
                              _totalFilesCount =
                                  (_totalFilesCount - removedFileIds.length)
                                      .clamp(0, 1 << 31);
                              _selectedFiles.clear();
                              _selectedFolders.clear();
                            });
                            try {
                              await HomeRepository().deleteItems(
                                files: removedFileIds,
                                folders: removedFolderIds,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                _files = filesSnapshot;
                                _folders = foldersSnapshot;
                                _totalFilesCount += removedFileIds.length;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: cs.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: Text(
          t.files,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        background: Container(color: cs.surface),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showFavourites
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: _showFavourites ? Colors.amber : cs.onSurface,
          ),
          onPressed: () {
            bool needsReload = false;
            setState(() {
              if (_showFavourites) {
                needsReload = _exitFavourites(restore: true);
              } else {
                _enterFavourites();
              }
            });
            if (needsReload) _loadContent();
          },
          tooltip: t.favourites,
        ),
        IconButton(
          icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view,
              color: cs.onSurface),
          onPressed: () => setState(() => _isGrid = !_isGrid),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: cs.onSurface),
          onPressed: _loadContent,
          tooltip: t.refresh,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBreadcrumb() {
    final t = AppLocalizations.of(context)!;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final needsReload = _showFavourites || _breadcrumb.isNotEmpty;
                setState(() {
                  if (_showFavourites) {
                    _exitFavourites(restore: false);
                  } else {
                    _breadcrumb.clear();
                    _folderPage = 0;
                    _activeFilter = _FilterType.all;
                  }
                });
                if (needsReload) {
                  widget.onFolderChanged?.call(null);
                  _loadContent();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _breadcrumb.isEmpty && !_showFavourites
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.home_rounded,
                        size: 16,
                        color: _breadcrumb.isEmpty && !_showFavourites
                            ? Colors.blue
                            : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      t.home_breadcrumb,
                      style: TextStyle(
                        color: _breadcrumb.isEmpty && !_showFavourites
                            ? Colors.blue
                            : Colors.grey,
                        fontWeight:
                        _breadcrumb.isEmpty && !_showFavourites
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showFavourites) ...[
              const Icon(Icons.chevron_right,
                  size: 16, color: Colors.grey),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(t.favourites_breadcrumb,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            ],
            for (int i = 0; i < _breadcrumb.length; i++) ...[
              const Icon(Icons.chevron_right,
                  size: 16, color: Colors.grey),
              GestureDetector(
                onTap: () => _navigateTo(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == _breadcrumb.length - 1
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _breadcrumb[i].name,
                    style: TextStyle(
                      color: i == _breadcrumb.length - 1
                          ? Colors.blue
                          : Colors.grey,
                      fontWeight: i == _breadcrumb.length - 1
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _removeDownloadNotifier(String fileId) {
    _downloadNotifiers.remove(fileId)?.dispose();
  }

  Future<void> _startDownload(FileModel file) async {
    final t = AppLocalizations.of(context)!;
    if (_downloadNotifiers.containsKey(file.id)) return;
    final notifier =
        ValueNotifier<({double progress, int received})>((progress: 0.0, received: 0));
    setState(() => _downloadNotifiers[file.id] = notifier);
    try {
      await _downloadRepo.downloadFile(
        fileId: file.id,
        fileName: file.name,
        mimeType: file.mimeType,
        onProgress: (received, total) {
          if (!mounted) return;
          // Direct notifier mutation — only the listening _FileTile rebuilds.
          notifier.value = (
            progress: total > 0 ? received / total : notifier.value.progress,
            received: received,
          );
        },
      );
      if (!mounted) return;
      setState(() => _removeDownloadNotifier(file.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.fileSaved(file.name)),
          backgroundColor: Colors.green,
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _removeDownloadNotifier(file.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorLocalizer.forException(e, AppLocalizations.of(context)!)), backgroundColor: Colors.red),
      );
    }
  }

  void _showShareDialog({
    required List<String> fileIds,
    required List<String> folderIds,
  }) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: _shareBloc,
        child: ShareDialog(
          initialFileIds: fileIds,
          initialFolderIds: folderIds,
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers() {
    final t = AppLocalizations.of(context)!;
    // Computed once per rebuild — the getter copies the whole list on each call
    final displayFiles = _displayFiles;
    // ── Header & folders section (non-virtualized, small content) ──
    final headerChildren = <Widget>[];

    // ── Sync folder info banner ── (not relevant while showing favourites)
    if (_isSyncFolder && !_showFavourites) {
      headerChildren.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Colors.blue.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.syncFolderReadOnly,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    if (_showFavourites) {
      headerChildren.add(Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text(
            t.favourites_breadcrumb,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${displayFiles.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _activeFilter != _FilterType.all
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded,
                      size: 14,
                      color: _activeFilter != _FilterType.all
                          ? Colors.blue
                          : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _activeFilter == _FilterType.images
                        ? t.photos
                        : _activeFilter == _FilterType.videos
                        ? t.videos
                        : t.filter,
                    style: TextStyle(
                      fontSize: 12,
                      color: _activeFilter != _FilterType.all
                          ? Colors.blue
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ));
      headerChildren.add(const SizedBox(height: 12));
    }

    if (_displayFolders.isNotEmpty) {
      headerChildren.add(_buildSectionHeader(
          t.folders, Icons.folder_rounded, _displayFolders.length,
          trailing: _isSyncFolder
              ? null
              : IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined,
                      color: Colors.blue, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _showCreateFolderDialog,
                )));
      if (!_showFavourites && _pinnedFolders.isNotEmpty) {
        headerChildren.add(const SizedBox(height: 8));
        headerChildren.add(_buildPinnedFolders());
      }
      headerChildren.add(const SizedBox(height: 8));
      headerChildren.add(_isGrid ? _buildFoldersGrid() : _buildFoldersList());
      headerChildren.add(const SizedBox(height: 20));
    } else if (!_showFavourites) {
      headerChildren.add(_buildSectionHeader(
          t.folders, Icons.folder_rounded, 0,
          trailing: _isSyncFolder
              ? null
              : IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined,
                      color: Colors.blue, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _showCreateFolderDialog,
                )));
      if (_pinnedFolders.isNotEmpty) {
        headerChildren.add(const SizedBox(height: 8));
        headerChildren.add(_buildPinnedFolders());
      }
      headerChildren.add(const SizedBox(height: 8));
    }

    if (displayFiles.isNotEmpty && !_showFavourites) {
      headerChildren.add(_buildSectionHeader(
          t.files, Icons.insert_drive_file, _totalFilesCount));
      headerChildren.add(const SizedBox(height: 8));
    }

    final slivers = <Widget>[];

    // ── 1. Header sliver (folders, section headers) ──
    if (headerChildren.isNotEmpty) {
      slivers.add(SliverList(
        delegate: SliverChildListDelegate(headerChildren),
      ));
    }

    // ── 2. Files sliver (virtualized, grouped by date) ──
    if (displayFiles.isNotEmpty) {
      if (_isGrid && !_showFavourites) {
        final grouped = _groupFilesByDate(displayFiles);
        for (final entry in grouped) {
          slivers.add(SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ));
          slivers.add(SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final f = entry.value[i];
                return StaggeredListItem(
                  index: i,
                  animate: _staggerActive,
                  child: RepaintBoundary(
                    child: _FileGridCard(
                      key: ValueKey(f.id),
                      file: f,
                      isSelected: _selectedFiles.contains(f.id),
                      isSelectionMode: _isSelectionMode,
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleFileSelection(f.id);
                        } else {
                          _openFileViewer(f);
                        }
                      },
                      onSelectTap: () => _toggleFileSelection(f.id),
                      onMenuTap: () => _showFileMenu(f),
                      onFavouriteTap: () => _toggleFavourite(f),
                    ),
                  ),
                );
              },
              childCount: entry.value.length,
              addAutomaticKeepAlives: false,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1.0,
            ),
          ));
        }
      } else {
        slivers.add(_buildFilesListSliver());
      }
    }

    // ── 3. Load-more trigger + indicator ──
    // Date-grouped grid has no index-based trigger (unlike list sliver),
    // so a trailing sliver re-triggers loading while it stays in viewport.
    if (_isGrid && !_showFavourites && displayFiles.isNotEmpty && _hasNextPage && !_loadMoreFailed) {
      slivers.add(SliverToBoxAdapter(
        child: Builder(builder: (ctx) {
          if (!_isLoadingMore && !_loadMoreFailed) {
            Future.microtask(() => _loadMoreContent());
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }),
      ));
    } else if (_isGrid && !_showFavourites && _isLoadingMore) {
      // List sliver already renders its own single trailing spinner —
      // this fallback only covers the grid layout, which has none.
      slivers.add(const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ));
    }

    return slivers;
  }

  Widget _buildPinnedFolders() {
    if (_pinnedFolders.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _pinnedFolders.length,
        itemBuilder: (context, index) {
          final pin = _pinnedFolders[index];
          final folder = pin['folder'] as FolderModel;
          final pinId = pin['pinId'] as String;
          return GestureDetector(
            onTap: () => _openFolder(folder),
            onLongPress: () {
              if (folder.isSync) return;
              if (!context.mounted) return;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: cs.surface,
                  title: Text(t.unpinFolder,
                      style: TextStyle(color: cs.onSurface)),
                  content: Text(folder.name,
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _unpinFolder(pinId);
                      },
                      child: Text(t.unpin,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(folder.isSync ? Icons.sync_rounded : Icons.push_pin,
                      size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Список-вид для sync-папок (обычная — сортировка не трогается,
  /// возвращается порядок с сервера как есть): порядок как в галерее
  /// телефона — по дате съёмки (или создания записи, если съёмки нет),
  /// новые сверху. Та же логика, что уже использует _groupFilesByDate
  /// для grid-режима.
  List<FileModel> _sortByCaptureDate(List<FileModel> files) {
    final sorted = [...files];
    sorted.sort((a, b) {
      final aDate = a.capturedAt ?? a.createdAt;
      final bDate = b.capturedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  /// Snapshot of `_files` sorted newest-first by capturedAt ?? createdAt
  /// (same comparator as _sortByCaptureDate / _groupFilesByDate). Used only
  /// by the FastScrollbar date bubble; never replaces `_files`.
  void _recomputeDateOrder() {
    _dateOrderedFiles = List<FileModel>.from(_files)
      ..sort((a, b) => (b.capturedAt ?? b.createdAt)
          .compareTo(a.capturedAt ?? a.createdAt));
  }

  List<MapEntry<String, List<FileModel>>> _groupFilesByDate(List<FileModel> files) {
    final Map<String, List<FileModel>> groups = {};
    for (final file in files) {
      final date = file.capturedAt ?? file.createdAt;
      final key = [
        date.year.toString().padLeft(4, '0'),
        date.month.toString().padLeft(2, '0'),
        date.day.toString().padLeft(2, '0'),
      ].join('-');
      groups.putIfAbsent(key, () => []).add(file);
    }
    final sorted = groups.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    for (final entry in sorted) {
      entry.value.sort((a, b) {
        final aDate = a.capturedAt ?? a.createdAt;
        final bDate = b.capturedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
    }
    return sorted;
  }

  Widget _buildFilesListSliver() {
    // Snapshot once — the _displayFiles getter copies the list on every
    // call, which is O(n²) when accessed per item in the delegate
    final files = _displayFiles;
    // Favourites has no pagination of its own — never show/trigger it here.
    final hasNextPage = _hasNextPage && !_showFavourites;
    final itemCount = files.length + (hasNextPage ? 1 : 0);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == files.length) {
            if (hasNextPage && !_isLoadingMore && !_loadMoreFailed) {
              Future.microtask(() => _loadMoreContent());
            }
            // Single pagination spinner — only while an actual fetch is in flight.
            if (!_isLoadingMore) return const SizedBox.shrink();
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final f = files[i];
          return StaggeredListItem(
            index: i,
            animate: _staggerActive,
            child: RepaintBoundary(
              child: _FileTile(
                key: ValueKey(f.id),
                file: f,
                isSelected: _selectedFiles.contains(f.id),
                isSelectionMode: _isSelectionMode,
                authToken: _authToken,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleFileSelection(f.id);
                  } else {
                    _openFileViewer(f);
                  }
                },
                onSelectTap: () => _toggleFileSelection(f.id),
                onMenuTap: () => _showFileMenu(f),
                downloadNotifier: _downloadNotifiers[f.id],
                onFavouriteTap: () => _toggleFavourite(f),
              ),
            ),
          );
        },
        childCount: itemCount,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count,
      {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _buildFoldersGrid() {
    final totalFolders = _displayFolders.length;
    final maxPage =
    totalFolders == 0 ? 0 : ((totalFolders - 1) / 4).floor();
    if (_folderPage > maxPage) _folderPage = maxPage;
    if (_folderPage < 0) _folderPage = 0;
    final start = _folderPage * 4;
    final end =
    (start + 4) > totalFolders ? totalFolders : start + 4;
    final pageFolders = _displayFolders.sublist(start, end);
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          addAutomaticKeepAlives: false,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: pageFolders.length,
          itemBuilder: (_, i) {
            final folder = pageFolders[i];
            return StaggeredListItem(
              index: i,
              animate: _staggerActive,
              child: _FolderCard(
                folder: folder,
                isSelected: _selectedFolders.contains(folder.id),
                isSelectionMode: _isSelectionMode,
                isSyncFolder: folder.isSync,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleFolderSelection(folder.id);
                  } else {
                    _openFolder(folder);
                  }
                },
                onSelectTap: () => _toggleFolderSelection(folder.id),
                onMenuTap: () => _showFolderMenu(folder),
              ),
            );
          },
        ),
        if (totalFolders > 4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildPaginationRow(
              page: _folderPage,
              isLastPage: (_folderPage + 1) * 4 >= totalFolders,
              onPageChanged: (p) =>
                  setState(() => _folderPage = p),
            ),
          ),
      ],
    );
  }

  Widget _buildFoldersList() {
    final totalFolders = _displayFolders.length;
    final maxPage =
    totalFolders == 0 ? 0 : ((totalFolders - 1) / 4).floor();
    if (_folderPage > maxPage) _folderPage = maxPage;
    if (_folderPage < 0) _folderPage = 0;
    final start = _folderPage * 4;
    final end =
    (start + 4) > totalFolders ? totalFolders : start + 4;
    final pageFolders = _displayFolders.sublist(start, end);
    return Column(
      children: [
        ...pageFolders.asMap().entries.map(
              (entry) => StaggeredListItem(
            index: entry.key,
            animate: _staggerActive,
            child: _FolderListTile(
              folder: entry.value,
              isSelected: _selectedFolders.contains(entry.value.id),
              isSelectionMode: _isSelectionMode,
              isSyncFolder: entry.value.isSync,
              onTap: () {
                if (_isSelectionMode) {
                  _toggleFolderSelection(entry.value.id);
                } else {
                  _openFolder(entry.value);
                }
              },
              onSelectTap: () => _toggleFolderSelection(entry.value.id),
              onMenuTap: () => _showFolderMenu(entry.value),
            ),
          ),
        ),
        if (totalFolders > 4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildPaginationRow(
              page: _folderPage,
              isLastPage: (_folderPage + 1) * 4 >= totalFolders,
              onPageChanged: (p) =>
                  setState(() => _folderPage = p),
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            ErrorLocalizer.forException(_error!, AppLocalizations.of(context)!),
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            label: Text(t.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child:
            const Icon(Icons.folder_open, size: 40, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            t.emptyFolder,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.emptyFolderSubtitle,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showCreateFolderDialog,
                    icon: const Icon(
                        Icons.create_new_folder_rounded,
                        color: Colors.blue),
                    label: Text(t.createFolder,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                          color: Colors.blue, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickAndUploadFiles,
                    icon: const Icon(Icons.cloud_upload_rounded,
                        color: Colors.white),
                    label: Text(t.uploadFiles,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFavourites() {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.star_border_rounded,
                size: 40, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          Text(
            t.noFavourites,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.noFavouritesSubtitle,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1A73E8)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Folder Grid Card ──────────────────────────────────────────────────────────
class _FolderCard extends StatelessWidget {
  final FolderModel folder;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isSyncFolder;
  final VoidCallback onTap;
  final VoidCallback onSelectTap;
  final VoidCallback onMenuTap;

  const _FolderCard({
    required this.folder,
    required this.isSelected,
    required this.isSelectionMode,
    this.isSyncFolder = false,
    required this.onTap,
    required this.onSelectTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final folderColor = isSyncFolder ? Colors.blue : Colors.amber;
    return RepaintBoundary(child: GestureDetector(
      onTap: isSelectionMode
          ? (isSyncFolder ? null : onSelectTap)
          : onTap,
      onLongPress: isSyncFolder ? null : onSelectTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:
          isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: folderColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.folder_rounded,
                          color: folderColor, size: 22),
                    ),
                    if (isSyncFolder)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sync_rounded,
                              color: Colors.white, size: 11),
                        ),
                      ),
                    if (isSelected && !isSyncFolder)
                      Positioned(
                        top: -6,
                        left: -6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border:
                            Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
                if (isSyncFolder)
                  const Icon(Icons.lock_outline_rounded,
                      color: Colors.grey, size: 18)
                else if (!isSelectionMode)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 22,
                      icon: const Icon(Icons.more_vert,
                          color: Colors.grey),
                      onPressed: onMenuTap,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              folder.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Folder List Tile ──────────────────────────────────────────────────────────
class _FolderListTile extends StatelessWidget {
  final FolderModel folder;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isSyncFolder;
  final VoidCallback onTap;
  final VoidCallback onSelectTap;
  final VoidCallback onMenuTap;

  const _FolderListTile({
    required this.folder,
    required this.isSelected,
    required this.isSelectionMode,
    this.isSyncFolder = false,
    required this.onTap,
    required this.onSelectTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final folderColor = isSyncFolder ? Colors.blue : Colors.amber;
    return RepaintBoundary(child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
              left: BorderSide(color: Colors.blue, width: 3))
              : null,
        ),
        child: ListTile(
          onTap: isSelectionMode
              ? (isSyncFolder ? null : onSelectTap)
              : onTap,
          onLongPress: isSyncFolder ? null : onSelectTap,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: isSelectionMode && !isSyncFolder
              ? InkWell(
            onTap: onSelectTap,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => onSelectTap(),
              shape: const CircleBorder(),
              activeColor: Colors.blue,
            ),
          )
              : Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: folderColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.folder_rounded,
                color: folderColor, size: 22),
          ),
          title: Text(
            folder.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: isSyncFolder
              ? const Icon(Icons.lock_outline_rounded,
                  color: Colors.grey, size: 18)
              : isSelectionMode
                  ? null
                  : IconButton(
              icon: const Icon(Icons.more_vert,
                  color: Colors.grey, size: 22),
              onPressed: onMenuTap,
            ),
        ),
      ),
    ));
  }
}

// ── File Tile ─────────────────────────────────────────────────────────────────
class _FileTile extends StatelessWidget {
  final FileModel file;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onMenuTap;
  // Ticks many times per second while downloading — kept as a standalone
  // notifier so progress updates rebuild only this tile, not the whole
  // FilesPageState (see _startDownload).
  final ValueNotifier<({double progress, int received})>? downloadNotifier;
  final VoidCallback? onFavouriteTap;
  final String? authToken;

  final VoidCallback? onTap;
  final VoidCallback? onSelectTap;

  const _FileTile({
    super.key,
    required this.file,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onMenuTap,
    this.downloadNotifier,
    this.onFavouriteTap,
    this.authToken,
    this.onTap,
    this.onSelectTap,
  });

  IconData _icon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.startsWith('video/')) return Icons.videocam_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _color(String mime) {
    if (mime.startsWith('image/')) return const Color(0xFF34A853);
    if (mime.startsWith('video/')) return const Color(0xFFEA4335);
    return const Color(0xFF1A73E8);
  }

  Widget _buildLeading(Color color) {
    final isMedia = MediaTypeHelper.isImage(file.mimeType) ||
        MediaTypeHelper.isVideo(file.mimeType);
    return MediaThumbnail(
      mimeType: file.mimeType,
      thumbnailPath: file.thumbnailPath,
      cacheKey: file.id,
      width: 42,
      height: 42,
      memCacheWidth: 130,
      memCacheHeight: 130,
      borderRadius: BorderRadius.circular(10),
      heroTag: isMedia ? 'file_hero_${file.id}' : null,
      fallbackIcon: _icon(file.mimeType),
      fallbackIconColor: color,
      playBadgeColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(file.mimeType);
    final notifier = downloadNotifier;
    if (notifier == null) return _buildTile(context, color, null, null);
    return ValueListenableBuilder<({double progress, int received})>(
      valueListenable: notifier,
      builder: (context, dl, _) =>
          _buildTile(context, color, dl.progress, dl.received),
    );
  }

  Widget _buildTile(BuildContext context, Color color, double? progress,
      int? received) {
    final isDownloading = progress != null;
    return RepaintBoundary(child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
              left: BorderSide(color: Colors.blue, width: 3))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: isSelectionMode ? onSelectTap : onTap,
              onLongPress: onSelectTap,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              leading: isSelectionMode
                  ? InkWell(
                onTap: onSelectTap,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectTap?.call(),
                  shape: const CircleBorder(),
                  activeColor: Colors.blue,
                ),
              )
                  : isDownloading
                  ? SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.12),
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A73E8)),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ],
                ),
              )
                  : _buildLeading(color),
              title: Text(
                file.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: isDownloading
                  ? Text(
                '${DownloadRepository.formatBytes(received ?? 0)} / ${file.formattedSize}',
                style: const TextStyle(
                    color: Color(0xFF1A73E8), fontSize: 12),
              )
                  : Text(
                file.formattedSize,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                    fontSize: 13),
              ),
              trailing: isSelectionMode
                  ? null
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onFavouriteTap,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        file.isFavourite
                            ? Icons.star
                            : Icons.star_border,
                        color: file.isFavourite
                            ? Colors.amber
                            : Colors.grey,
                        size: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.grey, size: 22),
                    onPressed: onMenuTap,
                  ),
                ],
              ),
            ),
            if (isDownloading)
              LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1A73E8)),
              ),
          ],
        ),
      ),
    ));
  }
}

// ── File Grid Card ────────────────────────────────────────────────────────────
class _FileGridCard extends StatelessWidget {
  final FileModel file;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onSelectTap;
  final VoidCallback onMenuTap;
  final VoidCallback onFavouriteTap;

  const _FileGridCard({
    super.key,
    required this.file,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onSelectTap,
    required this.onMenuTap,
    required this.onFavouriteTap,
  });

  IconData _icon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_rounded;
    if (mime.startsWith('video/')) return Icons.videocam_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _color(String mime) {
    if (mime.startsWith('image/')) return const Color(0xFF34A853);
    if (mime.startsWith('video/')) return const Color(0xFFEA4335);
    return const Color(0xFF1A73E8);
  }

  @override
  Widget build(BuildContext context) {
    final mime = file.mimeType.toLowerCase();
    final color = _color(mime);
    final thumb = file.thumbnailPath;
    final hasPreview = thumb != null && thumb.isNotEmpty;
    final isMedia = MediaTypeHelper.isImage(mime) || MediaTypeHelper.isVideo(mime);

    if (isMedia && hasPreview) {
      return MediaGridCard(
        mimeType: file.mimeType,
        thumbnailPath: file.thumbnailPath,
        cacheKey: file.id,
        heroTag: 'file_hero_${file.id}',
        isFavourite: file.isFavourite,
        isSelected: isSelected,
        isSelectionMode: isSelectionMode,
        playBadgeColor: Colors.black.withValues(alpha: 0.5),
        onTap: onTap,
        onSelectTap: onSelectTap,
        onFavouriteTap: onFavouriteTap,
        onMenuTap: onMenuTap,
      );
    }

    return RepaintBoundary(child: GestureDetector(
      onTap: isSelectionMode ? onSelectTap : onTap,
      onLongPress: onSelectTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaThumbnail(
                    mimeType: file.mimeType,
                    thumbnailPath: file.thumbnailPath,
                    cacheKey: file.id,
                    memCacheWidth: 300,
                    memCacheHeight: 300,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    heroTag: isMedia && hasPreview
                        ? 'file_hero_${file.id}'
                        : null,
                    fallbackIcon: _icon(mime),
                    fallbackIconColor: color,
                    fallbackBackgroundColor: color.withValues(alpha: 0.08),
                    fallbackIconSize: 40,
                    playBadgeColor: Colors.black.withValues(alpha: 0.5),
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
                          border:
                          Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  if (!isSelectionMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onFavouriteTap,
                        child: Icon(
                          file.isFavourite
                              ? Icons.star
                              : Icons.star_border,
                          color: file.isFavourite
                              ? Colors.amber
                              : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color:
                            Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          file.formattedSize,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSelectionMode)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: const Icon(Icons.more_vert,
                            color: Colors.grey),
                        onPressed: onMenuTap,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ── Info Bottom Sheet ─────────────────────────────────────────────────────────
class InfoBottomSheet extends StatefulWidget {
  final String id;
  final String type;
  final String name;
  final String previewUrl;
  final Color iconColor;
  final IconData icon;
  final String mimeType;
  final Future<Map<String, dynamic>> Function() fetchInfo;
  final String Function(dynamic) fmt;

  const InfoBottomSheet({
    super.key,
    required this.id,
    required this.type,
    required this.name,
    required this.previewUrl,
    required this.iconColor,
    required this.icon,
    this.mimeType = '',
    required this.fetchInfo,
    required this.fmt,
  });

  @override
  State<InfoBottomSheet> createState() => _InfoBottomSheetState();
}

class _InfoBottomSheetState extends State<InfoBottomSheet> {
  Map<String, dynamic>? _info;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.fetchInfo();
      if (mounted) {
        setState(() {
          _info = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final locale = Localizations.localeOf(context).toString();
      return DateFormat('d MMM yyyy, HH:mm', locale).format(dt);
    } catch (e) {
      if (kDebugMode) debugPrint('[FilesPage] _formatDate failed: $e');
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;
    final isFolder = widget.type == 'folder';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isFolder ? t.folderDetails : t.fileDetails,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  widget.previewUrl.isNotEmpty
                      ? MediaThumbnail(
                    mimeType: widget.mimeType,
                    thumbnailPath: widget.previewUrl,
                    cacheKey: widget.id,
                    width: 52,
                    height: 52,
                    memCacheWidth: 160,
                    memCacheHeight: 160,
                    borderRadius: BorderRadius.circular(10),
                    fallbackIcon: widget.icon,
                    fallbackIconColor: widget.iconColor,
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _iconBox(cs),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isFolder && _info != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.fmt(_info!['size']),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                              cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (isFolder && !_isLoading) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_info?['created_at']),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Text(
                  ErrorLocalizer.forException(_error!, AppLocalizations.of(context)!),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_info != null)
                isFolder
                    ? _buildFolderInfo(cs, t)
                    : _buildFileInfo(cs, t),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(ColorScheme cs) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: widget.iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(widget.icon, color: widget.iconColor, size: 26),
    );
  }

  Widget _buildFileInfo(ColorScheme cs, AppLocalizations t) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.fileName,
                value: _info!['name'] ?? widget.name,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.fileSize,
                value: widget.fmt(_info!['size']),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.createdAt,
                value: _formatDate(_info!['created_at']),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.capturedAt,
                value: _formatDate(_info!['captured_at']),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderInfo(ColorScheme cs, AppLocalizations t) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.fileName,
                value: _info!['name'] ?? widget.name,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.totalSize,
                value: widget.fmt(_info!['total_size']),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.folderCount,
                value: '${_info!['folder_count'] ?? 0}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _InfoTile(
                cs: cs,
                label: t.fileCount,
                value: '${_info!['file_count'] ?? 0}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final String value;

  const _InfoTile({
    required this.cs,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
