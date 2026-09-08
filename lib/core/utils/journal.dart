import 'package:flutter/foundation.dart';

/// Trace de développement, muette en production.
///
/// **Le piège que ça referme.** `debugPrint` ne disparaît pas d'un
/// build release — son nom le laisse croire, mais il écrit dans
/// `logcat` sur l'appareil du client, où toute application dotée de la
/// permission de lecture des journaux peut le lire. L'app y déposait
/// ainsi l'adresse e-mail et le nom de chaque utilisateur.
///
/// `journal` ne parle que hors release. Un message ajouté à la hâte
/// pendant un débogage ne peut donc plus fuiter en production, même
/// oublié dans le code.
///
/// Pour tout ce qui touche au réseau, préférer `ApiLogger` : il met en
/// forme méthode, statut et durée, et masque déjà les mots de passe.
void journal(Object? message) {
  if (kReleaseMode) return;
  debugPrint(message?.toString() ?? 'null');
}
