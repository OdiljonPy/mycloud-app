import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/error_localizer.dart';
import '../../sync/sync_providers.dart';
import '../../sync/upload_sync_coordinator.dart';
import '../data/upload_queue_state.dart';
import '../data/upload_repository.dart';
import '../upload_queue_provider.dart';
import '../../../l10n/app_localizations.dart';

class UploadPage extends ConsumerStatefulWidget {
  final String? parentId;
  final VoidCallback? onUploadComplete;
  final List<dynamic>? initialFiles;

  const UploadPage({super.key, this.parentId, this.onUploadComplete, this.initialFiles});

  @override
  ConsumerState<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends ConsumerState<UploadPage> {
  final _repo = UploadRepository();
  late final UploadSyncCoordinator _syncCoordinator;
  bool _isUploading = false;
  bool _allDone = false;
  // Счётчики ТЕКУЩЕГО батча для текста "Загрузка X из Y". Считаются
  // только по элементам, которые были waiting на момент старта батча —
  // done/error/cancelled из прошлых батчей (не очищенные вручную) остаются
  // в списке, но в X/Y не попадают.
  int _currentBatchTotal = 0;
  int _currentBatchProcessed = 0;
  // "Пауза всех" — блокирует старт СЛЕДУЮЩЕГО файла в _startUploadAll,
  // не трогая текущий цикл напрямую (см. проверку в начале for).
  bool _batchPaused = false;
  // Отслеживают жизненный цикл батча для dispose(): резюмим автосинк там
  // только если батч реально стартовал и не успел завершиться сам —
  // иначе либо нечего резюмить, либо это уже сделал normal-path.
  bool _batchStarted = false;
  bool _batchSettled = false;
  // Future текущей заливки файла (см. _startUploadAll) — dispose() дожидается
  // именно её перед резюмом автосинка, чтобы не столкнуть их за сеть.
  Future<void>? _inFlightUpload;
  // Завершается по окончании beforeManualUpload() (успех ИЛИ исключение).
  // dispose() дожидается его перед afterManualUploadComplete(): иначе, если
  // юзер уйдёт со страницы, пока before-хук ещё внутри await (getUserId /
  // stopSync), after-хук отработает ДО того, как координатор выставит
  // _pausedBySystem — и автосинк останется "на паузе системой" навсегда.
  Completer<void>? _beforeHookCompleter;

  @override
  void initState() {
    super.initState();
    // Корневой ProviderContainer (main.dart — один ProviderScope на всё
    // приложение), а не WidgetRef этой страницы: afterManualUploadComplete()
    // может сработать уже после dispose() (см. dispose() ниже), когда
    // WidgetRef этой страницы уже недействителен.
    _syncCoordinator = UploadSyncCoordinator(
      container: ProviderScope.containerOf(context, listen: false),
    );
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialFiles());
    }
  }

  Future<void> _loadInitialFiles() async {
    if (widget.initialFiles == null) return;
    setState(() => _allDone = false);
    final files = <XFile>[];
    for (final f in widget.initialFiles!) {
      if (f.path == null) continue;
      files.add(XFile(f.path!));
    }
    final anyRejected =
        ref.read(uploadQueueProvider.notifier).addFiles(files);
    if (anyRejected) _showUnsupportedFileSnackBar();
    if (ref.read(uploadQueueProvider).isNotEmpty) {
      await _startUploadAll();
    }
  }

  @override
  void dispose() {
    // Юзер ушёл со страницы до allSettled в _startUploadAll() — тот код
    // никогда не выполнится (он под if (mounted)), автосинк рискует
    // остаться на паузе навсегда. Резюмим здесь молча, fire-and-forget:
    // dispose() не может быть async, контекста для SnackBar тоже уже нет.
    if (_batchStarted && !_batchSettled) {
      final beforeHook = _beforeHookCompleter;
      final inFlight = _inFlightUpload;
      unawaited(() async {
        // Сначала — гарантия, что beforeManualUpload() реально отработал
        // (см. комментарий у _beforeHookCompleter), иначе after-хук
        // обгонит выставление _pausedBySystem в координаторе.
        if (beforeHook != null && !beforeHook.isCompleted) {
          await beforeHook.future;
        }
        if (inFlight != null) {
          // Файл всё ещё грузится — дожидаемся его фактического завершения
          // (успех ИЛИ ошибка) прежде чем резюмить автосинк, иначе они на
          // пару секунд столкнутся за сеть.
          try {
            await inFlight;
          } catch (_) {}
        }
        await _syncCoordinator.afterManualUploadComplete();
      }());
    }
    super.dispose();
  }

  void _showUnsupportedFileSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.photosAndVideosOnly)),
    );
  }

  Future<void> _pickFiles() async {
    if (_isUploading) return;

    final picker = ImagePicker();
    final List<XFile> selected = await picker.pickMultipleMedia();

    if (selected.isEmpty) return;

    setState(() => _allDone = false);
    final notifier = ref.read(uploadQueueProvider.notifier);
    final anyRejected = notifier.addFiles(selected);
    if (anyRejected) _showUnsupportedFileSnackBar();

    final queue = ref.read(uploadQueueProvider);
    if (queue.isNotEmpty &&
        queue.any((f) => f.status == UploadFileStatus.waiting) &&
        !_isUploading) {
      await _startUploadAll();
    }
  }

  Future<void> _startUploadAll() async {
    _batchStarted = true;
    // Синхронно с _batchStarted, до первого await — чтобы dispose() уже видел,
    // что before-хук "в процессе", и дождался его.
    final beforeHook = Completer<void>();
    _beforeHookCompleter = beforeHook;
    // Capture folder ID at batch start — in-progress uploads keep their target
    final targetFolderId = widget.parentId;
    final notifier = ref.read(uploadQueueProvider.notifier);

    final String? userId;
    try {
      userId = await SecureStorage.getUserId();
    } catch (_) {
      // Исключение ДО beforeManualUpload() — снимаем ожидание, иначе dispose()
      // повис бы на beforeHook.future навсегда. Саму ошибку не глотаем:
      // она и раньше уходила наружу из _startUploadAll.
      beforeHook.complete();
      rethrow;
    }
    if (userId == null) {
      // До beforeManualUpload() не дошли — снимаем ожидание, иначе dispose()
      // повис бы на beforeHook.future навсегда.
      beforeHook.complete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userNotFound),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _currentBatchProcessed = 0;
      // cancelRequested-элементы цикл ниже переводит в cancelled, не грузя —
      // в знаменатель их не берём, иначе X никогда не дойдёт до Y.
      _currentBatchTotal = ref
          .read(uploadQueueProvider)
          .where((f) => f.status == UploadFileStatus.waiting && !f.cancelRequested)
          .length;
    });

    // Автосинк не должен параллельно грузить фон, пока юзер грузит вручную —
    // иначе оба конкурируют за сеть/TusClient. Резюмится в конце этого
    // метода, но только если поставили на паузу мы сами (см. координатор).
    final bool syncWasPaused;
    try {
      syncWasPaused = await _syncCoordinator.beforeManualUpload();
    } finally {
      // Успех ИЛИ исключение — dispose() в любом случае должен отвиснуть.
      beforeHook.complete();
    }
    if (syncWasPaused && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.syncPausedForManualUpload(ref.read(uploadQueueProvider).length),
          ),
        ),
      );
    }

    // ✅ СТРОГО ПОСЛЕДОВАТЕЛЬНО: await на каждом файле
    // следующий файл начнётся ТОЛЬКО после полного завершения предыдущего
    // Длину/элемент читаем из провайдера на каждой итерации — как и раньше
    // с _queue, отражаем актуальное состояние очереди, а не снимок.
    try {
      for (int i = 0; i < ref.read(uploadQueueProvider).length; i++) {
        // Юзер ушёл со страницы посреди батча — ref больше нельзя трогать,
        // молча прекращаем (не ошибка, dispose() сам резюмит автосинк).
        if (!mounted) break;
        if (_batchPaused) break;
        final item = ref.read(uploadQueueProvider)[i];
        if (item.status != UploadFileStatus.waiting) continue;
        if (item.cancelRequested) {
          notifier.updateItemStatus(item.id, UploadFileStatus.cancelled);
          continue;
        }

        if (mounted) {
          setState(() {
            _currentBatchProcessed++;
            // Элемент стал waiting уже ПОСЛЕ старта батча (restoreFile /
            // resumeAllUploads во время загрузки) и цикл его подхватил —
            // не даём X обогнать Y.
            if (_currentBatchProcessed > _currentBatchTotal) {
              _currentBatchTotal = _currentBatchProcessed;
            }
          });
          notifier.startItem(item.id);
        }

        // Захватываем Future ДО await — если юзер уйдёт со страницы прямо
        // сейчас, dispose() должен дождаться именно этой заливки перед
        // резюмом автосинка (см. dispose()), а не резюмить его параллельно.
        final uploadFuture = _repo.uploadFile(
          file: item.file,
          parentId: targetFolderId,
          userId: userId,
          onProgress: (progress) {
            if (!mounted) return;
            if (item.cancelRequested) return;
            notifier.updateItemProgress(item.id, progress);
          },
          onComplete: () {
            if (!mounted) return;
            notifier.completeItem(item.id);
          },
          onStatusChange: (status) {
            if (!mounted) return;
            if (status == 'paused') {
              notifier.updateItemStatus(item.id, UploadFileStatus.paused);
            } else if (status == 'uploading' || status == 'resumed') {
              notifier.updateItemStatus(item.id, UploadFileStatus.uploading);
            } else if (status == 'pausedByUser') {
              notifier.updateItemStatus(item.id, UploadFileStatus.pausedByUser);
            } else if (status == 'cancelled') {
              notifier.updateItemStatus(item.id, UploadFileStatus.cancelled);
            }
          },
        );
        _inFlightUpload = uploadFuture;
        try {
          // ✅ await здесь — цикл стоит пока этот файл не закончится
          // включая все паузы/resume при потере сети
          await uploadFuture;
        } catch (e) {
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            notifier.failItem(item.id, ErrorLocalizer.forException(e, l10n));
          }
        } finally {
          _inFlightUpload = null;
        }
        // ✅ Только здесь переходим к следующему файлу
      }
    } on StateError catch (e) {
      // Защитный бэкстоп: ref мог "проскочить" mounted-проверку и упасть
      // между ней и самим чтением (гонка кадров). Ведём себя так же, как
      // при обычном mounted == false — просто останавливаем батч.
      debugPrint('[UploadPage] Batch loop stopped after dispose: $e');
    }

    if (mounted) {
      final finalQueue = ref.read(uploadQueueProvider);
      final hasSuccess = finalQueue.any((f) => f.status == UploadFileStatus.done);
      final allSettled = finalQueue.every(
        (f) =>
            f.status == UploadFileStatus.done ||
            f.status == UploadFileStatus.error ||
            f.status == UploadFileStatus.cancelled,
      );

      _batchSettled = allSettled;
      setState(() {
        _isUploading = false;
        _allDone = allSettled;
      });

      // Recheck дедупа + резюм автосинка — при любом ЗАВЕРШЕНИИ батча
      // (done/error/cancelled для всех файлов), не только hasSuccess:
      // onUploadComplete тут не подходит — он не срабатывает, если все
      // файлы ушли в error/cancelled. Гейт именно на allSettled, а не на
      // "цикл дошёл до конца функции" — цикл выходит сюда же и когда юзер
      // просто нажал "Пауза всех" (_batchPaused), а батч по факту не
      // завершён и вот-вот продолжится через _resumeAllUploads — резюмить
      // автосинк в этот момент было бы преждевременно и снова столкнуло
      // бы его с ручной загрузкой за сеть.
      if (allSettled) {
        if (syncWasPaused) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.uploadCheckingDuplicates)),
          );
        }
        unawaited(_syncCoordinator.afterManualUploadComplete().then((result) {
          if (!syncWasPaused || !mounted || !result.resumed) return;
          final message = result.duplicatesSkipped > 0
              ? AppLocalizations.of(context)!.syncResumedWithDuplicates(result.duplicatesSkipped)
              : AppLocalizations.of(context)!.syncResumed;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }));
      }

      if (hasSuccess) {
        HapticFeedback.lightImpact();
        widget.onUploadComplete?.call();
      }
    }
  }

  void _cancelFile(UploadFileItem item) {
    // Активная заливка/пауза-юзера — реально обрываем сеть. Финальный
    // статус 'cancelled' придёт через onStatusChange уже после обрыва —
    // cancelRequested тут намеренно НЕ трогаем: если файл в этот момент
    // как раз успел докачаться (гонка), onComplete должен пометить его
    // done, а не cancelled.
    if (item.status == UploadFileStatus.uploading ||
        item.status == UploadFileStatus.pausedByUser) {
      _repo.requestAbort(isCancel: true);
      return;
    }
    ref.read(uploadQueueProvider.notifier).cancelFile(item);
  }

  // Пауза применима только к активно грузящемуся файлу.
  void _pauseFile(UploadFileItem item) {
    if (item.status != UploadFileStatus.uploading) return;
    _repo.requestAbort(isCancel: false);
  }

  // Возврат в очередь paused-by-user/cancelled файла — единая точка входа
  // для обоих случаев, как и requeueTask на стороне авто-синка.
  void _restoreFile(UploadFileItem item) {
    if (item.status != UploadFileStatus.pausedByUser &&
        item.status != UploadFileStatus.cancelled) {
      return;
    }
    ref.read(uploadQueueProvider.notifier).restoreFile(item);
    setState(() => _allDone = false);
    if (!_isUploading) {
      _startUploadAll();
    }
  }

  void _pauseAllUploads() {
    setState(() => _batchPaused = true);
    // No-op если прямо сейчас ничего не грузится.
    _repo.requestAbort(isCancel: false);
  }

  void _resumeAllUploads() {
    setState(() => _batchPaused = false);
    ref.read(uploadQueueProvider.notifier).resumeAllUploads();
    if (!_isUploading) {
      _startUploadAll();
    }
  }

  Future<void> _cancelAllUploads() async {
    final queue = ref.read(uploadQueueProvider);
    final cancellable = queue
        .where((f) =>
            f.status == UploadFileStatus.waiting ||
            f.status == UploadFileStatus.uploading ||
            f.status == UploadFileStatus.pausedByUser)
        .toList();
    if (cancellable.isEmpty) return;

    final t = AppLocalizations.of(context)!;
    // Скрываем SyncStatusBubble на время диалога: она живёт сырым
    // OverlayEntry в root Overlay и Navigator.rearrange поднимает её
    // поверх барьера. Контроллер берём до await — State может отмонтироваться.
    final dialogFlag = ref.read(isModalDialogOpenProvider.notifier);
    dialogFlag.state = true;
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.syncCancelAllConfirmTitle),
          content: Text(t.syncCancelAllConfirmMessage(cancellable.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                t.syncCancelAllConfirmButton,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } finally {
      dialogFlag.state = false;
    }
    if (confirmed != true || !mounted) return;

    final hasActiveUpload =
        cancellable.any((f) => f.status == UploadFileStatus.uploading);
    if (hasActiveUpload) {
      _repo.requestAbort(isCancel: true);
    }
    // Отмена — не пауза: если что-то останется несделанным, следующий
    // цикл не должен быть заблокирован _batchPaused.
    setState(() => _batchPaused = false);
    ref.read(uploadQueueProvider.notifier).cancelAllUploads(cancellable);
  }

  void _removeFile(UploadFileItem item) {
    if (item.status == UploadFileStatus.uploading ||
        item.status == UploadFileStatus.paused ||
        item.status == UploadFileStatus.pausedByUser) {
      return;
    }
    ref.read(uploadQueueProvider.notifier).removeFile(item);
  }

  void _clearDone() {
    ref.read(uploadQueueProvider.notifier).clearDone();
    setState(() => _allDone = false);
  }

  int _doneCount(List<UploadFileItem> queue) =>
      queue.where((f) => f.status == UploadFileStatus.done).length;
  int _uploadingCount(List<UploadFileItem> queue) =>
      queue.where((f) => f.status == UploadFileStatus.uploading).length;
  int _pausedCount(List<UploadFileItem> queue) =>
      queue.where((f) => f.status == UploadFileStatus.paused).length;

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(uploadQueueProvider);
    final doneCount = _doneCount(queue);
    final uploadingCount = _uploadingCount(queue);
    final pausedCount = _pausedCount(queue);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                AppLocalizations.of(context)!.uploadPageTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              background: Container(color: Colors.transparent),
            ),
            actions: [
              if (queue.isNotEmpty && !_isUploading)
                TextButton(
                  onPressed: _clearDone,
                  child: Text(
                    AppLocalizations.of(context)!.clearDoneButton,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickFiles,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pausedCount > 0
                              ? Colors.orange
                              : _isUploading
                              ? Colors.blue
                              : Colors.blue.withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: pausedCount > 0
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _allDone
                                  ? Icons.check_circle_rounded
                                  : pausedCount > 0
                                  ? Icons.wifi_off_rounded
                                  : Icons.cloud_upload_rounded,
                              color: _allDone
                                  ? Colors.green
                                  : pausedCount > 0
                                  ? Colors.orange
                                  : Colors.blue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _allDone
                                ? AppLocalizations.of(context)!.allUploadedStatus
                                : pausedCount > 0
                                ? AppLocalizations.of(context)!.noNetworkWaiting
                                : _isUploading
                                // 1-индексный: инкремент идёт при старте
                                // элемента. До старта первого (await
                                // beforeManualUpload) показываем 1, как раньше.
                                ? AppLocalizations.of(context)!.uploadingProgress(
                                    _currentBatchProcessed < 1
                                        ? 1
                                        : _currentBatchProcessed,
                                    _currentBatchTotal)
                                : AppLocalizations.of(context)!.tapToSelectFiles,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _allDone
                                  ? Colors.green
                                  : pausedCount > 0
                                  ? Colors.orange
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            AppLocalizations.of(context)!.photosAndVideosOnly,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (queue.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          '${queue.length} / ${UploadQueueNotifier.maxFiles}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (uploadingCount > 0)
                          _StatusBadge(
                            AppLocalizations.of(context)!
                                .uploadingCountBadge(uploadingCount),
                            Colors.blue,
                          ),
                        if (pausedCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _StatusBadge(
                              AppLocalizations.of(context)!
                                  .pausedCountBadge(pausedCount),
                              Colors.orange,
                            ),
                          ),
                        if (doneCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _StatusBadge(
                              AppLocalizations.of(context)!
                                  .doneCountBadge(doneCount),
                              Colors.green,
                            ),
                          ),
                        const Spacer(),
                        if (!_isUploading)
                          TextButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add, size: 15),
                            label: Text(
                              AppLocalizations.of(context)!.addFilesButton,
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (queue.any((f) =>
                        f.status == UploadFileStatus.waiting ||
                        f.status == UploadFileStatus.uploading ||
                        f.status == UploadFileStatus.pausedByUser)) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _batchPaused
                                  ? _resumeAllUploads
                                  : _pauseAllUploads,
                              icon: Icon(
                                _batchPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _batchPaused
                                    ? AppLocalizations.of(context)!
                                        .syncResumeAllButton
                                    : AppLocalizations.of(context)!
                                        .syncPauseAllButton,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _cancelAllUploads,
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Colors.red),
                              label: Text(
                                AppLocalizations.of(context)!
                                    .syncCancelAllButton,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.red),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],

                  ...queue.map(
                    (item) => _FileItemTile(
                      item: item,
                      onPause: item.status == UploadFileStatus.uploading
                          ? () => _pauseFile(item)
                          : null,
                      onRestore: (item.status == UploadFileStatus.pausedByUser ||
                              item.status == UploadFileStatus.cancelled)
                          ? () => _restoreFile(item)
                          : null,
                      onCancel:
                          (item.status == UploadFileStatus.uploading ||
                              item.status == UploadFileStatus.waiting ||
                              item.status == UploadFileStatus.paused ||
                              item.status == UploadFileStatus.pausedByUser)
                          ? () => _cancelFile(item)
                          : null,
                      onRemove:
                          (item.status != UploadFileStatus.uploading &&
                              item.status != UploadFileStatus.paused &&
                              item.status != UploadFileStatus.pausedByUser)
                          ? () => _removeFile(item)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: _isUploading
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: pausedCount > 0
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                            ),
                            label: Text(
                              pausedCount > 0
                                  ? AppLocalizations.of(context)!.waitingForNetworkShort
                                  : AppLocalizations.of(context)!.uploadingEllipsis,
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              queue.isEmpty
                                  ? AppLocalizations.of(context)!.selectPhotosVideos
                                  : _allDone
                                  ? AppLocalizations.of(context)!.uploadMoreButton
                                  : AppLocalizations.of(context)!.addMoreButton,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FileItemTile extends StatelessWidget {
  final UploadFileItem item;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;
  final VoidCallback? onPause;
  final VoidCallback? onRestore;

  const _FileItemTile({
    required this.item,
    this.onCancel,
    this.onRemove,
    this.onPause,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Пауза — только у активно грузящегося файла. paused-by-user
              // и cancelled показывают вместо неё кнопку восстановления.
              if (onPause != null) ...[
                _tileIconButton(
                  icon: Icons.pause_rounded,
                  color: Colors.blue,
                  onTap: onPause!,
                ),
                const SizedBox(width: 4),
              ] else if (onRestore != null) ...[
                _tileIconButton(
                  icon: item.status == UploadFileStatus.cancelled
                      ? Icons.restore_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.blue,
                  onTap: onRestore!,
                ),
                const SizedBox(width: 4),
              ],
              if (onCancel != null)
                _tileIconButton(
                  icon: Icons.close_rounded,
                  color: Colors.red,
                  onTap: onCancel!,
                )
              else if (onRemove != null)
                _tileIconButton(
                  icon: Icons.close_rounded,
                  color: Colors.grey,
                  onTap: onRemove!,
                ),
            ],
          ),

          if (item.status == UploadFileStatus.uploading ||
              item.status == UploadFileStatus.paused ||
              item.status == UploadFileStatus.pausedByUser) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: item.progress),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.status == UploadFileStatus.paused
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(item.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: item.status == UploadFileStatus.paused
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
              ],
            ),
          ],

          if (item.status == UploadFileStatus.paused) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.wifi_off_rounded, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.pausedWillResumeAuto,
                  style: const TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ),
          ],
          if (item.status == UploadFileStatus.pausedByUser) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.syncQueueItemPaused,
              style: const TextStyle(fontSize: 11, color: Colors.blue),
            ),
          ],
          if (item.status == UploadFileStatus.done) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.uploadedLabel,
              style: const TextStyle(fontSize: 11, color: Colors.green),
            ),
          ],
          if (item.status == UploadFileStatus.cancelled) ...[
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.cancelledLabel,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
          if (item.status == UploadFileStatus.error && item.error != null) ...[
            const SizedBox(height: 4),
            Text(
              item.error!,
              style: const TextStyle(fontSize: 11, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    switch (item.status) {
      case UploadFileStatus.waiting:
        return _iconBox(Icons.schedule_rounded, Colors.grey);
      case UploadFileStatus.uploading:
        return _iconBox(Icons.cloud_upload_rounded, Colors.blue);
      case UploadFileStatus.paused:
        return _iconBox(Icons.wifi_off_rounded, Colors.orange);
      case UploadFileStatus.pausedByUser:
        return _iconBox(Icons.pause_circle_outline_rounded, Colors.blue);
      case UploadFileStatus.done:
        return _iconBox(Icons.check_circle_rounded, Colors.green);
      case UploadFileStatus.error:
        return _iconBox(Icons.error_outline_rounded, Colors.red);
      case UploadFileStatus.cancelled:
        return _iconBox(Icons.cancel_outlined, Colors.grey);
    }
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _tileIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
