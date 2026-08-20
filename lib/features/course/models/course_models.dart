// TypeVehicule vivait ici avec deux valeurs. Il est devenu l'enum
// unique de l'application — le backend en compte six — et a migré
// dans les modèles. On le ré-exporte pour ne pas casser les écrans
// qui n'importent que ce fichier.
export '../../../model/course/type_vehicule.dart';

/// Type de service demandé (envoyé à l'API estimation/création).
enum TypeService {
  livraison('LIVRAISON', 'Livraison'),
  course('COURSE', 'Course');

  const TypeService(this.code, this.label);
  final String code;
  final String label;
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
