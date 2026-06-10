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
import '../../features/auth/providers/auth_notifier.dart';
import '../../features/screens/cart/cart_screen.dart';
import '../../features/screens/cart/checkout_screen.dart';
import '../../features/screens/home/home_screen.dart';
import '../../features/screens/home/notifications.dart';
import '../../features/screens/order/order_detail_screen.dart';
import '../../features/screens/order/order_tracking_screen.dart';
import '../../features/screens/order/orders_screen.dart';
import '../../features/screens/product/product_detail_screen.dart';
import '../../features/screens/profile/edit_personal_info_screen.dart';
import '../../features/screens/profile/personal_info_screen.dart';
import '../../features/screens/category/category_screen.dart';
import '../../features/screens/profile/terms_screen.dart';
import '../../features/screens/search/search_screen.dart';
import '../../features/starter/onboarding/screens/onboarding_screen.dart';
import '../../features/starter/splash/splash_screen.dart';

// Routes qui nécessitent d'être connecté
const _protectedRoutes = {
  '/home', '/product-detail', '/cart', '/checkout',
  '/orders', '/order-detail', '/orderTracking',
  '/profile', '/personalInfo', '/editPersonalInfo',
  '/terms', '/notifications', '/search',
};

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

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
  static const String productDetail = '/product-detail';
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
  static const String orderDetail = '/order-detail';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String orderTracking = '/orderTracking';
  static const String personalInfo = '/personalInfo';
  static const String editPersonalInfo = '/editPersonalInfo';
  static const String terms = '/terms';
  static const String notifications = '/notifications';
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
  static const String productDetail = 'productDetail';
  static const String orderTracking = 'orderTracking';
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
  static const String personalInfo = 'personalInfo';
  static const String editPersonalInfo = 'editPersonalInfo';
  static const String terms = 'terms';
  static const String notifications = 'notifications';
  static const String category = 'category';
}

/// GoRouter provider for Riverpod.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    refreshListenable: _RouterNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final location = state.matchedLocation;

      if (!isAuthenticated && _protectedRoutes.contains(location)) {
        return RoutePaths.login;
      }
      return null;
    },
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
        name: RouteNames.verification,
        path: '/verification',
        builder: (context, state) => VerificationScreen(
          email: state.extra as String,
        ),
      ),
      GoRoute(
        name: RouteNames.password,
        path: '/password',
        builder: (context, state) => PasswordScreen(
          email: state.extra as String,
        ),
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
        builder: (context, state) => ForgotVerificationScreen(
          email: state.extra as String,
        ),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          email: state.extra as String,
        ),
      ),
      // ── Home ───────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.productDetail,
        name: RouteNames.productDetail,
        builder: (context, state) => const ProductDetailScreen(),
      ),

      // ── Cart & Checkout ────────────────────────────────────
      GoRoute(
        path: RoutePaths.cart,
        name: RouteNames.cart,
        builder: (context, state) => const Scaffold(
          backgroundColor: Colors.white,
          body: CartScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        name: RouteNames.checkout,
        builder: (context, state) => CheckoutScreen(
          modeLivraison: state.extra as String? ?? 'GROUPAGE',
        ),
      ),
      // ── Orders ─────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.orders,
        name: RouteNames.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: RoutePaths.orderTracking,
        name: RouteNames.orderTracking,
        builder: (context, state) => const OrderTrackingScreen(),
      ),
      GoRoute(
        path: RoutePaths.orderDetail,
        name: RouteNames.orderDetail,
        builder: (context, state) => OrderDetailScreen(
          commandeId: state.extra as int?,
        ),
      ),
      GoRoute(
        path: RoutePaths.personalInfo,
        name: RouteNames.personalInfo,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: RoutePaths.editPersonalInfo,
        name: RouteNames.editPersonalInfo,
        builder: (context, state) => const EditPersonalInfoScreen(),
      ),
      GoRoute(
        path: RoutePaths.terms,
        name: RouteNames.terms,
        builder: (context, state) => const TermsScreen(),
      ),

      GoRoute(
        path: RoutePaths.notifications,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/category',
        name: RouteNames.category,
        builder: (context, state) => CategoryScreen(
          args: state.extra as CategoryScreenArgs,
        ),
      ),
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        builder: (context, state) => const SearchScreen(),
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