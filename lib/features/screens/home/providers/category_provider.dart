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
// Reprend les critères acceptés par /produits/structure. Sert aux
// sections de la fiche établissement comme à la recherche dans son
// catalogue.
class ProduitQueryParams {
  final int structureId;
  final int? categorieProduitId;
  final String? nom;
  final String? marque;
  final String? unite;
  final bool? disponible;
  final bool? enPromotion;
  final bool? necessiteOrdonnance;
  final num? prixMin;
  final num? prixMax;

  const ProduitQueryParams({
    required this.structureId,
    this.categorieProduitId,
    this.nom,
    this.marque,
    this.unite,
    this.disponible,
    this.enPromotion,
    this.necessiteOrdonnance,
    this.prixMin,
    this.prixMax,
  });

  @override
  bool operator ==(Object other) =>
      other is ProduitQueryParams &&
      other.structureId         == structureId &&
      other.categorieProduitId  == categorieProduitId &&
      other.nom                 == nom &&
      other.marque              == marque &&
      other.unite               == unite &&
      other.disponible          == disponible &&
      other.enPromotion         == enPromotion &&
      other.necessiteOrdonnance == necessiteOrdonnance &&
      other.prixMin             == prixMin &&
      other.prixMax             == prixMax;

  @override
  int get hashCode => Object.hash(
        structureId,
        categorieProduitId,
        nom,
        marque,
        unite,
        disponible,
        enPromotion,
        necessiteOrdonnance,
        prixMin,
        prixMax,
      );
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

/// Critères de la liste d'établissements d'une catégorie
class StructuresQuery {
  const StructuresQuery({required this.categorieId, this.specialite});

  final int     categorieId;
  final String? specialite;

  @override
  bool operator ==(Object other) =>
      other is StructuresQuery &&
      other.categorieId == categorieId &&
      other.specialite  == specialite;

  @override
  int get hashCode => Object.hash(categorieId, specialite);
}

/// Établissements d'une catégorie, éventuellement restreints à une
/// spécialité (la catégorie de produit choisie dans les filtres).
final structuresFiltreesProvider =
    FutureProvider.family<List<Structure>, StructuresQuery>((ref, q) {
  return ApiService().getStructures(
    categorieId : q.categorieId,
    specialite  : q.specialite,
  );
});

/// Filtres de l'écran Catégorie.
///
/// L'ordre du serveur est significatif — il place « Populaire » en
/// tête, puis le reste alphabétiquement. On le conserve tel quel.
///
/// Seul garde-fou : la déduplication sur le nom normalisé. L'API a
/// déjà été nettoyée côté backend, mais deux libellés qui ne
/// diffèrent que par « & » et « et » afficheraient deux puces
/// identiques à l'écran.
final filtresCategorieProvider =
    FutureProvider.family<List<CategorieProduit>, int>((ref, categorieId) async {
  final filtres = await ApiService().getFiltresCategorie(categorieId);

  final vus = <String>{};
  final uniques = <CategorieProduit>[];
  for (final f in filtres) {
    final cle = f.nom
        .toLowerCase()
        .replaceAll('&', 'et')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (vus.add(cle)) uniques.add(f);
  }
  return uniques;
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
    categorieProduitId  : params.categorieProduitId,
    nom                 : params.nom,
    marque              : params.marque,
    unite               : params.unite,
    disponible          : params.disponible,
    enPromotion         : params.enPromotion,
    necessiteOrdonnance : params.necessiteOrdonnance,
    prixMin             : params.prixMin,
    prixMax             : params.prixMax,
  );
});
