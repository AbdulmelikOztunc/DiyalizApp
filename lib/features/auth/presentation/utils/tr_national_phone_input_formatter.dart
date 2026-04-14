import 'package:flutter/services.dart';

/// Türkiye ulusal cep formatı:
/// - Kullanıcı `507...` yazarsa ekranda `0 507 680 6503` gibi görünür.
/// - Kullanıcı `0507...` yazarsa yine aynı görünüme normalize edilir.
/// - Kullanıcı yalnız `0` yazarsa ekranda sadece `0` görünür.
final class TrNationalPhoneInputFormatter extends TextInputFormatter {
  TrNationalPhoneInputFormatter({this.maxDigits = 10});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.isEmpty) {
      return newValue;
    }

    final rawDigits = _digitsOnly(newText);
    final normalizedNational = _normalizeToNational(rawDigits, maxDigits);
    final formatted = _formatDisplay(rawDigits, normalizedNational);
    final before = newValue.selection.start.clamp(0, newText.length);
    var digitCountBefore = 0;
    for (var i = 0; i < before; i++) {
      if (i < newText.length && _isDigit(newText.codeUnitAt(i))) {
        digitCountBefore++;
      }
    }
    final displayDigits = _digitsOnly(formatted);
    var caretDigitsBefore = digitCountBefore;
    if (rawDigits.isNotEmpty && !rawDigits.startsWith('0')) {
      caretDigitsBefore += 1;
    }
    if (caretDigitsBefore > displayDigits.length) {
      caretDigitsBefore = displayDigits.length;
    }

    final newOffset = _offsetAfterDigitCount(formatted, caretDigitsBefore);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  static String _stripLeadingZeros(String digits) {
    var d = digits;
    while (d.startsWith('0')) {
      d = d.substring(1);
    }
    return d;
  }

  static String _normalizeToNational(String rawDigits, int maxDigits) {
    var national = _stripLeadingZeros(rawDigits);
    if (national.length > maxDigits) {
      national = national.substring(0, maxDigits);
    }
    return national;
  }

  static String _formatDisplay(String rawDigits, String nationalDigits) {
    if (rawDigits.isEmpty) return '';
    if (nationalDigits.isEmpty) return '0';

    if (nationalDigits.length <= 3) {
      return '0 $nationalDigits';
    }
    if (nationalDigits.length <= 6) {
      return '0 ${nationalDigits.substring(0, 3)} ${nationalDigits.substring(3)}';
    }
    return '0 ${nationalDigits.substring(0, 3)} ${nationalDigits.substring(3, 6)} '
        '${nationalDigits.substring(6)}';
  }

  static int _offsetAfterDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_isDigit(formatted.codeUnitAt(i))) {
        seen++;
        if (seen == digitCount) return i + 1;
      }
    }
    return formatted.length;
  }

  /// API / doğrulama: `0` ile başlayan 11 hane.
  static String toApiDigits(String formattedOrPlain, {int maxDigits = 10}) {
    final national = _normalizeToNational(_digitsOnly(formattedOrPlain), maxDigits);
    if (national.isEmpty) {
      return '';
    }
    return '0$national';
  }
}
