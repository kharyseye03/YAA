import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaa/features/screens/home/product_card.dart';
import 'package:yaa/features/screens/home/promo_banner_carousel.dart';
import 'package:yaa/features/screens/home/search_bar_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../user/providers/user_notifier.dart';
import '../order/orders_screen.dart';
import '../profile/profile_screen.dart';
import 'category_list.dart';
import 'home_bottom_nav.dart';
import 'home_header.dart';

/// Main home dashboard screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  int _activeCategoryIndex = 0;

  // ── Mock Data ────────────────────────────────────────────
  final _banners = const [
    PromoBannerData(
      title: 'Besoin d\'un livreur ?',
      description: 'Lancez une annonce et fixez votre prix\nde livraison.',
      icon: Icons.directions_bike,
    ),
    PromoBannerData(
      title: 'Offres du jour',
      description: 'Découvrez les meilleures offres\nsur vos produits préférés.',
      icon: Icons.local_offer,
    ),
    PromoBannerData(
      title: 'Livraison rapide',
      description: 'Recevez vos commandes en moins\nde 30 minutes.',
      icon: Icons.flash_on,
    ),
  ];

  late final List<CategoryData> _categories = [
    CategoryData(
      label: 'Restaurants',
      icon: Icons.restaurant,
      onTap: () => setState(() => _activeCategoryIndex = 0),
    ),
    CategoryData(
      label: 'Boutiques',
      icon: Icons.shopping_bag_outlined,
      onTap: () => setState(() => _activeCategoryIndex = 1),
    ),
    CategoryData(
      label: 'Pharmacies',
      icon: Icons.medical_services_outlined,
      onTap: () => setState(() => _activeCategoryIndex = 2),
    ),
    CategoryData(
      label: 'Supermarché',
      icon: Icons.store_outlined,
      onTap: () => setState(() => _activeCategoryIndex = 3),
    ),
  ];

  // ── Mock Data par catégorie ─────────────────────────────
  final Map<int, List<ProductData>> _productsByCategory = {
    // Restaurants
    0: const [
      ProductData(name: 'Crudité salade', price: 12000, rating: 4.8, imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'),
      ProductData(name: 'Truffle Beef Burger', price: 2500, rating: 4.5, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400'),
      ProductData(name: 'Charcoal Kebabs', price: 5000, rating: 4.9, imageUrl: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400'),
      ProductData(name: 'Spaguetti', price: 1000, rating: 4.7, imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400'),
    ],
    // Boutiques
    1: const [
      ProductData(name: 'Polo en cuire', price: 12000, rating: 4.8, imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400'),
      ProductData(name: 'Ensembles pull', price: 25000, rating: 4.5, imageUrl: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=400'),
      ProductData(name: 'Pull noir en cuire', price: 15000, rating: 4.9, imageUrl: 'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=400'),
      ProductData(name: 'Sack à main', price: 10000, rating: 4.7, imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400'),
    ],
    // Pharmacies
    2: const [
      ProductData(name: 'Siro deux couleur', price: 1200, rating: 4.8, imageUrl: 'https://images.unsplash.com/photo-1584308666544-ada528ea88e4?w=400'),
      ProductData(name: 'CAC1000 ml', price: 2500, rating: 4.5, imageUrl: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400'),
      ProductData(name: 'CAC1000 ml', price: 1500, rating: 4.9, imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400'),
      ProductData(name: 'Siro deux couleur', price: 1000, rating: 4.7, imageUrl: 'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=400'),
    ],
    // Supermarché
    3: const [
      ProductData(name: 'Pack légumes', price: 12000, rating: 4.8, imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400'),
      ProductData(name: 'Gel de douche', price: 25000, rating: 4.5, imageUrl: 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400'),
      ProductData(name: 'Patte', price: 15000, rating: 4.9, imageUrl: 'https://images.unsplash.com/photo-1553531384-cc64ac80f931?w=400'),
      ProductData(name: 'Joués', price: 10000, rating: 4.7, imageUrl: 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=400'),
    ],
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Header (blue) ─────────────────────────────────
          _currentNavIndex == 2
              ? _buildSimpleHeader('Commandes')
              : _currentNavIndex == 3
              ? _buildSimpleHeader('Mon compte')
              : HomeHeader(
            userName: ref.watch(userProvider).profile?.fullName ?? 'Bienvenue',
            imageUrl: ref.watch(userProvider).profile?.imageUrl,
            onNotificationTap: () => context.goNamed(RouteNames.notifications),
          ),

          // ── Scrollable content ────────────────────────────
          // ── Content based on tab ────────────────────────
          Expanded(
            child: _currentNavIndex == 2
                ? const OrdersScreen()
                : _currentNavIndex == 3
                ? const ProfileScreen()
                : _buildHomeContent(),
          ),
        ],
      ),

      // ── Bottom navigation ───────────────────────────────
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentNavIndex,
        cartItemCount: 0,
        onTap: (index) => setState(() => _currentNavIndex = index),
        onCartTap: () => context.pushNamed(RouteNames.cart),
      ),
    );
  }

  Widget _buildSimpleHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: MediaQuery.of(context).padding.top + AppDimens.md,
        bottom: AppDimens.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1652F0),
            Color(0xFF08399A)
          ],
        ),
      ),
      child: Text(
        title,
        style: AppTextStyles.h2.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimens.lg),

// Promo banner — hidden in search mode
          if (_currentNavIndex == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding),
              child: PromoBannerCarousel(banners: _banners),
            ),
            const SizedBox(height: AppDimens.xxl),
          ],

// Categories section
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Text(
              'Catégories',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: AppDimens.md),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: CategoryList(
              categories: _categories,
              activeIndex: _activeCategoryIndex,
            ),
          ),

          const SizedBox(height: AppDimens.xxl),

// Search bar — visible only in search mode
          if (_currentNavIndex == 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding),
              child: SearchBarWidget(
                onFilterTap: () {
// TODO: Open filter
                },
              ),
            ),
            const SizedBox(height: AppDimens.xxl),
          ],

// Recent publications section
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Text(
              'Publication récente',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: AppDimens.md),

// Products grid
          Builder(
            builder: (context) {
              final products =
                  _productsByCategory[_activeCategoryIndex] ?? [];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppDimens.lg,
                    crossAxisSpacing: AppDimens.md,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: products[index],
                      onTap: () =>
                          context.pushNamed(RouteNames.productDetail),
                      onAddTap: () {
                      // TODO: Add to cart
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
