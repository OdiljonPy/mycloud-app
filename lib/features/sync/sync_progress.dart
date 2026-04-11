import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_progress.freezed.dart';

@freezed
class SyncProgress with _$SyncProgress {
  const factory SyncProgress({
    @Default(0) int pending,
    @Default(0) int uploading,
    @Default(0) int done,
    @Default(0) int failed,
    @Default(0.0) double currentFileProgress,
    String? currentFileName,
    @Default(0) int totalInBatch,
    @Default(0) int scannedCount,
    @Default(false) bool isScanning,
    @Default(0) int sessionUploaded,
  }) = _SyncProgress;
}
