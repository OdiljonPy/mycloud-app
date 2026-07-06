import '../../l10n/app_localizations.dart';

/// Maps raw server error text (e.g. from `AppException.message`) to a
/// localized user-facing string. Uses `contains()` on the lowercased raw
/// message since the backend's exact wording isn't guaranteed.
class ErrorLocalizer {
  ErrorLocalizer._();

  static final Map<String, String Function(AppLocalizations)> _mappings = {
    'credential': (l10n) => l10n.errorInvalidCredentials,
    'not found': (l10n) => l10n.errorUserNotFound,
    'otp': (l10n) => l10n.errorInvalidCode,
    'code': (l10n) => l10n.errorInvalidCode,
    'expired': (l10n) => l10n.errorSessionExpired,
    'already': (l10n) => l10n.errorUserAlreadyExists,
    'exists': (l10n) => l10n.errorUserAlreadyExists,
  };

  static String localize(String serverMessage, AppLocalizations l10n) {
    final lower = serverMessage.toLowerCase();
    for (final entry in _mappings.entries) {
      if (lower.contains(entry.key)) {
        return entry.value(l10n);
      }
    }
    return l10n.genericErrorFallback;
  }
}
