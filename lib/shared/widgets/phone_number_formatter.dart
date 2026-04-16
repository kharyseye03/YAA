import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'yaa_text_field.dart';

/// Reusable phone number text field.
/// Auto-formats input as "XX XXX XX XX" (9 digits max).
/// Use across the app wherever a phone number is required.
class PhoneTextField extends StatelessWidget {
  const PhoneTextField({
    super.key,
    required this.controller,
    this.label = 'Numéro de téléphone',
    this.hint = 'Ex: 77 890 09 09',
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return YaaTextField(
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
        _PhoneNumberFormatter(),
      ],
      validator: validator ?? _defaultValidator,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre numéro';
    }
    final digits = value.replaceAll(' ', '');
    if (digits.length != 9) {
      return 'Le numéro doit contenir 9 chiffres';
    }
    return null;
  }
}

/// Formats a phone number input into "XX XXX XX XX" pattern
/// (9 digits grouped as 2-3-2-2).
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}