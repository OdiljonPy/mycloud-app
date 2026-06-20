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
}
