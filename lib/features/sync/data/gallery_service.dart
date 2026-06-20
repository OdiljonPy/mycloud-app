import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'sync_task.dart';

/// Генерирует стабильный UUID из имени файла, размера и типа.
/// Один и тот же файл → всегда один и тот же UUID.
/// Бекенд получает одинаковый UUID при повторных запросах → корректно
/// возвращает is_duplicate: true для уже загруженных файлов.
String _deterministicUuid(String fileName, int fileSize, String mimeType) {
  final input = '$fileName|$fileSize|$mimeType';
  final bytes = utf8.encode(input);
  final hash = sha256.convert(bytes).toString();
  // Форматируем первые 32 символа хеша в UUID формат
  final h = hash.replaceAll('-', '');
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
      '4${h.substring(13, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20, 32)}';
}

class GalleryFile {
  final String id;
  final String name;
  final int size;
  final String mimeType;
  final String uploadStatus;
  final String? capturedAt;
  final String? thumbnailPath;
  final String? previewType;
  final Map<String, dynamic>? previewMeta;

  const GalleryFile({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.uploadStatus,
    this.capturedAt,
    this.thumbnailPath,
    this.previewType,
    this.previewMeta,
  });

  factory GalleryFile.fromJson(Map<String, dynamic> json) {
    return GalleryFile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? '',
      uploadStatus: json['upload_status'] as String? ?? '',
      capturedAt: json['captured_at'] as String?,
      thumbnailPath: json['thumbnail_path'] as String?,
      previewType: json['preview_type'] as String?,
      previewMeta: json['preview_meta'] as Map<String, dynamic>?,
    );
  }

  bool get isVideo => previewType == 'video' || mimeType.startsWith('video/');
  bool get isImage => previewType == 'image' || mimeType.startsWith('image/');
}

class GalleryResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<GalleryFile> results;

  const GalleryResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory GalleryResponse.fromJson(Map<String, dynamic> json) {
    return GalleryResponse(
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => GalleryFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GalleryService {
  final Dio _dio;

  GalleryService({required String baseUrl, required String token})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Authorization': 'Bearer $token'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// GET /content/gallery/
  /// Returns Set<"name|size"> for deduplication during cold start.
  Future<Set<String>> getUploadedFileKeys() async {
    try {
      final response = await _dio.get('/content/gallery/');
      final data = response.data;
      final List<dynamic> items = data is List ? data : (data['result'] ?? []);
      final keys = <String>{};
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final name = item['name'] as String? ?? '';
          final size = (item['size'] as num?)?.toInt() ?? 0;
          if (name.isNotEmpty) {
            keys.add('$name|$size');
          }
        }
      }
      debugPrint('[GalleryService] Loaded ${keys.length} file keys');
      return keys;
    } catch (e) {
      debugPrint('[GalleryService] getUploadedFileKeys failed: $e');
      rethrow;
    }
  }

  /// GET /content/gallery/
  /// Returns full list of gallery files.
  Future<List<GalleryFile>> getGallery() async {
    try {
      final response = await _dio.get('/content/gallery/');
      final data = response.data;
      final List<dynamic> items = data is List ? data : (data['result'] ?? []);
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => GalleryFile.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('[GalleryService] getGallery failed: $e');
      rethrow;
    }
  }

  /// GET /content/gallery/?page=X&page_size=Y
  /// Returns paginated gallery files with next/previous links.
  Future<GalleryResponse> getGalleryPaginated({
    int page = 1,
    int pageSize = 48,
  }) async {
    try {
      final response = await _dio.get(
        '/content/gallery/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      return GalleryResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[GalleryService] getGalleryPaginated failed: $e');
      rethrow;
    }
  }

  /// GET /content/statistics/
  /// Returns raw stats map.
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _dio.get('/content/statistics/');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['result'] as Map<String, dynamic>? ?? data;
      }
      return {};
    } catch (e) {
      debugPrint('[GalleryService] getStatistics failed: $e');
      rethrow;
    }
  }

  /// GET /content/recent-files/?size=N
  Future<List<GalleryFile>> getRecentFiles({int size = 20}) async {
    try {
      final response = await _dio.get(
        '/content/recent-files/',
        queryParameters: {'size': size},
      );
      final data = response.data;
      final List<dynamic> items = data is List ? data : (data['result'] ?? []);
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) => GalleryFile.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('[GalleryService] getRecentFiles failed: $e');
      rethrow;
    }
  }

  /// GET /content/files/{uuid}/download/
  /// uuid must be valid UUID string — integers return 404.
  Future<Map<String, dynamic>> getDownloadInfo(String uuid) async {
    if (uuid.isEmpty) {
      throw ArgumentError('UUID cannot be empty');
    }
    try {
      final response = await _dio.get('/content/files/$uuid/download/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[GalleryService] getDownloadInfo($uuid) failed: $e');
      rethrow;
    }
  }

  /// POST /content/files/check-duplicate/
  /// Returns Map<localTaskId, isDuplicate> for deduplication before upload.
  /// On error returns empty map (safe fallback — upload all).
  Future<Map<String, bool>> checkDuplicates(
    List<SyncTask> tasks, {
    String? folderId,
  }) async {
    if (tasks.isEmpty) return {};

    try {
      // Build request: generate fresh UUID per file for tracking
      final uuidToTask = <String, SyncTask>{};
      final filesPayload = tasks.map((task) {
        final id = _deterministicUuid(task.fileName, task.fileSize, task.mimeType);
        debugPrint('[DupCheck] ${task.fileName} → uuid: $id');
        uuidToTask[id] = task;
        debugPrint('[GalleryService] 🔍 Checking: ${task.fileName} (${task.fileSize} bytes, ${task.mimeType})');
        return {
          'name': task.fileName,
          'size': task.fileSize,
          'type': task.mimeType,
          'uuid': id,
          if (folderId != null) 'folder_id': folderId,
        };
      }).toList();

<<<<<<< HEAD
      debugPrint('[GalleryService] checkDuplicates REQUEST: ${filesPayload.take(2).toList()}');
      debugPrint('[DupCheck] Sending ${filesPayload.length} files to check-duplicate');
      for (final f in filesPayload.take(3)) {
        debugPrint('[DupCheck] file → name: ${f['name']}, size: ${f['size']}, type: ${f['type']}');
      }
=======
      debugPrint('[GalleryService] 📤 Sending ${filesPayload.length} files to check-duplicate API');
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")

      final response = await _dio.post(
        '/content/files/check-duplicate/',
        data: {
          'files': filesPayload,
          if (folderId != null) 'folder_id': folderId,
        },
      );

<<<<<<< HEAD
      // Response: [{"uuid": "uuid-string", "is_duplicate": true/false}]
      final List<dynamic> result = response.data is List
          ? response.data as List<dynamic>
          : [];

      debugPrint('[GalleryService] checkDuplicates raw response: ${result.take(2).toList()}');
=======
      // Response: [{"is_duplicate": true, "uuid": "uuid-string"}]
      final List result = response.data as List;
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")

      // Map: localTaskId → is_duplicate
      final Map<String, bool> duplicateMap = {};
      for (final item in result) {
<<<<<<< HEAD
        if (item is! Map<String, dynamic>) continue;
        final uuid = item['uuid'] as String? ?? '';
        final isDuplicate = item['is_duplicate'] as bool? ?? false;
        if (uuid.isEmpty) continue;
        if (uuidToTask.containsKey(uuid)) {
=======
        final uuid = item['uuid']?.toString();
        final isDuplicate = item['is_duplicate'] as bool? ?? false;
        if (uuid != null && uuidToTask.containsKey(uuid)) {
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
          final task = uuidToTask[uuid]!;
          duplicateMap[task.localId] = isDuplicate;
        }
      }

      final dupCount = duplicateMap.values.where((v) => v).length;
      final notDupCount = duplicateMap.values.where((v) => !v).length;
      debugPrint('[GalleryService] checkDuplicates RESULT: '
          '$dupCount duplicates, $notDupCount new files');
      debugPrint('[GalleryService] checkDuplicates REQUEST sample: '
          '${filesPayload.take(1).toList()}');
      return duplicateMap;
    } catch (e) {
      debugPrint('[GalleryService] checkDuplicates failed: $e');
      return {}; // On error: upload all (safe fallback)
    }
  }
}
