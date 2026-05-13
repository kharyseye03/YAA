import '../../config/api/api_config.dart';

class ProduitDetail {
  final int id;
  final String nom;
  final String description;
  final double prix;
  final String image;

  const ProduitDetail({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.image,
  });

  String get imageUrl => ApiConfig.getImageUrl(image);

  factory ProduitDetail.fromJson(Map<String, dynamic> json) => ProduitDetail(
        id: json['id'] as int,
        nom: json['nom'] as String,
        description: json['description'] as String,
        prix: (json['prix'] as num).toDouble(),
        image: json['image'] as String,
      );
}
