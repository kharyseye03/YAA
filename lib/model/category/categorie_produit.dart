class CategorieProduit {
  final int id;
  final String nom;
  final String? categorie;

  const CategorieProduit({
    required this.id,
    required this.nom,
    this.categorie,
  });

  factory CategorieProduit.fromJson(Map<String, dynamic> json) =>
      CategorieProduit(
        id: json['id'] as int,
        nom: json['nom'] as String,
        categorie: json['categorie'] as String?,
      );
}
