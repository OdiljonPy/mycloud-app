import 'dart:async';
import 'dart:io';

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

<<<<<<< HEAD
=======
class SyncProgress {
  final int pending;
  final int uploading;
  final int done;
  final int failed;
  final double currentFileProgress;
  final String? currentFileName;
  final int totalInBatch;
  final int scannedCount;
  final bool isScanning;
  final int totalFiles;

  const SyncProgress({
    this.pending = 0,
    this.uploading = 0,
    this.done = 0,
    this.failed = 0,
    this.currentFileProgress = 0.0,
    this.currentFileName,
    this.totalInBatch = 0,
    this.scannedCount = 0,
    this.isScanning = false,
    this.totalFiles = 0,
  });
}
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")

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

  final SyncQueueDb _db = SyncQueueDb();
  final StreamController<SyncProgress> _progressController =
  StreamController<SyncProgress>.broadcast();

  Stream<SyncProgress> get progressStream => _progressController.stream;
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  int _syncSessionId = 0;

  Future<void> initialize() async {
    await _db.init();

    // Emit device total immediately — before any scan or token check
    unawaited(_emitDeviceTotal());

    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[AutoSync] No auth token found, skipping initialize');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    Set<String>? selectedIds;
    final selectiveOn = prefs.getBool('auto_sync_selected_only') ?? false;
    if (selectiveOn) {
      final list = prefs.getStringList('selected_files') ?? [];
      final cleaned = list.where((id) => id.trim().isNotEmpty).toSet();
      if (cleaned.isNotEmpty) {
        selectedIds = cleaned;
      }
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
      uploadedKeys: {}, // No longer used - backend checks duplicates
      selectedLocalIds: selectedIds,
      filterFromMs: filterFromMs,
    );
    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Scanned: $newItems new items enqueued');

<<<<<<< HEAD
    // Обновляем watermark = now после каждого scan
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
=======
    await _emitProgress();
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
  }

  // FIX 1: Пересканирует галерею без cold-start логики.
  // Вызывается при каждом нажатии "Синхронизировать сейчас".
  Future<void> _rescan() async {
    final mySession = _syncSessionId;
    _isScanning = true;
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    Set<String>? selectedIds;
    final selectiveOn = prefs.getBool('auto_sync_selected_only') ?? false;
    if (selectiveOn) {
      final list = prefs.getStringList('selected_files') ?? [];
      final cleaned = list.where((id) => id.trim().isNotEmpty).toSet();
      if (cleaned.isNotEmpty) selectedIds = cleaned;
    }

<<<<<<< HEAD
    // Delta scan: сканируем только файлы после последнего синка
    final watermarkMs = prefs.getInt(_kWatermarkKey);
    final filterFromMs = watermarkMs != null
        ? watermarkMs - const Duration(hours: 2).inMilliseconds
        : null;
    debugPrint('[AutoSync] Rescan watermark: ${watermarkMs != null ? DateTime.fromMillisecondsSinceEpoch(watermarkMs) : 'none (full scan)'}');

    // uploadedKeys = {} т.к. дубли уже есть в локальной БД (status=done)
=======
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
    _scannedCount = 0;
    if (mySession != _syncSessionId) {
      _isScanning = false;
      return;
    }
    final scanner = MediaScanner(
      db: _db,
      uploadedKeys: {},
      selectedLocalIds: selectedIds,
      filterFromMs: filterFromMs,
      resolveFiles: false,
      onProgress: (count) {
        _scannedCount = count;
        _emit(_currentProgress.copyWith(scannedCount: _scannedCount, isScanning: true, sessionUploaded: _sessionUploadedCount));
      },
    );

    _totalFiles = await scanner.countTotal();
    debugPrint('[AutoSync] Jami fayllar: $_totalFiles');
    await _emitProgress();

    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Rescan: $newItems new items enqueued');

    // Обновляем watermark после скана
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

      try {
        final pinnedFolders = await repo.getPinnedFolders();
        final alreadyPinned = pinnedFolders.any(
              (p) => (p['folder'] as FolderModel?)?.id == syncFolderUuid,
        );
        if (!alreadyPinned) {
          await repo.pinFolder(syncFolderUuid);
        }
      } catch (e) {
        debugPrint('[Sync] Pin attempt (non-critical): $e');
      }

      final galleryService = GalleryService(
        baseUrl: AppConfig.instance.baseUrl,
        token: token,
      );
      final uploader = TusSyncUploader();

      while (_isRunning && sessionId == _syncSessionId) {
<<<<<<< HEAD
        final tasks = await _db.getPendingOldestFirst(limit: 50);
=======
        final tasks = await _db.getPendingOldestFirst(limit: 200);
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
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

        Map<String, bool> duplicateMap;
        try {
          duplicateMap = await galleryService.checkDuplicates(
            resolvedTasks,
            folderId: syncFolderUuid,
          );
        } catch (e) {
          debugPrint('[Sync] Duplicate check failed (uploading all): $e');
          duplicateMap = {};
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
            // Резолвим через photo_manager по localId
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

          debugPrint('[Sync] 📤 Uploading: ${task.fileName} (${(task.fileSize / 1024 / 1024).toStringAsFixed(2)} MB, ${task.mimeType})');

          try {
            final uploadTask = resolvedPath != task.filePath
                ? task.copyWith(filePath: resolvedPath)
                : task;

            final serverUuid = await uploader.upload(
              uploadTask,
              folderId: syncFolderUuid,
              onProgress: (progress) {
                _emit(_currentProgress.copyWith(currentFileProgress: progress, sessionUploaded: _sessionUploadedCount));
              },
            );
<<<<<<< HEAD
            await _db.markDoneWithSession(task.id!, serverUuid);
            _sessionUploadedCount++;
            debugPrint('[Sync] Uploaded: ${task.fileName} -> $serverUuid (session: $_sessionUploadedCount)');
=======
            await _db.markDone(task.id!, serverUuid);
            debugPrint('[Sync] ✅ Uploaded: ${task.fileName} -> $serverUuid');
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
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

  String? _currentFileName;
  int _totalInBatch = 0;
  int _scannedCount = 0;
<<<<<<< HEAD
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

=======
  int _totalFiles = 0;
  Map<String, int> _lastCounts = {'pending': 0, 'uploading': 0, 'done': 0, 'failed': 0};

  // FIX 2: done берётся напрямую из БД (после markDone уже там).
  // Убрали _batchDone — он давал двойной счёт.
  Future<void> _emitProgress({double currentProgress = 0.0}) async {
    final counts = await _db.getStatusCounts();
    _lastCounts = counts;
    _progressController.add(SyncProgress(
      pending: counts['pending'] ?? 0,
      uploading: counts['uploading'] ?? 0,
      done: counts['done'] ?? 0,
      failed: counts['failed'] ?? 0,
      currentFileProgress: currentProgress,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
      scannedCount: _scannedCount,
      isScanning: _isScanning,
      totalFiles: _totalFiles,
    ));
  }

  void _emitScanProgress() {
    _progressController.add(SyncProgress(
      pending: _lastCounts['pending'] ?? 0,
      uploading: _lastCounts['uploading'] ?? 0,
      done: _lastCounts['done'] ?? 0,
      failed: _lastCounts['failed'] ?? 0,
      currentFileProgress: 0.0,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
      scannedCount: _scannedCount,
      isScanning: true,
      totalFiles: _totalFiles,
    ));
  }

  void _emitProgressSync({double currentProgress = 0.0}) {
    _progressController.add(SyncProgress(
      pending: _lastCounts['pending'] ?? 0,
      uploading: _lastCounts['uploading'] ?? 0,
      done: _lastCounts['done'] ?? 0,
      failed: _lastCounts['failed'] ?? 0,
      currentFileProgress: currentProgress,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
      scannedCount: _scannedCount,
      isScanning: _isScanning,
      totalFiles: _totalFiles,
    ));
  }
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
}