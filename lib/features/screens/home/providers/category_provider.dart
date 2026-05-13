import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../model/category/categorie_produit.dart';
import '../../../../model/category/categorie_structure.dart';
import '../../../../model/category/produit_detail.dart';
import '../../../../model/category/structure.dart';
import '../../../../model/category/structure_detail.dart';
import '../../../../service/api/api_service.dart';

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
