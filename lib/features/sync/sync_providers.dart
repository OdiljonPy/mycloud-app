import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auto_sync_service.dart';
import 'sync_progress.dart';
import 'domain/sync_facade.dart';
import 'data/sync_repository.dart';
import 'application/sync_settings_state.dart';
import 'application/sync_settings_notifier.dart';

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

/// UI and future Notifiers use this provider.
/// Returns SyncFacade — never AutoSyncService directly.
final syncRepositoryProvider = Provider<SyncFacade>((ref) {
  return SyncRepository(ref.watch(autoSyncServiceProvider));
});

/// Manages sync settings preferences state.
/// Use ref.watch(syncSettingsProvider) in UI for reactive reads.
/// Use ref.read(syncSettingsProvider.notifier) for actions.
final syncSettingsProvider =
    NotifierProvider<SyncSettingsNotifier, SyncSettingsState>(
  SyncSettingsNotifier.new,
);

/// Callback: вызывается при login/register для инициализации sync.
/// Передаётся в AuthRepository чтобы не создавать зависимость auth → AutoSyncService.
Future<void> syncOnLoginCallback() async {
  final service = AutoSyncService();
  await service.onLogout();
  // initialize и startAutoSync запускаются в фоне — не блокируют навигацию
  service.initialize().then((_) => service.startAutoSync()).catchError((e) {
    debugPrint('[syncOnLoginCallback] error: $e');
  });
}

/// Callback: вызывается при logout для очистки sync состояния.
Future<void> syncOnLogoutCallback() async {
  await AutoSyncService().onLogout();
}
