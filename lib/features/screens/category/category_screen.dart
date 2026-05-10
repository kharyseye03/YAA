import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../home/restaurant_card.dart';
import 'restaurant_bottom_sheet.dart';

class CategoryScreenArgs {
  final String categoryName;
  final int categoryId;

  const CategoryScreenArgs({
    required this.categoryName,
    required this.categoryId,
  });
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.args});

  final CategoryScreenArgs args;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _activeFilter = 0;

  // ── Mock data par catégorie ───────────────────────────
  static const _mockRestaurants = [
    RestaurantData(name: 'Chez Fatou', cuisine: 'Cuisine locale', rating: 4.8, deliveryTime: '20-30 min', imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800'),
    RestaurantData(name: 'Pizza Palace', cuisine: 'Pizzeria', rating: 4.5, deliveryTime: '25-35 min', imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800'),
    RestaurantData(name: 'Burger House', cuisine: 'Fast-food', rating: 4.6, deliveryTime: '15-25 min', imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800'),
    RestaurantData(name: 'Le Grill d\'Or', cuisine: 'Grillades', rating: 4.7, deliveryTime: '30-40 min', imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800'),
    RestaurantData(name: 'Sushi Garden', cuisine: 'Japonais', rating: 4.9, deliveryTime: '35-50 min', imageUrl: 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800'),
    RestaurantData(name: 'Brioche Dorée', cuisine: 'Boulangerie', rating: 4.3, deliveryTime: '20-35 min', imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=800'),
  ];

  static const _mockPharmacies = [
    RestaurantData(name: 'Pharmacie Centrale', cuisine: 'Médicaments', rating: 4.7, deliveryTime: '15-25 min', imageUrl: 'https://images.unsplash.com/photo-1584308666544-ada528ea88e4?w=800'),
    RestaurantData(name: 'Pharmacie du Plateau', cuisine: 'Parapharmacie', rating: 4.5, deliveryTime: '20-30 min', imageUrl: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=800'),
    RestaurantData(name: 'Pharmacie Fann', cuisine: 'Médicaments', rating: 4.8, deliveryTime: '25-35 min', imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800'),
    RestaurantData(name: 'Pharmacie Liberté', cuisine: 'Parapharmacie', rating: 4.4, deliveryTime: '20-30 min', imageUrl: 'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=800'),
    RestaurantData(name: 'Pharmacie Mermoz', cuisine: 'Médicaments', rating: 4.6, deliveryTime: '30-40 min', imageUrl: 'https://images.unsplash.com/photo-1576671414121-aa2d60f93631?w=800'),
  ];

  static const _mockSupermarchs = [
    RestaurantData(name: 'Casino Supermarché', cuisine: 'Épicerie', rating: 4.5, deliveryTime: '25-40 min', imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800'),
    RestaurantData(name: 'Auchan Dakar', cuisine: 'Grande surface', rating: 4.7, deliveryTime: '30-45 min', imageUrl: 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800'),
    RestaurantData(name: 'City Dia', cuisine: 'Épicerie fine', rating: 4.4, deliveryTime: '20-35 min', imageUrl: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800'),
    RestaurantData(name: 'Marché du Terroir', cuisine: 'Produits locaux', rating: 4.8, deliveryTime: '35-50 min', imageUrl: 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=800'),
    RestaurantData(name: 'FreshMart', cuisine: 'Bio & Naturel', rating: 4.6, deliveryTime: '20-30 min', imageUrl: 'https://images.unsplash.com/photo-1534723452862-4c874986ebad?w=800'),
  ];

  static const _mockBoutiques = [
    RestaurantData(name: 'AURA Fashion', cuisine: 'Vêtements & Mode', rating: 4.8, deliveryTime: '30-45 min', imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800'),
    RestaurantData(name: 'SneakerZone', cuisine: 'Chaussures', rating: 4.6, deliveryTime: '25-40 min', imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800'),
    RestaurantData(name: 'Maison Dakar', cuisine: 'Décoration', rating: 4.5, deliveryTime: '35-50 min', imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800'),
    RestaurantData(name: 'BabyShop', cuisine: 'Puériculture', rating: 4.7, deliveryTime: '20-35 min', imageUrl: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=800'),
    RestaurantData(name: 'Tech & Co', cuisine: 'Électronique', rating: 4.4, deliveryTime: '30-45 min', imageUrl: 'https://images.unsplash.com/photo-1491933382434-500287f9b54b?w=800'),
  ];

  List<RestaurantData> get _items {
    switch (widget.args.categoryName.toLowerCase()) {
      case 'pharmacie': return _mockPharmacies;
      case 'supermarché':
      case 'supermarche': return _mockSupermarchs;
      case 'boutique': return _mockBoutiques;
      default: return _mockRestaurants;
    }
  }

  List<_FilterData> get _filters {
    switch (widget.args.categoryName.toLowerCase()) {
      case 'pharmacie':
        return const [
          _FilterData(label: 'Filtres', icon: Icons.tune),
          _FilterData(label: 'Jusqu\'à 30 min', icon: Icons.access_time_outlined),
          _FilterData(label: 'Médicaments'),
          _FilterData(label: 'Parapharmacie'),
          _FilterData(label: 'Bio'),
        ];
      case 'supermarché':
      case 'supermarche':
        return const [
          _FilterData(label: 'Filtres', icon: Icons.tune),
          _FilterData(label: 'Jusqu\'à 30 min', icon: Icons.access_time_outlined),
          _FilterData(label: 'Épicerie'),
          _FilterData(label: 'Bio & Naturel'),
          _FilterData(label: 'Produits locaux'),
        ];
      case 'boutique':
        return const [
          _FilterData(label: 'Filtres', icon: Icons.tune),
          _FilterData(label: 'Jusqu\'à 30 min', icon: Icons.access_time_outlined),
          _FilterData(label: 'Mode'),
          _FilterData(label: 'Chaussures'),
          _FilterData(label: 'Électronique'),
          _FilterData(label: 'Bébé'),
        ];
      default:
        return const [
          _FilterData(label: 'Filtres', icon: Icons.tune),
          _FilterData(label: 'Jusqu\'à 30 min', icon: Icons.access_time_outlined),
          _FilterData(label: 'Burger'),
          _FilterData(label: 'Africain'),
          _FilterData(label: 'Pizza'),
          _FilterData(label: 'Fast-food'),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          const SizedBox(height: AppDimens.md),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                0,
                AppDimens.screenPadding,
                AppDimens.xxl,
              ),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimens.lg),
              itemBuilder: (_, i) => _FullWidthRestaurantCard(
                restaurant: _items[i],
                categoryName: widget.args.categoryName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final isActive = i == _activeFilter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.dark : Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                border: Border.all(
                  color: isActive ? AppColors.dark : AppColors.grey300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter.icon != null) ...[
                    Icon(
                      filter.icon,
                      size: 14,
                      color: isActive ? Colors.white : AppColors.dark,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    filter.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: MediaQuery.of(context).padding.top + AppDimens.sm,
        bottom: AppDimens.lg,
      ),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Text(
            widget.args.categoryName,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterData {
  final String label;
  final IconData? icon;
  const _FilterData({required this.label, this.icon});
}

class _FullWidthRestaurantCard extends StatelessWidget {
  const _FullWidthRestaurantCard({
    required this.restaurant,
    required this.categoryName,
  });

  final RestaurantData restaurant;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showRestaurantBottomSheet(context, restaurant, categoryType: categoryName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: Image.network(
                  restaurant.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    width: double.infinity,
                    color: AppColors.grey200,
                    child: const Icon(Icons.storefront_outlined,
                        color: AppColors.grey400, size: 48),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: SvgPicture.asset(
                  'assets/icones/heart.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Nom + Rating ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.dark,
                  ),
                ),
              ),
              Icon(Icons.star, size: 15, color: Colors.amber.shade600),
              const SizedBox(width: 4),
              Text(
                restaurant.rating.toStringAsFixed(1),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // ── Temps + Cuisine ─────────────────────────────────
          Row(
            children: [
              SvgPicture.asset(
                'assets/icones/motorcycle-fill.svg',
                width: 15,
                height: 15,
                colorFilter: const ColorFilter.mode(
                  AppColors.grey500,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                restaurant.deliveryTime,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  color: AppColors.grey500,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                restaurant.cuisine,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
