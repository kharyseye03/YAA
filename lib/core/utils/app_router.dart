import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Route path constants.
abstract final class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String restaurantList = '/restaurants';
  static const String restaurantDetail = '/restaurants/:id';
  static const String pharmacyList = '/pharmacies';
  static const String pharmacyDetail = '/pharmacies/:id';
  static const String boutiqueList = '/boutiques';
  static const String boutiqueDetail = '/boutiques/:id';
  static const String supermarketList = '/supermarkets';
  static const String supermarketDetail = '/supermarkets/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String profile = '/profile';
  static const String search = '/search';
}

/// Route name constants.
abstract final class RouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';
  static const String restaurantList = 'restaurantList';
  static const String restaurantDetail = 'restaurantDetail';
  static const String pharmacyList = 'pharmacyList';
  static const String pharmacyDetail = 'pharmacyDetail';
  static const String boutiqueList = 'boutiqueList';
  static const String boutiqueDetail = 'boutiqueDetail';
  static const String supermarketList = 'supermarketList';
  static const String supermarketDetail = 'supermarketDetail';
  static const String cart = 'cart';
  static const String checkout = 'checkout';
  static const String orders = 'orders';
  static const String orderDetail = 'orderDetail';
  static const String profile = 'profile';
  static const String search = 'search';
}

/// GoRouter provider for Riverpod.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // TODO: Add remaining routes as screens are built
    ],

    // Global error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.uri}'),
      ),
    ),
  );
});
