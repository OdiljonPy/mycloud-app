import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/secure_storage.dart';
import 'data/gallery_service.dart';
import 'data/sync_queue_db.dart';
import 'data/tus_sync_uploader.dart';
import 'domain/media_scanner.dart';
import 'sync_progress.dart';
import '../home/data/home_repository.dart';
import '../home/data/models/folder_model.dart';


class AutoSyncService {

  // FIX 1: startAutoSync теперь всегда пересканирует галерею перед
  // запуском — чтобы новые файлы добавились в очередь (pending > 0).
  Future<void> startAutoSync() async {
    if (_isRunning || _isScanning) {
      debugPrint("[AutoSync] Already running/scanning, skip");
      return;
    }
    // Инвалидируем предыдущую сессию перед новым scan
    _syncSessionId++;
    await _rescan();
    await startSync();
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

    final watermarkMs = prefs.getInt(_kWatermarkKey);
    debugPrint('[AutoSync] Watermark: ${watermarkMs != null ? DateTime.fromMillisecondsSinceEpoch(watermarkMs) : 'none (full scan)'}');

    // Delta scan: только от watermark - 1 день, чтобы не пропустить
    // фото сделанные после закрытия приложения
    final filterFromMs = watermarkMs != null
        ? watermarkMs - const Duration(days: 1).inMilliseconds
        : null;

    final scanner = MediaScanner(
      db: _db,
      uploadedKeys: uploadedKeys,
      selectedLocalIds: selectedIds,
      filterFromMs: filterFromMs,
    );
    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Scanned: $newItems new items enqueued');

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

    // uploadedKeys = {} т.к. дубли уже есть в локальной БД (status=done)
    _scannedCount = 0;
    if (mySession != _syncSessionId) {
      _isScanning = false;
      return;
    }
    final scanner = MediaScanner(
      db: _db,
      uploadedKeys: {},
      selectedLocalIds: selectedIds,
      onProgress: (count) {
        _scannedCount = count;
        _emit(_currentProgress.copyWith(scannedCount: _scannedCount, isScanning: true, sessionUploaded: _sessionUploadedCount));
      },
    );
    final newItems = await scanner.scanAndEnqueue();
    debugPrint('[AutoSync] Rescan: $newItems new items enqueued');
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
    _syncSessionId++;
    final sessionId = _syncSessionId;
    _totalInBatch = 0;
    _currentFileName = null;

    // FIX 1: Сбрасываем зависшие uploading -> pending
    // (остались после предыдущего краша/стопа)
    await _db.resetStuckUploading();
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
        final tasks = await _db.getPendingOldestFirst(limit: 50);
        if (tasks.isEmpty) {
          debugPrint('[Sync] No pending tasks, sync complete');
          break;
        }

        _totalInBatch = tasks.length;

        Map<String, bool> duplicateMap;
        try {
          duplicateMap = await galleryService.checkDuplicates(
            tasks,
            folderId: syncFolderUuid,
          );
        } catch (e) {
          debugPrint('[Sync] Duplicate check failed (uploading all): $e');
          duplicateMap = {};
        }

        for (final task in tasks) {
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
  int _sessionUploadedCount = 0;
  SyncProgress _currentProgress = const SyncProgress();

  void _emit(SyncProgress progress) {
    _currentProgress = progress;
    _progressController.add(progress);
  }

}