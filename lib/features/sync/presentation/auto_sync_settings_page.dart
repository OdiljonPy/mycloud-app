import 'package:flutter/material.dart';
import 'package:cloud_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/page_transitions.dart';
import '../sync_progress.dart';
import '../sync_providers.dart';
import 'select_sync_files_page.dart';

class AutoSyncSettingsPage extends ConsumerStatefulWidget {
  const AutoSyncSettingsPage({super.key});

  @override
  ConsumerState<AutoSyncSettingsPage> createState() =>
      _AutoSyncSettingsPageState();
}

class _AutoSyncSettingsPageState extends ConsumerState<AutoSyncSettingsPage> {
  // true = user manually stopped → show "Continue" + "Reset"
  bool _paused = false;
  bool _isResetting = false;
  // Separate flags (not a single shared one) — start can run for a while
  // (gallery scan + uploads) and stop must still be able to interrupt it,
  // so the two must not block each other.
  bool _isStarting = false;
  bool _isStopping = false;

  // ─── Button actions ───────────────────────────────────────────────────────

  void _startSync() {
    if (_isStarting) return;
    _isStarting = true;
    if (mounted) setState(() => _paused = false);
    ref
        .read(syncRepositoryProvider)
        .startAutoSync()
        .whenComplete(() => _isStarting = false);
  }

  Future<void> _stopSync() async {
    if (_isStopping) return;
    _isStopping = true;
    if (mounted) setState(() => _paused = true);
    try {
      await ref.read(syncRepositoryProvider).stopSync();
    } finally {
      _isStopping = false;
    }
  }

  Future<void> _resetQueue() async {
    if (_isResetting) return;
    if (mounted) {
      setState(() {
      _paused = false;
      _isResetting = true;
    });
    }
    try {
      final repo = ref.read(syncRepositoryProvider);
      await repo.stopSync();
      await repo.onLogout();
      await repo.initialize();
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  // ─── Settings toggles ─────────────────────────────────────────────────────

  // Настройка влияет только на автозапуск при холодном старте / логине /
  // обновлении главной (см. app_initializer.dart, auth_repository.dart,
  // home_page.dart) — на текущий/ручной синк (кнопки ниже) не влияет и
  // ничего не запускает и не останавливает сама по себе.
  Future<void> _setAutoSync(bool value) async {
    await ref.read(syncSettingsProvider.notifier).setAutoSync(value);
  }

  Future<void> _setWifiOnly(bool value) async {
    await ref.read(syncSettingsProvider.notifier).setWifiOnly(value);
  }

  // Свич сам по себе не может включить режим "только выбранные" без
  // непустого списка — вместо этого сразу открываем пикер.
  Future<void> _setUseSelected(bool value) async {
    if (value && ref.read(syncSettingsProvider).selectedFiles.isEmpty) {
      await _openFilePicker();
      return;
    }
    await ref.read(syncSettingsProvider.notifier).setUseSelectedFiles(value);
    if (value) {
      // Свич включили с уже сохранённым выбором альбомов (не через пикер) —
      // всё равно чистим очередь от того, что могло насинкаться в full-sync
      // режиме, пока свич был выключен.
      await ref.read(syncRepositoryProvider).purgeNonSelectedAlbums();
    }
  }

  // Тап по строке (не по свичу) — всегда открывает пикер для
  // просмотра/изменения текущего выбора.
  Future<void> _openFilePicker() async {
    final notifier = ref.read(syncSettingsProvider.notifier);
    final current = ref.read(syncSettingsProvider).selectedFiles.toSet();

    final result = await Navigator.of(context).push<List<String>>(
      slideUpRoute(SelectSyncFilesPage(initiallySelected: current)),
    );
    if (result == null || !mounted) return; // отмена/свайп назад — не трогаем

    if (result.isEmpty) {
      // Submit с 0 файлов: список не трогаем, режим не включаем.
      await notifier.setUseSelectedFiles(false);
      return;
    }

    await notifier.saveSelectedFiles(result);
    await notifier.setUseSelectedFiles(true);
    // Вычищаем из очереди всё, что не входит в новый выбор альбомов —
    // иначе то, что уже насканилось раньше (full-sync или прошлый выбор),
    // всё равно догрузится в фоне.
    await ref.read(syncRepositoryProvider).purgeNonSelectedAlbums();

    // Подхватываем новый фильтр независимо от тумблера "Sync Enable" —
    // startAutoSync() сам безопасно no-op'нется, если синк уже идёт
    // (см. guard isRunning/isScanning в AutoSyncService).
    ref.read(syncRepositoryProvider).startAutoSync();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(syncProgressProvider);
    final progress = progressAsync.valueOrNull ?? const SyncProgress();
    // База для строк статуса — размер очереди, не deviceTotal
    // (единый формат "done / total" с sync_status_bubble.dart).
    final queueTotal = progress.pending +
        progress.uploading +
        progress.done +
        progress.failed;

    final repo = ref.watch(syncRepositoryProvider);
    final isSyncing = repo.isRunning || repo.isScanning;

    final settings = ref.watch(syncSettingsProvider);
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final iosBlue = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final iosRed = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);
    final bgColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark
        ? const Color(0xFFEBEBF5).withValues(alpha: 0.6)
        : const Color(0xFF3C3C43).withValues(alpha: 0.6);
    final separatorColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0xFFE5E5EA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
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
        iconTheme: IconThemeData(color: iosBlue),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Settings toggles ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: t.syncEnableToggle,
                    subtitle: t.syncAutoUpload,
                    value: settings.autoSyncEnabled,
                    onChanged: _setAutoSync,
                    iosBlue: iosBlue,
                    textColor: textColor,
                    labelColor: labelColor,
                    separatorColor: separatorColor,
                    showDivider: true,
                  ),
                  _buildSwitchTile(
                    title: t.syncWifiOnly,
                    subtitle: t.syncNoMobileData,
                    value: settings.wifiOnly,
                    onChanged: _setWifiOnly,
                    iosBlue: iosBlue,
                    textColor: textColor,
                    labelColor: labelColor,
                    separatorColor: separatorColor,
                    showDivider: true,
                  ),
                  _buildSwitchTile(
                    title: t.syncSelectedFiles,
                    subtitle: settings.selectedFiles.isNotEmpty
                        ? t.syncSelectedCount(settings.selectedFiles.length)
                        : t.syncSelectedFilesSubtitle,
                    value: settings.useSelectedFiles,
                    onChanged: _setUseSelected,
                    onTitleTap: _openFilePicker,
                    iosBlue: iosBlue,
                    textColor: textColor,
                    labelColor: labelColor,
                    separatorColor: separatorColor,
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Status block ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    label: t.syncStatusTitle,
                    value: '${progress.done}/$queueTotal',
                    valueColor: iosBlue,
                    textColor: textColor,
                    separatorColor: separatorColor,
                    showDivider: true,
                    bold: true,
                  ),
                  _buildStatRow(
                    label: t.syncTotal,
                    value: queueTotal.toString(),
                    valueColor: textColor,
                    textColor: textColor,
                    separatorColor: separatorColor,
                    showDivider: true,
                    bold: false,
                  ),
                  _buildStatRow(
                    label: t.syncStatusDone,
                    value: progress.done.toString(),
                    valueColor: isDark
                        ? const Color(0xFF32D74B)
                        : const Color(0xFF34C759),
                    textColor: textColor,
                    separatorColor: separatorColor,
                    showDivider: false,
                    bold: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Buttons (3 states) ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildButtons(
                isSyncing: isSyncing,
                iosBlue: iosBlue,
                iosRed: iosRed,
                t: t,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // State 1: idle  → 1 blue  "Sync Now"
  // State 2: running → 1 red   "Stop"
  // State 3: paused → blue "Continue" + outlined red "Reset Queue"
  Widget _buildButtons({
    required bool isSyncing,
    required Color iosBlue,
    required Color iosRed,
    required AppLocalizations t,
  }) {
    if (isSyncing && !_paused) {
      // State 2 — running
      return _button(
        label: t.syncStop,
        color: iosRed,
        onPressed: _stopSync,
      );
    }

    if (_paused) {
      // State 3 — manually stopped
      return Column(
        children: [
          _button(
            label: t.syncResumeButton,
            color: iosBlue,
            onPressed: _startSync,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _isResetting ? null : _resetQueue,
              style: OutlinedButton.styleFrom(
                foregroundColor: iosRed,
                side: BorderSide(color: iosRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                t.syncResetButton,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // State 1 — idle
    return _button(
      label: t.syncNowButton,
      color: iosBlue,
      onPressed: _startSync,
    );
  }

  Widget _button({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color valueColor,
    required Color textColor,
    required Color separatorColor,
    required bool showDivider,
    required bool bold,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Divider(height: 1, thickness: 0.5, color: separatorColor),
          ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color iosBlue,
    required Color textColor,
    required Color labelColor,
    required Color separatorColor,
    required bool showDivider,
    VoidCallback? onTitleTap,
  }) {
    final titleColumn = Column(
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
            color: labelColor,
          ),
        ),
      ],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: onTitleTap != null
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTitleTap,
                        child: titleColumn,
                      )
                    : titleColumn,
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: iosBlue,
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
              color: separatorColor,
            ),
          ),
      ],
    );
  }
}
