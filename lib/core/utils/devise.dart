/// Monnaie de l'application, en un seul endroit.
///
/// YAA opère en Guinée : la monnaie est le franc guinéen (GNF).
/// Les écrans affichaient auparavant « F » ou « FCFA », hérités des
/// données de test sénégalaises.
///
/// Règle : n'utiliser [kDevise] que pour un montant calculé côté app.
/// Quand une API renvoie son propre champ `devise`, on affiche le
/// sien — c'est lui qui fait foi sur ce qui sera facturé.
const String kDevise = 'GNF';

/// Sépare les milliers par une espace insécable : 2500 → « 2 500 »
String formaterMontant(num montant) {
  final entier = montant.toStringAsFixed(0);
  final tampon = StringBuffer();
  for (var i = 0; i < entier.length; i++) {
    if (i > 0 && (entier.length - i) % 3 == 0) tampon.write(' ');
    tampon.write(entier[i]);
  }
  return tampon.toString();
}

/// Montant prêt à afficher : « 2 500 GNF ».
///
/// [devise] permet de passer celle renvoyée par le serveur ; sans
/// elle, on retombe sur la monnaie de l'app.
String montantLabel(num montant, {String? devise}) =>
    '${formaterMontant(montant)} ${devise ?? kDevise}';
