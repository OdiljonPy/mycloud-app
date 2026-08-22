import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'data/upload_queue_state.dart';
import 'data/upload_repository.dart';

/// Holds the manual-upload queue (UploadPage). Lives above the Navigator —
/// unlike the old `_queue` field on `_UploadPageState`, this state survives
/// UploadPage being popped and pushed again (was the cause of the queue
/// appearing empty on re-entry).
///
/// TUS upload orchestration (UploadRepository calls, UploadSyncCoordinator)
/// stays in UploadPage — this notifier only stores/updates item state.
final uploadQueueProvider =
    NotifierProvider<UploadQueueNotifier, List<UploadFileItem>>(
  UploadQueueNotifier.new,
);

class UploadQueueNotifier extends Notifier<List<UploadFileItem>> {
  // Лимит убран по факту — загружаем сколько выбрал пользователь.
  static const int maxFiles = 10000;

  @override
  List<UploadFileItem> build() => [];

  UploadFileItem? _findById(String id) {
    for (final item in state) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Возвращает true, если хотя бы один файл был отклонён (не фото/видео).
  bool addFiles(List<XFile> files) {
    bool anyRejected = false;
    final next = List<UploadFileItem>.of(state);
    for (final xFile in files) {
      if (next.length >= maxFiles) break;
      if (!UploadRepository.isAllowed(xFile.name)) {
        anyRejected = true;
        continue;
      }
      final alreadyAdded = next.any((q) => q.name == xFile.name);
      if (!alreadyAdded) {
        next.add(UploadFileItem(file: xFile, name: xFile.name));
      }
    }
    state = next;
    return anyRejected;
  }

  void updateItemStatus(String id, UploadFileStatus status) {
    final item = _findById(id);
    if (item == null) return;
    item.status = status;
    state = List.of(state);
  }

  void updateItemProgress(String id, double progress) {
    final item = _findById(id);
    if (item == null) return;
    item.progress = progress;
    state = List.of(state);
  }

  /// item становится uploading, прогресс сбрасывается — используется в
  /// начале обработки каждого файла в _startUploadAll.
  void startItem(String id) {
    final item = _findById(id);
    if (item == null) return;
    item.status = UploadFileStatus.uploading;
    item.progress = 0;
    state = List.of(state);
  }

  /// onComplete из UploadRepository.uploadFile.
  void completeItem(String id) {
    final item = _findById(id);
    if (item == null) return;
    item.status =
        item.cancelRequested ? UploadFileStatus.cancelled : UploadFileStatus.done;
    item.progress = 1.0;
    state = List.of(state);
    // Удаляем закешированный image_picker файл только после подтверждённой
    // сервером загрузки — cancelled сюда не попадает (см. cancelRequested).
    if (item.status == UploadFileStatus.done) {
      _deletePickedFile(item);
    }
  }

  /// catch-блок вокруг UploadRepository.uploadFile.
  void failItem(String id, String error) {
    final item = _findById(id);
    if (item == null) return;
    item.status =
        item.cancelRequested ? UploadFileStatus.cancelled : UploadFileStatus.error;
    item.error = error;
    state = List.of(state);
    // На error файл больше никем не переиспользуется (в отличие от
    // pausedByUser/cancelled, которые restoreFile поднимает по item.file) —
    // безопасно удалить закешированную image_picker копию.
    if (item.status == UploadFileStatus.error) {
      _deletePickedFile(item);
    }
  }

  void _deletePickedFile(UploadFileItem item) {
    try {
      final file = File(item.file.path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('[UploadQueue] Failed to delete cached picked file: $e');
    }
  }

  void cancelFile(UploadFileItem item) {
    item.cancelRequested = true;
    if (item.status == UploadFileStatus.waiting) {
      item.status = UploadFileStatus.cancelled;
    }
    state = List.of(state);
  }

  void restoreFile(UploadFileItem item) {
    item.status = UploadFileStatus.waiting;
    item.progress = 0;
    item.cancelRequested = false;
    item.error = null;
    state = List.of(state);
  }

  void resumeAllUploads() {
    final next = List<UploadFileItem>.of(state);
    for (final item in next) {
      if (item.status == UploadFileStatus.pausedByUser) {
        item.status = UploadFileStatus.waiting;
        item.progress = 0;
      }
    }
    state = next;
  }

  void cancelAllUploads(List<UploadFileItem> items) {
    for (final item in items) {
      // Активный получит cancelled через onStatusChange после реального
      // обрыва сети — трогать его статус здесь напрямую нельзя (гонка).
      if (item.status != UploadFileStatus.uploading) {
        item.status = UploadFileStatus.cancelled;
      }
    }
    state = List.of(state);
  }

  void removeFile(UploadFileItem item) {
    state = state.where((f) => f != item).toList();
  }

  void clearDone() {
    state = state
        .where((f) =>
            f.status != UploadFileStatus.done &&
            f.status != UploadFileStatus.cancelled &&
            f.status != UploadFileStatus.error)
        .toList();
  }
}
