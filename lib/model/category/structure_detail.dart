import '../../config/api/api_config.dart';

class Produit {
  final int id;
  final String nom;
  final String image;
  final double prix;
  final int categorieProduitId;

  const Produit({
    required this.id,
    required this.nom,
    required this.image,
    required this.prix,
    required this.categorieProduitId,
  });

  factory Produit.fromJson(Map<String, dynamic> json) => Produit(
        id: json['id'] as int,
        nom: json['nom'] as String,
        image: json['image'] as String,
        prix: (json['prix'] as num).toDouble(),
        categorieProduitId: json['categorieProduitId'] as int,
      );

  String get imageUrl => ApiConfig.getImageUrl(image);
}

class StructureDetail {
  final int id;
  final String name;
  final String adresse;
  final String categorie;
  final String logoFile;
  final int nombreEtoile;
  final String tempsLivraison;
  final String codeStructure;
  final List<Produit> produits;

  const StructureDetail({
    required this.id,
    required this.name,
    required this.adresse,
    required this.categorie,
    required this.logoFile,
    required this.nombreEtoile,
    required this.tempsLivraison,
    required this.codeStructure,
    required this.produits,
  });

  factory StructureDetail.fromJson(Map<String, dynamic> json) => StructureDetail(
        id: json['id'] as int,
        name: json['name'] as String,
        adresse: json['adresse'] as String,
        categorie: json['categorie'] as String,
        logoFile: json['logoFile'] as String,
        nombreEtoile: json['nombreEtoile'] as int,
        tempsLivraison: json['tempsLivraison'] as String,
        codeStructure: json['codeStructure'] as String,
        produits: (json['produits'] as List<dynamic>)
            .map((e) => Produit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get logoUrl => ApiConfig.getImageUrl(logoFile);
}
