import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:tus_client/tus_client.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/secure_storage.dart';
import 'sync_task.dart';

class TusUploadException implements Exception {
  final String message;
  TusUploadException(this.message);

  @override
  String toString() => 'TusUploadException: $message';
}

/// Кидается когда загрузку прервали вручную через [TusSyncUploader.requestAbort]
/// (пауза или отмена конкретного файла) — отличать от реальной сетевой ошибки,
/// чтобы вызывающий код не увёл файл в failed/retry.
class TusUploadAbortedException implements Exception {
  final bool isCancel;
  TusUploadAbortedException({required this.isCancel});

  @override
  String toString() => 'TusUploadAbortedException(isCancel: $isCancel)';
}

/// Disk-based TUS store for resumable uploads (matches upload_repository.dart pattern).
class _SyncTusDiskStore extends TusStore {
  final Directory _dir;
  _SyncTusDiskStore(this._dir);

  String _keyFile(String fingerprint) => p.join(
        _dir.path,
        '${fingerprint.replaceAll(RegExp(r'[^\w]'), '_')}.tusurl',
      );

  @override
  Future<Uri?> get(String fingerprint) async {
    try {
      final f = File(_keyFile(fingerprint));
      if (!await f.exists()) return null;
      final url = await f.readAsString();
      return Uri.tryParse(url);
    } catch (e) {
      if (kDebugMode) debugPrint('[TusUploader] disk store get failed: $e');
      return null;
    }
  }

  @override
  Future<void> set(String fingerprint, Uri url) async {
    try {
      await File(_keyFile(fingerprint)).writeAsString(url.toString());
    } catch (e) {
      if (kDebugMode) debugPrint('[TusUploader] disk store set failed: $e');
    }
  }

  @override
  Future<void> remove(String fingerprint) async {
    try {
      final f = File(_keyFile(fingerprint));
      if (await f.exists()) await f.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[TusUploader] disk store remove failed: $e');
    }
  }
}

class TusSyncUploader {
  TusSyncUploader();

  // Заливка всегда идёт строго последовательно (один файл за раз, см.
  // AutoSyncService), поэтому активный клиент — ровно один, отдельный
  // registry по task id не нужен.
  TusClient? _activeClient;
  bool _abortIsCancel = false;

  /// Прерывает текущую активную заливку, если она есть — иначе no-op.
  /// [isCancel]=false — пауза (resumable state в сторе остаётся, следующая
  /// заливка этого файла продолжится с того же байтового оффсета).
  /// [isCancel]=true — отмена (resumable state будет вычищен внутри
  /// [upload] после того как заливка фактически остановится).
  void requestAbort({required bool isCancel}) {
    final client = _activeClient;
    if (client == null) return;
    _abortIsCancel = isCancel;
    client.pause();
  }

  /// Uploads a file via TUS protocol and returns the server UUID
  /// extracted from the upload URL.
  /// [folderId] — if provided, the file will be placed into this folder
  /// via TUS metadata (matches upload_repository.dart pattern).
  Future<String> upload(
    SyncTask task, {
    String? folderId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(task.filePath);
      if (!file.existsSync()) {
        throw TusUploadException('File not found: ${task.filePath}');
      }

      // Fresh token on every upload — matches UploadRepository pattern.
      // Prevents 400 from stale/expired tokens during long batch runs.
      final token = await SecureStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw TusUploadException('No auth token available');
      }

      final userId = await SecureStorage.getUserId();
      if (userId == null) {
        throw TusUploadException('No valid user ID found for upload');
      }

      debugPrint('[Sync] Uploading file → ${task.fileName}');

      final xFile = XFile(task.filePath);
      final mimeType =
          lookupMimeType(task.fileName) ?? 'application/octet-stream';

      final metadata = {
        'filename': task.fileName,
        'filetype': mimeType,
        'owner': userId,
        if (folderId != null) 'folder_id': folderId,
      };

      final tempDir = await getTemporaryDirectory();
      final tusDir = Directory(p.join(tempDir.path, 'tus_sync_uploads'));
      if (!tusDir.existsSync()) tusDir.createSync(recursive: true);
      final store = _SyncTusDiskStore(tusDir);

      final tusUrl = AppConfig.instance.tusUrl;
      final client = TusClient(
        Uri.parse(tusUrl),
        xFile,
        store: store,
        headers: {'Authorization': 'Bearer $token'},
        metadata: metadata,
        maxChunkSize: 512 * 1024,
      );

      _activeClient = client;
      bool completed = false;
      try {
        await client.upload(
          onProgress: (double progress) {
            onProgress?.call((progress / 100.0).clamp(0.0, 1.0));
          },
          onComplete: () {
            completed = true;
            debugPrint('[TusSyncUploader] Upload complete for ${task.fileName}');
          },
        );
      } finally {
        _activeClient = null;
      }

      // client.upload() возвращается без исключения и без onComplete
      // ровно в одном случае — client.pause() был вызван снаружи через
      // requestAbort (см. TusClient.upload источник: цикл может выйти
      // только по _pauseUpload либо по завершению, других return нет).
      if (!completed) {
        final isCancel = _abortIsCancel;
        _abortIsCancel = false;
        if (isCancel) {
          // Чистим resumable-URL — следующая заливка этого файла должна
          // начаться с нуля, а не резюмиться на отменённый upload.
          await store.remove(client.fingerprint);
          debugPrint('[Sync] Upload cancelled by user: ${task.fileName}');
        } else {
          debugPrint('[Sync] Upload paused by user: ${task.fileName}');
        }
        throw TusUploadAbortedException(isCancel: isCancel);
      }

      final uploadUrl = client.uploadUrl?.toString();

      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw TusUploadException(
            'Upload completed but no URL returned for ${task.fileName}');
      }

      final uri = Uri.parse(uploadUrl);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) {
        throw TusUploadException(
            'Cannot extract UUID from upload URL: $uploadUrl');
      }
      final serverUuid = segments.last;

      if (serverUuid.isEmpty) {
        throw TusUploadException(
            'Extracted empty UUID from upload URL: $uploadUrl');
      }

      debugPrint('[Sync] Uploaded → ${task.fileName}, folder=$folderId, uuid=$serverUuid');
      return serverUuid;
    } on TusUploadAbortedException {
      rethrow;
    } on TusUploadException {
      rethrow;
    } catch (e) {
      throw TusUploadException('Upload failed for ${task.fileName}: $e');
    }
  }
}
