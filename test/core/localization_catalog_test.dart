import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ru, uz and en catalogs have the same keys and placeholder names', () {
    final catalogs = <String, Map<String, dynamic>>{};
    for (final language in ['en', 'ru', 'uz']) {
      final source = File('lib/l10n/app_$language.arb').readAsStringSync();
      final rootKeys = RegExp(r'^  "([^\"]+)":', multiLine: true)
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toList();
      expect(rootKeys.toSet().length, rootKeys.length,
          reason: 'Duplicate keys in $language');
      catalogs[language] = jsonDecode(source) as Map<String, dynamic>;
    }
    final template = catalogs['en']!;
    final keys = template.keys.where((key) => !key.startsWith('@')).toSet();
    for (final entry in catalogs.entries) {
      expect(
          entry.value.keys.where((key) => !key.startsWith('@')).toSet(), keys,
          reason: 'Missing or extra keys in ${entry.key}');
      final generated = File('lib/l10n/app_localizations_${entry.key}.dart')
          .readAsStringSync();
      for (final key in keys) {
        final value = entry.value[key];
        expect(value, isA<String>(), reason: '${entry.key}: $key');
        expect((value as String).trim(), isNotEmpty,
            reason: '${entry.key}: $key');
        Set<String> placeholders(String text) => RegExp(r'\{(\w+)')
            .allMatches(text)
            .map((match) => match.group(1)!)
            .toSet();
        expect(placeholders(value), placeholders(template[key] as String),
            reason: 'Placeholder mismatch: ${entry.key}: $key');
        expect(RegExp('\\b$key\\b').hasMatch(generated), isTrue,
            reason: 'Generated translation missing: ${entry.key}: $key');
      }
    }
  });
}
