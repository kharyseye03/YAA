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
      produits            : _trierParLigne(produitsJson),
    );
  }

  /// Ordonne les lignes par leur identifiant, croissant.
  ///
  /// Le serveur renvoie le panier dans un ordre qui change après une
  /// modification : la ligne qu'on vient de toucher repasse en
  /// dernier. À l'écran, incrémenter une quantité faisait donc sauter
  /// l'article en bas de la liste, et remonter le suivant — le doigt
  /// de l'utilisateur se retrouvait sur un autre produit.
  ///
  /// L'identifiant de ligne est attribué au premier ajout : trier
  /// dessus redonne l'ordre dans lequel les articles ont été mis au
  /// panier, et surtout un ordre **stable** d'un rafraîchissement à
  /// l'autre.
  static List<CartItemModel> _trierParLigne(List<dynamic> json) {
    final lignes = json
        .whereType<Map<String, dynamic>>()
        .map(CartItemModel.fromJson)
        .toList();
    lignes.sort((a, b) => a.id.compareTo(b.id));
    return lignes;
  }
}
