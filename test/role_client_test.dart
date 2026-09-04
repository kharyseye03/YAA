import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaa/features/auth/providers/auth_notifier.dart';

/// Fabrique un jeton non signé : seule la charge utile est lue, la
/// signature est vérifiée par le serveur, pas par nous.
String jeton(Map<String, dynamic> payload) {
  String b64(Object o) => base64Url
      .encode(utf8.encode(json.encode(o)))
      .replaceAll('=', '');
  return '${b64({'alg': 'RS256'})}.${b64(payload)}.signature';
}

void main() {
  test('un compte CLIENT est accepté', () {
    expect(
      AuthNotifier.estCompteClient(jeton({
        'realm_access': {
          'roles': ['default-roles-yaagn', 'offline_access', 'CLIENT'],
        },
      })),
      isTrue,
    );
  });

  test('un compte coursier est refusé', () {
    expect(
      AuthNotifier.estCompteClient(jeton({
        'realm_access': {
          'roles': ['default-roles-yaagn', 'LIVREUR'],
        },
      })),
      isFalse,
    );
  });

  test('un jeton sans realm_access est refusé', () {
    expect(AuthNotifier.estCompteClient(jeton({'sub': 'x'})), isFalse);
  });

  test('un jeton illisible est refusé, sans lever', () {
    expect(AuthNotifier.estCompteClient('pas-un-jwt'), isFalse);
    expect(AuthNotifier.estCompteClient(''), isFalse);
  });

  test('un rôle proche ne suffit pas', () {
    expect(
      AuthNotifier.estCompteClient(jeton({
        'realm_access': {'roles': ['CLIENTS', 'client']},
      })),
      isFalse,
    );
  });
}
