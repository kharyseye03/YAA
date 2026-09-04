/// Coordonnées publiques de YAA et liens sortants.
///
/// Regroupés ici plutôt qu'écrits dans les écrans : un numéro de
/// support change, et il ne doit alors se corriger qu'à un endroit.
abstract final class AppContacts {
  /// Support client — ligne guinéenne, indicatif compris.
  static const String telephoneSupport = '+224610781799';

  static const String emailSupport = 'yaa.support@gmail.com';

  static const String siteWeb = 'https://yaagn.com';

  /// Destination de la carte « Devenir coursier ».
  ///
  /// Renvoie vers le site tant que YAA PRO n'est pas publié. Le jour
  /// du déploiement, remplacer par la fiche du magasin — Android et
  /// iOS séparément, `Platform.isIOS` décidant lequel ouvrir :
  ///   Play Store : https://play.google.com/store/apps/details?id=gn.yaa.pro
  ///   App Store  : https://apps.apple.com/app/id + identifiant
  static const String lienDevenirCoursier = siteWeb;
}
