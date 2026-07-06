import '../../l10n/app_localizations.dart';

/// Single source of truth for storage-size formatting, so the same byte
/// count reads identically (units + language) on every screen.
String formatBytes(dynamic bytes, AppLocalizations l10n) {
  final v = (bytes is num) ? bytes.toDouble() : double.tryParse(bytes?.toString() ?? '') ?? 0;
  if (v >= 1099511627776) {
    return '${(v / 1099511627776).toStringAsFixed(2)} ${l10n.unitTb}';
  }
  if (v >= 1073741824) {
    return '${(v / 1073741824).toStringAsFixed(2)} ${l10n.unitGb}';
  }
  if (v >= 1048576) {
    return '${(v / 1048576).toStringAsFixed(1)} ${l10n.unitMb}';
  }
  if (v >= 1024) {
    return '${(v / 1024).toStringAsFixed(0)} ${l10n.unitKb}';
  }
  return '${v.toStringAsFixed(0)} ${l10n.unitBytes}';
}
