import 'package:flutter/services.dart';

/// Форматирует узбекский номер: +998 XX XXX XX XX
/// Курсор сохраняется на правильной позиции при редактировании середины.
class UzbekPhoneFormatter extends TextInputFormatter {
  static const _prefix = '+998 ';
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Извлекаем только цифры из нового текста
    final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // 2. Всегда держим префикс 998
    String digits;
    if (newDigits.startsWith('998')) {
      digits = newDigits;
    } else {
      digits = '998$newDigits';
    }
    if (digits.length > 12) digits = digits.substring(0, 12);

    // 3. Форматируем: +998 XX XXX XX XX
    final after = digits.length > 3 ? digits.substring(3) : '';
    final buf = StringBuffer('+998');
    if (after.isNotEmpty) {
      buf.write(' ');
      buf.write(after.substring(0, after.length.clamp(0, 2)));
    }
    if (after.length > 2) {
      buf.write(' ');
      buf.write(after.substring(2, after.length.clamp(2, 5)));
    }
    if (after.length > 5) {
      buf.write(' ');
      buf.write(after.substring(5, after.length.clamp(5, 7)));
    }
    if (after.length > 7) {
      buf.write(' ');
      buf.write(after.substring(7, after.length.clamp(7, 9)));
    }

    final formatted = buf.toString();

    // 4. Защита: если стёрли префикс — возвращаем +998 с курсором в конце
    if (formatted.length <= _prefix.length) {
      return const TextEditingValue(
        text: _prefix,
        selection: TextSelection.collapsed(offset: _prefix.length),
      );
    }

    // 5. Умный курсор: считаем сколько значимых цифр было ДО курсора в старом тексте
    //    и восстанавливаем эту же позицию в новом отформатированном тексте
    // Новые цифры до курсора — с учётом что мы могли добавить/удалить цифру
    final newDigitsBeforeCursor = newValue.text
        .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'[^\d]'), '')
        .length;

    // Считаем позицию курсора в отформатированной строке по кол-ву цифр
    int targetDigits = newDigitsBeforeCursor;
    // Префикс 998 всегда присутствует — курсор не может быть перед ним
    if (targetDigits < 3) targetDigits = 3;

    int newCursor = 0;
    int digitsSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitsSeen++;
        if (digitsSeen == targetDigits) {
          newCursor = i + 1;
          break;
        }
      }
    }
    // Если не нашли — ставим в конец
    if (newCursor == 0) newCursor = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  static String extractDigits(String formatted) =>
      formatted.replaceAll(RegExp(r'[^\d]'), '');

  static bool isValid(String formatted) =>
      extractDigits(formatted).length == 12;
}
