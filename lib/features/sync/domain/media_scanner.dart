import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

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

<<<<<<< HEAD
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
                } catch (_) {}
              }

              // Skip if already in local DB
              if (await db.exists(asset.id)) continue;
=======
              // Delete existing record if any (to allow re-sync)
              if (await db.exists(asset.id)) {
                await db.deleteByLocalId(asset.id);
              }
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")

              // Дополнительно: проверка по имени+размеру для случая после logout
              if (realSize > 0) {
                final alreadyDone = await db.isDoneByNameAndSize(name, realSize);
                if (alreadyDone) continue;
              }

<<<<<<< HEAD
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
=======
              // Get original filename - try multiple sources
              String originalName = asset.title ?? '';
              if (originalName.isEmpty || originalName.contains('/')) {
                // asset.title is null or contains path - extract from file path
                originalName = p.basename(file.path);
              }
              if (originalName.isEmpty) {
                // Last resort: generate filename from timestamp
                final timestamp = asset.createDateTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
                final ext = p.extension(file.path);
                originalName = 'IMG_$timestamp${ext.isEmpty ? '.jpg' : ext}';
              }

              debugPrint('[MediaScanner] 📝 File: $originalName (${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB)');

              // Convert HEIC/HEIF to JPEG if needed
              File finalFile = file;
              String finalName = originalName;
              String finalMimeType = _mimeForAsset(asset);

              if (asset.type == AssetType.image && _isHeicFormat(file.path)) {
                try {
                  final converted = await _convertHeicToJpeg(file, asset.id);
                  if (converted != null) {
                    finalFile = converted;
                    // Replace extension in original filename
                    finalName = originalName.replaceAll(RegExp(r'\.(heic|heif)$', caseSensitive: false), '.jpg');
                    // If no extension was replaced, add .jpg
                    if (finalName == originalName) {
                      finalName = '$originalName.jpg';
                    }
                    finalMimeType = 'image/jpeg';
                    debugPrint('[MediaScanner] ✅ Converted HEIC to JPEG: $originalName -> $finalName');
                  }
                } catch (e) {
                  debugPrint('[MediaScanner] ❌ HEIC conversion failed for ${asset.id}: $e');
                  // Continue with original file if conversion fails
                }
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
              }

              final size = finalFile.lengthSync();

              // Compute hash (optional, for logging/debugging)
              final hash = await _computeHash(asset, finalFile, size);

              // Always enqueue as pending - backend will check duplicates
              await db.insertOrIgnore(SyncTask(
                localId: asset.id,
<<<<<<< HEAD
                filePath: resolvedPath,
                fileName: name,
                fileSize: realSize,
                mimeType: mimeType,
=======
                filePath: finalFile.path,
                fileName: finalName,
                fileSize: size,
                mimeType: finalMimeType,
                sha256: hash,
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
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

  /// Check if file is HEIC/HEIF format
  bool _isHeicFormat(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return ext == '.heic' || ext == '.heif';
  }

  /// Convert HEIC/HEIF to JPEG
  Future<File?> _convertHeicToJpeg(File heicFile, String assetId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        'converted_$assetId.jpg',
      );

      debugPrint('[MediaScanner] Converting HEIC: ${heicFile.path} -> $targetPath');

      final result = await FlutterImageCompress.compressAndGetFile(
        heicFile.path,
        targetPath,
        quality: 90,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        debugPrint('[MediaScanner] HEIC conversion successful: ${result.path}');
        return File(result.path);
      } else {
        debugPrint('[MediaScanner] HEIC conversion returned null');
        return null;
      }
    } catch (e) {
      debugPrint('[MediaScanner] HEIC conversion error: $e');
      return null;
    }
  }
}
