import 'package:flutter/material.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync_progress.dart';
import '../sync_providers.dart';

class AutoSyncSettingsPage extends ConsumerStatefulWidget {
  const AutoSyncSettingsPage({super.key});

  @override
  ConsumerState<AutoSyncSettingsPage> createState() => _AutoSyncSettingsPageState();
}

class _AutoSyncSettingsPageState extends ConsumerState<AutoSyncSettingsPage> {
  static const _accent = Color(0xFF2563EB);

  // Только для защиты от двойного нажатия Reset (пока диалог открыт)
  bool _isResetting = false;

  // ─── Переключатели ────────────────────────────────────────────────────────

  Future<void> _setAutoSync(bool value) async {
    await ref.read(syncSettingsProvider.notifier).setAutoSync(value);
    if (value) {
      ref.read(syncRepositoryProvider).startAutoSync();
    } else {
      ref.read(syncRepositoryProvider).stopSync();
    }
  }

  Future<void> _setWifiOnly(bool value) async {
    await ref.read(syncSettingsProvider.notifier).setWifiOnly(value);
  }

  Future<void> _setUseSelected(bool value) async {
    await ref.read(syncSettingsProvider.notifier).setUseSelectedFiles(value);
    if (value) _openFilePicker();
  }

  Future<void> _openFilePicker() async {
    final files = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (_) => const _DummyPickerPage()),
    );
    if (files != null) {
      await ref.read(syncSettingsProvider.notifier).saveSelectedFiles(files);
    }
  }

  // ─── Кнопки Sync / Stop / Reset ──────────────────────────────────────────

  /// Запуск sync — мгновенно, fire-and-forget.
  /// Если уже запущен — игнорируем (защита от многократного нажатия).
  void _startSync() {
    final repo = ref.read(syncRepositoryProvider);
    if (repo.isRunning || repo.isScanning) return; // уже идёт — игнор
    repo.startAutoSync(); // не await — UI обновляется через провайдер
  }

  /// Остановка — мгновенно, всегда доступна пока isSyncing.
  void _stopSync() {
    ref.read(syncRepositoryProvider).stopSync();
  }

  /// Сброс очереди — диалог подтверждения, потом сброс.
  Future<void> _resetQueue() async {
    if (_isResetting) return;
    final t = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    if (confirmed != true) return;

    if (mounted) setState(() => _isResetting = true);
    try {
      final repo = ref.read(syncRepositoryProvider);
      await repo.stopSync();       // сначала стоп
      await repo.onLogout();       // сброс очереди
      await repo.initialize();     // реинициализация
      repo.startAutoSync();        // fire-and-forget — сразу начинаем
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final syncProgressAsync = ref.watch(syncProgressProvider);
    final progress = syncProgressAsync.valueOrNull ?? const SyncProgress();

    final repo = ref.watch(syncRepositoryProvider);
    final isSyncing = repo.isRunning || repo.isScanning;

    final settings = ref.watch(syncSettingsProvider);
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
            // ── Настройки ──────────────────────────────────────────────────
            _buildCard(
              cardColor: cardColor,
              child: Column(
                children: [
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.syncEnableToggle),
                    subtitle: Text(t.syncAutoUpload),
                    value: settings.autoSyncEnabled,
                    onChanged: _setAutoSync,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.syncWifiOnly),
                    subtitle: Text(t.syncNoMobileData),
                    value: settings.wifiOnly,
                    onChanged: _setWifiOnly,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.syncSelectedFiles),
                    subtitle: Text(t.syncSelectedFilesSubtitle),
                    value: settings.useSelectedFiles,
                    onChanged: _setUseSelected,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Статус ─────────────────────────────────────────────────────
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

                  _buildStatRow(
                    Icons.photo_library_outlined,
                    t.syncTotal,
                    (progress.deviceTotal - progress.done).clamp(0, progress.deviceTotal),
                    Colors.blueGrey,
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    Icons.check_circle,
                    t.syncStatusDone,
                    progress.done,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),

                  if (progress.currentFileName != null) ...[
                    Text(
                      progress.currentFileName!,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.currentFileProgress > 0
                            ? progress.currentFileProgress
                            : null,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        progress.currentFileProgress > 0
                            ? '${(progress.currentFileProgress * 100).toStringAsFixed(0)}%'
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Кнопки ─────────────────────────────────────────────────────

            // Sync now — активна только если НЕ идёт sync
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync, color: Colors.white),
                label: Text(t.syncNowButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: _accent.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isSyncing ? null : _startSync,
              ),
            ),

            // Stop — видна и активна только пока идёт sync
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
                  onPressed: _stopSync, // всегда активна пока isSyncing
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Reset — заблокирована пока идёт сам сброс (диалог)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(t.syncResetButton),
                onPressed: _isResetting ? null : _resetQueue,
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

  Widget _buildStatRow(IconData icon, String label, int count, Color color) {
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

// Заглушка picker — замени на свою галерею
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
