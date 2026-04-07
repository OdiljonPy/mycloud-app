import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auto_sync_service.dart';
import 'sync_progress.dart';

/// Provides the AutoSyncService singleton.
/// No codegen — plain Provider.
final autoSyncServiceProvider = Provider<AutoSyncService>((ref) {
  return AutoSyncService();
});

/// Streams SyncProgress from AutoSyncService.
/// UI watches this — no setState needed.
final syncProgressProvider = StreamProvider<SyncProgress>((ref) {
  return ref.watch(autoSyncServiceProvider).progressStream;
});
