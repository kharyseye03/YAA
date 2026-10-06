import 'package:flutter_test/flutter_test.dart';
import 'package:yaa/core/errors/messages_erreur.dart';

/// Ce que l'utilisateur lit quand quelque chose échoue.
///
/// La règle est simple mais l'équilibre est fin : assez d'information
/// pour qu'il puisse corriger, jamais assez pour exposer le
/// fonctionnement du serveur. Ces tests figent la frontière.
void main() {
  group('depuisReponse — ce qui remonte du serveur', () {
    test('400 : le message du serveur est affiché', () {
      // Le cas vécu : « Service disponible uniquement en Guinée et au
      // Sénégal ». Le cacher laissait réessayer le même numéro.
      final e = MessagesErreur.depuisReponse(
          400, 'Service disponible uniquement en Guinée et au Sénégal.');
      expect(e, isA<ErreurValidation>());
      expect(MessagesErreur.depuisException(e),
          'Service disponible uniquement en Guinée et au Sénégal.');
    });

    test('422 aussi — même nature de refus', () {
      final e = MessagesErreur.depuisReponse(422, 'Numéro déjà utilisé.');
      expect(MessagesErreur.depuisException(e), 'Numéro déjà utilisé.');
    });

    test('500 : le message du serveur ne sort jamais', () {
      // « Erreur interne du serveur » n'aide personne et fait porter
      // le chapeau à l'application.
      final e = MessagesErreur.depuisReponse(500, 'Erreur interne du serveur');
      expect(MessagesErreur.depuisException(e), MessagesErreur.generique);
    });

    test('401 : session expirée, quel que soit le texte du serveur', () {
      final e = MessagesErreur.depuisReponse(401, 'JWT expired at ...');
      expect(MessagesErreur.depuisException(e), MessagesErreur.sessionExpiree);
    });

    test('400 avec une trace trop longue : écartée', () {
      // Au-delà de 160 caractères ce n'est plus une phrase écrite pour
      // l'utilisateur, mais une pile d'appels échappée d'un framework.
      final trace = 'jakarta.validation.ConstraintViolationException: ${'x' * 200}';
      final e = MessagesErreur.depuisReponse(400, trace);
      expect(MessagesErreur.depuisException(e), MessagesErreur.generique);
    });

    test('400 sans message : générique', () {
      final e = MessagesErreur.depuisReponse(400, null);
      expect(MessagesErreur.depuisException(e), MessagesErreur.generique);
    });
  });

  group('depuisException — le filet devant l\'écran', () {
    test('une exception technique ne passe pas', () {
      final e = Exception('SocketException: Failed host lookup');
      expect(MessagesErreur.depuisException(e), MessagesErreur.generique);
    });

    test('nos propres messages passent tels quels', () {
      expect(
        MessagesErreur.depuisException(Exception(MessagesErreur.horsLigne)),
        MessagesErreur.horsLigne,
      );
    });

    test('un compte coursier lit la même phrase qu\'un mot de passe faux', () {
      // Volontaire : un message distinct permettrait de deviner,
      // numéro par numéro, qui est coursier.
      expect(MessagesErreur.compteNonClient,
          MessagesErreur.identifiantsInvalides);
    });
  });
}
