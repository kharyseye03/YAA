import 'package:flutter_test/flutter_test.dart';
import 'package:yaa/core/utils/phone_formatter.dart';

void main() {
  group('telephoneLocal — formes renvoyées par le serveur', () {
    test('numéro déjà local, inchangé', () {
      expect(telephoneLocal('771234567'), '771234567');
    });

    test('indicatif sénégalais avec +', () {
      expect(telephoneLocal('+221771234567'), '771234567');
    });

    test('indicatif guinéen avec +', () {
      expect(telephoneLocal('+224622123456'), '622123456');
    });

    test('indicatif en 00', () {
      expect(telephoneLocal('00221771234567'), '771234567');
    });

    test('indicatif et espaces', () {
      expect(telephoneLocal('+221 77 123 45 67'), '771234567');
    });

    test('numéro trop court laissé tel quel, pour que la validation parle', () {
      expect(telephoneLocal('7712'), '7712');
    });

    test('vide', () => expect(telephoneLocal(''), ''));
  });

  test('le piège que formatPhone seul ne voit pas', () {
    // formatPhone garde les 9 PREMIERS chiffres : neuf chiffres
    // plausibles, validation satisfaite, numéro pourtant faux.
    expect(formatPhone('+221771234567'), '221 77 12 34');
    // Avec la normalisation, le vrai numéro ressort.
    expect(formatPhone(telephoneLocal('+221771234567')), '771 23 45 67');
  });

  test('un numéro normalisé passe la validation', () {
    expect(validatePhone(formatPhone(telephoneLocal('+221771234567'))), isNull);
    expect(validatePhone('+221771234567'), isNotNull); // avant correctif
  });
}
