import 'package:flutter/material.dart';

/// Premium визуальный стиль карточки плана: градиент + иконка.
/// Ключи — те же raw-имена с бэкенда (RU), что и в [PlanLocalizer].
class PlanStyle {
  final List<Color> gradient;
  final IconData icon;

  const PlanStyle(this.gradient, this.icon);

  static const _fallback = PlanStyle(
    [Color(0xFF2A2A2E), Color(0xFF48484E)],
    Icons.workspace_premium_rounded,
  );

  static const Map<String, PlanStyle> _styles = {
    // Про — золото/корона
    'Про': PlanStyle(
      [Color(0xFF3D2F0A), Color(0xFF9C7A22)],
      Icons.workspace_premium_rounded,
    ),
    // Семья (Oila) — фиолет/люди
    'Семья': PlanStyle(
      [Color(0xFF2E1F45), Color(0xFF6B4FA0)],
      Icons.groups_rounded,
    ),
    // Плюс — синий/молния
    'Плюс': PlanStyle(
      [Color(0xFF122845), Color(0xFF2A5DA8)],
      Icons.bolt_rounded,
    ),
    // Старт — зелёный/звезда
    'Старт': PlanStyle(
      [Color(0xFF13321F), Color(0xFF2E7D4F)],
      Icons.star_rounded,
    ),
    // Бесплатно — серый/коробка
    'Бесплатно': PlanStyle(
      [Color(0xFF2A2A2E), Color(0xFF4A4A50)],
      Icons.inventory_2_rounded,
    ),
  };

  static PlanStyle forName(String rawName) =>
      _styles[rawName.trim()] ?? _fallback;
}
