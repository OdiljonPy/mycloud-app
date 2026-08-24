import '../data/sync_task.dart';
import '../sync_progress.dart';

/// Abstract interface for sync operations.
/// UI and Notifiers depend on this — never on AutoSyncService directly.
/// AutoSyncService is an implementation detail behind this facade.
abstract class SyncFacade {
  /// Stream of sync progress updates.
  Stream<SyncProgress> get progressStream;

  /// Whether upload is currently running.
  bool get isRunning;

  /// Whether gallery scan is currently running.
  bool get isScanning;

  /// Start full sync: scan gallery + upload pending files.
  Future<void> startAutoSync();

  /// Resume upload only — no gallery rescan.
  /// Used on app restart to continue interrupted uploads.
  Future<void> startSync();

  /// Stop current sync session.
  Future<void> stopSync();

  /// Called on user logout: clears queue and resets cold start flag.
  Future<void> onLogout();

  /// Returns true if auto-sync toggle is enabled in settings.
  Future<bool> isAutoSyncEnabled();

  /// Saves auto-sync toggle state to preferences.
  Future<void> setAutoSyncEnabled(bool enabled);

  /// Initialize service: open DB, run cold start scan if needed.
  Future<void> initialize();

  /// Removes queued-but-not-yet-uploaded files whose album isn't in the
  /// current "selected albums" filter. Call after enabling/changing that
  /// filter so stale full-sync leftovers don't upload in the background.
  Future<void> purgeNonSelectedAlbums();

  /// Pauses the file that is actively uploading right now. No-op for any
  /// other task id (queued-but-not-started files can only be cancelled).
  Future<void> pauseTask(int id);

  /// Cancels a single queued/uploading file. The file itself is left
  /// untouched on device — only removed from the sync queue.
  Future<void> cancelTask(int id);

  /// Re-queues a previously paused or cancelled file (status -> pending).
  Future<void> resumeTask(int id);

  /// Cancels every pending/uploading/paused file in the queue at once.
  /// Done and failed entries are left untouched.
  Future<void> cancelAllPending();

  /// Session id — bumped on startAutoSync/stopSync/onLogout. UI uses this
  /// to know when a manually-hidden status bubble should reappear.
  int get sessionId;

  /// Queue items for the sync status popup (pending/uploading/paused/cancelled).
  Future<List<SyncTask>> getQueueItems({int limit, int offset});
}
