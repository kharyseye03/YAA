class MapsConfig {
  // ⚠️ Colle ici ta clé API Google Cloud (AIzaSy...)
  static const String apiKey = 'AIzaSyBUIUFuknenEGOxzRekkzhbyHE6RubvcGE';

  // ── Places API (autocomplétion) ───────────────────────────
  static const String placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Autocomplétion : suggestions d'adresses pendant la saisie
  // components=country:sn → limite les résultats au Sénégal
  static String autocompleteUrl(String input) =>
      '$placesBaseUrl/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&components=country:sn'
      '&language=fr'
      '&key=$apiKey';

  // Détails d'un lieu : récupère les coordonnées GPS à partir
  // du place_id retourné par l'autocomplétion
  static String placeDetailsUrl(String placeId) =>
      '$placesBaseUrl/details/json'
      '?place_id=$placeId'
      '&fields=geometry,formatted_address'
      '&language=fr'
      '&key=$apiKey';
}
