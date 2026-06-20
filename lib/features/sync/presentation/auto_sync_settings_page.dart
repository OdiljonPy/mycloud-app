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

<<<<<<< HEAD
class _AutoSyncSettingsPageState extends ConsumerState<AutoSyncSettingsPage> {
=======
class _AutoSyncSettingsPageState extends State<AutoSyncSettingsPage> with AutomaticKeepAliveClientMixin {
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
  static const _accent = Color(0xFF2563EB);

  // Только для защиты от двойного нажатия Reset (пока диалог открыт)
  bool _isResetting = false;

<<<<<<< HEAD
  // ─── Переключатели ────────────────────────────────────────────────────────
=======
  bool _autoSyncEnabled = false;
  bool _wifiOnly = false;
  bool _useSelectedFiles = false; // 👈 НОВОЕ
  bool _isSyncing = false;

  List<String> _selectedFiles = []; // 👈 НОВОЕ

  StreamSubscription<SyncProgress>? _progressSub;
  SyncProgress _lastProgress = const SyncProgress();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();

    _progressSub = _syncService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _lastProgress = progress;
          _isSyncing = _syncService.isRunning;
        });
      }
    });

    _isSyncing = _syncService.isRunning;
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
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")

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
<<<<<<< HEAD
    final syncProgressAsync = ref.watch(syncProgressProvider);
    final progress = syncProgressAsync.valueOrNull ?? const SyncProgress();

    final repo = ref.watch(syncRepositoryProvider);
    final isSyncing = repo.isRunning || repo.isScanning;

    final settings = ref.watch(syncSettingsProvider);
=======
    super.build(context); // AutomaticKeepAliveClientMixin uchun kerak
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS ranglar
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final secondaryBgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
    final labelColor = isDark ? const Color(0xFFEBEBF5).withOpacity(0.6) : const Color(0xFF3C3C43).withOpacity(0.6);
    final textColor = isDark ? Colors.white : Colors.black;
    final separatorColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        title: Text(
          t.syncSettingsTitle,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
<<<<<<< HEAD
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
=======
            const SizedBox(height: 20),

            // Sozlamalar kartasi
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildIOSSwitchTile(
                    title: t.syncEnableToggle,
                    subtitle: t.syncAutoUpload,
                    value: _autoSyncEnabled,
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
                    onChanged: _setAutoSync,
                    isDark: isDark,
                    textColor: textColor,
                    labelColor: labelColor,
                    showDivider: true,
                  ),
<<<<<<< HEAD
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.syncWifiOnly),
                    subtitle: Text(t.syncNoMobileData),
                    value: settings.wifiOnly,
=======
                  _buildIOSSwitchTile(
                    title: t.syncWifiOnly,
                    subtitle: t.syncNoMobileData,
                    value: _wifiOnly,
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
                    onChanged: _setWifiOnly,
                    isDark: isDark,
                    textColor: textColor,
                    labelColor: labelColor,
                    showDivider: true,
                  ),
<<<<<<< HEAD
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: _accent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.syncSelectedFiles),
                    subtitle: Text(t.syncSelectedFilesSubtitle),
                    value: settings.useSelectedFiles,
=======
                  _buildIOSSwitchTile(
                    title: 'Tanlangan fayllar',
                    subtitle: 'Faqat tanlanganlarni sinxronlash',
                    value: _useSelectedFiles,
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
                    onChanged: _setUseSelected,
                    isDark: isDark,
                    textColor: textColor,
                    labelColor: labelColor,
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

<<<<<<< HEAD
            // ── Статус ─────────────────────────────────────────────────────
            _buildCard(
              cardColor: cardColor,
=======
            // Status kartasi
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.sync_rounded,
                          color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        t.syncStatusTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
<<<<<<< HEAD
                      if (isSyncing)
                        const SizedBox(
                          width: 16,
                          height: 16,
=======
                      if (_isSyncing)
                        SizedBox(
                          width: 20,
                          height: 20,
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

<<<<<<< HEAD
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
=======
                  if (_lastProgress.totalFiles > 0) ...[
                    _buildIOSStatRow(
                      icon: Icons.photo_library_outlined,
                      label: 'Jami fayllar',
                      value: '${_lastProgress.totalFiles}',
                      color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_lastProgress.isScanning) ...[
                    _buildIOSScanningRow(
                      label: 'Tekshirilmoqda',
                      count: _lastProgress.scannedCount,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildIOSStatRow(
                    icon: Icons.hourglass_empty_rounded,
                    label: t.syncStatusPending,
                    value: '${_lastProgress.pending}',
                    color: isDark ? const Color(0xFFFF9F0A) : const Color(0xFFFF9500),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  _buildIOSStatRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: t.syncStatusDone,
                    value: '${_lastProgress.done}',
                    color: isDark ? const Color(0xFF32D74B) : const Color(0xFF34C759),
                    isDark: isDark,
                  ),

                  if (_lastProgress.currentFileName != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 18,
                                color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lastProgress.currentFileName!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _lastProgress.currentFileProgress > 0
                                  ? _lastProgress.currentFileProgress
                                  : null,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? const Color(0xFF3A3A3C)
                                  : const Color(0xFFE5E5EA),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                              ),
                            ),
                          ),
                          if (_lastProgress.currentFileProgress > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${(_lastProgress.currentFileProgress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF98989D) : const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ],
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

<<<<<<< HEAD
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
=======
            // Tugmalar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSyncing ? null : _startSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF0A84FF).withOpacity(0.3)
                            : const Color(0xFF007AFF).withOpacity(0.3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        t.syncNowButton,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_isSyncing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _stopSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          t.syncStop,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // const SizedBox(height: 12),
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 50,
                  //   child: OutlinedButton(
                  //     onPressed: _resetQueue,
                  //     style: OutlinedButton.styleFrom(
                  //       foregroundColor: isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30),
                  //       side: BorderSide(
                  //         color: isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30),
                  //         width: 1.5,
                  //       ),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //     ),
                  //     child: Text(
                  //       t.syncResetButton,
                  //       style: const TextStyle(
                  //         fontSize: 17,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
    required Color textColor,
    required Color labelColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeColor: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            ),
          ),
      ],
    );
  }

<<<<<<< HEAD
  Widget _buildStatRow(IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text('$count', style: TextStyle(color: color)),
      ],
=======
  Widget _buildIOSStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSScanningRow({
    required String label,
    required int count,
    required bool isDark,
  }) {
    const color = Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            '$count ta',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
>>>>>>> parent of 6d49955 (Revert "Fayllar sahifasi uchun pagination tizimini yangilandi")
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
