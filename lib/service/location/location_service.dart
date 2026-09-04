import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../config/maps/maps_config.dart';

/// Suggestion d'adresse retournée par l'autocomplétion Google Places
class PlaceSuggestion {
  final String placeId;
  final String description;
  final List<String> types;     // types Google du lieu (restaurant, pharmacy…)
  final String mainText;        // nom du lieu (ex: "Pharmacie Guigon")
  final String secondaryText;   // adresse (ex: "Avenue Cheikh Anta Diop, Dakar")

  /// Distance à vol d'oiseau depuis la position de l'utilisateur.
  /// Null si l'autocomplétion a été appelée sans origine.
  final int? distanceMetres;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.types         = const [],
    this.mainText      = '',
    this.secondaryText = '',
    this.distanceMetres,
  });

  /// « 480 m » ou « 1,2 km » — vide si la distance est inconnue.
  /// C'est un vol d'oiseau, pas un trajet routier : ça sert à classer
  /// les suggestions entre elles, pas à estimer un temps de route.
  String get distanceLabel {
    final d = distanceMetres;
    if (d == null) return '';
    if (d < 1000) return '$d m';
    return '${(d / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}

/// Résultat d'une localisation : adresse lisible + coordonnées GPS
class LocationResult {
  final String adresse;
  final double latitude;
  final double longitude;

  const LocationResult({
    required this.adresse,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  // Détecte un "Plus Code" Google (ex: "PG8J+MWG", "8FVC9G8F+5W")
  // que le reverse geocoding met parfois en début d'adresse.
  static final _plusCodeRegExp = RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}$');
  static bool _isPlusCode(String value) =>
      _plusCodeRegExp.hasMatch(value.trim());

  /// Retire un Plus Code présent en tête d'une adresse à segments
  /// (ex: "PG8J+MWG, Mermoz, Dakar" → "Mermoz, Dakar").
  static String cleanAddress(String adresse) {
    final parts = adresse.split(',').map((e) => e.trim());
    final cleaned =
        parts.where((e) => e.isNotEmpty && !_isPlusCode(e)).join(', ');
    return cleaned.isEmpty ? adresse : cleaned;
  }

  // ── Position actuelle (GPS) ─────────────────────────────────
  /// Demande la permission, récupère la position GPS puis la
  /// convertit en adresse lisible (reverse geocoding natif).
  Future<LocationResult> getCurrentLocation() async {
    // 1. Vérifier que le GPS du téléphone est activé
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Veuillez activer la localisation de votre téléphone');
    }

    // 2. Vérifier / demander la permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Permission refusée définitivement. Activez-la dans les réglages.');
    }

    // 3. Récupérer la position GPS
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // 4. Convertir les coordonnées en adresse lisible
    String adresse = 'Position actuelle';
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        adresse = [p.street, p.subLocality, p.locality]
            .where((e) => e != null && e.isNotEmpty && !_isPlusCode(e))
            .join(', ');
        if (adresse.isEmpty) adresse = 'Position actuelle';
      }
    } catch (_) {
      // Le reverse geocoding peut échouer — on garde les coordonnées
    }

    return LocationResult(
      adresse   : adresse,
      latitude  : position.latitude,
      longitude : position.longitude,
    );
  }

  // ── Autocomplétion (Google Places API) ──────────────────────
  /// Retourne des suggestions d'adresses pendant la saisie
  /// [origine] : position de l'utilisateur. Fournie, Google calcule la
  /// distance de chaque suggestion et la renvoie dans la même réponse.
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    LatLng? origine,
  }) async {
    if (input.trim().length < 3) return [];

    // Sans origine explicite, on prend la dernière position connue du
    // système : elle est immédiate, ne réveille pas le GPS, et suffit
    // largement pour une distance indicative. Si elle est absente, on
    // s'en passe — la distance ne s'affichera simplement pas.
    var depuis = origine;
    if (depuis == null) {
      try {
        final derniere = await Geolocator.getLastKnownPosition();
        if (derniere != null) {
          depuis = (derniere.latitude, derniere.longitude);
        }
      } catch (_) {
        // Permission absente ou service coupé : on continue sans
      }
    }

    final response = await http.get(
        Uri.parse(MapsConfig.autocompleteUrl(input, origine: depuis)));

    if (response.statusCode != 200) {
      throw Exception('Erreur Places API (${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;

    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') {
      throw Exception('Places API : ${data['error_message'] ?? status}');
    }

    final predictions = data['predictions'] as List<dynamic>;
    return predictions.map((p) {
      final formatting = p['structured_formatting'] as Map<String, dynamic>?;
      return PlaceSuggestion(
        placeId       : p['place_id'] as String,
        description   : p['description'] as String,
        types         : (p['types'] as List<dynamic>?)
                            ?.map((t) => t as String)
                            .toList() ??
                        const [],
        mainText      : formatting?['main_text'] as String? ?? '',
        distanceMetres: (p['distance_meters'] as num?)?.toInt(),
        secondaryText : formatting?['secondary_text'] as String? ?? '',
      );
    }).toList();
  }

  // ── Détails d'un lieu sélectionné ───────────────────────────
  /// Récupère les coordonnées GPS d'une suggestion sélectionnée
  Future<LocationResult> getPlaceDetails(PlaceSuggestion suggestion) async {
    final response =
        await http.get(Uri.parse(MapsConfig.placeDetailsUrl(suggestion.placeId)));

    if (response.statusCode != 200) {
      throw Exception('Erreur Places API (${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') {
      throw Exception('Places API : ${data['error_message'] ?? data['status']}');
    }

    final result   = data['result'] as Map<String, dynamic>;
    final location = result['geometry']['location'] as Map<String, dynamic>;

    final formatted =
        result['formatted_address'] as String? ?? suggestion.description;

    return LocationResult(
      adresse   : cleanAddress(formatted),
      latitude  : (location['lat'] as num).toDouble(),
      longitude : (location['lng'] as num).toDouble(),
    );
  }

  // ── Tracé du trajet (Directions API) ─────────────────────────
  /// Retourne les points du trajet routier A → B sous forme de
  /// paires [latitude, longitude]. Liste vide si aucun trajet.
  Future<List<List<double>>> getRoutePolyline({
    required double departLat,
    required double departLng,
    required double arriveeLat,
    required double arriveeLng,
  }) async {
    final url = MapsConfig.directionsUrl(
      originLat : departLat,
      originLng : departLng,
      destLat   : arriveeLat,
      destLng   : arriveeLng,
    );
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Erreur Directions API (${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String?;
    if (status != 'OK') {
      throw Exception('Directions : ${data['error_message'] ?? status}');
    }

    final routes = data['routes'] as List<dynamic>;
    if (routes.isEmpty) return [];
    final encoded =
        routes.first['overview_polyline']['points'] as String;
    return _decodePolyline(encoded);
  }

  /// Décode une polyline encodée Google en liste de [lat, lng].
  static List<List<double>> _decodePolyline(String encoded) {
    final points = <List<double>>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add([lat / 1e5, lng / 1e5]);
    }
    return points;
  }
}
