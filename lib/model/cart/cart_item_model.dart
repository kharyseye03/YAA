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
    this.sousTotal = 0.0,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final prix     = (json['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
    final quantite = (json['quantite']     as num?)?.toInt()    ?? 1;
    return CartItemModel(
      produitId    : (json['produitId']    as num).toInt(),
      nom          : json['nom']           as String? ?? '',
      quantite     : quantite,
      prixUnitaire : prix,
      sousTotal    : (json['sousTotal']    as num?)?.toDouble() ?? prix * quantite,
    );
  }
}
