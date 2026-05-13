import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../home/providers/category_provider.dart';
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

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.args});

  final CategoryScreenArgs args;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  int _activeFilter = 0;

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
            child: ref.watch(structuresProvider(widget.args.categoryId)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (structures) => structures.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun établissement pour cette catégorie',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey500),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding,
                        0,
                        AppDimens.screenPadding,
                        AppDimens.xxl,
                      ),
                      itemCount: structures.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimens.lg),
                      itemBuilder: (_, i) {
                        final s = structures[i];
                        return _FullWidthRestaurantCard(
                          restaurant: RestaurantData(
                            name: s.name,
                            cuisine: s.adresse,
                            rating: s.nombreEtoile.toDouble(),
                            deliveryTime: s.tempsLivraison,
                            imageUrl: s.logoUrl,
                          ),
                          structureId: s.id,
                          categoryName: widget.args.categoryName,
                        );
                      },
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
    required this.structureId,
    required this.categoryName,
  });

  final RestaurantData restaurant;
  final int structureId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showRestaurantBottomSheet(
        context,
        restaurant,
        structureId: structureId,
        categoryType: categoryName,
      ),
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
