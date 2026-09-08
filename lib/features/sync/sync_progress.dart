import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_progress.freezed.dart';

@freezed
class SyncProgress with _$SyncProgress {
  const factory SyncProgress({
    @Default(0) int pending,
    @Default(0) int uploading,
    @Default(0) int done,
    @Default(0) int failed,
    /// Подмножество [failed], которое ещё будет ретраиться по backoff
    /// (retry_count ниже порога SyncQueueDb). [failed] — все failed-строки,
    /// включая терминальные; это поле чисто аддитивное.
    @Default(0) int retryableFailed,
    @Default(0) int paused,
    @Default(0) int cancelled,
    @Default(0.0) double currentFileProgress,
    String? currentFileName,
    @Default(0) int totalInBatch,
    @Default(0) int scannedCount,
    @Default(false) bool isScanning,
    @Default(0) int deviceTotal,
  }) = _SyncProgress;
}
