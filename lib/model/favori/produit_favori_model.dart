import '../../config/api/api_config.dart';

class ProduitFavoriModel {
  final int     id;          // ID du record favori
  final int     produitId;
  final String  nom;
  final String? image;
  final double  prix;
  final String? structureName;
  final String? categorie;

  const ProduitFavoriModel({
    required this.id,
    required this.produitId,
    required this.nom,
    this.image,
    required this.prix,
    this.structureName,
    this.categorie,
  });

  String? get imageUrl =>
      image != null ? ApiConfig.getImageUrl(image!) : null;

  factory ProduitFavoriModel.fromJson(Map<String, dynamic> json) {
    // Format imbriqué : { id, produit: { id, nom, ... } }
    if (json.containsKey('produit') && json['produit'] is Map) {
      final p = json['produit'] as Map<String, dynamic>;
      return ProduitFavoriModel(
        id            : (json['id'] as num).toInt(),
        produitId     : (p['id'] as num).toInt(),
        nom           : p['nom'] as String? ?? '',
        image         : p['image'] as String?,
        prix          : (p['prix'] as num?)?.toDouble() ?? 0.0,
        structureName : p['structureName'] as String?
                        ?? p['structure']?['name'] as String?,
        categorie     : p['categorie'] as String?,
      );
    }
    // Format plat
    return ProduitFavoriModel(
      id            : (json['id'] as num).toInt(),
      produitId     : (json['produitId'] as num?)?.toInt()
                      ?? (json['id'] as num).toInt(),
      nom           : json['nom'] as String? ?? '',
      image         : json['image'] as String?,
      prix          : (json['prix'] as num?)?.toDouble() ?? 0.0,
      structureName : json['structureName'] as String?,
      categorie     : json['categorie'] as String?,
    );
  }
}
