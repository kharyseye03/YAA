import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../model/cart/cart_model.dart';
import '../../../service/api/api_service.dart';

const _tokenKey        = 'access_token';
const _refreshTokenKey = 'refresh_token';

class CartState {
  final bool isLoading;
  final bool isAdding;
  final CartModel? cart;
  final String? error;

  const CartState({
    this.isLoading = false,
    this.isAdding  = false,
    this.cart,
    this.error,
  });

  CartState copyWith({
    bool? isLoading,
    bool? isAdding,
    CartModel? cart,
    String? error,
    bool clearError = false,
    bool clearCart  = false,   // ← permet de mettre cart à null explicitement
  }) {
    return CartState(
      isLoading : isLoading ?? this.isLoading,
      isAdding  : isAdding  ?? this.isAdding,
      cart      : clearCart ? null : (cart ?? this.cart),
      error     : clearError ? null : (error ?? this.error),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._prefs) : super(const CartState());

  final SharedPreferences _prefs;

  // ── Vérifie si le JWT est expiré (avec 30s de marge) ──────
  static bool _isExpired(String token) {
    try {
      final payload = AuthNotifier.decodeJwtPayload(token);
      if (payload == null) return true;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      final expiryMs = exp * 1000 - 30000; // 30s de marge
      return DateTime.now().millisecondsSinceEpoch > expiryMs;
    } catch (_) {
      return false;
    }
  }

  // ── Rafraîchit le token via Keycloak ──────────────────────
  Future<String?> _refreshToken() async {
    try {
      final refreshTk = _prefs.getString(_refreshTokenKey);
      if (refreshTk == null) {
        debugPrint('⚠️ Pas de refresh_token disponible');
        return null;
      }
      debugPrint('🔄 Rafraîchissement du token...');
      final response = await ApiService().refreshToken(refreshToken: refreshTk);
      await _prefs.setString(_tokenKey,        response.accessToken);
      await _prefs.setString(_refreshTokenKey, response.refreshToken);
      debugPrint('✅ Token rafraîchi avec succès');
      return response.accessToken;
    } catch (e) {
      debugPrint('❌ Échec du refresh token: $e');
      return null;
    }
  }

  // ── Retourne un token valide (rafraîchit si expiré) ───────
  Future<String?> _getValidToken() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null) return null;
    if (_isExpired(token)) {
      debugPrint('⚠️ Token expiré, rafraîchissement automatique...');
      return await _refreshToken();
    }
    return token;
  }

  // ─────────────────────────────────────────────────────────

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _getValidToken();
      final cart  = await ApiService().getCart(token: token);
      // cart == null → pas de panier actif (corps vide du serveur) : état normal
      state = state.copyWith(
        isLoading : false,
        cart      : cart,
        clearCart : cart == null,
        clearError: true,
      );
    } catch (e) {
      debugPrint('❌ loadCart: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> addToCart({required int produitId, int quantite = 1}) async {
    state = state.copyWith(isAdding: true, clearError: true);
    try {
      final token = await _getValidToken();
      await ApiService().addToCart(
        produitId : produitId,
        quantite  : quantite,
        token     : token,
      );
      // Recharge le panier depuis le serveur pour avoir
      // le vrai total, les noms et tous les champs à jour
      final cart = await ApiService().getCart(token: token);
      state = state.copyWith(isAdding: false, cart: cart);
      return true;
    } catch (e) {
      debugPrint('❌ addToCart: $e');
      state = state.copyWith(
        isAdding: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Supprime un produit du panier via son produitId
  Future<void> removeItem(int produitId) async {
    try {
      final token = await _getValidToken();
      await ApiService().deleteCartLine(idLigne: produitId, token: token);
      final cart = await ApiService().getCart(token: token);
      state = state.copyWith(cart: cart, clearError: true);
    } catch (e) {
      debugPrint('❌ removeItem: $e');
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Vide entièrement le panier
  Future<void> clearCartFromServer() async {
    final idPanier = state.cart?.id;
    if (idPanier == null) return;
    try {
      final token = await _getValidToken();
      await ApiService().clearEntireCart(idPanier: idPanier, token: token);
      // Recharge depuis le serveur → loadCart gère le corps vide (panier vidé)
      await loadCart();
    } catch (e) {
      debugPrint('❌ clearCartFromServer: $e');
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearCart() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final prefs    = ref.watch(sharedPreferencesProvider);
  final notifier = CartNotifier(prefs);

  ref.listen(authProvider, (previous, next) {
    if (!next.isAuthenticated) notifier.clearCart();
  });

  return notifier;
});
