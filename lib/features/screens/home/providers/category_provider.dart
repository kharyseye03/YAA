import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../model/category/categorie_produit.dart';
import '../../../../model/category/categorie_structure.dart';
import '../../../../model/category/produit_detail.dart';
import '../../../../model/category/structure.dart';
import '../../../../model/category/structure_detail.dart'; // contient aussi Produit
import '../../../../service/api/api_service.dart';

// ── Paramètres pour filtrer les produits ──────────────────────────
class ProduitQueryParams {
  final int structureId;
  final int? categorieProduitId;

  const ProduitQueryParams({
    required this.structureId,
    this.categorieProduitId,
  });

  @override
  bool operator ==(Object other) =>
      other is ProduitQueryParams &&
      other.structureId == structureId &&
      other.categorieProduitId == categorieProduitId;

  @override
  int get hashCode => Object.hash(structureId, categorieProduitId);
}

final categoriesProvider = FutureProvider<List<CategorieStructure>>((ref) {
  return ApiService().getCategories();
});

final structuresProvider =
    FutureProvider.family<List<Structure>, int>((ref, categorieId) {
  return ApiService().getStructuresByCategory(categorieId);
});

final structureDetailProvider =
    FutureProvider.family<StructureDetail, int>((ref, structureId) {
  return ApiService().getStructureDetail(structureId);
});

final produitDetailProvider =
    FutureProvider.family<ProduitDetail, int>((ref, produitId) {
  return ApiService().getProduitDetail(produitId);
});

final categorieProduitProvider =
    FutureProvider.family<List<CategorieProduit>, int>((ref, structureId) {
  return ApiService().getCategorieProduits(structureId);
});

final produitsByStructureProvider =
    FutureProvider.family<List<Produit>, ProduitQueryParams>((ref, params) {
  return ApiService().getProduitsByStructure(
    params.structureId,
    categorieProduitId: params.categorieProduitId,
  );
});
