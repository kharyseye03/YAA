import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/forgot_verification_screen.dart';
import '../../features/auth/location_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/password_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/verification_screen.dart';
import '../../features/starter/onboarding/screens/onboarding_screen.dart';
import '../../features/starter/splash/splash_screen.dart';

/// Route path constants.
abstract final class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verification = '/verification';
  static const String password = '/password';
  static const String location = '/location';
  static const String forgotPassword = '/forgot-password';
  static const String forgotVerification = '/forgot-verification';
  static const String resetPassword = '/reset-password';
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
  static const String verification = 'verification';
  static const String password = 'password';
  static const String location = 'location';
  static const String forgotPassword = 'forgotPassword';
  static const String forgotVerification = 'forgotVerification';
  static const String resetPassword = 'resetPassword';
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

      // ── Auth Flow ──────────────────────────────────────────
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.verification,
        name: RouteNames.verification,
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: RoutePaths.password,
        name: RouteNames.password,
        builder: (context, state) => const PasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.location,
        name: RouteNames.location,
        builder: (context, state) => const LocationScreen(),
      ),

      // ── Login Flow ─────────────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotVerification,
        name: RouteNames.forgotVerification,
        builder: (context, state) => const ForgotVerificationScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      ],

    // Global error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.uri}'),
      ),
    ),
  );
});