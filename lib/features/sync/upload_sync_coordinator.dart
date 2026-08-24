import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/secure_storage.dart';
import 'auto_sync_service.dart';
import 'data/gallery_service.dart';
import 'data/sync_queue_db.dart';

/// Координирует ручную загрузку (UploadPage) с фоновым AutoSyncService:
/// - ставит автосинк на паузу перед стартом ручного батча, если он бежал;
/// - после завершения батча перепроверяет уже стоящие в очереди
///   pending-файлы на дубликаты (юзер мог только что залить их вручную) —
///   иначе автосинк повторно загрузил бы то же самое;
/// - резюмит автосинк, но только если поставили на паузу сами — если синк
///   уже не бежал (юзер сам остановил / не был включён), чужое состояние
///   не трогаем.
///
/// Не трогает pauseTask/cancelTask/основной цикл AutoSyncService.startSync() —
/// recheck здесь отдельный путь, оперирует SyncQueueDb напрямую.
class UploadSyncCoordinator {
  UploadSyncCoordinator({AutoSyncService? service, SyncQueueDb? db})
      : _service = service ?? AutoSyncService(),
        _db = db ?? SyncQueueDb();

  final AutoSyncService _service;
  final SyncQueueDb _db;

  // Тот же лимит, что неявно использует основной цикл синка
  // (см. AutoSyncService.startSync — getPendingOldestFirst(limit: 50)).
  static const int _dedupBatchSize = 50;

  static const String _duplicateMarker = 'duplicate_skipped_recheck';

  // Пауза применена нами — резюмить можно только если сами и поставили,
  // иначе можно случайно запустить синк, который юзер сам остановил.
  bool _pausedBySystem = false;

  Future<bool> beforeManualUpload() async {
    if (!_service.isRunning) return false;
    await _service.stopSync();
    _pausedBySystem = true;
    return true;
  }

  Future<({int duplicatesSkipped, bool resumed})> afterManualUploadComplete() async {
    final duplicatesSkipped = await _recheckPendingDuplicates();

    final resumed = _pausedBySystem;
    if (_pausedBySystem) {
      _pausedBySystem = false;
      unawaited(_service.startAutoSync());
    }

    return (duplicatesSkipped: duplicatesSkipped, resumed: resumed);
  }

  /// Прогоняет весь текущий pending через check-duplicate батчами по 50 и
  /// помечает найденные дубликаты как done (без инкремента session_uploaded —
  /// см. SyncQueueDb.markDoneWithoutSessionIncrement).
  Future<int> _recheckPendingDuplicates() async {
    var duplicateCount = 0;
    try {
      await _db.init();
      final pending = await _db.getPending();
      if (pending.isEmpty) return 0;

      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) return 0;

      final galleryService = GalleryService(
        baseUrl: AppConfig.instance.baseUrl,
        token: token,
      );

      for (var offset = 0; offset < pending.length; offset += _dedupBatchSize) {
        final end = (offset + _dedupBatchSize < pending.length)
            ? offset + _dedupBatchSize
            : pending.length;
        final batch = pending.sublist(offset, end);

        final duplicateMap = await galleryService.checkDuplicates(batch);
        if (duplicateMap.isEmpty) continue;

        for (final task in batch) {
          if (task.id == null) continue;
          if (duplicateMap[task.localId] == true) {
            await _db.markDoneWithoutSessionIncrement(task.id!, _duplicateMarker);
            duplicateCount++;
            debugPrint('[UploadSyncCoordinator] Recheck duplicate: ${task.fileName}');
          }
        }
      }

      await _service.refreshQueueCounts();
    } catch (e) {
      debugPrint('[UploadSyncCoordinator] recheck failed: $e');
    }
    return duplicateCount;
  }
}
