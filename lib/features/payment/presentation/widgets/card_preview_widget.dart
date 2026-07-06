import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

enum CardBrand { uzcard, humo, visa, mastercard, unknown }

CardBrand detectCardBrand(String digitsOnly) {
  if (digitsOnly.startsWith('8600')) return CardBrand.uzcard;
  if (digitsOnly.startsWith('9860')) return CardBrand.humo;
  if (digitsOnly.startsWith('4')) return CardBrand.visa;
  if (digitsOnly.startsWith('5')) return CardBrand.mastercard;
  return CardBrand.unknown;
}

String cardBrandLabel(CardBrand brand, AppLocalizations l10n) {
  switch (brand) {
    case CardBrand.uzcard:
      return l10n.cardTypeUzcard;
    case CardBrand.humo:
      return l10n.cardTypeHumo;
    case CardBrand.visa:
      return l10n.cardTypeVisa;
    case CardBrand.mastercard:
      return l10n.cardTypeMastercard;
    case CardBrand.unknown:
      return l10n.cardTypeUnknown;
  }
}

/// Shared bank-card mockup used both for a saved card (SubscriptionPage)
/// and for the live input preview (AddCardPage).
class CardPreviewWidget extends StatelessWidget {
  final String numberText;
  final String? expiryText;
  final String detectionDigits;

  const CardPreviewWidget({
    super.key,
    required this.numberText,
    required this.detectionDigits,
    this.expiryText,
  });

  static const _primary = Color(0xFF1A73E8);
  static const _primaryDark = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brandLabel = detectionDigits.isEmpty
        ? null
        : cardBrandLabel(detectCardBrand(detectionDigits), l10n);

    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.credit_card, color: Colors.white70, size: 32),
              if (brandLabel != null)
                Text(
                  brandLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              numberText,
              key: ValueKey(numberText),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (expiryText != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  l10n.validThruLabel,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    expiryText!,
                    key: ValueKey(expiryText),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
