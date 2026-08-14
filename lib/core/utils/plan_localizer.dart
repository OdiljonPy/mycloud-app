import '../../l10n/app_localizations.dart';

/// Plan names (e.g. "Про", "Семья") come from the backend in Russian only.
/// This maps the known server names to a localized label; unknown names
/// (e.g. future plans the backend adds) are shown as-is.
class PlanLocalizer {
  PlanLocalizer._();

  static final Map<String, String Function(AppLocalizations)> _mappings = {
    'Бесплатно': (l10n) => l10n.planNameFree,
    'Старт': (l10n) => l10n.planNameStart,
    'Плюс': (l10n) => l10n.planNamePlus,
    'Семья': (l10n) => l10n.planNameFamily,
    'Про': (l10n) => l10n.planNamePro,
  };

  static String localize(String rawName, AppLocalizations l10n) {
    final mapper = _mappings[rawName.trim()];
    return mapper != null ? mapper(l10n) : rawName;
  }
}
