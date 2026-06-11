import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:yaa/features/screens/home/product_card.dart';
import 'package:yaa/features/screens/home/restaurant_card.dart';
import 'package:yaa/features/screens/home/promo_banner_carousel.dart';
import 'package:yaa/features/screens/home/search_bar_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../cart/cart_screen.dart';
import '../favoris/favoris_screen.dart';
import '../order/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../category/restaurant_bottom_sheet.dart';
import 'category_list.dart';
import 'home_bottom_nav.dart';
import 'home_header.dart';
import 'providers/category_provider.dart';
import '../../../config/api/api_config.dart';
import '../category/category_screen.dart';

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
      badge: '🔥 OFFRE DU JOUR',
      title: 'Restos & Fast-food\nlivrés chez vous',
      subtitle: '-10% sur votre 1ère commande',
      icon: LucideIcons.utensils,
      gradient: [Color(0xFFFF6B35), Color(0xFFCC4400)],
    ),
    PromoBannerData(
      badge: '⚡ LIVRAISON EXPRESS',
      title: 'Courses & Épicerie\nen 30 minutes',
      subtitle: 'Disponible 7j/7 dans votre ville',
      icon: LucideIcons.shoppingCart,
      gradient: [Color(0xFF1652F0), Color(0xFF0E3BB8)],
    ),
    PromoBannerData(
      badge: '✨ NOUVEAUTÉS',
      title: 'Mode & Boutiques\nlocales',
      subtitle: 'Découvrez les tendances du moment',
      icon: LucideIcons.shoppingBag,
      gradient: [Color(0xFF9B59B6), Color(0xFF6C3483)],
    ),
    PromoBannerData(
      badge: '💊 SANTÉ',
      title: 'Pharmacies proches\nde vous',
      subtitle: 'Médicaments livrés rapidement',
      icon: LucideIcons.cross,
      gradient: [Color(0xFF27AE60), Color(0xFF1A7A40)],
    ),
  ];

  // ── Mock : Top vente ────────────────────────────────────
  final _topSelling = const [
    ProductData(
      name: 'Assiette du jour',
      subtitle: 'Chez Fatou Restaurant',
      price: 3500,
      rating: 4.9,
      imageUrl: 'assets/images/food.jpeg',
      isAsset: true,
    ),
    ProductData(
      name: 'Pack Skincare',
      subtitle: 'AURA Boutique',
      price: 18000,
      rating: 4.8,
      imageUrl: 'assets/images/tv1.jpeg',
      isAsset: true,
    ),
    ProductData(
      name: 'Basket Homme',
      subtitle: 'SneakerZone',
      price: 25000,
      rating: 4.7,
      imageUrl: 'assets/images/tv3.jpeg',
      isAsset: true,
    ),
    ProductData(
      name: 'Produit Bébé',
      subtitle: 'BabyShop Dakar',
      price: 5500,
      rating: 4.6,
      imageUrl: 'assets/images/tv4.jpeg',
      isAsset: true,
    ),
  ];

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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────
          if (_currentNavIndex == 0)
            HomeHeader(
              onNotificationTap: () => context.goNamed(RouteNames.notifications),
            ),

          // ── Content based on tab ─────────────────────────
          Expanded(
            child: _currentNavIndex == 1
                ? const OrdersScreen()
                : _currentNavIndex == 2
                ? const FavorisScreen()
                : _currentNavIndex == 3
                ? const ProfileScreen()
                : _currentNavIndex == 4
                ? CartScreen(onAddMore: () => setState(() => _currentNavIndex = 0))
                : _buildHomeContent(),
          ),
        ],
      ),

      extendBody: true,

      // ── Bottom navigation ───────────────────────────────
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        onCartTap: () => setState(() => _currentNavIndex = 4),
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
      padding: const EdgeInsets.only(bottom: 90),
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

// Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: SearchBarWidget(
              onTap: () => context.pushNamed(RouteNames.search),
            ),
          ),

          const SizedBox(height: AppDimens.xxl),

// Categories section
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Text(
              'Explorer par catégorie',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: AppDimens.md),

          ref.watch(categoriesProvider).when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (apiCategories) {
              const palette = [
                AppColors.restaurant,
                AppColors.primary,
                AppColors.pharmacy,
                AppColors.boutique,
                AppColors.supermarket,
                AppColors.secondary,
              ];
              const categoryFallbacks = {
                'restaurant'  : 'assets/images/food.jpeg',
                'boutique'    : 'assets/images/cat2.jpeg',
                'pharmacie'   : 'assets/images/cat3.jpeg',
                'supermarché' : 'assets/images/cat4.jpeg',
              };
              final categories = List.generate(apiCategories.length, (i) {
                final cat = apiCategories[i];
                return CategoryData(
                  label         : cat.name,
                  imageUrl      : cat.imageFileName != null
                      ? ApiConfig.getImageUrl(cat.imageFileName!)
                      : null,
                  fallbackAsset : categoryFallbacks[cat.name.toLowerCase()],
                  color         : palette[i % palette.length],
                  onTap: () {
                    setState(() => _activeCategoryIndex = i);
                    context.pushNamed(
                      RouteNames.category,
                      extra: CategoryScreenArgs(
                        categoryName: cat.name,
                        categoryId: cat.id,
                      ),
                    );
                  },
                );
              });
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding),
                child: CategoryList(
                  categories: categories,
                  activeIndex: _activeCategoryIndex,
                ),
              );
            },
          ),

          const SizedBox(height: AppDimens.xxl),

// ── Section : Restaurants proches ──────────────────────
          _buildSectionHeader('Autour de vous', onSeeAll: () {
            final cats = ref.read(categoriesProvider).value;
            if (cats != null && cats.isNotEmpty) {
              final restaurant = cats.first;
              context.pushNamed(
                RouteNames.category,
                extra: CategoryScreenArgs(
                  categoryName: restaurant.name,
                  categoryId: restaurant.id,
                ),
              );
            }
          }),
          const SizedBox(height: AppDimens.md),
          SizedBox(
            height: 200,
            child: ref.watch(nearbyStructuresProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Impossible de charger les structures',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey400,
                  ),
                ),
              ),
              data: (structures) {
                if (structures.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune structure autour de vous',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey400,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.screenPadding),
                  itemCount: structures.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppDimens.md),
                  itemBuilder: (_, i) {
                    final s = structures[i];
                    return RestaurantCard(
                      restaurant: RestaurantData(
                        name         : s.name,
                        cuisine      : s.categorie,
                        rating       : s.nombreEtoile.toDouble(),
                        deliveryTime : s.tempsLivraison,
                        imageUrl     : s.logoUrl,
                        distance     : s.distance > 0 ? s.distanceLabel : null,
                      ),
                      onTap: () => showRestaurantBottomSheet(
                        context,
                        RestaurantData(
                          name         : s.name,
                          cuisine      : s.categorie,
                          rating       : s.nombreEtoile.toDouble(),
                          deliveryTime : s.tempsLivraison,
                          imageUrl     : s.logoUrl,
                        ),
                        structureId  : s.id,
                        categoryType : s.categorie,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AppDimens.lg),

// ── Section : Top vente ─────────────────────────────────
          _buildSectionHeader('Coup de cœur'),
          const SizedBox(height: AppDimens.md),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding),
              itemCount: _topSelling.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppDimens.md),
              itemBuilder: (_, i) => _buildTopSellingCard(_topSelling[i]),
            ),
          ),

          const SizedBox(height: AppDimens.xxl),
        ],
      ),
    );
  }

  Widget _buildTopSellingCard(ProductData product) {
    return GestureDetector(
      onTap: () => context.pushNamed(RouteNames.productDetail),
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + cœur ──────────────────────────────
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    child: product.isAsset
                        ? Image.asset(
                            product.imageUrl,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            product.imageUrl,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              color: AppColors.grey200,
                              child: const Icon(Icons.image_outlined,
                                  color: AppColors.grey400, size: 28),
                            ),
                          ),
                  ),
                ),
                // Flamme top vente
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    LucideIcons.flame,
                    size: 18,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),

            // ── Infos ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.dark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price} F',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.dark,
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tous',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.chevron_right, size: 15, color: AppColors.dark),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
