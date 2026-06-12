import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../service/location/location_service.dart';

/// Adresse de livraison choisie pour la commande EN COURS uniquement
/// (adresse lisible + latitude/longitude pour le backend).
///
/// `null` → on utilise l'adresse par défaut du profil
/// (`UserProfile.address` + lat/lng, venant de /registrations/detail).
///
/// Modifier cette valeur ne touche PAS l'adresse par défaut du compte
/// (aucun appel au PUT set-adresse) : l'utilisateur peut changer
/// d'adresse juste pour une commande.
final deliveryAddressProvider = StateProvider<LocationResult?>((ref) => null);
