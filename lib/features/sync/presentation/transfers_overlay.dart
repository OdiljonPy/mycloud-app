import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cloud_app/l10n/app_localizations.dart';
import '../data/sync_task.dart';
import '../sync_progress.dart';
import '../sync_providers.dart';

/// Глобальная плавающая панель передачи файлов — компактная, в нижнем-правом
/// углу, видна поверх ВСЕХ экранов пока идёт загрузка (авто-синхронизация).
/// Разворачивается/сворачивается с анимацией из угла. Процент считается из
/// постоянного состояния SQLite — не обнуляется при refresh/перезаходе.
class TransfersOverlay extends ConsumerStatefulWidget {
  const TransfersOverlay({super.key});

  @override
  ConsumerState<TransfersOverlay> createState() => _TransfersOverlayState();
}

class _TransfersOverlayState extends ConsumerState<TransfersOverlay> {
  bool _expanded = false;
  bool _dismissed = false;
  int _lastActiveKey = 0;

  String _compKey = '';
  Future<UploadSnapshot>? _snapshotFuture;

  @override
  Widget build(BuildContext context) {
    final progress =
        ref.watch(syncProgressProvider).valueOrNull ?? const SyncProgress();
    final busy = progress.uploading + progress.pending > 0;

    final activity = progress.uploading + progress.pending;
    if (busy && activity > _lastActiveKey && _dismissed) _dismissed = false;
    _lastActiveKey = activity;

    final key =
        '${progress.pending}-${progress.uploading}-${progress.sessionUploaded}-${progress.currentFileName}';
    if (busy && !_dismissed && key != _compKey) {
      _compKey = key;
      _snapshotFuture =
          ref.read(syncRepositoryProvider).getUploadSnapshot(limit: 40);
    }

    Widget content;
    if (!busy || _dismissed) {
      content = const SizedBox.shrink(key: ValueKey('t_none'));
    } else {
      content = FutureBuilder<UploadSnapshot>(
        key: ValueKey(_expanded ? 't_panel' : 't_pill'),
        future: _snapshotFuture,
        builder: (context, snap) => _expanded
            ? _panel(context, progress, snap.data)
            : _pill(context, progress, snap.data),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 78, left: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
                alignment: Alignment.bottomRight,
                child: child,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  // ── Расчёты по байтам ──────────────────────────────────────────────────────
  int _liveUploaded(SyncProgress pr, UploadSnapshot s) {
    var up = s.doneBytes;
    final uploading = s.tasks.where((t) => t.status == SyncStatus.uploading);
    if (uploading.isNotEmpty) {
      up += (uploading.first.fileSize * pr.currentFileProgress).round();
    }
    return up;
  }

  double _fraction(SyncProgress pr, UploadSnapshot? s) {
    if (s == null || s.totalBytes <= 0) {
      final total = pr.done + pr.pending + pr.uploading;
      return total > 0 ? (pr.done / total).clamp(0.0, 1.0) : 0.0;
    }
    return (_liveUploaded(pr, s) / s.totalBytes).clamp(0.0, 1.0);
  }

  // ── Свёрнутая таблетка ─────────────────────────────────────────────────────
  Widget _pill(BuildContext context, SyncProgress pr, UploadSnapshot? s) {
    final cs = Theme.of(context).colorScheme;
    final frac = _fraction(pr, s);
    final pct = (frac * 100).round();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _expanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: frac == 0 ? null : frac,
                  strokeWidth: 2.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text('$pct%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_up_rounded,
                  color: Colors.white.withValues(alpha: 0.85), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Развёрнутая панель (узкая, нижний-правый угол) ─────────────────────────
  Widget _panel(BuildContext context, SyncProgress pr, UploadSnapshot? s) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    final textColor = cs.onSurface;
    final subtitle = cs.onSurface.withValues(alpha: 0.6);
    final screen = MediaQuery.of(context).size;
    final width = (screen.width * 0.8).clamp(240.0, 320.0);
    final maxH = (screen.height * 0.5).clamp(240.0, 380.0);

    final frac = _fraction(pr, s);
    final uploaded = s != null ? _liveUploaded(pr, s) : 0;
    final total = s?.totalBytes ?? 0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxH),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.transfersTitle,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 1),
                        Text(
                          t.transfersSummary(
                              pr.uploading, pr.pending, pr.done),
                          style: TextStyle(fontSize: 11, color: subtitle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _iconBtn(Icons.remove_rounded, subtitle,
                      () => setState(() => _expanded = false)),
                  _iconBtn(Icons.close_rounded, subtitle,
                      () => setState(() => _dismissed = true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: frac == 0 ? null : frac,
                      minHeight: 5,
                      backgroundColor: divider,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(frac * 100).round()}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.primary)),
                      Text('${_fmt(uploaded)} / ${_fmt(total)}',
                          style: TextStyle(fontSize: 11, color: subtitle)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, thickness: 0.5, color: divider),
            Flexible(
              child: (s == null || s.tasks.isEmpty)
                  ? const SizedBox(height: 8)
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: s.tasks.length,
                      itemBuilder: (_, i) => _row(s.tasks[i], pr, cs, divider,
                          textColor, subtitle, t),
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 14,
                          color: divider),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
        icon: Icon(icon, color: color, size: 20),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      );

  Widget _row(SyncTask task, SyncProgress pr, ColorScheme cs, Color divider,
      Color textColor, Color subtitle, AppLocalizations t) {
    final isUploading = task.status == SyncStatus.uploading;
    final frac = isUploading ? pr.currentFileProgress.clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: textColor)),
              ),
              const SizedBox(width: 8),
              Text(
                isUploading ? '${(frac * 100).round()}%' : t.statusQueued,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUploading ? cs.primary : subtitle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: isUploading ? frac : 0,
                    minHeight: 3,
                    backgroundColor: divider,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_fmt(task.fileSize),
                  style: TextStyle(fontSize: 10.5, color: subtitle)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}
