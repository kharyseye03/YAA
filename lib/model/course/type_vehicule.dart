import 'package:flutter/material.dart';

/// Types de véhicule du backend, dans son ordre de déclaration.
///
/// Enum unique de l'application : il sert aussi bien au choix du
/// véhicule d'une course qu'à l'affichage du tarif d'une livraison
/// ou du véhicule d'un coursier. Ce que le client peut réellement
/// commander dépend du contexte et de ce que l'API propose — ce
/// n'est pas à l'enum d'en décider.
enum TypeVehicule {
  moto('MOTO', 'Moto', Icons.two_wheeler_rounded),
  vehicule('VEHICULE', 'Voiture', Icons.local_taxi_rounded),
  cargo('CARGO', 'Cargo', Icons.local_shipping_outlined),
  pickup('PICKUP', 'Pick-up', Icons.airport_shuttle_outlined),
  fourgonnette('FOURGONNETTE', 'Fourgonnette', Icons.local_shipping_rounded),
  camion('CAMION', 'Camion', Icons.fire_truck_outlined);

  const TypeVehicule(this.code, this.libelle, this.icone);

  /// Valeur envoyée et reçue par l'API
  final String code;

  /// Libellé affiché à l'utilisateur
  final String libelle;

  final IconData icone;

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
