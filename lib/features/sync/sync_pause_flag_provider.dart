import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while UploadSyncCoordinator has paused AutoSyncService to run a
/// manual upload batch (see upload_sync_coordinator.dart). Purely
/// presentational — lets SyncStatusBubble tell this apart from a user-paused
/// sync. In-memory only: resets to false on cold start, so an app kill
/// mid-pause can never leave a stale "still paused" value behind.
///
/// Lives in its own file (not sync_providers.dart) so AutoSyncService can
/// import it without pulling in autoSyncServiceProvider — that would be a
/// circular import (sync_providers.dart -> auto_sync_service.dart).
final isSyncPausedBySystemProvider = StateProvider<bool>((ref) => false);
