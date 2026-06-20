import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/secure_storage.dart';
import 'data/gallery_service.dart';
import 'data/sync_queue_db.dart';
import 'data/tus_sync_uploader.dart';
import 'domain/media_scanner.dart';
import '../home/data/home_repository.dart';
import '../home/data/models/folder_model.dart';

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
  });
}

class AutoSyncService {

  // FIX 1: startAutoSync теперь всегда пересканирует галерею перед
  // запуском — чтобы новые файлы добавились в очередь (pending > 0).
  Future<void> startAutoSync() async {
    if (_isRunning || _isScanning) {
      debugPrint("[AutoSync] Already running/scanning, skip");
      return;
    }
    await _rescan();
    await startSync();
  }

  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();

  static const String _kColdStartKey = 'sync_cold_start_done';
  static const String _kAutoSyncEnabledKey = 'auto_sync_enabled';

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

    Set<String>? selectedIds;
    final selectiveOn = prefs.getBool('auto_sync_selected_only') ?? false;
    if (selectiveOn) {
      final list = prefs.getStringList('selected_files') ?? [];
      final cleaned = list.where((id) => id.trim().isNotEmpty).toSet();
      if (cleaned.isNotEmpty) {
        selectedIds = cleaned;
      }
    }

    final scanner = MediaScanner(
      db: _db,
      uploadedKeys: uploadedKeys,
      selectedLocalIds: selectedIds,
    );
    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Scanned: $newItems new items enqueued');

    if (!coldStartDone) {
      await prefs.setBool(_kColdStartKey, true);
    }

    await _emitProgress();
  }

  // FIX 1: Пересканирует галерею без cold-start логики.
  // Вызывается при каждом нажатии "Синхронизировать сейчас".
  Future<void> _rescan() async {
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

    // uploadedKeys = {} т.к. дубли уже есть в локальной БД (status=done)
    _scannedCount = 0;
    final scanner = MediaScanner(
      db: _db,
      uploadedKeys: {},
      selectedLocalIds: selectedIds,
      onProgress: (count) {
        _scannedCount = count;
        _emitScanProgress();
      },
    );
    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Rescan: $newItems new items enqueued');
    await _emitProgress();
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
    _syncSessionId++;
    final sessionId = _syncSessionId;
    _totalInBatch = 0;
    _currentFileName = null;

    // FIX 1: Сбрасываем зависшие uploading -> pending
    // (остались после предыдущего краша/стопа)
    await _db.resetStuckUploading();

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
        final tasks = await _db.getPendingOldestFirst(limit: 10);
        if (tasks.isEmpty) {
          debugPrint('[Sync] No pending tasks, sync complete');
          break;
        }

        _totalInBatch = tasks.length;

        Map<String, bool> duplicateMap;
        try {
          duplicateMap = await galleryService.checkDuplicates(tasks);
        } catch (e) {
          debugPrint('[Sync] Duplicate check failed (uploading all): $e');
          duplicateMap = {};
        }

        for (final task in tasks) {
          if (!_isRunning || sessionId != _syncSessionId) break;
          if (task.id == null) continue;

          final isDuplicate = duplicateMap[task.localId] ?? false;
          if (isDuplicate) {
            await _db.markDone(task.id!, 'duplicate_skipped');
            debugPrint('[Sync] Skipped duplicate: ${task.fileName}');
            await _emitProgress();
            continue;
          }

          final file = File(task.filePath);
          if (!file.existsSync()) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync] File missing, skipped: ${task.filePath}');
            await _emitProgress();
            continue;
          }

          _currentFileName = task.fileName;
          await _db.markUploading(task.id!);
          await _emitProgress(currentProgress: 0.0);

          try {
            final serverUuid = await uploader.upload(
              task,
              folderId: syncFolderUuid,
              onProgress: (progress) {
                _emitProgressSync(currentProgress: progress);
              },
            );
            await _db.markDone(task.id!, serverUuid);
            debugPrint('[Sync] Uploaded: ${task.fileName} -> $serverUuid');
          } on TusUploadException catch (e) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync][ERROR] Upload failed: ${task.fileName} — $e');
          } catch (e) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync][ERROR] Unexpected: ${task.fileName} — $e');
          }

          await _emitProgress();
        }
      }
    } finally {
      _isRunning = false;
      _currentFileName = null;
      await _emitProgress();
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
    ));
  }
}