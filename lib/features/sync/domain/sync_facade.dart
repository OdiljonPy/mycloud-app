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

  /// Активная очередь загрузки (uploading + pending) для глобальной панели.
  Future<List<SyncTask>> getUploadQueue({int limit});

  /// Снимок очереди + суммы байтов для глобальной панели передачи файлов.
  Future<UploadSnapshot> getUploadSnapshot({int limit});
}
