import '../../../core/utils/journal.dart';
import '../../../core/errors/messages_erreur.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/favori/produit_favori_model.dart';
import '../../../model/favori/structure_favori_model.dart';
import '../../../service/api/api_service.dart';


// ── State ──────────────────────────────────────────────────────
class FavoriState {
  final bool                       isLoading;
  final List<StructureFavoriModel> favoris;
  final List<ProduitFavoriModel>   produitsFavoris;
  final String?                    error;
  final Set<int>                   togglingIds;
  final Set<int>                   favorisIds;
  final Set<int>                   produitsFavorisIds;

  const FavoriState({
    this.isLoading          = false,
    this.favoris            = const [],
    this.produitsFavoris    = const [],
    this.error,
    this.togglingIds        = const {},
    this.favorisIds         = const {},
    this.produitsFavorisIds = const {},
  });

  bool isFavori(int structureId)       => favorisIds.contains(structureId);
  bool isProduitFavori(int produitId)  => produitsFavorisIds.contains(produitId);
  bool isToggling(int id)              => togglingIds.contains(id);

  FavoriState copyWith({
    bool?                       isLoading,
    List<StructureFavoriModel>? favoris,
    List<ProduitFavoriModel>?   produitsFavoris,
    String?                     error,
    bool                        clearError          = false,
    Set<int>?                   togglingIds,
    Set<int>?                   favorisIds,
    Set<int>?                   produitsFavorisIds,
  }) {
    return FavoriState(
      isLoading          : isLoading          ?? this.isLoading,
      favoris            : favoris            ?? this.favoris,
      produitsFavoris    : produitsFavoris    ?? this.produitsFavoris,
      error              : clearError         ? null : (error ?? this.error),
      togglingIds        : togglingIds        ?? this.togglingIds,
      favorisIds         : favorisIds         ?? this.favorisIds,
      produitsFavorisIds : produitsFavorisIds ?? this.produitsFavorisIds,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────
class FavoriNotifier extends StateNotifier<FavoriState> {
  FavoriNotifier() : super(const FavoriState());



  // ── Charger la liste ─────────────────────────────────────────
  Future<void> loadFavoris() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final favoris = await ApiService().getStructuresFavoris();
      // Met à jour la liste ET le set d'IDs en même temps
      state = state.copyWith(
        isLoading  : false,
        favoris    : favoris,
        favorisIds : favoris.map((f) => f.structureId).toSet(),
      );
    } catch (e) {
      journal('❌ loadFavoris: $e');
      state = state.copyWith(
        isLoading : false,
        error     : MessagesErreur.depuisException(e),
      );
    }
  }

  // ── Toggle (optimiste) ───────────────────────────────────────
  Future<void> toggleFavori(int structureId) async {
    final isCurrent = state.isFavori(structureId);

    // 1. Snapshot AVANT toute modification (pour rollback si erreur)
    final snapshotFavoris = List<StructureFavoriModel>.from(state.favoris);
    final snapshotIds     = Set<int>.from(state.favorisIds);

    // 2. Mise à jour optimiste immédiate
    final newIds = Set<int>.from(state.favorisIds);
    if (isCurrent) {
      newIds.remove(structureId);
    } else {
      newIds.add(structureId);
    }
    state = state.copyWith(
      favorisIds  : newIds,
      togglingIds : {...state.togglingIds, structureId},
    );

    // 3. Appel API
    try {
      await ApiService().toggleStructureFavori(
        structureId : structureId,
      );
      // L'état optimiste est correct — on retire juste le spinner
      state = state.copyWith(
        togglingIds: state.togglingIds.difference({structureId}),
      );
    } catch (e) {
      journal('❌ toggleFavori: $e');
      // Rollback : on remet l'état avant le clic
      state = state.copyWith(
        favoris     : snapshotFavoris,
        favorisIds  : snapshotIds,
        error       : MessagesErreur.depuisException(e),
        togglingIds : state.togglingIds.difference({structureId}),
      );
    }
  }

  // ── Charger produits favoris ─────────────────────────────────
  Future<void> loadProduitsFavoris() async {
    try {
      final produits = await ApiService().getProduitsFavoris();
      state = state.copyWith(
        produitsFavoris    : produits,
        produitsFavorisIds : produits.map((p) => p.produitId).toSet(),
      );
    } catch (e) {
      journal('❌ loadProduitsFavoris: $e');
    }
  }

  // ── Toggle produit (optimiste) ───────────────────────────────
  Future<void> toggleProduitFavori(int produitId) async {
    final isCurrent = state.isProduitFavori(produitId);

    // Snapshot avant modification
    final snapshotIds = Set<int>.from(state.produitsFavorisIds);

    // Mise à jour optimiste immédiate
    final newIds = Set<int>.from(state.produitsFavorisIds);
    if (isCurrent) {
      newIds.remove(produitId);
    } else {
      newIds.add(produitId);
    }
    state = state.copyWith(
      produitsFavorisIds : newIds,
      togglingIds        : {...state.togglingIds, produitId},
    );

    try {
      await ApiService().toggleProduitFavori(
        produitId : produitId,
      );
      state = state.copyWith(
        togglingIds: state.togglingIds.difference({produitId}),
      );
    } catch (e) {
      journal('❌ toggleProduitFavori: $e');
      // Rollback
      state = state.copyWith(
        produitsFavorisIds : snapshotIds,
        error              : MessagesErreur.depuisException(e),
        togglingIds        : state.togglingIds.difference({produitId}),
      );
    }
  }
}

// ── Provider ───────────────────────────────────────────────────
final favoriProvider =
    StateNotifierProvider<FavoriNotifier, FavoriState>((ref) {
  return FavoriNotifier();
});
