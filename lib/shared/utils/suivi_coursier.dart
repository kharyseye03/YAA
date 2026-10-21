import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Calculs du suivi d'un véhicule sur son itinéraire.
///
/// Trois besoins, un seul outil : orienter le marqueur dans le sens de
/// la marche, effacer le tracé déjà parcouru, et le faire sans à-coups
/// entre deux relevés de position.
///
/// Tout est géométrique et local : aucune requête, donc aucun coût.
class SuiviCoursier {
  const SuiviCoursier._();

  /// Index du point du tracé le plus proche de [position].
  ///
  /// Sert à deux choses : savoir où couper le tracé — ce qui est
  /// derrière est parcouru — et sur quel segment lire la direction.
  ///
  /// Comparaison en degrés au carré, sans racine ni conversion en
  /// mètres : on cherche un minimum, pas une distance. À l'échelle
  /// d'une ville, l'écart avec un vrai calcul géodésique est sans
  /// effet sur le classement.
  static int indexLePlusProche(List<LatLng> trace, LatLng position) {
    if (trace.isEmpty) return 0;
    var meilleur = 0;
    var minimum  = double.infinity;
    for (var i = 0; i < trace.length; i++) {
      final dLat = trace[i].latitude  - position.latitude;
      final dLng = trace[i].longitude - position.longitude;
      final d    = dLat * dLat + dLng * dLng;
      if (d < minimum) {
        minimum  = d;
        meilleur = i;
      }
    }
    return meilleur;
  }

  /// Ce qu'il reste à parcourir : le tracé coupé à hauteur du coursier,
  /// sa position exacte en tête.
  ///
  /// Le trait s'efface ainsi derrière lui au fil de sa progression,
  /// au lieu de rester tendu du départ à l'arrivée.
  static List<LatLng> traceRestant(List<LatLng> trace, LatLng position) {
    if (trace.isEmpty) return const [];
    final i = indexLePlusProche(trace, position);
    return [position, ...trace.sublist(math.min(i + 1, trace.length))];
  }

  /// Cap du véhicule, en degrés depuis le nord.
  ///
  /// Lu **sur l'itinéraire**, pas entre deux positions GPS : c'est ce
  /// qui change tout. Deux relevés successifs donnent un cap
  /// instable — à l'arrêt, le point sautille de quelques mètres et le
  /// véhicule tournoie sur lui-même. Le tracé, lui, est lisse par
  /// construction : dans un virage, l'angle suit la courbe de la rue.
  ///
  /// Null si le tracé est trop court pour donner une direction ;
  /// l'appelant garde alors le dernier cap connu plutôt que de
  /// remettre le véhicule au nord.
  static double? capSurTrace(List<LatLng> trace, LatLng position) {
    if (trace.length < 2) return null;
    final i = indexLePlusProche(trace, position);
    // Le segment regardé part du point courant vers le suivant ; sur
    // le dernier point, on reprend le segment précédent.
    final a = i < trace.length - 1 ? trace[i]     : trace[i - 1];
    final b = i < trace.length - 1 ? trace[i + 1] : trace[i];
    return cap(a, b);
  }

  /// Cap de [a] vers [b], en degrés depuis le nord, dans [0, 360).
  static double cap(LatLng a, LatLng b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLng = _rad(b.longitude - a.longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    return (_deg(math.atan2(y, x)) + 360) % 360;
  }

  /// Angle intermédiaire entre [depuis] et [vers], par le chemin le
  /// plus court.
  ///
  /// Sans ce traitement, passer de 359° à 1° ferait tourner le
  /// véhicule de 358° dans le mauvais sens : un tour complet sur
  /// lui-même à chaque passage par le nord.
  static double capInterpole(double depuis, double vers, double t) {
    var ecart = (vers - depuis) % 360;
    if (ecart > 180) ecart -= 360;
    if (ecart < -180) ecart += 360;
    return (depuis + ecart * t + 360) % 360;
  }

  /// Position intermédiaire, en ligne droite.
  ///
  /// Suffit entre deux relevés distants de quelques secondes : à cette
  /// échelle, la route est quasi droite, et l'œil ne verrait pas la
  /// différence avec un suivi au millimètre du tracé.
  static LatLng positionInterpolee(LatLng depuis, LatLng vers, double t) {
    return LatLng(
      depuis.latitude  + (vers.latitude  - depuis.latitude)  * t,
      depuis.longitude + (vers.longitude - depuis.longitude) * t,
    );
  }

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;
}
