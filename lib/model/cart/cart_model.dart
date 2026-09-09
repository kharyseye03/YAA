import '../../core/utils/journal.dart';
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

    // Une ligne illisible est écartée, pas propagée.
    //
    // `CartStructureModel.fromJson` exige un `structure.structureId` :
    // s'il manque sur **une seule** ligne, le `map` levait et c'est le
    // panier entier qui échouait à se construire. L'écran devenait
    // vide et le client ne pouvait plus commander du tout — pour un
    // champ absent sur un article.
    //
    // Perdre un article et pouvoir commander vaut mieux que tout
    // perdre. L'incident part dans les journaux : il vient du serveur
    // et doit être corrigé là-bas.
    final lignes = <CartStructureModel>[];
    for (final e in lignesJson) {
      try {
        lignes.add(CartStructureModel.fromJson(e as Map<String, dynamic>));
      } catch (erreur) {
        journal('⚠️ ligne de panier illisible, ignorée : $erreur');
      }
    }

    return CartModel(
      id                : (json['id'] as num).toInt(),
      montantTotal      : (json['montantTotal'] as num?)?.toDouble() ?? 0.0,
      multipleLivraison : json['multipleLivraison'] as bool? ?? false,
      lignes            : lignes,
    );
  }

  /// Nombre total d'articles (toutes structures confondues)
  int get totalArticles =>
      lignes.fold(0, (sum, l) => sum + l.totalArticles);

  /// Liste à plat de tous les produits
  List<CartItemModel> get allProduits =>
      lignes.expand((l) => l.produits).toList();
}
