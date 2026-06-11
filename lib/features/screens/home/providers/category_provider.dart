import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../model/category/categorie_produit.dart';
import '../../../../model/category/categorie_structure.dart';
import '../../../../model/category/produit_detail.dart';
import '../../../../model/category/structure.dart';
import '../../../../model/category/structure_detail.dart'; // contient aussi Produit
import '../../../../service/api/api_service.dart';
import '../../../location/providers/position_provider.dart';

// Position par défaut si le GPS est indisponible (centre de Dakar)
const _dakarLat = 14.6928;
const _dakarLng = -17.4467;

// Rayon de la section "Autour de vous" (en mètres)
const _nearbyRayon = 3000.0;

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

/// Structures autour de l'utilisateur (rayon 3 km), triées par
/// distance par le backend. Fallback : centre de Dakar si le GPS
/// est indisponible (permission refusée, etc.)
final nearbyStructuresProvider = FutureProvider<List<Structure>>((ref) async {
  double lat = _dakarLat;
  double lng = _dakarLng;
  try {
    final position = await ref.watch(currentPositionProvider.future);
    lat = position.latitude;
    lng = position.longitude;
  } catch (_) {
    // GPS indisponible → coordonnées par défaut
  }
  return ApiService().getStructures(
    latitude  : lat,
    longitude : lng,
    rayon     : _nearbyRayon,
  );
});

/// Recherche globale de structures par nom (pas de filtre géo)
final searchStructuresProvider =
    FutureProvider.family<List<Structure>, String>((ref, nom) {
  return ApiService().getStructures(nom: nom);
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
