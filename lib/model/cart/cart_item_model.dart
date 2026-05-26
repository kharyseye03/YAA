class CartItemModel {
  final int id;          // idLigne — pour la suppression
  final int produitId;
  final String nom;
  final String? image;
  final int quantite;
  final double prixUnitaire;
  final double sousTotal;

  const CartItemModel({
    required this.id,
    required this.produitId,
    required this.nom,
    this.image,
    required this.quantite,
    required this.prixUnitaire,
    this.sousTotal = 0.0,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final prix     = (json['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
    final quantite = (json['quantite']     as num?)?.toInt()    ?? 1;
    return CartItemModel(
      id           : (json['id']        as num).toInt(),
      produitId    : (json['produitId'] as num).toInt(),
      nom          : json['nom']        as String? ?? '',
      image        : json['image']      as String?,
      quantite     : quantite,
      prixUnitaire : prix,
      sousTotal    : (json['sousTotal'] as num?)?.toDouble() ?? prix * quantite,
    );
  }
}
