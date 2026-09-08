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

  const GalleryFile({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.uploadStatus,
    this.capturedAt,
    this.thumbnailPath,
  });

  bool get isVideo => mimeType.startsWith('video/');

  factory GalleryFile.fromJson(Map<String, dynamic> json) {
    return GalleryFile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? '',
      uploadStatus: json['upload_status'] as String? ?? '',
      capturedAt: json['captured_at'] as String?,
      thumbnailPath: json['thumbnail_path'] as String?,
    );
  }
}

class GalleryPaginatedResponse {
  final List<GalleryFile> results;
  final int count;
  final String? next;

  const GalleryPaginatedResponse({
    required this.results,
    required this.count,
    this.next,
  });
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
  /// Follows `next` across all server-side pages so cold start sees the
  /// full uploaded set, not just page 1.
  Future<Set<String>> getUploadedFileKeys() async {
    try {
      final keys = <String>{};
      String? url = '/content/gallery/';
      while (url != null) {
        final response = await _dio.get(url);
        final data = response.data;
        final List<dynamic> items = data is List ? data : (data['results'] ?? []);
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final name = item['name'] as String? ?? '';
            final size = (item['size'] as num?)?.toInt() ?? 0;
            if (name.isNotEmpty) {
              keys.add('$name|$size');
            }
          }
        }
        url = data is Map<String, dynamic> ? data['next'] as String? : null;
      }
      debugPrint('[GalleryService] Loaded ${keys.length} file keys (all pages)');
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

  /// GET /content/gallery/?page=N&page_size=N
  Future<GalleryPaginatedResponse> getGalleryPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.get(
        '/content/gallery/',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final items = data['results'] as List<dynamic>? ?? [];
        return GalleryPaginatedResponse(
          results: items
              .whereType<Map<String, dynamic>>()
              .map((e) => GalleryFile.fromJson(e))
              .toList(),
          count: (data['count'] as num?)?.toInt() ?? 0,
          next: data['next'] as String?,
        );
      }
      // Non-paginated fallback (API returns plain list)
      final items = data is List ? data : [];
      final files = items
          .whereType<Map<String, dynamic>>()
          .map((e) => GalleryFile.fromJson(e))
          .toList();
      return GalleryPaginatedResponse(
        results: files,
        count: files.length,
        next: null,
      );
    } catch (e) {
      debugPrint('[GalleryService] getGalleryPaginated failed: $e');
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
  /// On error: return null so callers know this check failed and must not
  /// treat absence as confirmed non-duplicate.
  Future<Map<String, bool>?> checkDuplicates(
    List<SyncTask> tasks, {
    String? folderId,
  }) async {
    if (tasks.isEmpty) return {};

    try {
      final uuidToTask = <String, SyncTask>{};
      final filesPayload = tasks.map((task) {
        final id = _deterministicUuid(task.fileName, task.fileSize, task.mimeType);
        uuidToTask[id] = task;
        return {
          'name': task.fileName,
          'size': task.fileSize,
          'type': task.mimeType,
          'uuid': id,
        };
      }).toList();

      debugPrint('[DupCheck] Sending ${filesPayload.length} files to check-duplicate');

      final response = await _dio.post(
        '/content/files/check-duplicate/',
        data: {
          'files': filesPayload,
        },
      );

      // Response: [{"uuid": "uuid-string", "is_duplicate": true/false}]
      final List<dynamic> result = response.data is List
          ? response.data as List<dynamic>
          : [];

      debugPrint('[GalleryService] checkDuplicates raw response: ${result.take(2).toList()}');

      // Map: localTaskId → is_duplicate
      final Map<String, bool> duplicateMap = {};
      for (final item in result) {
        if (item is! Map<String, dynamic>) continue;
        final uuid = item['uuid'] as String? ?? '';
        final isDuplicate = item['is_duplicate'] as bool? ?? false;
        if (uuid.isEmpty) continue;
        if (uuidToTask.containsKey(uuid)) {
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        // Confirmed data-rejection signal (e.g. one file's name is rejected
        // by the backend) — not transient. Rethrow so the caller can bisect
        // the batch instead of skipping everything in it forever.
        rethrow;
      }
      debugPrint('[GalleryService] checkDuplicates failed: $e');
      // On error: return null so callers know this check failed and must
      // not treat absence as confirmed non-duplicate.
      return null;
    } catch (e) {
      debugPrint('[GalleryService] checkDuplicates failed: $e');
      // On error: return null so callers know this check failed and must
      // not treat absence as confirmed non-duplicate.
      return null;
    }
  }
}
