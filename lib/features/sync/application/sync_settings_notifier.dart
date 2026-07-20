import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_settings_state.dart';

class SyncSettingsNotifier extends Notifier<SyncSettingsState> {
  static const _keyAutoSync = 'auto_sync_enabled';
  static const _keyWifiOnly = 'auto_sync_wifi_only';
  static const _keySelectedOnly = 'auto_sync_selected_only';
  static const _keySelectedFiles = 'selected_albums';

  @override
  SyncSettingsState build() {
    _load();
    return const SyncSettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      autoSyncEnabled: prefs.getBool(_keyAutoSync) ?? false,
      wifiOnly: prefs.getBool(_keyWifiOnly) ?? false,
      useSelectedFiles: prefs.getBool(_keySelectedOnly) ?? false,
      selectedFiles: prefs.getStringList(_keySelectedFiles) ?? [],
      isLoading: false,
    );
  }

  Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, value);
    state = state.copyWith(autoSyncEnabled: value);
  }

  Future<void> setWifiOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWifiOnly, value);
    state = state.copyWith(wifiOnly: value);
  }

  Future<void> setUseSelectedFiles(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySelectedOnly, value);
    state = state.copyWith(useSelectedFiles: value);
  }

  Future<void> saveSelectedFiles(List<String> files) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySelectedFiles, files);
    state = state.copyWith(selectedFiles: files);
  }
}
