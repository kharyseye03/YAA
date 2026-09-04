import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../config/maps/maps_config.dart' as config;
import '../../main.dart' show rendererCarte;

/// Carte invisible qui absorbe le coût de démarrage du SDK Maps.
///
/// **Le problème.** Sur Android, `GoogleMap` n'est pas un widget
/// Flutter mais une vue native incrustée. La toute première carte du
/// processus doit charger les bibliothèques natives, créer la surface
/// de rendu et amorcer les caches de tuiles : une à trois secondes.
/// Les suivantes sont immédiates, l'initialisation étant faite une
/// fois pour toute la durée de vie de l'application.
///
/// **Le procédé.** Ce coût est inévitable, mais son emplacement ne
/// l'est pas. En montant une carte d'un pixel sur l'accueil, il est
/// payé pendant que l'utilisateur parcourt les catégories — un moment
/// où personne n'attend une carte. Course et Livraison trouvent
/// ensuite le SDK déjà chaud et s'affichent d'un coup.
///
/// C'est ce que font les applications où la carte apparaît
/// instantanément : chez elles, l'accueil *est* une carte, donc
/// l'initialisation est faite avant qu'on commande quoi que ce soit.
///
/// **À poser** dans un `Stack`, une seule fois, sur un écran assez
/// durable pour que l'initialisation ait le temps d'aboutir.
class MapPrewarm extends StatefulWidget {
  const MapPrewarm({super.key});

  @override
  State<MapPrewarm> createState() => _MapPrewarmState();
}

class _MapPrewarmState extends State<MapPrewarm> {
  GoogleMapController? _controller;

  /// Le choix du renderer est lancé au démarrage sans bloquer
  /// l'affichage ; on attend ici qu'il aboutisse. Créer une carte
  /// avant sa fin figerait le renderer hérité pour tout le processus.
  bool _pret = false;

  @override
  void initState() {
    super.initState();
    rendererCarte.whenComplete(() {
      if (mounted) setState(() => _pret = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_pret) return const SizedBox.shrink();
    // Hors écran plutôt qu'en Opacity(0) : une vue native reste une
    // surface native, et l'opacité ne garantit pas qu'elle ne vienne
    // pas se peindre par-dessus le contenu. À -100 px, la question
    // ne se pose pas — la vue est bien créée, jamais visible.
    return Positioned(
      left   : -100,
      top    : -100,
      width  : 1,
      height : 1,
      child: IgnorePointer(
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(
              config.MapsConfig.villeLat,
              config.MapsConfig.villeLng,
            ),
            zoom: 11,
          ),
          onMapCreated: (c) => _controller = c,
          // Rien d'actif : on veut l'initialisation du moteur, pas
          // une carte fonctionnelle. Surtout pas myLocationEnabled,
          // qui déclencherait une demande de permission à l'accueil.
          liteModeEnabled         : false,
          myLocationEnabled       : false,
          myLocationButtonEnabled : false,
          zoomControlsEnabled     : false,
          compassEnabled          : false,
          mapToolbarEnabled       : false,
          scrollGesturesEnabled   : false,
          zoomGesturesEnabled     : false,
          rotateGesturesEnabled   : false,
          tiltGesturesEnabled     : false,
        ),
      ),
    );
  }
}
