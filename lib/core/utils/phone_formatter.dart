import 'package:flutter/services.dart';

/// Formate la saisie d'un numéro sénégalais au format `77 123 45 67`
/// (9 chiffres, groupés 2-3-2-2).
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = formatPhone(newValue.text);
    return TextEditingValue(
      text      : formatted,
      selection : TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// "771234567" → "77 123 45 67"
String formatPhone(String value) {
  final digits = unformatPhone(value);
  final capped = digits.length > 9 ? digits.substring(0, 9) : digits;
  final buffer = StringBuffer();
  for (var i = 0; i < capped.length; i++) {
    if (i == 2 || i == 5 || i == 7) buffer.write(' ');
    buffer.write(capped[i]);
  }
  return buffer.toString();
}

/// "77 123 45 67" → "771234567" (format attendu par l'API)
String unformatPhone(String value) => value.replaceAll(RegExp(r'\D'), '');

/// Valide un numéro : 9 chiffres attendus
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'Champ requis';
  return unformatPhone(value).length == 9 ? null : 'Numéro invalide';
}
