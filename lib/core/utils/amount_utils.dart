import 'package:flutter/services.dart';

/// Parses a user-entered decimal amount, accepting BOTH '.' and ',' as the
/// decimal separator.
///
/// Comma-decimal locales (fr, nl, es, de, …) show a comma as the decimal key on
/// the numeric keypad, and plain `double.parse`/`double.tryParse` rejects "1,5",
/// which previously made amount fields unusable in those locales. Keypad input
/// only ever produces a single separator, so normalizing ',' to '.' is safe;
/// genuinely malformed input (e.g. two separators) still yields null.
double? parseAmount(String? input) {
  if (input == null) return null;
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

/// TextInputFormatter that accepts digits and a single decimal separator (either
/// '.' or ','), matching what numeric keypads produce across locales while
/// blocking stray characters. Pair with `parseAmount` on the value.
class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange = 9});

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final pattern = RegExp('^\\d*([.,]\\d{0,$decimalRange})?\$');
    return pattern.hasMatch(text) ? newValue : oldValue;
  }
}
