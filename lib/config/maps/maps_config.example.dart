class MapsConfig {
  static const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  static const String placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  static String autocompleteUrl(String input) =>
      '$placesBaseUrl/autocomplete/json'
          '?input=${Uri.encodeComponent(input)}'
          '&components=country:sn'
          '&language=fr'
          '&key=$apiKey';

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