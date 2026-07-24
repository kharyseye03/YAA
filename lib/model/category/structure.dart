import '../../config/api/api_config.dart';

class Structure {
  final int id;
  final String categorie;
  final String logoFile;
  final String name;
  final double latitude;
  final double longitude;
  final String adresse;
  final int nombreEtoile;
  final String tempsLivraison;
  final String codeStructure;
  final double distance; // en mètres, calculée par le backend si lat/lng fournis

  const Structure({
    required this.id,
    required this.categorie,
    required this.logoFile,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.adresse,
    required this.nombreEtoile,
    required this.tempsLivraison,
    required this.codeStructure,
    this.distance = 0,
  });

  // Parsing tolérant : le backend peut renvoyer null sur certains
  // champs (structure incomplète) — on met des valeurs par défaut
  // plutôt que de faire planter toute la liste
  factory Structure.fromJson(Map<String, dynamic> json) => Structure(
        id: (json['id'] as num).toInt(),
        categorie: json['categorie'] as String? ?? '',
        logoFile: json['logoFile'] as String? ?? '',
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        adresse: json['adresse'] as String? ?? '',
        nombreEtoile: (json['nombreEtoile'] as num?)?.toInt() ?? 0,
        tempsLivraison: json['tempsLivraison'] as String? ?? '',
        codeStructure: json['codeStructure'] as String? ?? '',
        distance: (json['distance'] as num?)?.toDouble() ?? 0,
      );

  String get logoUrl => ApiConfig.getImageUrl(logoFile);

  /// Distance lisible : "487 m" ou "1,3 km"
  String get distanceLabel => distance < 1000
      ? '${distance.round()} m'
      : '${(distance / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}
