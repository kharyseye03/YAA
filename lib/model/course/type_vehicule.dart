import 'package:flutter/material.dart';

/// Types de véhicule du backend.
///
/// Les six valeurs sont déclarées pour que l'app sache nommer et
/// dessiner tout ce qu'une estimation peut renvoyer. Seules celles
/// marquées [actif] sont exploitées aujourd'hui — les autres
/// attendent que la flotte suive.
enum TypeVehicule {
  moto('MOTO', 'Moto', Icons.two_wheeler_rounded, actif: true),
  cargo('CARGO', 'Cargo', Icons.local_shipping_outlined, actif: true),
  vehicule('VEHICULE', 'Voiture', Icons.directions_car_outlined),
  pickup('PICKUP', 'Pick-up', Icons.airport_shuttle_outlined),
  fourgonnette('FOURGONNETTE', 'Fourgonnette', Icons.local_shipping_rounded),
  camion('CAMION', 'Camion', Icons.fire_truck_outlined);

  const TypeVehicule(this.code, this.libelle, this.icone, {this.actif = false});

  /// Valeur envoyée et reçue par l'API
  final String code;

  /// Libellé affiché à l'utilisateur
  final String libelle;

  final IconData icone;

  /// Proposé au client aujourd'hui. Sert de garde-fou : si le backend
  /// se met à renvoyer un type non exploité, on le repère au lieu de
  /// l'afficher comme une offre valable.
  final bool actif;

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
