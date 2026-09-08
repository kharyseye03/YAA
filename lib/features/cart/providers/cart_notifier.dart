import '../../../core/utils/journal.dart';
import '../../../core/errors/messages_erreur.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../model/cart/cart_model.dart';
import '../../../service/api/api_service.dart';


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
  CartNotifier() : super(const CartState());


  // ─────────────────────────────────────────────────────────

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cart  = await ApiService().getCart();
      // cart == null → pas de panier actif (corps vide du serveur) : état normal
      state = state.copyWith(
        isLoading : false,
        cart      : cart,
        clearCart : cart == null,
        clearError: true,
      );
    } catch (e) {
      journal('❌ loadCart: $e');
      state = state.copyWith(
        isLoading: false,
        error: MessagesErreur.depuisException(e),
      );
    }
  }

  Future<bool> addToCart({required int produitId, int quantite = 1}) async {
    state = state.copyWith(isAdding: true, clearError: true);
    try {
      await ApiService().addToCart(
        produitId : produitId,
        quantite  : quantite,
      );
      // Recharge le panier depuis le serveur pour avoir
      // le vrai total, les noms et tous les champs à jour
      final cart = await ApiService().getCart();
      state = state.copyWith(isAdding: false, cart: cart);
      return true;
    } catch (e) {
      journal('❌ addToCart: $e');
      state = state.copyWith(
        isAdding: false,
        error: MessagesErreur.depuisException(e),
      );
      return false;
    }
  }

  /// Fixe la quantité d'une ligne du panier.
  ///
  /// `POST /paniers` **remplace** la quantité au lieu de s'y ajouter :
  /// on envoie donc la valeur voulue, jamais l'écart. C'est aussi ce
  /// qui rend l'appel rejouable — envoyer deux fois « 3 » laisse 3.
  ///
  /// À la différence d'[addToCart], `isAdding` n'est pas levé : ce
  /// drapeau déclenche l'état occupé du bouton d'ajout, et faire
  /// clignoter tout l'écran à chaque appui sur `+` serait pénible.
  /// Le total se met à jour parce qu'on relit le panier ensuite.
  Future<bool> changerQuantite({
    required int produitId,
    required int quantite,
  }) async {
    try {
      await ApiService().addToCart(produitId: produitId, quantite: quantite);
      final cart = await ApiService().getCart();
      state = state.copyWith(cart: cart, clearError: true);
      return true;
    } catch (e) {
      journal('❌ changerQuantite: $e');
      state = state.copyWith(error: MessagesErreur.depuisException(e));
      return false;
    }
  }

  /// Supprime une ligne du panier via son id (idLigne)
  Future<void> removeItem(int idLigne) async {
    try {
      await ApiService().deleteCartLine(idLigne: idLigne);
      final cart = await ApiService().getCart();
      state = state.copyWith(cart: cart, clearError: true);
    } catch (e) {
      journal('❌ removeItem: $e');
      state = state.copyWith(
        error: MessagesErreur.depuisException(e),
      );
    }
  }

  /// Vide entièrement le panier
  Future<void> clearCartFromServer() async {
    final idPanier = state.cart?.id;
    if (idPanier == null) return;
    try {
      await ApiService().clearEntireCart(idPanier: idPanier);
      // Recharge depuis le serveur → loadCart gère le corps vide (panier vidé)
      await loadCart();
    } catch (e) {
      journal('❌ clearCartFromServer: $e');
      state = state.copyWith(
        error: MessagesErreur.depuisException(e),
      );
    }
  }

  void clearCart() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final notifier = CartNotifier();

  ref.listen(authProvider, (previous, next) {
    if (!next.isAuthenticated) notifier.clearCart();
  });

  return notifier;
});
