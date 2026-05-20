class CartItemModel {
  final int produitId;
  final String nom;
  final int quantite;
  final double prixUnitaire;
  final double sousTotal;

  const CartItemModel({
    required this.produitId,
    required this.nom,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      produitId    : (json['produitId']    as num).toInt(),
      nom          : json['nom']           as String? ?? '',
      quantite     : (json['quantite']     as num).toInt(),
      prixUnitaire : (json['prixUnitaire'] as num).toDouble(),
      sousTotal    : (json['sousTotal']    as num).toDouble(),
    );
  }
}
