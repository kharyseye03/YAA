import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../config/maps/maps_config.dart';

/// Suggestion d'adresse retournée par l'autocomplétion Google Places
class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({required this.placeId, required this.description});
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
            .where((e) => e != null && e.isNotEmpty)
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
  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().length < 3) return [];

    final response =
        await http.get(Uri.parse(MapsConfig.autocompleteUrl(input)));

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
    return predictions
        .map((p) => PlaceSuggestion(
              placeId     : p['place_id'] as String,
              description : p['description'] as String,
            ))
        .toList();
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

    return LocationResult(
      adresse   : result['formatted_address'] as String? ?? suggestion.description,
      latitude  : (location['lat'] as num).toDouble(),
      longitude : (location['lng'] as num).toDouble(),
    );
  }
}
