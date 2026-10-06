import 'dart:async';
import '../utils/journal.dart';


/// Ce que l'application dit à l'utilisateur quand quelque chose échoue.
///
/// **Le principe.** L'écran ne dit jamais *pourquoi* techniquement. Ni
/// code HTTP, ni nom de service, ni phrase renvoyée par le serveur :
/// tout cela s'adresse à nous, pas au client. Il n'a besoin que d'une
/// chose — savoir s'il peut agir, ou s'il doit seulement réessayer.
///
/// **Trois cas seulement**, parce que c'est tout ce qui change quelque
/// chose pour lui :
///   - il n'a pas de réseau      → il peut le rétablir
///   - sa session a expiré       → il doit se reconnecter
///   - tout le reste             → il n'y peut rien, qu'il réessaie
///
/// Distinguer un 500 d'un 404 à l'écran n'aiderait personne : dans les
/// deux cas l'utilisateur n'a aucune prise. Le détail part dans les
/// logs, où il nous sert vraiment.
/// Refus de saisie expliqué par le serveur, destiné à l'utilisateur.
///
/// Un type à part, et non une `Exception` ordinaire portant du texte :
/// c'est ce qui permet à [MessagesErreur.depuisException] de laisser
/// passer cette phrase-là sans ouvrir la porte à tout le reste. Sans
/// lui il faudrait deviner, au vu d'une chaîne, si elle vient d'une
/// validation ou d'une trace échappée — et deviner finit toujours par
/// se tromper dans le mauvais sens.
class ErreurValidation implements Exception {
  const ErreurValidation(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract final class MessagesErreur {
  /// Réseau absent : le seul cas où l'utilisateur peut corriger.
  static const String horsLigne =
      'Vérifiez votre connexion et réessayez.';

  /// Session expirée : le seul cas qui appelle une action précise.
  static const String sessionExpiree =
      'Votre session a expiré. Reconnectez-vous.';

  /// Tout le reste. Serveur en panne, ressource absente, requête
  /// rejetée, réponse illisible : de son point de vue c'est identique.
  static const String generique = 'Une erreur est survenue. Réessayez.';

  // Anciens noms, conservés pour ne pas éparpiller les appels.
  static const String delaiDepasse       = generique;
  static const String serveurInjoignable = generique;
  static const String requeteInvalide    = generique;
  static const String accesRefuse        = generique;
  static const String introuvable        = generique;
  static const String conflit            = generique;
  static const String serveurEnErreur    = generique;
  static const String inattendue         = generique;
  static const String reponseIllisible   = generique;

  /// Identifiants refusés à la connexion.
  ///
  /// Seule entorse à la règle du message unique, et elle est
  /// nécessaire : sans elle, quelqu'un qui se trompe de mot de passe
  /// lirait « Une erreur est survenue » et réessaierait indéfiniment
  /// le même. Ce n'est pas une fuite technique — ça ne révèle ni le
  /// fonctionnement du serveur, ni si le compte existe.
  static const String identifiantsInvalides =
      'Numéro ou mot de passe incorrect.';

  /// Compte valide, mais qui n'a rien à faire ici : un coursier.
  ///
  /// Volontairement la même phrase que des identifiants refusés.
  /// Deux raisons : c'est court, et surtout ça ne confirme pas
  /// l'existence du compte sous un autre rôle. Un message distinct
  /// permettrait de deviner, numéro par numéro, qui est coursier.
  static const String compteNonClient = identifiantsInvalides;

  /// Traduction d'une réponse d'erreur du serveur d'authentification.
  ///
  /// Keycloak répond en anglais et en jargon (« invalid_grant »,
  /// « Account is not fully set up ») : rien de tout cela ne doit
  /// s'afficher. Seul le cas des identifiants refusés est distingué,
  /// le reste part dans les logs.
  static String pourAuthentification(
    int statut,
    String? code,
    String? description,
  ) {
    if (code != null || description != null) {
      journal('↩︎ auth ($statut) : $code — $description');
    }
    return code == 'invalid_grant'
        ? identifiantsInvalides
        : pourStatut(statut);
  }

  /// Message pour un code HTTP.
  ///
  /// Seul 401 se distingue : lui seul demande une action que
  /// l'utilisateur peut accomplir.
  static String pourStatut(int statut) =>
      statut == 401 ? sessionExpiree : generique;

  /// Message quand le serveur a répondu avec un corps.
  ///
  /// **La ligne de partage est le code, pas le goût.**
  ///
  /// Un **400** ou un **422** dit ce que l'utilisateur a mal saisi :
  /// « Service disponible uniquement en Guinée et au Sénégal »,
  /// « Ce numéro est déjà utilisé ». Ces phrases sont écrites pour
  /// lui, elles nomment une action qu'il peut corriger, et les cacher
  /// le laisse réessayer la même chose indéfiniment.
  ///
  /// Tout le reste — 500 en tête — parle de nous, pas de lui.
  /// « Erreur interne du serveur » n'apprend rien, n'oriente vers
  /// aucune action, et donne l'impression que l'application est
  /// cassée. Ces messages restent dans les journaux.
  ///
  /// Un garde-fou tout de même : au-delà de [_longueurMaxServeur], ce
  /// n'est plus une phrase mais une trace technique échappée d'un
  /// framework. On la journalise et on affiche le message générique.
  static Exception depuisReponse(int statut, String? messageServeur) {
    final m = messageServeur?.trim();
    if (m == null || m.isEmpty) return Exception(pourStatut(statut));

    journal('↩︎ serveur ($statut) : $m');

    final estValidation = statut == 400 || statut == 422;
    if (estValidation && m.length <= _longueurMaxServeur) {
      return ErreurValidation(m);
    }
    return Exception(pourStatut(statut));
  }

  /// Au-delà, ce n'est plus un message mais une trace.
  static const int _longueurMaxServeur = 160;

  /// Phrase présentable pour n'importe quelle exception attrapée.
  ///
  /// Filet de sécurité pour les écrans qui affichent encore le
  /// résultat brut d'un `catch` : rien de technique ne doit passer,
  /// qu'il s'agisse du préfixe « Exception: », d'un `ParallelWaitError`
  /// ou d'une trace quelconque.
  ///
  /// Seuls nos propres messages, définis ci-dessus, sont laissés
  /// passer. Tout le reste devient [generique] et part dans les logs.
  static String depuisException(Object e) {
    // Refus de saisie : le serveur a expliqué à l'utilisateur ce qu'il
    // doit corriger. Le type garantit l'origine du message, aucune
    // heuristique n'est nécessaire.
    if (e is ErreurValidation) return e.message;

    final texte = e.toString().replaceAll('Exception: ', '').trim();
    if (e is ParallelWaitError || !_connus.contains(texte)) {
      journal('↩︎ exception non présentable : $e');
      return generique;
    }
    return texte;
  }

  static const Set<String> _connus = {
    horsLigne,
    sessionExpiree,
    // compteNonClient vaut la même phrase, il est donc déjà couvert
    identifiantsInvalides,
    generique,
  };
}
