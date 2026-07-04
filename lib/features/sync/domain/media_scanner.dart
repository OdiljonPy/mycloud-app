import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/sync_queue_db.dart';
import '../data/sync_task.dart';

class MediaScanner {
  final SyncQueueDb db;
  final Set<String> uploadedKeys;
  final Set<String>? selectedLocalIds;
  final String? sessionId;
  final void Function(int pending)? onProgress;

  /// Если задан — сканировать только ассеты созданные ПОСЛЕ этого timestamp (мс).
  /// Используется для delta scan. Null = полный scan.
  final int? filterFromMs;

  /// false = не резолвить originFile во время скана (быстрый режим).
  /// _resolveTaskSizes в startSync() доделает это перед загрузкой.
  final bool resolveFiles;

  MediaScanner({
    required this.db,
    required this.uploadedKeys,
    this.selectedLocalIds,
    this.sessionId,
    this.onProgress,
    this.filterFromMs,
    this.resolveFiles = true,
  });

  /// Быстро считает общее кол-во файлов в галерее без сканирования.
  Future<int> countTotal() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return 0;
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
      );
      if (albums.isEmpty) return 0;
      // Берём только "All" альбом чтобы не дублировать
      final allAlbum = albums.firstWhere(
        (a) => a.isAll,
        orElse: () => albums.first,
      );
      return await allAlbum.assetCountAsync;
    } catch (e) {
      debugPrint('[MediaScanner] countTotal failed: \$e');
      return 0;
    }
  }

  /// Scans device gallery, deduplicates, and enqueues new items.
  /// Returns count of newly added pending items.
  Future<int> scanAndEnqueue() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('[MediaScanner] Permission denied');
        return 0;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common, // images + videos
        hasAll: true,
      );

      if (albums.isEmpty) {
        debugPrint('[MediaScanner] No albums found');
        return 0;
      }

      int enqueued = 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final album in albums) {
        final assetCount = await album.assetCountAsync;
        if (assetCount == 0) continue;

        // Load assets in batches of 100 to avoid memory issues
        const batchSize = 100;
        for (int offset = 0; offset < assetCount; offset += batchSize) {
          final remaining = assetCount - offset;
          final count = remaining < batchSize ? remaining : batchSize;
          final assets = await album.getAssetListRange(
            start: offset,
            end: offset + count,
          );

          await Future.delayed(Duration.zero);
          for (final asset in assets) {
            try {
              // Skip if selective sync is on and asset not selected
              if (selectedLocalIds != null &&
                  !selectedLocalIds!.contains(asset.id)) {
                continue;
              }

              // Delta filter: пропускаем если ассет старее watermark
              final assetCreatedMs = asset.createDateTime.millisecondsSinceEpoch;
              if (filterFromMs != null && assetCreatedMs < filterFromMs!) continue;

              // Metadata-only for name/mime — originFile for real size + path
              final name = asset.title ?? '${asset.id}.${asset.type == AssetType.video ? 'mp4' : 'jpg'}';
              final mimeType = _mimeForAsset(asset);

              // bucket_day для группировки
              final bucketDay = '${asset.createDateTime.year.toString().padLeft(4, '0')}'
                  '-${asset.createDateTime.month.toString().padLeft(2, '0')}'
                  '-${asset.createDateTime.day.toString().padLeft(2, '0')}';

              // В быстром режиме (resolveFiles=false) пропускаем IO.
              // _resolveTaskSizes в startSync доделает это перед загрузкой.
              int realSize = 0;
              String resolvedPath = '';
              if (resolveFiles) {
                try {
                  final file = await asset.originFile;
                  if (file != null && file.existsSync()) {
                    realSize = await file.length();
                    resolvedPath = file.path;
                  }
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('[MediaScanner] originFile resolve failed for ${asset.id}: $e');
                  }
                }
              }

              // Skip if already in local DB
              if (await db.exists(asset.id)) continue;

              // Дополнительно: проверка по имени+размеру для случая после logout
              if (realSize > 0) {
                final alreadyDone = await db.isDoneByNameAndSize(name, realSize);
                if (alreadyDone) continue;
              }

              // Key для server-side dedup
              final key = '$name|$realSize';

              // Check if already uploaded to server (cold start dedup)
              if (uploadedKeys.contains(key)) {
                await db.insertOrIgnore(SyncTask(
                  localId: asset.id,
                  filePath: resolvedPath,
                  fileName: name,
                  fileSize: realSize,
                  mimeType: mimeType,
                  sessionId: sessionId,
                  status: SyncStatus.done,
                  assetCreatedAt: assetCreatedMs,
                  bucketDay: bucketDay,
                  createdAt: now,
                  updatedAt: now,
                ));
                continue;
              }

              // Enqueue as pending
              await db.insertOrIgnore(SyncTask(
                localId: asset.id,
                filePath: resolvedPath,
                fileName: name,
                fileSize: realSize,
                mimeType: mimeType,
                sessionId: sessionId,
                status: SyncStatus.pending,
                assetCreatedAt: assetCreatedMs,
                bucketDay: bucketDay,
                createdAt: now,
                updatedAt: now,
              ));
              enqueued++;
              onProgress?.call(enqueued);
            } catch (e) {
              debugPrint('[MediaScanner] Error processing asset ${asset.id}: $e');
            }
          }
        }
      }

      debugPrint('[MediaScanner] Scan complete: $enqueued new items enqueued');
      return enqueued;
    } catch (e) {
      debugPrint('[MediaScanner] scanAndEnqueue failed: $e');
      return 0;
    }
  }

  String _mimeForAsset(AssetEntity asset) {
    switch (asset.type) {
      case AssetType.image:
        return asset.mimeType ?? 'image/jpeg';
      case AssetType.video:
        return asset.mimeType ?? 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
