import '../../l10n/app_localizations.dart';
import '../errors/app_exception.dart';

/// Maps raw server error text (e.g. from `AppException.message`) to a
/// localized user-facing string. Uses `contains()` on the lowercased raw
/// message since the backend's exact wording isn't guaranteed.
class ErrorLocalizer {
  ErrorLocalizer._();

  // Order matters: entries are checked top-to-bottom and the first substring
  // match wins (see `localize` below). Specific phrases must come before the
  // bare single-word keys they'd otherwise be swallowed by — e.g. a plain
  // 'code' key would match "status code"/"error code" text leaking in from
  // an unparsed backend error body and wrongly claim "invalid verification
  // code", so it's dropped entirely; 'already'/'not found' are kept but only
  // as a last-resort fallback (below 'exists'), since "folder already
  // exists" or "file not found" would otherwise get the wrong ("user...")
  // wording.
  static final Map<String, String Function(AppLocalizations)> _mappings = {
    'still valid': (l10n) => l10n.errorOtpStillValid,
    'invalid code': (l10n) => l10n.errorInvalidCode,
    'wrong code': (l10n) => l10n.errorInvalidCode,
    'otp': (l10n) => l10n.errorInvalidCode,
    'user already exists': (l10n) => l10n.errorUserAlreadyExists,
    'phone already': (l10n) => l10n.errorUserAlreadyExists,
    'user not found': (l10n) => l10n.errorUserNotFound,
    'account not found': (l10n) => l10n.errorUserNotFound,
    'credential': (l10n) => l10n.errorInvalidCredentials,
    'expired': (l10n) => l10n.errorSessionExpired,
    'exists': (l10n) => l10n.errorUserAlreadyExists,
    'already': (l10n) => l10n.errorUserAlreadyExists,
    'not found': (l10n) => l10n.errorUserNotFound,
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

  /// Converts any caught error into a safe, localized, user-facing string.
  /// Never surfaces `toString()`/`AppException(...)`/raw technical text —
  /// null or empty messages fall back to a generic localized string.
  static String forException(Object error, AppLocalizations l10n) {
    if (error is AppException) {
      final message = error.message.trim();
      return message.isEmpty ? l10n.genericErrorFallback : localize(message, l10n);
    }
    return l10n.genericErrorFallback;
  }
}
