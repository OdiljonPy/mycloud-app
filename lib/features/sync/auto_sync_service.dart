import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
import 'sync_pause_flag_provider.dart';
import '../home/data/home_repository.dart';
import '../home/data/models/folder_model.dart';


class AutoSyncService with WidgetsBindingObserver {

  // Riverpod-контейнер приложения. Нужен только чтобы в lifecycle-resume
  // прочитать isSyncPausedBySystemProvider и не перезапустить автосинк,
  // пока UploadSyncCoordinator держит его на паузе ради ручной загрузки.
  // Null до attachContainer() (или если контекст ещё не готов) — тогда
  // проверка пропускается, поведение как раньше.
  ProviderContainer? _container;

  void attachContainer(ProviderContainer container) {
    _container = container;
  }

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
  static const Duration _syncFolderCacheTtl = Duration(minutes: 2);

  final SyncQueueDb _db = SyncQueueDb();
  // Один инстанс на весь синглтон — заливка последовательная, всегда не
  // больше одного активного TusClient (см. TusSyncUploader.requestAbort).
  final TusSyncUploader _uploader = TusSyncUploader();
  final StreamController<SyncProgress> _progressController =
  StreamController<SyncProgress>.broadcast();

  Stream<SyncProgress> get progressStream => _progressController.stream;
  bool _isRunning = false;
  bool get isRunning => _isRunning;
  bool _isScanning = false;
  bool get isScanning => _isScanning;
  int _syncSessionId = 0;
  // Меняется на startAutoSync/stopSync/onLogout — UI (таблетка синка)
  // сверяется с этим значением, чтобы понять "начался новый синк/пауза/
  // рестарт", и автоматически снять свой ручной hidden-флаг ("x").
  int get sessionId => _syncSessionId;
  bool _settingsChanged = false;
  // id задачи, которая прямо сейчас грузится — pauseTask разрешён только
  // для неё (пауза не имеет смысла для ещё не начатого файла).
  int? _currentUploadingTaskId;
  String? _cachedSyncFolderId;
  DateTime? _cachedSyncFolderResolvedAt;
  bool _lifecycleObserverRegistered = false;
  // Защита от retry-storm: счётчик подряд идущих циклов while в startSync(),
  // в которых checkDuplicates не смог разрезолвить НИ ОДНУ задачу батча
  // (протухший токен / 401 / 5xx / оффлайн — всё, что GalleryService гасит
  // в null). Без него цикл крутился бы вхолостую без задержки (continue по
  // каждой задаче → тот же батч → тот же сбой) до stopSync/logout.
  // Сбрасывается на старте сессии и на любом цикле с успешным резолвом.
  static const int _kMaxConsecutiveDuplicateCheckFailures = 3;
  int _consecutiveDuplicateCheckFailures = 0;

  /// Кэширует id sync-папки на TTL (_syncFolderCacheTtl) — HomeRepository
  /// создаётся заново на каждый вызов (не синглтон), поэтому без кэша
  /// resolveSyncFolder() гонял бы полный постраничный fetch всех папок
  /// на КАЖДЫЙ вызов startSync()/groupTasksByDestinationFolder(). Кэш живёт
  /// в AutoSyncService (синглтон), а не в HomeRepository.
  Future<String> _resolveSyncFolderCached(HomeRepository repo) async {
    final now = DateTime.now();
    if (_cachedSyncFolderId != null &&
        _cachedSyncFolderResolvedAt != null &&
        now.difference(_cachedSyncFolderResolvedAt!) < _syncFolderCacheTtl) {
      debugPrint('[AutoSync] Using cached sync folder id: $_cachedSyncFolderId');
      return _cachedSyncFolderId!;
    }
    final folder = await repo.resolveSyncFolder();
    _cachedSyncFolderId = folder.id;
    _cachedSyncFolderResolvedAt = now;
    return folder.id;
  }

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
      retryableFailed: await _db.getRetryableFailedCount(),
      scannedCount: _scannedCount,
      isScanning: _isScanning,
      currentFileProgress: 0.0,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
    ));

    if (!_lifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
    }
  }

  // Возобновляет автосинк, если ОС "заморозила"/убила процесс синка пока
  // приложение было в фоне — синк не запускался/убился, но настройка
  // auto-sync включена. При сворачивании (paused/inactive) — ничего не
  // делаем намеренно, синк продолжает идти как есть.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_resumeAutoSyncIfNeeded());
    }
  }

  Future<void> _resumeAutoSyncIfNeeded() async {
    final enabled = await isAutoSyncEnabled();
    if (enabled && !_isRunning && !_isScanning) {
      // Автосинк на паузе со стороны системы (UploadSyncCoordinator гоняет
      // ручную загрузку) — не перезапускаем, координатор сам возобновит.
      if (_container?.read(isSyncPausedBySystemProvider) == true) {
        debugPrint("[AutoSync] Resume skipped: paused by system");
        return;
      }
      unawaited(startAutoSync());
    }
  }

  // FIX 1: Пересканирует галерею без cold-start логики.
  // Вызывается при каждом нажатии "Синхронизировать сейчас".
  Future<void> _rescan() async {
    final mySession = _syncSessionId;
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;
    _isScanning = true;

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
        _emit(_currentProgress.copyWith(scannedCount: _scannedCount, isScanning: true));
      },
    );
    try {
      final newItems = await scanner.scanAndEnqueue(
        isCancelled: () => mySession != _syncSessionId,
      );
      debugPrint('[AutoSync] Rescan: $newItems new items enqueued');
      await prefs.setInt(_kWatermarkKey, DateTime.now().millisecondsSinceEpoch);
    } finally {
      // Обязательно сбрасываем даже при исключении внутри scanAndEnqueue —
      // иначе _isScanning зависает в true навсегда и guard в startAutoSync()
      // молча блокирует все последующие синки (и авто, и ручные).
      _isScanning = false;
    }

    final counts = await _db.getStatusCounts();
    _emit(_currentProgress.copyWith(
      pending: counts['pending'] ?? 0,
      uploading: counts['uploading'] ?? 0,
      done: counts['done'] ?? 0,
      failed: counts['failed'] ?? 0,
      retryableFailed: await _db.getRetryableFailedCount(),
      scannedCount: _scannedCount,
      isScanning: _isScanning,
      currentFileProgress: 0.0,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
    ));
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
    _consecutiveDuplicateCheckFailures = 0;

    // Сбрасываем зависшие uploading -> pending (после краша/стопа)
    await _db.resetStuckUploading();
    // Retry failed файлов по backoff: 1мин → 5мин → 30мин (макс 3 попытки)
    await _db.resetFailedForRetry();
    _sessionUploadedCount = 0;

    // Подчищаем орфанные temp-файлы photo_manager, оставшиеся от прошлой
    // сессии, убитой/крашнувшейся до markDoneWithSession по её файлам.
    try {
      await PhotoManager.clearFileCache();
    } catch (e) {
      debugPrint('[Sync] clearFileCache failed (non-critical): $e');
    }

    try {
      final repo = HomeRepository();
      final syncFolderUuid = await _resolveSyncFolderCached(repo);
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

      // TODO(sync-token-refresh): GalleryService создаётся один раз на
      // сессию с токеном, снятым на старте startSync(), и никогда не
      // обновляется. Если access-token протухнет посреди долгой сессии
      // (сотни файлов), checkDuplicates начнёт стабильно падать (401 →
      // null → unresolved) до конца сессии, хотя DioClient уже мог
      // обновить токен для остальных запросов. Отдельная задача: либо
      // перечитывать SecureStorage.getAccessToken() перед каждым
      // checkDuplicates, либо перевести GalleryService на DioClient с
      // общим refresh-interceptor'ом. Здесь НЕ реализовано намеренно —
      // текущий фикс только рвёт бесконечный цикл (см. счётчик ниже).
      final galleryService = GalleryService(
        baseUrl: AppConfig.instance.baseUrl,
        token: token,
      );

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
        final Set<String> skippedTaskIds = {};
        final Set<String> quarantinedTaskIds = {};
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
              final resolved = await _resolveDuplicatesBisecting(
                galleryService,
                entry.value,
                entry.key,
              );
              duplicateMap.addAll(resolved.results);
              skippedTaskIds.addAll(resolved.unresolved);
              quarantinedTaskIds.addAll(resolved.quarantined);
            } catch (e) {
              debugPrint('[Sync] Unexpected error resolving duplicates for folder '
                  '${entry.key}, skipping this cycle: $e');
              skippedTaskIds.addAll(entry.value.map((t) => t.localId));
            }
          }
        } else {
          try {
            final resolved = await _resolveDuplicatesBisecting(
              galleryService,
              resolvedTasks,
              syncFolderUuid,
            );
            duplicateMap = resolved.results;
            skippedTaskIds.addAll(resolved.unresolved);
            quarantinedTaskIds.addAll(resolved.quarantined);
          } catch (e) {
            debugPrint('[Sync] Unexpected error resolving duplicates for folder '
                '$syncFolderUuid, skipping this cycle: $e');
            skippedTaskIds.addAll(resolvedTasks.map((t) => t.localId));
          }
        }

        // Retry-storm guard: если весь батч ушёл в unresolved — прогресса в
        // этом цикле не будет, следующая итерация while возьмёт те же
        // задачи и упрётся в тот же сбой без задержки. После N таких
        // циклов подряд останавливаем сессию тем же путём, что и обычный
        // stopSync() (requestAbort + _isRunning=false + бамп sessionId;
        // финальный emit — в finally ниже). Уже проставленные done/failed
        // строки не трогаем. Частичный сбой (одна папка из нескольких в
        // альбомном режиме) не считается — остальные задачи грузятся,
        // цикл не «тугой».
        final allUnresolved = resolvedTasks.isNotEmpty &&
            resolvedTasks.every((t) => skippedTaskIds.contains(t.localId));
        if (allUnresolved) {
          _consecutiveDuplicateCheckFailures++;
          if (_consecutiveDuplicateCheckFailures >=
              _kMaxConsecutiveDuplicateCheckFailures) {
            debugPrint('[Sync][ERROR] auth/duplicate-check failing repeatedly '
                '($_consecutiveDuplicateCheckFailures cycles in a row, '
                '${resolvedTasks.length} tasks unresolved), stopping session');
            _consecutiveDuplicateCheckFailures = 0;
            await stopSync();
            break;
          }
        } else {
          _consecutiveDuplicateCheckFailures = 0;
        }

        for (final task in resolvedTasks) {
          if (!_isRunning || sessionId != _syncSessionId) break;
          if (task.id == null) continue;
          if (skippedTaskIds.contains(task.localId)) {
            debugPrint('[Sync] Skipping ${task.fileName} — duplicate check failed this cycle, will retry next cycle');
            continue;
          }
          if (quarantinedTaskIds.contains(task.localId)) {
            // Уже помечен markDoneWithoutSessionIncrement(..., 'invalid_rejected_by_server')
            // внутри _resolveDuplicatesBisecting — не даём коду ниже
            // (isDoneByNameAndSize) найти этот же, только что проставленный
            // status=done и перезаписать маркер через обычный dup-skip путь.
            debugPrint('[Sync] Skipping ${task.fileName} — permanently quarantined (server rejected file data)');
            continue;
          }

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
            counts = await _db.getStatusCounts();
            _emit(_currentProgress.copyWith(
              pending: counts['pending'] ?? 0,
              uploading: counts['uploading'] ?? 0,
              done: counts['done'] ?? 0,
              failed: counts['failed'] ?? 0,
              retryableFailed: await _db.getRetryableFailedCount(),
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
                  retryableFailed: await _db.getRetryableFailedCount(),
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
              retryableFailed: await _db.getRetryableFailedCount(),
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
            retryableFailed: await _db.getRetryableFailedCount(),
            scannedCount: _scannedCount,
            isScanning: _isScanning,
            currentFileProgress: 0.0,
            currentFileName: _currentFileName,
            totalInBatch: _totalInBatch,
          ));

          _currentUploadingTaskId = task.id;
          try {
            final uploadTask = resolvedPath != task.filePath
                ? task.copyWith(filePath: resolvedPath)
                : task;

            final serverUuid = await _uploader.upload(
              uploadTask,
              folderId: taskFolderIds[task.id!] ?? syncFolderUuid,
              onProgress: (progress) {
                _emit(_currentProgress.copyWith(currentFileProgress: progress));
              },
            );
            await _db.markDoneWithSession(task.id!, serverUuid);
            _sessionUploadedCount++;
            debugPrint('[Sync] Uploaded: ${task.fileName} -> $serverUuid (session: $_sessionUploadedCount)');
            try {
              if (file.existsSync()) {
                file.deleteSync();
              }
            } catch (e) {
              debugPrint('[Sync] Failed to delete temp file after upload: $resolvedPath — $e');
            }
          } on TusUploadAbortedException catch (e) {
            // Прервано вручную через pauseTask/cancelTask/cancelAllPending —
            // это не ошибка, отдельная ветка, чтобы не улетело в retry/failed.
            if (e.isCancel) {
              await _db.markCancelled(task.id!);
              debugPrint('[Sync] Cancelled by user: ${task.fileName}');
            } else {
              await _db.markPaused(task.id!);
              debugPrint('[Sync] Paused by user: ${task.fileName}');
            }
          } on TusUploadException catch (e) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync][ERROR] Upload failed: ${task.fileName} — $e');
          } catch (e) {
            await _db.markFailed(task.id!);
            debugPrint('[Sync][ERROR] Unexpected: ${task.fileName} — $e');
          } finally {
            _currentUploadingTaskId = null;
          }

          counts = await _db.getStatusCounts();
          _emit(_currentProgress.copyWith(
            pending: counts['pending'] ?? 0,
            uploading: counts['uploading'] ?? 0,
            done: counts['done'] ?? 0,
            failed: counts['failed'] ?? 0,
            retryableFailed: await _db.getRetryableFailedCount(),
            // Единственное место в главном цикле, где статус задачи мог
            // реально стать paused/cancelled (см. catch TusUploadAbortedException
            // выше) — остальные emit-точки в файле эти поля не трогают,
            // copyWith сохраняет последнее известное значение.
            paused: counts['paused'] ?? 0,
            cancelled: counts['cancelled'] ?? 0,
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
        retryableFailed: await _db.getRetryableFailedCount(),
        scannedCount: _scannedCount,
        isScanning: _isScanning,
        currentFileProgress: 0.0,
        currentFileName: _currentFileName,
        totalInBatch: _totalInBatch,
      ));

      // Страховочная очистка temp-файлов photo_manager (originFile/file),
      // оставшихся после failed/paused/cancelled загрузок этого цикла:
      // per-file удаление происходит только после успешного
      // markDoneWithSession, а вызов в начале startSync() чистит их лишь
      // при СЛЕДУЮЩЕМ запуске. Выполняется на любом пути выхода из цикла.
      try {
        await PhotoManager.clearFileCache();
      } catch (e) {
        debugPrint('[Sync] clearFileCache (end of cycle) failed (non-critical): $e');
      }

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

  /// Группирует задачи по итоговой папке назначения на сервере — та же
  /// логика резолва, что startSync() использует для выбора папки на файл
  /// (см. _resolveTargetFolderId), но с полностью локальным кэшем/списком
  /// закреплённых папок на этот вызов: НЕ шарит albumFolderCache/pinnedFolders
  /// с параллельно идущей сессией startSync() — если синк активен прямо
  /// сейчас, у него своя, независимая копия этого состояния в его локальных
  /// переменных, гонок по общему mutable state нет.
  Future<Map<String, List<SyncTask>>> groupTasksByDestinationFolder(
    List<SyncTask> tasks,
  ) async {
    final grouped = <String, List<SyncTask>>{};
    if (tasks.isEmpty) return grouped;

    final repo = HomeRepository();
    final syncFolderUuid = await _resolveSyncFolderCached(repo);

    final prefs = await SharedPreferences.getInstance();
    final selectiveOn = prefs.getBool(_kSelectedOnlyKey) ?? false;

    if (!selectiveOn) {
      grouped[syncFolderUuid] = tasks;
      return grouped;
    }

    List<Map<String, dynamic>> pinnedFolders = [];
    try {
      pinnedFolders = await repo.getPinnedFolders();
    } catch (e) {
      debugPrint('[AutoSync] groupTasksByDestinationFolder: getPinnedFolders failed (non-critical): $e');
    }

    final Map<String, String> albumNames = {};
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );
      for (final a in albums) {
        if (!a.isAll) albumNames[a.id] = a.name;
      }
    } catch (e) {
      debugPrint('[AutoSync] groupTasksByDestinationFolder: failed to load album names: $e');
    }

    final Map<String, String> albumFolderCache = {};

    for (final task in tasks) {
      final folderId = await _resolveTargetFolderId(
        selectiveOn: selectiveOn,
        task: task,
        repo: repo,
        fallbackFolderId: syncFolderUuid,
        albumNames: albumNames,
        albumFolderCache: albumFolderCache,
        pinnedFolders: pinnedFolders,
      );
      grouped.putIfAbsent(folderId, () => []).add(task);
    }

    return grouped;
  }

  /// Резолвит дубликаты для батча, бисектя его при подтверждённом 400 от
  /// сервера (см. GalleryService.checkDuplicates — рвётся наружу только на
  /// 400, всё остальное там же гасится в null). Один плохой файл (сервер
  /// навсегда отклоняет его данные, например имя) раньше отравлял весь
  /// батч из 50 файлов навечно — теперь бисекция изолирует именно его,
  /// карантинит через markDoneWithoutSessionIncrement, а остальные файлы
  /// батча резолвятся нормально. Транзиентные ошибки (не 400) — как и
  /// раньше, весь переданный список уходит в unresolved на этот цикл,
  /// без бисекции (ретраить сетевой таймаут разбиением было бы бессмысленно
  /// и лишний раз бьёт по бэкенду).
  Future<({Map<String, bool> results, Set<String> unresolved, Set<String> quarantined})>
      _resolveDuplicatesBisecting(
    GalleryService galleryService,
    List<SyncTask> tasks,
    String folderId,
  ) async {
    if (tasks.isEmpty) {
      return (results: <String, bool>{}, unresolved: <String>{}, quarantined: <String>{});
    }
    try {
      final result = await galleryService.checkDuplicates(tasks, folderId: folderId);
      if (result != null) {
        return (results: result, unresolved: <String>{}, quarantined: <String>{});
      }
      // Транзиентный сбой (не 400, уже залогирован внутри checkDuplicates) —
      // весь этот под-список остаётся unresolved на следующий цикл.
      return (
        results: <String, bool>{},
        unresolved: tasks.map((t) => t.localId).toSet(),
        quarantined: <String>{},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 400) {
        // В норме сюда не попадаем — checkDuplicates рвётся наружу только
        // на 400 — но на всякий случай: не-400 трактуем как транзиентный.
        return (
          results: <String, bool>{},
          unresolved: tasks.map((t) => t.localId).toSet(),
          quarantined: <String>{},
        );
      }
      if (tasks.length == 1) {
        // Базовый случай: этот единственный файл подтверждённо отклонён
        // сервером — карантинируем навсегда, из очереди исключается.
        // localId идёт в quarantined (а не unresolved/results) — иначе
        // per-task цикл ниже сам же наткнётся на этот только что
        // проставленный status=done через isDoneByNameAndSize (совпадёт
        // сам с собой по имени+размеру) и перезапишет наш маркер через
        // markDoneWithSession(..., 'duplicate_skipped_local_db'), затерев
        // 'invalid_rejected_by_server' и ложно инкрементировав
        // session_uploaded для файла, который на самом деле не грузился.
        final task = tasks.first;
        final quarantinedIds = <String>{};
        if (task.id != null) {
          await _db.markDoneWithoutSessionIncrement(task.id!, 'invalid_rejected_by_server');
          quarantinedIds.add(task.localId);
          debugPrint('[Sync] File permanently rejected by server (400 on '
              'single-item check), quarantined and excluded from future '
              'syncs: ${task.fileName} (id=${task.id})');
        }
        return (results: <String, bool>{}, unresolved: <String>{}, quarantined: quarantinedIds);
      }
      // Больше одного файла всё ещё даёт 400 — бисектим дальше.
      final mid = tasks.length ~/ 2;
      final leftR = await _resolveDuplicatesBisecting(
          galleryService, tasks.sublist(0, mid), folderId);
      final rightR = await _resolveDuplicatesBisecting(
          galleryService, tasks.sublist(mid), folderId);
      return (
        results: {...leftR.results, ...rightR.results},
        unresolved: {...leftR.unresolved, ...rightR.unresolved},
        quarantined: {...leftR.quarantined, ...rightR.quarantined},
      );
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
    _uploader.requestAbort(isCancel: false);
    _isRunning = false;
    _syncSessionId++;
    debugPrint('[AutoSync] Sync stopped (session invalidated)');
  }

  // ─── Управление отдельными задачами (UI: таблетка/попап очереди) ─────────

  Future<void> _emitQueueCounts() async {
    final counts = await _db.getStatusCounts();
    _emit(_currentProgress.copyWith(
      pending: counts['pending'] ?? 0,
      uploading: counts['uploading'] ?? 0,
      done: counts['done'] ?? 0,
      failed: counts['failed'] ?? 0,
      retryableFailed: await _db.getRetryableFailedCount(),
      // Используется cancelTask/resumeTask/cancelAllPending — те самые
      // действия, которые меняют paused/cancelled. Без этого "Отменить
      // всех" не обновлял бы эти счётчики немедленно, и SyncStatusBubble
      // могла бы скрыться раньше, чем следующий per-task emit в главном
      // цикле их подтянет.
      paused: counts['paused'] ?? 0,
      cancelled: counts['cancelled'] ?? 0,
      scannedCount: _scannedCount,
      isScanning: _isScanning,
      currentFileName: _currentFileName,
      totalInBatch: _totalInBatch,
    ));
  }

  /// Публичная обёртка над _emitQueueCounts — для внешних координаторов
  /// (см. UploadSyncCoordinator), которым нужно протолкнуть свежие counts
  /// в progressStream после того как они поменяли статусы задач напрямую
  /// через SyncQueueDb, в обход основного цикла startSync().
  Future<void> refreshQueueCounts() => _emitQueueCounts();

  /// Ставит на паузу текущий активно грузящийся файл. No-op для файла,
  /// который ещё не начал грузиться — пауза применима только к активной
  /// заливке (UI показывает кнопку паузы только у неё).
  Future<void> pauseTask(int id) async {
    if (id != _currentUploadingTaskId) return;
    _uploader.requestAbort(isCancel: false);
  }

  /// Отменяет конкретный файл из очереди — сам файл на устройстве не
  /// трогает. Если это активная заливка — обрывает сеть через
  /// TusClient.pause(); markCancelled применится в startSync() после
  /// того как заливка реально остановится (см. TusUploadAbortedException).
  Future<void> cancelTask(int id) async {
    if (id == _currentUploadingTaskId) {
      _uploader.requestAbort(isCancel: true);
      return;
    }
    await _db.markCancelled(id);
    await _emitQueueCounts();
  }

  /// Возвращает paused/cancelled файл обратно в очередь. Если движок сейчас
  /// простаивает (очередь была пуста, цикл вышел) — перезапускает синк,
  /// иначе файл подхватится уже идущим циклом на следующей итерации.
  Future<void> resumeTask(int id) async {
    await _db.requeueTask(id);
    await _emitQueueCounts();
    if (!_isRunning) {
      unawaited(startAutoSync());
    }
  }

  /// Массовая отмена всей текущей очереди (pending/uploading/paused).
  /// done и failed не трогает. Если что-то грузится прямо сейчас —
  /// дополнительно обрывает сеть, иначе эта запись осталась бы в uploading
  /// до следующего resetStuckUploading вместо cancelled.
  Future<void> cancelAllPending() async {
    if (_currentUploadingTaskId != null) {
      _uploader.requestAbort(isCancel: true);
    }
    await _db.cancelAllPending();
    await _emitQueueCounts();
  }

  /// Список задач для попапа очереди синка — вся история, без фильтра по
  /// статусу: pending/uploading/paused/cancelled/failed и done тоже.
  /// Постранично: [limit] записей (по умолчанию 50) начиная с [offset].
  /// Порядок — как в [SyncQueueDb.getQueueItems]: сначала все НЕ-done по
  /// возрастанию asset_created_at/created_at, done — после, тем же порядком.
  Future<List<SyncTask>> getQueueItems({int limit = 50, int offset = 0}) {
    return _db.getQueueItems(limit: limit, offset: offset);
  }

  Future<void> onLogout() async {
    // Как в stopSync(): обрываем активную TUS-заливку до того, как вайпнем
    // очередь. Иначе in-flight upload дожил бы до конца на токене, зашитом
    // в TusClient.headers (clearTokens его не отзывает), а затем
    // markDoneWithSession ушёл бы в уже несуществующую строку. No-op, если
    // активного клиента нет (см. TusSyncUploader.requestAbort).
    _uploader.requestAbort(isCancel: false);
    _isRunning = false;
    _isScanning = false;
    _syncSessionId++;
    await _db.reset();
    await _clearTusResumableStore();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kColdStartKey);
    await prefs.remove(_kWatermarkKey);
    _cachedSyncFolderId = null;
    _cachedSyncFolderResolvedAt = null;
    debugPrint('[AutoSync] Logout: queue cleared');
    _currentFileName = null;
    _totalInBatch = 0;
    _scannedCount = 0;
    _sessionUploadedCount = 0;
    // Если logout случился, пока UploadSyncCoordinator держал автосинк на
    // паузе ради ручной загрузки — флаг остался бы висеть true после
    // выхода. Без контейнера (attachContainer не вызывали) — пропускаем,
    // как и в lifecycle-resume выше.
    _container?.read(isSyncPausedBySystemProvider.notifier).state = false;
    _emit(const SyncProgress());
  }

  /// Удаляет все .tusurl-файлы resumable-стора TUS (та же директория, что
  /// создаёт TusSyncUploader.upload: <temp>/tus_sync_uploads). После
  /// вайпа sync_queue они орфанные: строк, к которым относятся, уже нет,
  /// а resumable-URL привязаны к сессии старого пользователя. Каждый файл
  /// удаляется отдельно — один сбой не прерывает остальные.
  Future<void> _clearTusResumableStore() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tusDir = Directory(p.join(tempDir.path, 'tus_sync_uploads'));
      if (!await tusDir.exists()) return;
      var removed = 0;
      await for (final entity in tusDir.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          await entity.delete();
          removed++;
        } catch (e) {
          debugPrint('[AutoSync] Logout: failed to delete ${entity.path}: $e');
        }
      }
      debugPrint('[AutoSync] Logout: tus store cleared ($removed files)');
    } catch (e) {
      debugPrint('[AutoSync] Logout: tus store cleanup failed: $e');
    }
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
    // Проталкиваем свежие counts в progressStream сразу: вызов из
    // _setUseSelected (свич включён с уже сохранённым выбором) не ведёт
    // к startAutoSync, и без этого таблетка показывала бы stale pending>0
    // до ближайшего постороннего emit.
    await _emitQueueCounts();
  }

  /// Одноразовое обслуживание очереди при старте: вычищает failed/cancelled
  /// старше 30 дней и, только если что-то удалилось, ужимает файл БД
  /// (VACUUM). done-историю дедупа не трогает. Вызывать fire-and-forget
  /// (см. AppInitializer) — никогда не блокирует старт.
  Future<void> pruneQueueHistory() async {
    try {
      await _db.init();
      final deleted = await _db.pruneOldFailedAndCancelled();
      if (deleted > 0) {
        await _db.vacuum();
      }
    } catch (e) {
      debugPrint('[AutoSync] pruneQueueHistory failed (non-critical): $e');
    }
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