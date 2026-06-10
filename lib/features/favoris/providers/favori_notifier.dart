import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../model/favori/produit_favori_model.dart';
import '../../../model/favori/structure_favori_model.dart';
import '../../../service/api/api_service.dart';

const _tokenKey        = 'access_token';
const _refreshTokenKey = 'refresh_token';

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
  FavoriNotifier(this._prefs) : super(const FavoriState());

  final SharedPreferences _prefs;

  // ── Token ────────────────────────────────────────────────────
  static bool _isExpired(String token) {
    try {
      final payload = AuthNotifier.decodeJwtPayload(token);
      if (payload == null) return true;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch > exp * 1000 - 30000;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshTk = _prefs.getString(_refreshTokenKey);
      if (refreshTk == null) return null;
      final res = await ApiService().refreshToken(refreshToken: refreshTk);
      await _prefs.setString(_tokenKey,        res.accessToken);
      await _prefs.setString(_refreshTokenKey, res.refreshToken);
      return res.accessToken;
    } catch (e) {
      debugPrint('❌ refresh: $e');
      return null;
    }
  }

  Future<String?> _getValidToken() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null) return null;
    if (_isExpired(token)) return await _refreshToken();
    return token;
  }

  // ── Charger la liste ─────────────────────────────────────────
  Future<void> loadFavoris() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token   = await _getValidToken();
      final favoris = await ApiService().getStructuresFavoris(token: token);
      // Met à jour la liste ET le set d'IDs en même temps
      state = state.copyWith(
        isLoading  : false,
        favoris    : favoris,
        favorisIds : favoris.map((f) => f.structureId).toSet(),
      );
    } catch (e) {
      debugPrint('❌ loadFavoris: $e');
      state = state.copyWith(
        isLoading : false,
        error     : e.toString().replaceAll('Exception: ', ''),
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
      final token = await _getValidToken();
      await ApiService().toggleStructureFavori(
        structureId : structureId,
        token       : token,
      );
      // L'état optimiste est correct — on retire juste le spinner
      state = state.copyWith(
        togglingIds: state.togglingIds.difference({structureId}),
      );
    } catch (e) {
      debugPrint('❌ toggleFavori: $e');
      // Rollback : on remet l'état avant le clic
      state = state.copyWith(
        favoris     : snapshotFavoris,
        favorisIds  : snapshotIds,
        error       : e.toString().replaceAll('Exception: ', ''),
        togglingIds : state.togglingIds.difference({structureId}),
      );
    }
  }

  // ── Charger produits favoris ─────────────────────────────────
  Future<void> loadProduitsFavoris() async {
    try {
      final token   = await _getValidToken();
      final produits = await ApiService().getProduitsFavoris(token: token);
      state = state.copyWith(
        produitsFavoris    : produits,
        produitsFavorisIds : produits.map((p) => p.produitId).toSet(),
      );
    } catch (e) {
      debugPrint('❌ loadProduitsFavoris: $e');
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
      final token = await _getValidToken();
      await ApiService().toggleProduitFavori(
        produitId : produitId,
        token     : token,
      );
      state = state.copyWith(
        togglingIds: state.togglingIds.difference({produitId}),
      );
    } catch (e) {
      debugPrint('❌ toggleProduitFavori: $e');
      // Rollback
      state = state.copyWith(
        produitsFavorisIds : snapshotIds,
        error              : e.toString().replaceAll('Exception: ', ''),
        togglingIds        : state.togglingIds.difference({produitId}),
      );
    }
  }
}

// ── Provider ───────────────────────────────────────────────────
final favoriProvider =
    StateNotifierProvider<FavoriNotifier, FavoriState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoriNotifier(prefs);
});
