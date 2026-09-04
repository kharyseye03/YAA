import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/widgets/yaa_text_field.dart';

/// Tout ce qui concerne les numéros de téléphone, en un seul endroit.
///
/// Format guinéen : 9 chiffres groupés 3-2-2-2 — `622 12 34 56`.
/// L'API attend les chiffres bruts, jamais la version espacée.
///
/// Il existait quatre implémentations de ce formatage dans le projet
/// (deux privées dans les écrans d'authentification, deux partagées) ;
/// elles divergeaient déjà entre elles. Tout passe désormais par ici.

/// Nombre de chiffres d'un numéro guinéen
const int kLongueurTelephone = 9;

/// Exemple affiché dans les champs vides
const String kExempleTelephone = 'Ex : 622 12 34 56';

/// `622123456` → `622 12 34 56`
String formatPhone(String value) {
  final chiffres = unformatPhone(value);
  final limite = chiffres.length > kLongueurTelephone
      ? chiffres.substring(0, kLongueurTelephone)
      : chiffres;
  final tampon = StringBuffer();
  for (var i = 0; i < limite.length; i++) {
    if (i == 3 || i == 5 || i == 7) tampon.write(' ');
    tampon.write(limite[i]);
  }
  return tampon.toString();
}

/// `622 12 34 56` → `622123456`, la forme attendue par l'API.
String unformatPhone(String value) => value.replaceAll(RegExp(r'\D'), '');

/// Ramène un numéro **venant du serveur** à ses 9 chiffres locaux.
///
/// Le backend ne stocke pas toujours la même forme : `771234567`,
/// mais aussi `+221771234567` ou `00224622123456` selon la façon dont
/// le compte a été créé. Chargé tel quel dans le champ, un numéro à
/// indicatif fait 12 chiffres — la validation le rejette avec « Le
/// numéro doit contenir 9 chiffres », sur une valeur que
/// l'utilisateur n'a pas saisie et qu'il ne comprend pas.
///
/// On garde les **neuf derniers** chiffres : un indicatif est
/// toujours en tête, jamais en queue. [formatPhone] garde les neuf
/// premiers, ce qui est juste pendant la frappe mais faux ici — il
/// transformerait `+221 77 123 45 67` en `221 77 12 34`, un numéro
/// plausible et pourtant inexistant.
///
/// À appliquer chaque fois qu'une valeur stockée entre dans un champ.
String telephoneLocal(String value) {
  final chiffres = unformatPhone(value);
  return chiffres.length <= kLongueurTelephone
      ? chiffres
      : chiffres.substring(chiffres.length - kLongueurTelephone);
}

/// Valide un numéro saisi. Renvoie null si tout va bien.
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) return 'Champ requis';
  return unformatPhone(value).length == kLongueurTelephone
      ? null
      : 'Le numéro doit contenir $kLongueurTelephone chiffres';
}

/// Applique le format pendant la frappe.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final formate = formatPhone(newValue.text);
    return TextEditingValue(
      text      : formate,
      selection : TextSelection.collapsed(offset: formate.length),
    );
  }
}

/// Les trois filtres à poser sur un champ téléphone : chiffres
/// uniquement, longueur bornée, puis mise en forme.
List<TextInputFormatter> get phoneInputFormatters => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(kLongueurTelephone),
      PhoneInputFormatter(),
    ];

/// Champ téléphone prêt à l'emploi — à préférer partout où l'on
/// demande un numéro, plutôt que de recomposer les formateurs.
class PhoneTextField extends StatelessWidget {
  const PhoneTextField({
    super.key,
    required this.controller,
    this.label = 'Numéro de téléphone',
    this.hint = kExempleTelephone,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return YaaTextField(
      controller      : controller,
      label           : label,
      hint            : hint,
      enabled         : enabled,
      keyboardType    : TextInputType.phone,
      textInputAction : textInputAction,
      onChanged       : onChanged,
      inputFormatters : phoneInputFormatters,
      validator       : validator ?? validatePhone,
    );
  }
}
