import 'cart_item_model.dart';

/// Représente un groupe de produits d'une même structure dans le panier.
class CartStructureModel {
  final int structureId;
  final String nomStructure;
  final String adresseStructure;
  final String telephoneStructure;
  final List<CartItemModel> produits;

  const CartStructureModel({
    required this.structureId,
    required this.nomStructure,
    required this.adresseStructure,
    required this.telephoneStructure,
    required this.produits,
  });

  double get sousTotal =>
      produits.fold(0.0, (sum, p) => sum + p.sousTotal);

  int get totalArticles =>
      produits.fold(0, (sum, p) => sum + p.quantite);

  factory CartStructureModel.fromJson(Map<String, dynamic> json) {
    final structure   = json['structure']  as Map<String, dynamic>;
    final produitsJson = json['produits'] as List<dynamic>? ?? [];
    return CartStructureModel(
      structureId         : (structure['structureId']  as num).toInt(),
      nomStructure        : structure['nomStructure']  as String? ?? '',
      adresseStructure    : structure['adresseStructure'] as String? ?? '',
      telephoneStructure  : structure['telephoneStructure'] as String? ?? '',
      produits            : produitsJson
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
