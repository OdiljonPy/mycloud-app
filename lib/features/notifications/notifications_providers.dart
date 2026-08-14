import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/notifications_repository.dart';

/// Provides the NotificationsRepository singleton.
/// No codegen — plain Provider (тот же стиль, что sync_providers.dart).
final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

/// Бейдж непрочитанных. UI читает через ref.watch(unreadCountProvider) и
/// AsyncValue.when. Обновляется вызовом ref.invalidate(unreadCountProvider)
/// после mark-read/mark-all-read/delete в NotificationsPage.
final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationsRepositoryProvider).getUnreadCount();
});
