import '../auto_sync_service.dart';
import '../domain/sync_facade.dart';
import '../sync_progress.dart';

/// Concrete implementation of SyncFacade.
/// Delegates everything to AutoSyncService.
/// No logic here — pure delegation.
class SyncRepository implements SyncFacade {
  final AutoSyncService _service;

  const SyncRepository(this._service);

  @override
  Stream<SyncProgress> get progressStream => _service.progressStream;

  @override
  bool get isRunning => _service.isRunning;

  @override
  bool get isScanning => _service.isScanning;

  @override
  Future<void> startAutoSync() => _service.startAutoSync();

  @override
  Future<void> startSync() => _service.startSync();

  @override
  Future<void> stopSync() => _service.stopSync();

  @override
  Future<void> onLogout() => _service.onLogout();

  @override
  Future<bool> isAutoSyncEnabled() => _service.isAutoSyncEnabled();

  @override
  Future<void> setAutoSyncEnabled(bool enabled) =>
      _service.setAutoSyncEnabled(enabled);

  @override
  Future<void> initialize() => _service.initialize();
}
