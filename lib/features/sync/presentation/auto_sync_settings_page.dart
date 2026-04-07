import 'package:flutter/material.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync_progress.dart';
import '../sync_providers.dart';

class AutoSyncSettingsPage extends ConsumerStatefulWidget {
  const AutoSyncSettingsPage({super.key});

  @override
  ConsumerState<AutoSyncSettingsPage> createState() => _AutoSyncSettingsPageState();
}

class _AutoSyncSettingsPageState extends ConsumerState<AutoSyncSettingsPage> {
  static const _accent = Color(0xFF2563EB);

  bool _autoSyncEnabled = false;
  bool _wifiOnly = false;
  bool _useSelectedFiles = false; // 👈 НОВОЕ

  List<String> _selectedFiles = []; // 👈 НОВОЕ

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? false;
        _wifiOnly = prefs.getBool('auto_sync_wifi_only') ?? false;
        _useSelectedFiles =
            prefs.getBool('auto_sync_selected_only') ?? false;
        _selectedFiles =
            prefs.getStringList('selected_files') ?? [];
      });
    }
  }

  Future<void> _setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', value);
    if (mounted) setState(() => _autoSyncEnabled = value);
  }

  Future<void> _setWifiOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_wifi_only', value);
    if (mounted) setState(() => _wifiOnly = value);
  }

  Future<void> _setUseSelected(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_selected_only', value);

    if (mounted) setState(() => _useSelectedFiles = value);

    if (value) {
      _openFilePicker();
    }
  }

  Future<void> _openFilePicker() async {
    // ⚠️ ЗАГЛУШКА — подключи свой picker
    final files = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => const _DummyPickerPage(),
      ),
    );

    if (files != null) {
      setState(() => _selectedFiles = files);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_files', files);
    }
  }

  Future<void> _startSync() async {
    final service = ref.read(autoSyncServiceProvider);
    if (service.isRunning || service.isScanning) return;
    await service.startAutoSync();
  }

  Future<void> _stopSync() async {
    await ref.read(autoSyncServiceProvider).stopSync();
  }

  Future<void> _resetQueue() async {
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.syncResetConfirmTitle),
        content: Text(t.syncResetConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.syncResetConfirmButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(autoSyncServiceProvider);
      await service.onLogout();
      await service.initialize();
      await service.startAutoSync();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncProgressAsync = ref.watch(syncProgressProvider);
    final progress = syncProgressAsync.valueOrNull ?? const SyncProgress();
    final isSyncing = ref.watch(autoSyncServiceProvider).isRunning ||
        ref.watch(autoSyncServiceProvider).isScanning;

    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(t.syncSettingsTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCard(
              cardColor: cardColor,
              child: Column(
                children: [
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.syncEnableToggle),
                    subtitle: Text(t.syncAutoUpload),
                    value: _autoSyncEnabled,
                    onChanged: _setAutoSync,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.syncWifiOnly),
                    subtitle: Text(t.syncNoMobileData),
                    value: _wifiOnly,
                    onChanged: _setWifiOnly,
                  ),
                  const Divider(height: 1),

                  // 👇 НОВЫЙ БЛОК
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Выбранные файлы'),
                    subtitle: const Text(
                        'Синхронизировать только выбранные'),
                    value: _useSelectedFiles,
                    onChanged: _setUseSelected,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildCard(
              cardColor: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync, color: _accent, size: 20),
                      const SizedBox(width: 8),
                      Text(t.syncStatusTitle),
                      const Spacer(),
                      if (isSyncing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (progress.isScanning)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Сканирование галереи'),
                          const Spacer(),
                          Text(
                            '${progress.scannedCount} файлов',
                            style: const TextStyle(color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  _buildStatRow(Icons.hourglass_empty,
                      t.syncStatusPending, progress.pending, Colors.orange),

                  const SizedBox(height: 8),

                  // Загрузка — скрыта
                  _buildStatRow(Icons.check_circle,
                      t.syncStatusDone, progress.done, Colors.green),

                  const SizedBox(height: 8),

                  // _buildStatRow(Icons.error_outline,
                  //     t.syncStatusFailed, progress.failed, Colors.red),

                  const SizedBox(height: 16),
                  // Текущий файл — показываем всегда, не мигает
                  if (progress.currentFileName != null)
                    Text(
                      progress.currentFileName!,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (progress.currentFileName != null)
                    const SizedBox(height: 6),
                  if (progress.currentFileName != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.currentFileProgress > 0
                            ? progress.currentFileProgress
                            : null,
                        minHeight: 6,
                      ),
                    ),
                  if (progress.currentFileName != null)
                    const SizedBox(height: 4),
                  if (progress.currentFileName != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        progress.currentFileProgress > 0
                            ? '${(progress.currentFileProgress * 100).toStringAsFixed(0)}%'
                            : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync, color: Colors.white),
                label: Text(t.syncNowButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isSyncing ? null : _startSync,
              ),
            ),

            if (isSyncing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.stop, color: Colors.white),
                  label: Text(t.syncStop),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _stopSync,
                ),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(t.syncResetButton),
                onPressed: _resetQueue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Color cardColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildStatRow(
      IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text('$count', style: TextStyle(color: color)),
      ],
    );
  }
}

// 👇 ЗАГЛУШКА picker (замени на свою галерею)
class _DummyPickerPage extends StatelessWidget {
  const _DummyPickerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор файлов')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, ['file1.jpg', 'file2.mp4']);
          },
          child: const Text('Выбрать тестовые файлы'),
        ),
      ),
    );
  }
}