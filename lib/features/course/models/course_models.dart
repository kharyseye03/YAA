import 'package:flutter/material.dart';

/// Type de service demandé (envoyé à l'API estimation/création).
enum TypeService {
  livraison('LIVRAISON', 'Livraison'),
  course('COURSE', 'Course');

  const TypeService(this.code, this.label);
  final String code;
  final String label;
}

/// Type de véhicule (codes backend : MOTO / VEHICULE).
enum TypeVehicule {
  moto('MOTO', 'Moto', 'Rapide, colis standard', Icons.sports_motorsports),
  voiture('VEHICULE', 'Voiture', 'Gros volume, confort',
      Icons.local_taxi_rounded);

  const TypeVehicule(this.code, this.label, this.description, this.icon);
  final String   code;
  final String   label;
  final String   description;
  final IconData icon;
}

/// Un point du trajet : adresse lisible + coordonnées.
class CoursePoint {
  final String adresse;
  final double latitude;
  final double longitude;

  const CoursePoint({
    required this.adresse,
    required this.latitude,
    required this.longitude,
  });
}

/// Arguments passés d'un écran à l'autre du flow course/livraison.
class CourseFlowArgs {
  final TypeService  typeService;
  final CoursePoint? depart;
  final CoursePoint? arrivee;

  const CourseFlowArgs({
    required this.typeService,
    this.depart,
    this.arrivee,
  });

  CourseFlowArgs copyWith({
    TypeService?  typeService,
    CoursePoint?  depart,
    CoursePoint?  arrivee,
  }) {
    return CourseFlowArgs(
      typeService : typeService ?? this.typeService,
      depart      : depart      ?? this.depart,
      arrivee     : arrivee     ?? this.arrivee,
    );
  }
}
