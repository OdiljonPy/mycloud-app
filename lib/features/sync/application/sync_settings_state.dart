import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_settings_state.freezed.dart';

@freezed
class SyncSettingsState with _$SyncSettingsState {
  const factory SyncSettingsState({
    @Default(false) bool autoSyncEnabled,
    @Default(false) bool wifiOnly,
    @Default(false) bool useSelectedFiles,
    @Default(<String>[]) List<String> selectedFiles,
    @Default(true) bool isLoading,
  }) = _SyncSettingsState;
}
