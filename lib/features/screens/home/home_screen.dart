import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import 'service_cards.dart';
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

  // ── Bannières du carrousel ───────────────────────────────
  // Slide 1 : Promo acquisition · Slide 2 : Pub sponsorisée
  // Slide 3 : Mise en avant du service Course
  final _banners = const [
    PromoBannerData(
      badge      : 'Flash Deal',
      title      : '-50% sur votre\n1ère commande',
      subtitle   : 'Code BIENVENUE · valable 7 jours',
      badgeColor : Color(0xFFFF6B35),
      image      : 'assets/images/slide1.jpg',
    ),
    PromoBannerData(
      badge      : 'Sponsorisé',
      title      : 'Le Djoloff\nvous régale',
      subtitle   : '2 pizzas achetées = 1 offerte',
      badgeColor : Color(0xFF1A1A2E),
      image      : 'assets/images/slide2.png',
    ),
    PromoBannerData(
      badge      : 'Nouveau',
      title      : 'Envoyez vos colis\nen quelques clics',
      subtitle   : 'Un coursier récupère et livre',
      badgeColor : Color(0xFF27AE60),
      image      : 'assets/images/slide3.png',
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

// ── Cartes de service : Livraison / Course ─────────────
          _buildSectionHeader('Livraison & Course'),
          const SizedBox(height: AppDimens.md),
          ServiceCards(
            onLivraison: () {
              // TODO: flow livraison (à venir)
            },
            onCourse: () {
              // TODO: flow course (à venir)
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

          const SizedBox(height: AppDimens.xxl),
        ],
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
