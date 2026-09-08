import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_app/core/services/main_page_visibility_observer.dart';
import 'package:cloud_app/core/storage/secure_storage.dart';
import 'package:cloud_app/features/home/presentation/main_page.dart';
import 'package:cloud_app/l10n/app_localizations.dart';

import '../../data/sync_task.dart';
import '../../domain/sync_facade.dart';
import '../../sync_progress.dart';
import '../../sync_providers.dart';

// Upload FAB на FilesPage (files_page.dart, _buildFABs()) — стандартный
// endFloat: 56×56, отступ от края Scaffold'а 16px. Используется, чтобы
// развёрнутый попап синка не перекрывал его, когда MainPage на вершине стека.
const double _kFabSize = 56;
const double _kFabMargin = 16;

const _kSyncBlue = Color(0xFF1A73E8);

enum _BubbleView { collapsed, expanded }

/// Плавающая таблетка/попап статуса синка. Живёт поверх всего [MainPage]
/// (см. main_page.dart) — видна на любой вкладке, пока в очереди есть
/// активность. Ничего не решает сама — вся логика паузы/отмены/очереди
/// уже в AutoSyncService, здесь только UI поверх syncRepositoryProvider.
class SyncStatusBubble extends ConsumerStatefulWidget {
  const SyncStatusBubble({super.key});

  @override
  ConsumerState<SyncStatusBubble> createState() => _SyncStatusBubbleState();
}

class _SyncStatusBubbleState extends ConsumerState<SyncStatusBubble> {
  _BubbleView _view = _BubbleView.collapsed;
  // Сессия, на которой юзер нажал "x". Пока repo.sessionId не изменится
  // (новый синк/пауза/рестарт — всё это бампает sessionId) — таблетка
  // скрыта. Как только сессия сменилась — условие ниже само перестаёт
  // совпадать, отдельного сброса не требуется.
  int? _hiddenAtSession;

  // Throttle: ref.listenManual копит последний progress в поле без
  // ребилда на каждый emit (при TUS-чанках это сотни emit за файл);
  // отдельный Timer раз в 200мс подтягивает накопленное значение в UI.
  SyncProgress _progress = const SyncProgress();
  Timer? _throttleTimer;
  ProviderSubscription<AsyncValue<SyncProgress>>? _progressSub;

  // Reentrancy-guard на время сброса очереди — тот же паттерн, что
  // _isResetting в auto_sync_settings_page.dart. Живёт здесь, а не в
  // попапе: onLogout() внутри сброса эмитит пустой SyncProgress, и без
  // этого флага gate hasActivity ниже спрятал бы всю таблетку (и
  // размонтировал попап) на весь initialize()-рескан.
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _progressSub = ref.listenManual<AsyncValue<SyncProgress>>(
      syncProgressProvider,
      (previous, next) => _progress = next.valueOrNull ?? const SyncProgress(),
      fireImmediately: true,
    );
    _throttleTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _progressSub?.close();
    super.dispose();
  }


  // Точная копия последовательности _resetQueue() из
  // auto_sync_settings_page.dart: stopSync() → onLogout() → initialize().
  // stopSync() перед onLogout() выглядит избыточным (onLogout сам обрывает
  // заливку и бампает sessionId), но оставлен намеренно — полный паритет
  // с кнопкой "Сбросить очередь" на странице настроек.
  Future<void> _resetQueue() async {
    if (_isResetting) return;
    if (mounted) setState(() => _isResetting = true);
    try {
      final repo = ref.read(syncRepositoryProvider);
      await repo.stopSync();
      await repo.onLogout();
      await repo.initialize();
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Пока открыт модальный диалог, прячем таблетку через Offstage ниже
    // (не размонтируя её): сырой OverlayEntry всегда всплывает выше барьера,
    // иначе попап перекрывает AlertDialog и его кнопки остаются кликабельными.
    final isModalDialogOpen = ref.watch(isModalDialogOpenProvider);

    final progress = _progress;
    final repo = ref.watch(syncRepositoryProvider);

    final hasActivity = repo.isRunning ||
        repo.isScanning ||
        progress.pending > 0 ||
        progress.uploading > 0 ||
        // Только ретраящиеся failed: если все failed терминальные (исчерпали
        // попытки), таблетка не должна висеть вечно. Общий progress.failed
        // всё равно показывается внутри попапа, пока она видна.
        progress.retryableFailed > 0 ||
        progress.paused > 0 ||
        progress.cancelled > 0;
    final isLoggedIn = SecureStorage.hasCachedAccessToken;
    // _isResetting держит таблетку видимой на время сброса — см. поле.
    if (!isLoggedIn || (!hasActivity && !_isResetting)) {
      return const SizedBox.shrink();
    }

    final hiddenByUser =
        _hiddenAtSession != null && _hiddenAtSession == repo.sessionId;
    if (hiddenByUser) return const SizedBox.shrink();

    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final isMainTopmost = ref.watch(isMainPageTopmostProvider);
    final isFilesTabActive = ref.watch(isFilesTabActiveProvider);
    final navBarHeight = ref.watch(bottomNavBarHeightProvider);

    // На MainPage: только Files-таб держит Upload FAB в этом углу — там
    // компенсация FAB-размера; остальные табы (Home/Shared/Profile) — просто
    // выше нав-бара. На любой другой странице (включая UploadPage) — просто
    // safe area + отступ, без page-specific компенсации.
    final bottomInset = (isMainTopmost && isFilesTabActive)
        ? safeAreaBottom + navBarHeight + _kFabSize + _kFabMargin + 16
        : isMainTopmost
            ? safeAreaBottom + navBarHeight + 16
            : safeAreaBottom + 16;

    // Offstage внутри Positioned, а не снаружи: Positioned обязан остаться
    // прямым child'ом Stack'а оверлея (иначе ParentDataWidget-ассерт).
    return Positioned(
      right: 16,
      bottom: bottomInset,
      child: Offstage(
        offstage: isModalDialogOpen,
        child: _view == _BubbleView.collapsed
            ? _CollapsedPill(
                progress: progress,
                onTap: () => setState(() => _view = _BubbleView.expanded),
              )
            : _ExpandedPopup(
                progress: progress,
                isResetting: _isResetting,
                onReset: _resetQueue,
                onMinimize: () => setState(() => _view = _BubbleView.collapsed),
                onClose: () => setState(() {
                  _hiddenAtSession = repo.sessionId;
                  _view = _BubbleView.collapsed;
                }),
              ),
      ),
    );
  }
}

class _CollapsedPill extends StatelessWidget {
  final SyncProgress progress;
  final VoidCallback onTap;

  const _CollapsedPill({required this.progress, required this.onTap});

  // База 100% — размер очереди (всё, что должно синкнуться), а не вся
  // галерея устройства: при выборочном синке deviceTotal завышал старт.
  double get _percent {
    final queueTotal =
        progress.pending + progress.uploading + progress.done + progress.failed;
    return queueTotal == 0
        ? 0.0
        : (progress.done / queueTotal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kSyncBlue,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: _percent,
                  strokeWidth: 2.5,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_percent * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedPopup extends ConsumerStatefulWidget {
  final SyncProgress progress;
  // Сброс очереди живёт в родителе (_SyncStatusBubbleState) — он
  // переживает скрытие таблетки, попап — нет.
  final bool isResetting;
  final VoidCallback onReset;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const _ExpandedPopup({
    required this.progress,
    required this.isResetting,
    required this.onReset,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  ConsumerState<_ExpandedPopup> createState() => _ExpandedPopupState();
}

class _ExpandedPopupState extends ConsumerState<_ExpandedPopup> {
  // Загружаем окно из первых N задач очереди (порядок = порядок реальной
  // заливки) — не всю очередь целиком, чтобы не тащить тысячи строк в
  // память/на экран разом. Полная пагинация — не в этом заходе.
  static const _pageSize = 60;

  List<SyncTask> _items = [];
  bool _loading = true;
  String? _lastSignature;

  @override
  void initState() {
    super.initState();
    _lastSignature = _signature(widget.progress);
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _ExpandedPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sig = _signature(widget.progress);
    // Перезапрашиваем только когда реально изменились статусы/счётчики —
    // не на каждый tick прогресса текущего файла (тот приходит отдельно,
    // через widget.progress.currentFileProgress, без похода в БД).
    if (sig != _lastSignature) {
      _lastSignature = sig;
      _refresh();
    } else if (oldWidget.isResetting && !widget.isResetting) {
      // Сброс завершился, но счётчики совпали с прежними (те же файлы
      // после рескана) — список всё равно надо перечитать: строки новые.
      _refresh();
    }
  }

  String _signature(SyncProgress p) =>
      '${p.pending}|${p.uploading}|${p.done}|${p.failed}|${p.paused}|${p.cancelled}|${p.currentFileName}';

  Future<void> _refresh() async {
    final repo = ref.read(syncRepositoryProvider);
    final items = await repo.getQueueItems(limit: _pageSize);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  // Внутренние подтверждения (Cancel All / Reset Queue)
  // Показываются НАД списком внутри карточки попапа, гарантируя корректный Z-index на iOS и Android
  bool _showCancelConfirm = false;
  bool _showResetConfirm = false;

  void _onCancelAllPressed() {
    setState(() {
      _showCancelConfirm = true;
      _showResetConfirm = false;
    });
  }

  void _onResetPressed() {
    setState(() {
      _showResetConfirm = true;
      _showCancelConfirm = false;
    });
  }

  void _dismissConfirm() {
    if (_showCancelConfirm || _showResetConfirm) {
      setState(() {
        _showCancelConfirm = false;
        _showResetConfirm = false;
      });
    }
  }

  Future<void> _executeCancelAll(SyncFacade repo) async {
    _dismissConfirm();
    await repo.cancelAllPending();
    await _refresh();
  }

  Future<void> _executeReset() async {
    _dismissConfirm();
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final repo = ref.watch(syncRepositoryProvider);
    final p = widget.progress;
    // Синк стоит на паузе не из-за юзера, а потому что сейчас идёт ручная
    // заливка (UploadSyncCoordinator, upload_sync_coordinator.dart) — это
    // временно и само пройдёт, поэтому кнопка паузы/резюма здесь неприменима.
    final pausedBySystem = ref.watch(isSyncPausedBySystemProvider);

    final width =
        (MediaQuery.of(context).size.width * 0.82).clamp(280.0, 360.0);
    // База 100% — размер очереди, не deviceTotal (см. _CollapsedPill._percent).
    final queueTotal = p.pending + p.uploading + p.done + p.failed;
    final total = queueTotal;
    final displayedSynced = p.done;
    final overallPercent =
        queueTotal == 0 ? 0.0 : (p.done / queueTotal).clamp(0.0, 1.0);
    final isSyncing = repo.isRunning || repo.isScanning;
    // Список ограничен _pageSize и упорядочен так, что done-строки могут
    // вообще не попасть в окно, пока хватает активных. Честно показываем
    // "N из M": M — точный размер очереди по всей БД из SyncProgress
    // (getStatusCounts()), N — сколько строк реально отрисовано.
    final queueRowsTotal =
        p.pending + p.uploading + p.done + p.failed + p.paused + p.cancelled;
    final showPartialNote =
        !_loading && _items.isNotEmpty && _items.length < queueRowsTotal;

    final cancellableCount = p.pending + p.uploading + p.paused;

    return Material(
      color: Colors.transparent,
      child: Container(
      width: width,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.syncBubbleTitle,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pausedBySystem
                                  ? t.syncPausedDuringUpload
                                  : t.syncBubbleSummary(
                                      p.uploading, p.pending, p.done),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_rounded),
                        onPressed: widget.onMinimize,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: widget.onClose,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: overallPercent,
                            minHeight: 5,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation(_kSyncBlue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t.syncQueueFraction(displayedSynced, total),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      // Все failed (ретраящиеся + терминальные) — тот же стиль,
                      // что у failed-строки в _QueueRow.
                      if (p.failed > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          t.syncFailedCount(p.failed),
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: pausedBySystem
                              ? null
                              : () =>
                                  isSyncing ? repo.stopSync() : repo.startSync(),
                          icon: Icon(
                            isSyncing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(
                            isSyncing ? t.syncPauseAllButton : t.syncResumeAllButton,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _items.isEmpty ? null : _onCancelAllPressed,
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Colors.red),
                          label: Text(
                            t.syncCancelAllButton,
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Как Reset на странице настроек: без gate'ов на
                      // _items.isEmpty / pausedBySystem — только reentrancy.
                      Expanded(
                        child: TextButton.icon(
                          onPressed: widget.isResetting ? null : _onResetPressed,
                          icon: const Icon(Icons.restart_alt_rounded,
                              size: 18, color: Colors.red),
                          label: Text(
                            t.syncResetButton,
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
                Flexible(
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : _items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                t.syncStatusComplete,
                                style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.5)),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: Platform.isIOS
                                  ? const BouncingScrollPhysics()
                                  : const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: cs.outlineVariant.withValues(alpha: 0.25),
                              ),
                              itemBuilder: (context, index) {
                                final task = _items[index];
                                return _QueueRow(
                                  task: task,
                                  liveProgress: p.currentFileProgress,
                                  onPause: () => repo.pauseTask(task.id!),
                                  onCancel: () => repo.cancelTask(task.id!),
                                  onRestore: () => repo.resumeTask(task.id!),
                                );
                              },
                            ),
                ),
                if (showPartialNote) ...[
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.25),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      t.syncQueueShowingPartial(_items.length, queueRowsTotal),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Слой подтверждения (Z-index всегда НАД содержимым попапа)
            if (_showCancelConfirm || _showResetConfirm)
              Positioned.fill(
                child: Container(
                  color: cs.surface.withValues(alpha: 0.95),
                  padding: const EdgeInsets.all(18),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _showCancelConfirm
                                  ? Icons.close_rounded
                                  : Icons.restart_alt_rounded,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _showCancelConfirm
                                ? t.syncCancelAllConfirmTitle
                                : t.syncResetConfirmTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showCancelConfirm
                                ? t.syncCancelAllConfirmMessage(cancellableCount)
                                : t.syncResetConfirmMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _dismissConfirm,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: Text(t.cancel),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showCancelConfirm
                                      ? _executeCancelAll(repo)
                                      : _executeReset(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: Text(
                                    _showCancelConfirm
                                        ? t.syncCancelAllConfirmButton
                                        : t.syncResetConfirmButton,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final SyncTask task;
  final double liveProgress;
  final VoidCallback onPause;
  final VoidCallback onCancel;
  final VoidCallback onRestore;

  const _QueueRow({
    required this.task,
    required this.liveProgress,
    required this.onPause,
    required this.onCancel,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isUploading = task.status == SyncStatus.uploading;
    final isPaused = task.status == SyncStatus.paused;
    final isCancelled = task.status == SyncStatus.cancelled;
    final isDone = task.status == SyncStatus.done;
    final isFailed = task.status == SyncStatus.failed;
    // done/failed — только для просмотра, без ручных действий: done уже
    // завершён, failed уже ретраится автоматически по backoff.
    final isReadOnly = isDone || isFailed;

    final nameColor =
        isCancelled ? cs.onSurface.withValues(alpha: 0.38) : cs.onSurface;

    return Opacity(
      opacity: isCancelled ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: nameColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Пауза — только у активно грузящегося файла. У остальных
                // (pending) — только отмена. paused/cancelled — иконка
                // восстановления вместо паузы. done/failed — без кнопок.
                if (isUploading)
                  _RowIconButton(icon: Icons.pause_rounded, onTap: onPause)
                else if (isPaused)
                  _RowIconButton(
                    icon: Icons.play_arrow_rounded,
                    onTap: onRestore,
                    color: _kSyncBlue,
                  )
                else if (isCancelled)
                  _RowIconButton(
                    icon: Icons.restore_rounded,
                    onTap: onRestore,
                    color: _kSyncBlue,
                  ),
                if (!isCancelled && !isReadOnly) ...[
                  const SizedBox(width: 4),
                  _RowIconButton(
                    icon: Icons.close_rounded,
                    onTap: onCancel,
                    color: Colors.red,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            if (isUploading)
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: liveProgress.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation(_kSyncBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(liveProgress.clamp(0.0, 1.0) * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kSyncBlue,
                    ),
                  ),
                ],
              )
            else
              Text(
                isDone
                    ? t.syncStatusDone
                    : isFailed
                        ? t.syncStatusFailed
                        : isPaused
                            ? t.syncQueueItemPaused
                            : isCancelled
                                ? t.syncQueueItemCancelled
                                : t.syncQueueItemPending,
                style: TextStyle(
                  fontSize: 11,
                  color: isDone
                      ? Colors.green
                      : isFailed
                          ? Colors.red
                          : isPaused
                              ? Colors.orange
                              : isCancelled
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _RowIconButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurface.withValues(alpha: 0.6);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: effectiveColor),
      ),
    );
  }
}
