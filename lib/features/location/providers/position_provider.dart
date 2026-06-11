import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../service/location/location_service.dart';

/// Position actuelle de l'utilisateur (GPS + adresse lisible).
/// Mise en cache : récupérée une fois, puis réutilisée partout.
/// Pour forcer une mise à jour : ref.invalidate(currentPositionProvider)
final currentPositionProvider = FutureProvider<LocationResult>((ref) async {
  return LocationService().getCurrentLocation();
});
