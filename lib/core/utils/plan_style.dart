import 'package:flutter/material.dart';

/// Иконка + цвета icon-бейджа карточки плана по имени.
/// Ключи — те же raw-имена с бэкенда (RU), что и в [PlanLocalizer].
class PlanStyle {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const PlanStyle(this.icon, this.iconBgColor, this.iconColor);

  static const _fallback = PlanStyle(
    Icons.workspace_premium_rounded,
    Color(0xFFF1F5F9),
    Color(0xFF64748B),
  );

  static const Map<String, PlanStyle> _styles = {
    'Про': PlanStyle(
      Icons.workspace_premium_rounded,
      Color(0xFFFEF3E2),
      Color(0xFFB45309),
    ),
    'Семья': PlanStyle(
      Icons.groups_rounded,
      Color(0xFFF3EEFD),
      Color(0xFF7C3AED),
    ),
    'Плюс': PlanStyle(
      Icons.bolt_rounded,
      Color(0xFFE6F1FB),
      Color(0xFF0066FF),
    ),
    'Старт': PlanStyle(
      Icons.star_rounded,
      Color(0xFFE7F7EF),
      Color(0xFF0F9D58),
    ),
    'Бесплатно': PlanStyle(
      Icons.inventory_2_rounded,
      Color(0xFFF1F5F9),
      Color(0xFF64748B),
    ),
  };

  static PlanStyle forName(String rawName) =>
      _styles[rawName.trim()] ?? _fallback;
}
