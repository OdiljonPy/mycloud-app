import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/secure_storage.dart';
import 'data/gallery_service.dart';
import 'data/sync_queue_db.dart';
import 'data/sync_task.dart';
import 'data/tus_sync_uploader.dart';
import 'domain/media_scanner.dart';
import 'sync_progress.dart';
import '../home/data/home_repository.dart';
import '../home/data/models/folder_model.dart';


class AutoSyncService {

  Future<void> startAutoSync() async {
    if (_isRunning || _isScanning) {
      debugPrint("[AutoSync] Already running/scanning, skip");
      return;
    }
    _syncSessionId++;
    await _emitDeviceTotal();
    await Future.wait([_rescan(), startSync()]);
  }

  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();

  static const String _kColdStartKey = 'sync_cold_start_done';
  static const String _kAutoSyncEnabledKey = 'auto_sync_enabled';
  static const String _kWatermarkKey = 'sync_last_watermark_ms';
  static const String _kWifiOnlyKey = 'auto_sync_wifi_only';
  static const String _kSelectedOnlyKey = 'auto_sync_selected_only';
  static const String _kSelectedAlbumsKey = 'selected_albums';

  final SyncQueueDb _db = SyncQueueDb();
  final StreamController<SyncProgress> _progressController =
  StreamController<SyncProgress>.broadcast();

  Stream<SyncProgress> get progressStream => _progressController.stream;
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  int _syncSessionId = 0;
  bool _settingsChanged = false;

  Future<void> initialize() async {
    await _db.init();

    // Emit device total immediately — before any scan or token check
    unawaited(_emitDeviceTotal());

    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[AutoSync] No auth token found, skipping initialize');
      return;
    }

    final baseUrl = AppConfig.instance.baseUrl;
    final galleryService = GalleryService(baseUrl: baseUrl, token: token);

    Set<String> uploadedKeys = {};
    final prefs = await SharedPreferences.getInstance();
    final coldStartDone = prefs.getBool(_kColdStartKey) ?? false;

    if (!coldStartDone) {
      try {
        uploadedKeys = await galleryService.getUploadedFileKeys();
        debugPrint('[AutoSync] Cold start: loaded ${uploadedKeys.length} keys from server');
      } catch (e) {
        debugPrint('[AutoSync] Cold start gallery fetch failed: $e');
      }
    }

    // selectiveOn + пустой selectedAlbumIds (Set, не null) => MediaScanner
    // отфильтрует ВСЁ (ничего не заматчится) — это осознанно: "только
    // выбранные альбомы" с пустым списком должно ничего не синкать, а не всё.
    Set<String>? selectedAlbumIds;
    final selectiveOn = prefs.getBool(_kSelectedOnlyKey) ?? false;
    if (selectiveOn) {
      final list = prefs.getStringList(_kSelectedAlbumsKey) ?? [];
      selectedAlbumIds = list.where((id) => id.trim().isNotEmpty).toSet();
    }

    final watermarkMs = prefs.getInt(_kWatermarkKey);
    debugPrint('[AutoSync] Watermark: ${watermarkMs != null ? DateTime.fromMillisecondsSinceEpoch(watermarkMs) : 'none (full scan)'}');

    // Delta scan: только от watermark - 1 день, чтобы не пропустить
    // фото сделанные после закрытия приложения
    final filterFromMs = watermarkMs != null
        ? watermarkMs - const Duration(hours: 2).inMilliseconds
        : null;

    final scanner = MediaScanner(
      db: _db,
      uploadedKeys: uploadedKeys,
      selectedAlbumIds: selectedAlbumIds,
      filterFromMs: filterFromMs,
    );
    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Scanned: $newItems new items enqueued');

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_kWatermarkKey, nowMs);
    debugPrint('[AutoSync] Watermark updated: ${DateTime.fromMillisecondsSinceEpoch(nowMs)}');

    if (!coldStartDone) {
      await prefs.setBool(_kColdStartKey, true);
    }

    final counts = await _db.getStatusCounts();
    _emit(_currentProgress.copyWith(
      pending: counts['pending'] ?? 0,
      uploading: counts['uploading'] ?? 0,
      done: counts['done'] ?? 0,
      failed: counts['failed'] ?? 0,
      sessionUploaded: _sessionUploadedCount,
      scannedCount: _scannedCount,
      isScanning: _isScanning,
      currentFileProgress: 0.0,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
    ));
  }

  // FIX 1: Пересканирует галерею без cold-start логики.
  // Вызывается при каждом нажатии "Синхронизировать сейчас".
  Future<void> _rescan() async {
    final mySession = _syncSessionId;
    _isScanning = true;
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    // См. комментарий в initialize(): пустой список при selectiveOn
    // должен фильтровать всё, а не отключать фильтр.
    Set<String>? selectedAlbumIds;
    final selectiveOn = prefs.getBool(_kSelectedOnlyKey) ?? false;
    if (selectiveOn) {
      final list = prefs.getStringList(_kSelectedAlbumsKey) ?? [];
      selectedAlbumIds = list.where((id) => id.trim().isNotEmpty).toSet();
    }

    // Delta scan: сканируем только файлы после последнего синка
    final watermarkMs = prefs.getInt(_kWatermarkKey);
    final filterFromMs = watermarkMs != null
        ? watermarkMs - const Duration(hours: 2).inMilliseconds
        : null;
    debugPrint('[AutoSync] Rescan watermark: ${watermarkMs != null ? DateTime.fromMillisecondsSinceEpoch(watermarkMs) : 'none (full scan)'}');

    // uploadedKeys = {} т.к. дубли уже есть в локальной БД (status=done)
    _scannedCount = 0;
    if (mySession != _syncSessionId) {
      _isScanning = false;
      return;
    }
    final scanner = MediaScanner(
      db: _db,
      uploadedKeys: {},
      selectedAlbumIds: selectedAlbumIds,
      filterFromMs: filterFromMs,
      resolveFiles: false,
      onProgress: (count) {
        _scannedCount = count;
        _emit(_currentProgress.copyWith(scannedCount: _scannedCount, isScanning: true, sessionUploaded: _sessionUploadedCount));
      },
    );
    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Rescan: $newItems new items enqueued');

    await prefs.setInt(_kWatermarkKey, DateTime.now().millisecondsSinceEpoch);
    final counts = await _db.getStatusCounts();
    _emit(_currentProgress.copyWith(
      pending: counts['pending'] ?? 0,
      uploading: counts['uploading'] ?? 0,
      done: counts['done'] ?? 0,
      failed: counts['failed'] ?? 0,
      sessionUploaded: _sessionUploadedCount,
      scannedCount: _scannedCount,
      isScanning: _isScanning,
      currentFileProgress: 0.0,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
    ));
    _isScanning = false;
  }

  Future<void> startSync() async {
    if (_isRunning) return;

    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[AutoSync] Cannot start sync: no auth token');
      return;
    }

    _isRunning = true;
    final sessionId = _syncSessionId;
    _totalInBatch = 0;
    _currentFileName = null;

    // Сбрасываем зависшие uploading -> pending (после краша/стопа)
    await _db.resetStuckUploading();
    // Retry failed файлов по backoff: 1мин → 5мин → 30мин (макс 3 попытки)
    await _db.resetFailedForRetry();
    _sessionUploadedCount = 0;
    await _db.resetSessionCounter();

    try {
      final repo = HomeRepository();
      final syncFolder = await repo.resolveSyncFolder();
      final syncFolderUuid = syncFolder.id;
      debugPrint('[Sync] Session $sessionId using folder: $syncFolderUuid');

      List<Map<String, dynamic>> pinnedFolders = [];
      try {
        pinnedFolders = await repo.getPinnedFolders();
        final alreadyPinned = pinnedFolders.any(
              (p) => (p['folder'] as FolderModel?)?.id == syncFolderUuid,
        );
        if (!alreadyPinned) {
          await repo.pinFolder(syncFolderUuid);
        }
      } catch (e) {
        debugPrint('[Sync] Pin attempt (non-critical): $e');
      }

      // Альбомный режим: у каждого выбранного альбома своя папка на
      // сервере (то же имя, что на телефоне) вместо единой syncFolderUuid.
      // Имена альбомов нужны только для резолва — не храним их в БД.
      final prefs = await SharedPreferences.getInstance();
      final selectiveOn = prefs.getBool(_kSelectedOnlyKey) ?? false;
      // Снимок настроек на старте сессии — сверяется в конце каждой
      // итерации while, чтобы обнаружить смену выбора папок "на лету"
      // без прерывания текущей сессии (см. _settingsChanged ниже).
      final initialSelectiveOn = selectiveOn;
      final initialSelectedAlbumIds =
          prefs.getStringList(_kSelectedAlbumsKey)?.toSet() ?? <String>{};
      _settingsChanged = false;
      final Map<String, String> albumNames = {};
      if (selectiveOn) {
        try {
          final albums = await PhotoManager.getAssetPathList(
            type: RequestType.common,
            hasAll: true,
          );
          for (final a in albums) {
            if (!a.isAll) albumNames[a.id] = a.name;
          }
        } catch (e) {
          debugPrint('[Sync] Failed to load album names: $e');
        }
      }
      final Map<String, String> albumFolderCache = {};

      final galleryService = GalleryService(
        baseUrl: AppConfig.instance.baseUrl,
        token: token,
      );
      final uploader = TusSyncUploader();

      while (_isRunning && sessionId == _syncSessionId) {
        await _waitForWifiIfNeeded(sessionId);
        if (!_isRunning || sessionId != _syncSessionId) break;

        final tasks = await _db.getPendingOldestFirst(limit: 50);
        if (tasks.isEmpty) {
          if (_isScanning) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          debugPrint('[Sync] No pending tasks, sync complete');
          break;
        }

        _totalInBatch = tasks.length;

        // Резолвим реальный путь и размер для задач с fileSize=0
        // до checkDuplicates — иначе сервер не распознаёт дубли
        final resolvedTasks = await _resolveTaskSizes(tasks);

        // Целевая папка на задачу: в альбомном режиме — своя папка на
        // альбом, иначе — единая syncFolderUuid (старое поведение).
        final Map<int, String> taskFolderIds = {};
        for (final task in resolvedTasks) {
          if (task.id == null) continue;
          taskFolderIds[task.id!] = await _resolveTargetFolderId(
            selectiveOn: selectiveOn,
            task: task,
            repo: repo,
            fallbackFolderId: syncFolderUuid,
            albumNames: albumNames,
            albumFolderCache: albumFolderCache,
            pinnedFolders: pinnedFolders,
          );
        }

        Map<String, bool> duplicateMap = {};
        if (selectiveOn) {
          // checkDuplicates бьёт по конкретной папке — с несколькими
          // альбомами группируем задачи по целевой папке и проверяем
          // каждую группу отдельно, иначе дубликаты в "чужой" папке
          // проверялись бы неправильно.
          final byFolder = <String, List<SyncTask>>{};
          for (final task in resolvedTasks) {
            final folderId = task.id != null
                ? (taskFolderIds[task.id!] ?? syncFolderUuid)
                : syncFolderUuid;
            byFolder.putIfAbsent(folderId, () => []).add(task);
          }
          for (final entry in byFolder.entries) {
            try {
              final partial = await galleryService.checkDuplicates(
                entry.value,
                folderId: entry.key,
              );
              duplicateMap.addAll(partial);
            } catch (e) {
              debugPrint('[Sync] Duplicate check failed for folder ${entry.key} (uploading all): $e');
            }
          }
        } else {
          try {
            duplicateMap = await galleryService.checkDuplicates(
              resolvedTasks,
              folderId: syncFolderUuid,
            );
          } catch (e) {
            debugPrint('[Sync] Duplicate check failed (uploading all): $e');
            duplicateMap = {};
          }
        }

        for (final task in resolvedTasks) {
          if (!_isRunning || sessionId != _syncSessionId) break;
          if (task.id == null) continue;

          Map<String, int> counts;

          // Проверка 1: ответ бекенда
          final isServerDuplicate = duplicateMap[task.localId] ?? false;

          // Проверка 2: локальная DB — файл с таким именем уже done
          final isLocalDuplicate = await _db.isDoneByNameAndSize(
            task.fileName, task.fileSize);

          final isDuplicate = isServerDuplicate || isLocalDuplicate;

          if (isDuplicate) {
            final reason = isServerDuplicate ? 'server' : 'local_db';
            await _db.markDoneWithSession(task.id!, 'duplicate_skipped_$reason');
            debugPrint('[Sync] SKIP duplicate ($reason): ${task.fileName}');
            counts = await _db.getStatusCounts();
            _emit(_currentProgress.copyWith(
              pending: counts['pending'] ?? 0,
              uploading: counts['uploading'] ?? 0,
              done: counts['done'] ?? 0,
              failed: counts['failed'] ?? 0,
              sessionUploaded: _sessionUploadedCount,
              scannedCount: _scannedCount,
              isScanning: _isScanning,
              currentFileProgress: 0.0,
              currentFileName: _currentFileName,
              totalInBatch: _totalInBatch,
            ));
            continue;
          }

          // filePath резолвится здесь — не во время scan
          String resolvedPath = task.filePath;
          if (resolvedPath.isEmpty) {
            try {
              final asset = await AssetEntity.fromId(task.localId);
              final originFile = await asset?.originFile;
              if (originFile == null) {
                await _db.markFailed(task.id!);
                debugPrint('[Sync] Cannot resolve file for ${task.fileName}');
                counts = await _db.getStatusCounts();
                _emit(_currentProgress.copyWith(
                  pending: counts['pending'] ?? 0,
                  uploading: counts['uploading'] ?? 0,
                  done: counts['done'] ?? 0,
                  failed: counts['failed'] ?? 0,
                  sessionUploaded: _sessionUploadedCount,
                  scannedCount: _scannedCount,
                  isScanning: _isScanning,
                  currentFileProgress: 0.0,
                  currentFileName: _currentFileName,
                  totalInBatch: _totalInBatch,
                ));
                continue;
              }
              resolvedPath = originFile.path;
            } catch (e) {
              await _db.markFailed(task.id!);
              debugPrint('[Sync] resolveFile error for ${task.fileName}: $e');
              continue;
            }
          }

          final file = File(resolvedPath);
          if (!file.existsSync()) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync] File missing, skipped: $resolvedPath');
            counts = await _db.getStatusCounts();
            _emit(_currentProgress.copyWith(
              pending: counts['pending'] ?? 0,
              uploading: counts['uploading'] ?? 0,
              done: counts['done'] ?? 0,
              failed: counts['failed'] ?? 0,
              sessionUploaded: _sessionUploadedCount,
              scannedCount: _scannedCount,
              isScanning: _isScanning,
              currentFileProgress: 0.0,
              currentFileName: _currentFileName,
              totalInBatch: _totalInBatch,
            ));
            continue;
          }

          await _waitForWifiIfNeeded(sessionId);
          if (!_isRunning || sessionId != _syncSessionId) break;

          _currentFileName = task.fileName;
          await _db.markUploading(task.id!);
          counts = await _db.getStatusCounts();
          _emit(_currentProgress.copyWith(
            pending: counts['pending'] ?? 0,
            uploading: counts['uploading'] ?? 0,
            done: counts['done'] ?? 0,
            failed: counts['failed'] ?? 0,
            sessionUploaded: _sessionUploadedCount,
            scannedCount: _scannedCount,
            isScanning: _isScanning,
            currentFileProgress: 0.0,
            currentFileName: _currentFileName,
            totalInBatch: _totalInBatch,
          ));

          try {
            final uploadTask = resolvedPath != task.filePath
                ? task.copyWith(filePath: resolvedPath)
                : task;

            final serverUuid = await uploader.upload(
              uploadTask,
              folderId: taskFolderIds[task.id!] ?? syncFolderUuid,
              onProgress: (progress) {
                _emit(_currentProgress.copyWith(currentFileProgress: progress, sessionUploaded: _sessionUploadedCount));
              },
            );
            await _db.markDoneWithSession(task.id!, serverUuid);
            _sessionUploadedCount++;
            debugPrint('[Sync] Uploaded: ${task.fileName} -> $serverUuid (session: $_sessionUploadedCount)');
          } on TusUploadException catch (e) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync][ERROR] Upload failed: ${task.fileName} — $e');
          } catch (e) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync][ERROR] Unexpected: ${task.fileName} — $e');
          }

          counts = await _db.getStatusCounts();
          _emit(_currentProgress.copyWith(
            pending: counts['pending'] ?? 0,
            uploading: counts['uploading'] ?? 0,
            done: counts['done'] ?? 0,
            failed: counts['failed'] ?? 0,
            sessionUploaded: _sessionUploadedCount,
            scannedCount: _scannedCount,
            isScanning: _isScanning,
            currentFileProgress: 0.0,
            currentFileName: _currentFileName,
            totalInBatch: _totalInBatch,
          ));
        }

        // Смена выбора папок "на лету": не прерываем текущую сессию —
        // только помечаем, что следующий цикл должен пересканировать со
        // свежим фильтром (см. _settingsChanged в finally ниже).
        final freshPrefs = await SharedPreferences.getInstance();
        final freshSelectiveOn = freshPrefs.getBool(_kSelectedOnlyKey) ?? false;
        final freshSelectedAlbumIds =
            freshPrefs.getStringList(_kSelectedAlbumsKey)?.toSet() ?? <String>{};
        if (freshSelectiveOn != initialSelectiveOn ||
            !setEquals(freshSelectedAlbumIds, initialSelectedAlbumIds)) {
          _settingsChanged = true;
        }
      }
    } finally {
      _isRunning = false;
      _currentFileName = null;
      final counts = await _db.getStatusCounts();
      _emit(_currentProgress.copyWith(
        pending: counts['pending'] ?? 0,
        uploading: counts['uploading'] ?? 0,
        done: counts['done'] ?? 0,
        failed: counts['failed'] ?? 0,
        sessionUploaded: _sessionUploadedCount,
        scannedCount: _scannedCount,
        isScanning: _isScanning,
        currentFileProgress: 0.0,
        currentFileName: _currentFileName,
        totalInBatch: _totalInBatch,
      ));

      // Если во время этой сессии сменился выбор папок и сессию не
      // остановили вручную (stopSync/onLogout бампают _syncSessionId) —
      // запускаем новый цикл со свежим фильтром сразу после того, как
      // текущий доканчился естественным образом.
      if (_settingsChanged && sessionId == _syncSessionId) {
        _settingsChanged = false;
        unawaited(startAutoSync());
      }
    }
  }

  /// Возвращает id папки на сервере для задачи. В обычном режиме — всегда
  /// [fallbackFolderId]. В альбомном — папка, соответствующая альбому
  /// задачи (создаётся/резолвится лениво и кэшируется на сессию синка).
  Future<String> _resolveTargetFolderId({
    required bool selectiveOn,
    required SyncTask task,
    required HomeRepository repo,
    required String fallbackFolderId,
    required Map<String, String> albumNames,
    required Map<String, String> albumFolderCache,
    required List<Map<String, dynamic>> pinnedFolders,
  }) async {
    if (!selectiveOn) return fallbackFolderId;
    final albumId = task.albumId;
    // Задачи без albumId — легаси-записи до миграции v5, в альбомном
    // режиме их не должно быть в очереди (purgeNonSelectedAlbums их
    // чистит), но на всякий случай не роняем sync, а шлём в дефолтную папку.
    if (albumId == null) return fallbackFolderId;

    final cached = albumFolderCache[albumId];
    if (cached != null) return cached;

    final albumName = albumNames[albumId] ?? albumId;
    try {
      final folder = await repo.resolveSyncFolderForAlbum(
        albumId: albumId,
        albumName: albumName,
      );
      albumFolderCache[albumId] = folder.id;

      final alreadyPinned = pinnedFolders.any(
        (p) => (p['folder'] as FolderModel?)?.id == folder.id,
      );
      if (!alreadyPinned) {
        try {
          await repo.pinFolder(folder.id);
        } catch (e) {
          debugPrint('[Sync] Pin attempt for album folder "$albumName" (non-critical): $e');
        }
      }
      return folder.id;
    } catch (e) {
      debugPrint('[Sync] resolveSyncFolderForAlbum failed for "$albumName": $e — falling back to default folder');
      // Кешируем и неудачу — иначе при 50+ файлах в альбоме тот же
      // падающий запрос повторялся бы на каждый файл в этой сессии синка.
      albumFolderCache[albumId] = fallbackFolderId;
      return fallbackFolderId;
    }
  }

  /// Для задач с fileSize=0 или пустым filePath резолвит реальный файл
  /// через photo_manager и обновляет DB. Возвращает список с корректными данными.
  Future<List<SyncTask>> _resolveTaskSizes(List<SyncTask> tasks) async {
    final result = <SyncTask>[];
    for (final task in tasks) {
      if (task.fileSize > 0 && task.filePath.isNotEmpty) {
        result.add(task);
        continue;
      }
      try {
        final asset = await AssetEntity.fromId(task.localId);
        final file = await asset?.originFile;
        if (file == null || !file.existsSync()) {
          result.add(task);
          continue;
        }
        final realSize = await file.length();
        final resolvedPath = file.path;
        if (task.id != null) {
          await _db.updatePathAndSize(task.id!, resolvedPath, realSize);
        }
        result.add(task.copyWith(filePath: resolvedPath, fileSize: realSize));
        debugPrint('[Sync] Resolved size for ${task.fileName}: $realSize bytes');
      } catch (e) {
        debugPrint('[Sync] _resolveTaskSizes failed for ${task.fileName}: $e');
        result.add(task);
      }
    }
    return result;
  }

  /// Если включён "только Wi-Fi" и сейчас не Wi-Fi — блокируется
  /// (с поллингом раз в 3с) пока сеть не станет Wi-Fi, настройка не
  /// выключится или синк не остановится извне.
  Future<void> _waitForWifiIfNeeded(int sessionId) async {
    var loggedPause = false;
    while (_isRunning && sessionId == _syncSessionId) {
      final prefs = await SharedPreferences.getInstance();
      final wifiOnly = prefs.getBool(_kWifiOnlyKey) ?? false;
      if (!wifiOnly) return;

      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) {
        if (loggedPause) debugPrint('[Sync] Wi-Fi restored, resuming');
        return;
      }

      if (!loggedPause) {
        loggedPause = true;
        debugPrint('[Sync] Wi-Fi only: no Wi-Fi, pausing until it returns');
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> stopSync() async {
    _isRunning = false;
    _syncSessionId++;
    debugPrint('[AutoSync] Sync stopped (session invalidated)');
  }

  Future<void> onLogout() async {
    _isRunning = false;
    _isScanning = false;
    _syncSessionId++;
    await _db.reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kColdStartKey);
    await prefs.remove(_kWatermarkKey);
    debugPrint('[AutoSync] Logout: queue cleared');
  }

  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoSyncEnabledKey) ?? false;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoSyncEnabledKey, enabled);
  }

  /// Вычищает из очереди pending-задачи вне текущего выбора альбомов.
  /// Вызывается при включении/изменении режима "только выбранные альбомы" —
  /// без этого уже отсканированные, но не загруженные файлы из других
  /// папок продолжили бы синкаться в фоне.
  Future<void> purgeNonSelectedAlbums() async {
    await _db.init();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kSelectedAlbumsKey) ?? [];
    final albumIds = list.where((id) => id.trim().isNotEmpty).toSet();
    await _db.purgeNonSelectedPending(albumIds);
  }

  String? _currentFileName;
  int _totalInBatch = 0;
  int _scannedCount = 0;
  int _sessionUploadedCount = 0;
  SyncProgress _currentProgress = const SyncProgress();

  Future<void> _emitDeviceTotal() async {
    try {
      final scanner = MediaScanner(db: _db, uploadedKeys: {});
      final total = await scanner.countTotal();
      _emit(_currentProgress.copyWith(deviceTotal: total));
      debugPrint('[AutoSync] Device total: $total');
    } catch (e) {
      debugPrint('[AutoSync] _emitDeviceTotal failed: $e');
    }
  }

  void _emit(SyncProgress progress) {
    _currentProgress = progress;
    _progressController.add(progress);
  }

}