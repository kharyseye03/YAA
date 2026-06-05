import 'cart_item_model.dart';
import 'cart_structure_model.dart';

class CartModel {
  final int id;
  final double montantTotal;
  final bool multipleLivraison;
  final List<CartStructureModel> lignes;

  const CartModel({
    required this.id,
    required this.montantTotal,
    this.multipleLivraison = false,
    required this.lignes,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final lignesJson = json['lignes'] as List<dynamic>? ?? [];
    return CartModel(
      id                : (json['id'] as num).toInt(),
      montantTotal      : (json['montantTotal'] as num?)?.toDouble() ?? 0.0,
      multipleLivraison : json['multipleLivraison'] as bool? ?? false,
      lignes            : lignesJson
          .map((e) => CartStructureModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Nombre total d'articles (toutes structures confondues)
  int get totalArticles =>
      lignes.fold(0, (sum, l) => sum + l.totalArticles);

  /// Liste à plat de tous les produits
  List<CartItemModel> get allProduits =>
      lignes.expand((l) => l.produits).toList();
}
