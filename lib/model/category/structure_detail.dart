import '../../config/api/api_config.dart';

// Ce fichier ne contient plus que Produit. Il portait aussi
// StructureDetail, le modèle de /structures/{id}, retiré avec le
// passage de la fiche établissement à /produits/structure.

class Produit {
  final int id;
  final String nom;
  final String image;
  final double prix;
  final int categorieProduitId;

  /// Nom de la catégorie tel que renvoyé par /produits/structure.
  /// Absent de /structures/{id}, qui expose une forme allégée.
  final String nomCategorieProduit;

  const Produit({
    required this.id,
    required this.nom,
    required this.image,
    required this.prix,
    required this.categorieProduitId,
    this.nomCategorieProduit = '',
  });

  // Parsing tolérant : un champ manquant sur un seul produit ne doit
  // pas faire échouer toute la liste
  factory Produit.fromJson(Map<String, dynamic> json) => Produit(
        id: (json['id'] as num).toInt(),
        nom: json['nom'] as String? ?? '',
        image: json['image'] as String? ?? '',
        prix: (json['prix'] as num?)?.toDouble() ?? 0,
        categorieProduitId: (json['categorieProduitId'] as num?)?.toInt() ?? 0,
        nomCategorieProduit: json['nomCategorieProduit'] as String? ?? '',
      );

  String get imageUrl => ApiConfig.getImageUrl(image);
}
