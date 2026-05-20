import 'cart_item_model.dart';

class CartModel {
  final int id;
  final double montantTotal;
  final List<CartItemModel> lignes;

  const CartModel({
    required this.id,
    required this.montantTotal,
    required this.lignes,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final lignesJson = json['lignes'] as List<dynamic>? ?? [];
    return CartModel(
      id           : (json['id'] as num).toInt(),
      montantTotal : (json['montantTotal'] as num).toDouble(),
      lignes       : lignesJson
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalArticles => lignes.fold(0, (sum, l) => sum + l.quantite);
}
