import '../../config/api/api_config.dart';

class StructureFavoriModel {
  final int    id;          // ID du record favori
  final int    structureId;
  final String nom;
  final String adresse;
  final String telephone;
  final String? logoFile;
  final int    nombreEtoile;
  final String tempsLivraison;
  final String? categorie;

  const StructureFavoriModel({
    required this.id,
    required this.structureId,
    required this.nom,
    required this.adresse,
    required this.telephone,
    this.logoFile,
    required this.nombreEtoile,
    required this.tempsLivraison,
    this.categorie,
  });

  String? get logoUrl =>
      logoFile != null ? ApiConfig.getImageUrl(logoFile!) : null;

  factory StructureFavoriModel.fromJson(Map<String, dynamic> json) {
    // Le backend peut renvoyer la structure imbriquée ou à plat
    if (json.containsKey('structure') && json['structure'] is Map) {
      final s = json['structure'] as Map<String, dynamic>;
      return StructureFavoriModel(
        id            : (json['id'] as num).toInt(),
        structureId   : (s['id'] as num).toInt(),
        nom           : s['name'] as String? ?? s['nom'] as String? ?? '',
        adresse       : s['adresse'] as String? ?? '',
        telephone     : s['telephone'] as String? ?? '',
        logoFile      : s['logoFile'] as String? ?? s['logo'] as String?,
        nombreEtoile  : (s['nombreEtoile'] as num?)?.toInt() ?? 0,
        tempsLivraison: s['tempsLivraison'] as String? ?? '30-45 min',
        categorie     : s['categorie'] as String?,
      );
    }
    // Format plat
    return StructureFavoriModel(
      id            : (json['id'] as num).toInt(),
      structureId   : (json['structureId'] as num?)?.toInt()
                      ?? (json['id'] as num).toInt(),
      nom           : json['name'] as String? ?? json['nom'] as String? ?? '',
      adresse       : json['adresse'] as String? ?? '',
      telephone     : json['telephone'] as String? ?? '',
      logoFile      : json['logoFile'] as String? ?? json['logo'] as String?,
      nombreEtoile  : (json['nombreEtoile'] as num?)?.toInt() ?? 0,
      tempsLivraison: json['tempsLivraison'] as String? ?? '30-45 min',
      categorie     : json['categorie'] as String?,
    );
  }
}
