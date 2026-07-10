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
}