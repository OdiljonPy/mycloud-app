import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'sync_task.dart';

class SyncQueueDb {
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'sync_queue.db');
      _db = await openDatabase(
        path,
        version: 5,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              local_id TEXT UNIQUE NOT NULL,
              file_path TEXT NOT NULL,
              file_name TEXT NOT NULL,
              file_size INTEGER NOT NULL,
              mime_type TEXT NOT NULL,
              sha256 TEXT,
              session_id TEXT,
              status TEXT NOT NULL DEFAULT 'pending',
              retry_count INTEGER NOT NULL DEFAULT 0,
              server_uuid TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              asset_created_at INTEGER,
              bucket_day TEXT,
              session_uploaded INTEGER NOT NULL DEFAULT 0,
              album_id TEXT
            )
          ''');
          await db.execute('CREATE INDEX idx_name_size_status ON sync_queue (file_name, file_size, status)');
          await db.execute('CREATE INDEX idx_fingerprint_status ON sync_queue (sha256, file_size, mime_type, status)');
          await db.execute('CREATE INDEX idx_status ON sync_queue (status)');
          await db.execute('CREATE INDEX idx_album_status ON sync_queue (album_id, status)');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            try {
              await db.execute('ALTER TABLE sync_queue ADD COLUMN session_id TEXT');
              debugPrint('[SyncQueueDb] Migrated to v2: added session_id column');
            } catch (e) {
              debugPrint('[SyncQueueDb] Migration v2 skipped (column already exists): $e');
            }
          }
          if (oldVersion < 3) {
            try {
              await db.execute('ALTER TABLE sync_queue ADD COLUMN asset_created_at INTEGER');
              await db.execute('ALTER TABLE sync_queue ADD COLUMN bucket_day TEXT');
              await db.execute('ALTER TABLE sync_queue ADD COLUMN session_uploaded INTEGER NOT NULL DEFAULT 0');
              debugPrint('[SyncQueueDb] Migrated to v3: added asset_created_at, bucket_day, session_uploaded');
            } catch (e) {
              debugPrint('[SyncQueueDb] Migration v3 skipped: $e');
            }
          }
          if (oldVersion < 4) {
            try {
              await db.execute('CREATE INDEX IF NOT EXISTS idx_name_size_status ON sync_queue (file_name, file_size, status)');
              await db.execute('CREATE INDEX IF NOT EXISTS idx_fingerprint_status ON sync_queue (sha256, file_size, mime_type, status)');
              await db.execute('CREATE INDEX IF NOT EXISTS idx_status ON sync_queue (status)');
              debugPrint('[SyncQueueDb] Migrated to v4: added deduplication indexes');
            } catch (e) {
              debugPrint('[SyncQueueDb] Migration v4 skipped: $e');
            }
          }
          if (oldVersion < 5) {
            try {
              await db.execute('ALTER TABLE sync_queue ADD COLUMN album_id TEXT');
              await db.execute('CREATE INDEX IF NOT EXISTS idx_album_status ON sync_queue (album_id, status)');
              debugPrint('[SyncQueueDb] Migrated to v5: added album_id column');
            } catch (e) {
              debugPrint('[SyncQueueDb] Migration v5 skipped (column already exists): $e');
            }
          }
        },
      );
      debugPrint('[SyncQueueDb] Database initialized');
    } catch (e) {
      debugPrint('[SyncQueueDb] Failed to initialize database: $e');
      rethrow;
    }
  }

  Database get _database {
    if (_db == null) throw StateError('SyncQueueDb not initialized. Call init() first.');
    return _db!;
  }

  Future<void> insertOrIgnore(SyncTask task) async {
    try {
      await _database.insert('sync_queue', task.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      debugPrint('[SyncQueueDb] insertOrIgnore failed: $e');
    }
  }

  Future<List<SyncTask>> getPending({int limit = 10}) async {
    try {
      final rows = await _database.query('sync_queue', where: 'status = ?', whereArgs: ['pending'], orderBy: 'COALESCE(asset_created_at, created_at) ASC',);
      return rows.map((r) => SyncTask.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[SyncQueueDb] getPending failed: $e');
      return [];
    }
  }

  Future<List<SyncTask>> getPendingOldestFirst({int limit = 10}) async {
    try {
      final rows = await _database.query('sync_queue', where: 'status = ?', whereArgs: ['pending'], orderBy: 'COALESCE(asset_created_at, created_at) ASC', limit: limit);
      return rows.map((r) => SyncTask.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[SyncQueueDb] getPendingOldestFirst failed: $e');
      return [];
    }
  }

  Future<void> markUploading(int id) async {
    try {
      await _database.update('sync_queue', {'status': SyncStatus.uploading.name, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[SyncQueueDb] markUploading failed: $e');
    }
  }

  Future<void> markDone(int id, String serverUuid) async {
    try {
      await _database.update('sync_queue', {'status': SyncStatus.done.name, 'server_uuid': serverUuid, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[SyncQueueDb] markDone failed: $e');
    }
  }

  Future<void> markFailed(int id) async {
    try {
      final current = Sqflite.firstIntValue(
        await _database.rawQuery('SELECT retry_count FROM sync_queue WHERE id = ?', [id]),
      ) ?? 0;
      await _database.update('sync_queue', {
        'status': SyncStatus.failed.name,
        'retry_count': current + 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[SyncQueueDb] markFailed failed: $e');
    }
  }

  Future<bool> isDoneByHash(String sha256) async {
    try {
      final result = await _database.query('sync_queue', where: 'sha256 = ? AND status = ?', whereArgs: [sha256, SyncStatus.done.name], limit: 1);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('[SyncQueueDb] isDoneByHash failed: $e');
      return false;
    }
  }

  Future<bool> exists(String localId) async {
    try {
      final result = await _database.query('sync_queue', where: 'local_id = ?', whereArgs: [localId], limit: 1);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('[SyncQueueDb] exists failed: $e');
      return false;
    }
  }

  Future<Map<String, int>> getStatusCounts() async {
    try {
      final counts = <String, int>{'pending': 0, 'uploading': 0, 'done': 0, 'failed': 0};
      final rows = await _database.rawQuery('SELECT status, COUNT(*) as cnt FROM sync_queue GROUP BY status');
      for (final row in rows) {
        counts[row['status'] as String] = row['cnt'] as int;
      }
      return counts;
    } catch (e) {
      debugPrint('[SyncQueueDb] getStatusCounts failed: $e');
      return {'pending': 0, 'uploading': 0, 'done': 0, 'failed': 0};
    }
  }

  Future<int> countByStatus(String? status, {String? sessionId}) async {
    try {
      final where = <String>[];
      final args = <dynamic>[];
      if (status != null) { where.add('status = ?'); args.add(status); }
      if (sessionId != null) { where.add('session_id = ?'); args.add(sessionId); }
      final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
      final result = await _database.rawQuery('SELECT COUNT(*) as count FROM sync_queue $whereClause', args);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('[SyncQueueDb] countByStatus failed: $e');
      return 0;
    }
  }

  Future<void> reset() async {
    try {
      await _database.delete('sync_queue');
      debugPrint('[SyncQueueDb] Queue reset');
    } catch (e) {
      debugPrint('[SyncQueueDb] reset failed: $e');
    }
  }

  // FIX 1: Сбрасывает задачи со статусом 'uploading' обратно в 'pending'.
  // Нужно при старте новой сессии — после краша/стопа они могли зависнуть.
  Future<void> resetStuckUploading() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final count = await _database.update(
        'sync_queue',
        {'status': SyncStatus.pending.name, 'updated_at': now},
        where: 'status = ?',
        whereArgs: [SyncStatus.uploading.name],
      );
      if (count > 0) {
        debugPrint('[SyncQueueDb] Reset $count stuck uploading tasks to pending');
      }
    } catch (e) {
      debugPrint('[SyncQueueDb] resetStuckUploading failed: $e');
    }
  }

  /// Помечает задачу как done и увеличивает session_uploaded счётчик.
  Future<void> markDoneWithSession(int id, String serverUuid) async {
    try {
      await _database.update('sync_queue', {
        'status': SyncStatus.done.name,
        'server_uuid': serverUuid,
        'session_uploaded': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[SyncQueueDb] markDoneWithSession failed: $e');
    }
  }

  /// Сколько файлов загружено в текущей сессии.
  Future<int> countSessionUploaded() async {
    try {
      final result = await _database.rawQuery(
        'SELECT COUNT(*) as count FROM sync_queue WHERE session_uploaded = 1',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Сбрасывает session_uploaded счётчик при старте новой сессии.
  Future<void> resetSessionCounter() async {
    try {
      await _database.update('sync_queue', {'session_uploaded': 0});
      debugPrint('[SyncQueueDb] Session counter reset');
    } catch (e) {
      debugPrint('[SyncQueueDb] resetSessionCounter failed: $e');
    }
  }

  /// Проверяет есть ли файл с таким же именем и размером
  /// уже помеченный как done в локальной DB.
  Future<bool> isDoneByNameAndSize(String fileName, int fileSize) async {
    try {
      final result = await _database.query(
        'sync_queue',
        where: 'file_name = ? AND file_size = ? AND status = ?',
        whereArgs: [fileName, fileSize, SyncStatus.done.name],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('[SyncQueueDb] isDoneByNameAndSize failed: $e');
      return false;
    }
  }

  /// Проверяет дубликат по SHA256 + размер + MIME-тип.
  /// Точнее чем isDoneByNameAndSize: два файла с одним именем но разным содержимым
  /// не будут считаться дублями.
  Future<bool> isDoneByFingerprint({
    required String sha256,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      final result = await _database.query(
        'sync_queue',
        where: 'sha256 = ? AND file_size = ? AND mime_type = ? AND status = ?',
        whereArgs: [sha256, fileSize, mimeType, SyncStatus.done.name],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('[SyncQueueDb] isDoneByFingerprint failed: $e');
      return false;
    }
  }

  /// Сбрасывает failed задачи обратно в pending по exponential backoff.
  /// retry_count 0 → ждать 1мин, 1 → 5мин, 2 → 30мин. После 3 попыток — не трогать.
  Future<void> resetFailedForRetry() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      const backoffMs = [
        60 * 1000,        // 1 мин
        5 * 60 * 1000,    // 5 мин
        30 * 60 * 1000,   // 30 мин
      ];
      for (int i = 0; i < backoffMs.length; i++) {
        final cutoff = now - backoffMs[i];
        final count = await _database.update(
          'sync_queue',
          {'status': SyncStatus.pending.name, 'updated_at': now},
          where: 'status = ? AND retry_count = ? AND updated_at <= ?',
          whereArgs: [SyncStatus.failed.name, i, cutoff],
        );
        if (count > 0) {
          debugPrint('[SyncQueueDb] Retry: $count задач (retry=$i) → pending');
        }
      }
    } catch (e) {
      debugPrint('[SyncQueueDb] resetFailedForRetry failed: $e');
    }
  }

  /// Удаляет из очереди pending-задачи, чей album_id не входит в текущий
  /// выбор альбомов (либо album_id вообще не проставлен — старые записи
  /// до миграции v5). Вызывается при включении/изменении режима "только
  /// выбранные альбомы", чтобы уже отсканированные, но ещё не загруженные
  /// файлы из других папок гарантированно не улетели на сервер.
  /// done-записи не трогает — история/дедуп остаются целыми.
  Future<int> purgeNonSelectedPending(Set<String> albumIds) async {
    try {
      if (albumIds.isEmpty) {
        return await _database.delete(
          'sync_queue',
          where: 'status = ?',
          whereArgs: [SyncStatus.pending.name],
        );
      }
      final placeholders = List.filled(albumIds.length, '?').join(',');
      final count = await _database.delete(
        'sync_queue',
        where: 'status = ? AND (album_id IS NULL OR album_id NOT IN ($placeholders))',
        whereArgs: [SyncStatus.pending.name, ...albumIds],
      );
      if (count > 0) {
        debugPrint('[SyncQueueDb] Purged $count pending tasks outside selected albums');
      }
      return count;
    } catch (e) {
      debugPrint('[SyncQueueDb] purgeNonSelectedPending failed: $e');
      return 0;
    }
  }

  /// Обновляет file_path и file_size для задачи с size=0.
  /// Вызывается перед checkDuplicates чтобы сервер получил реальные данные.
  Future<void> updatePathAndSize(int id, String filePath, int fileSize) async {
    try {
      await _database.update(
        'sync_queue',
        {
          'file_path': filePath,
          'file_size': fileSize,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[SyncQueueDb] updatePathAndSize failed: $e');
    }
  }
}