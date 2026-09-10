/// Coordonnées passées à l'autocomplétion pour obtenir les distances
typedef LatLng = (double, double);

class MapsConfig {
  // ── Zone d'exploitation ───────────────────────────────────

  /// Centre de la carte tant que la position réelle n'est pas connue.
  ///
  /// Conakry : marché principal. Ce n'est qu'un repli — dès que le GPS
  /// répond, la carte suit l'utilisateur, où qu'il soit dans la zone.
  ///
  /// En deux champs plutôt qu'un record : Dart interdit d'accéder aux
  /// champs d'un record dans une expression constante, et les écrans
  /// en ont besoin pour construire un `LatLng` const.
  static const double villeLat = 9.6412;
  static const double villeLng = -13.5784;

  /// Pays où l'autocomplétion propose des adresses (ISO 3166-1).
  ///
  /// Guinée **et** Sénégal, parce que c'est exactement ce que le
  /// backend autorise : il refuse une inscription avec « Service
  /// disponible uniquement en Guinée et au Sénégal ». N'en accepter
  /// qu'un rendait l'app plus restrictive que le serveur — un testeur
  /// à Dakar ne trouvait aucune adresse alors que son compte était
  /// parfaitement valide.
  ///
  /// Places accepte jusqu'à cinq pays, séparés par une barre verticale.
  static const List<String> paysAutorises = ['gn', 'sn'];

  /// `country:gn|country:sn` — la forme attendue par Places.
  static String get _filtrePays =>
      paysAutorises.map((p) => 'country:$p').join('|');

  // Clé « Web — YAA client » : appels HTTPS faits depuis le code Dart
  // (Places, Directions). Ce type d'appel ne peut recevoir aucune
  // restriction d'application — sa seule protection est la restriction
  // d'API côté Cloud Console, plus un plafond de quota.
  static const String apiKey = 'VOTRE_CLE_GOOGLE_MAPS_ICI';

  // ── Places API (autocomplétion) ───────────────────────────
  static const String placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Autocomplétion : suggestions d'adresses pendant la saisie
  // components=country → restreint aux pays où YAA opère
  /// Suggestions de lieux.
  ///
  /// Quand [origine] est fournie, Google calcule lui-même la distance
  /// à vol d'oiseau et la renvoie dans `distance_meters`, sans appel
  /// ni facturation supplémentaires. Sans elle, l'autocomplétion ne
  /// renvoie aucune coordonnée — il faudrait interroger Place Details
  /// pour chaque suggestion.
  static String autocompleteUrl(String input, {LatLng? origine}) =>
      '$placesBaseUrl/autocomplete/json'
          '?input=${Uri.encodeComponent(input)}'
          '&components=$_filtrePays'
          '&language=fr'
          '${origine == null ? '' : '&origin=${origine.$1},${origine.$2}'}'
          '&key=$apiKey';

  // Détails d'un lieu : récupère les coordonnées GPS à partir
  // du place_id retourné par l'autocomplétion
  static String placeDetailsUrl(String placeId) =>
      '$placesBaseUrl/details/json'
          '?place_id=$placeId'
          '&fields=geometry,formatted_address'
          '&language=fr'
          '&key=$apiKey';

  // ── Directions API (tracé du trajet A → B) ────────────────
  static String directionsUrl({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) =>
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$originLat,$originLng'
          '&destination=$destLat,$destLng'
          '&mode=driving'
          '&language=fr'
          '&key=$apiKey';
}

// ─────────────────────────────────────────────────────────────
// Gabarit — le vrai fichier, maps_config.dart, est exclu du dépôt
// (.gitignore) parce qu'il porte la clé Google Maps.
//
// Pour démarrer sur un poste neuf :
//   1. copier ce fichier en lib/config/maps/maps_config.dart
//   2. y coller la clé du projet Google Cloud
//
// Ce gabarit est une copie exacte du fichier réel, clé masquée. Le
// tenir à jour n'est pas cosmétique : il avait divergé, et un clone
// frais ne compilait plus — villeLat, villeLng, paysAutorises et le
// typedef LatLng manquaient alors que trois écrans les utilisent.
