import 'package:flutter/material.dart';

/// Types de véhicule du backend, dans son ordre de déclaration.
///
/// Enum unique de l'application : il sert aussi bien au choix du
/// véhicule d'une course qu'à l'affichage du tarif d'une livraison
/// ou du véhicule d'un coursier. Ce que le client peut réellement
/// commander dépend du contexte et de ce que l'API propose — ce
/// n'est pas à l'enum d'en décider.
enum TypeVehicule {
  moto('MOTO', 'Moto', Icons.two_wheeler_rounded,
      'assets/images/moto.png', 'Rapide et abordable',
      assetSuivi: 'assets/images/suivi_moto.png', largeurSuivi: 42),
  vehicule('VEHICULE', 'Voiture', Icons.local_taxi_rounded,
      'assets/images/voiture.png', 'Confortable',
      assetSuivi: 'assets/images/suivi_voiture.png', largeurSuivi: 34),
  cargo('CARGO', 'Cargo', Icons.local_shipping_outlined,
      'assets/images/cargo.png', 'Gros volumes'),
  pickup('PICKUP', 'Pick-up', Icons.airport_shuttle_outlined,
      null, 'Charges lourdes'),
  fourgonnette('FOURGONNETTE', 'Fourgonnette', Icons.local_shipping_rounded,
      null, 'Volume et distance'),
  camion('CAMION', 'Camion', Icons.fire_truck_outlined,
      null, 'Très gros volumes');

  const TypeVehicule(
      this.code, this.libelle, this.icone, this.asset, this.description,
      {this.assetSuivi, this.largeurSuivi = 42});

  /// Valeur envoyée et reçue par l'API
  final String code;

  /// Libellé affiché à l'utilisateur
  final String libelle;

  final IconData icone;

  /// Visuel du véhicule. Null tant qu'aucune image n'existe pour ce
  /// type : à l'appelant de retomber sur [icone].
  final String? asset;

  /// Argument court affiché sous le libellé dans le sélecteur.
  final String description;

  /// Véhicule vu de dessus, posé sur la carte pendant le suivi.
  ///
  /// Rien à voir avec [asset], qui est une vue de trois quarts faite
  /// pour le sélecteur : sur une carte, un véhicule se regarde d'en
  /// haut. Null pour les types sans visuel dédié — à l'appelant de
  /// retomber sur un pin portant [icone], plutôt que d'afficher une
  /// moto à la place d'un camion.
  final String? assetSuivi;

  /// Largeur du marqueur sur la carte, en pixels logiques.
  ///
  /// Propre à chaque type, parce que les visuels n'ont pas les mêmes
  /// proportions : à largeur égale, une voiture vue de dessus paraît
  /// bien plus massive qu'une moto, qui est tout en longueur.
  final double largeurSuivi;

  /// Retrouve un type depuis son code. Renvoie null sur un code
  /// inconnu — à l'appelant de décider s'il l'affiche brut ou l'écarte.
  static TypeVehicule? depuisCode(String? code) {
    if (code == null) return null;
    for (final t in TypeVehicule.values) {
      if (t.code == code) return t;
    }
    return null;
  }
}
