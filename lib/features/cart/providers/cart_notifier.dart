import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/providers/auth_notifier.dart'; // pour sharedPreferencesProvider et authProvider
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
  }) {
    return CartState(
      isLoading : isLoading ?? this.isLoading,
      isAdding  : isAdding  ?? this.isAdding,
      cart      : cart      ?? this.cart,
      error     : clearError ? null : (error ?? this.error),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._prefs) : super(const CartState());

  final SharedPreferences _prefs;

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Endpoint public — ne pas envoyer le token (Spring Security le rejette)
      final cart = await ApiService().getCart();
      state = state.copyWith(isLoading: false, cart: cart);
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
      // Endpoint public — ne pas envoyer le token
      final cart = await ApiService().addToCart(
        produitId : produitId,
        quantite  : quantite,
      );
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
