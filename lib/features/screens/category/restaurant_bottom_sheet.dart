import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../home/restaurant_card.dart';

// ── Modèles ───────────────────────────────────────────────
class _MenuTab {
  final String label;
  const _MenuTab(this.label);
}

class _MenuItem {
  final String name;
  final String description;
  final int price;
  final String imageUrl;
  const _MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}

// ── Entry point ───────────────────────────────────────────
void showRestaurantBottomSheet(BuildContext context, RestaurantData restaurant) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RestaurantSheet(restaurant: restaurant),
  );
}

class _RestaurantSheet extends StatefulWidget {
  const _RestaurantSheet({required this.restaurant});
  final RestaurantData restaurant;

  @override
  State<_RestaurantSheet> createState() => _RestaurantSheetState();
}

class _RestaurantSheetState extends State<_RestaurantSheet> {
  int _activeTab = 0;

  final _tabs = const [
    _MenuTab('Populaire'),
    _MenuTab('Entrées'),
    _MenuTab('Plats'),
    _MenuTab('Desserts'),
    _MenuTab('Boissons'),
  ];

  final _menuItems = const [
    _MenuItem(name: 'Hamburger', description: '300 g', price: 1600, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400'),
    _MenuItem(name: 'Tacos', description: '350 g', price: 2500, imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400'),
    _MenuItem(name: 'Chawarma', description: '250 g', price: 1500, imageUrl: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400'),
    _MenuItem(name: 'Burger Royal', description: '400 g', price: 2500, imageUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400'),
    _MenuItem(name: 'Pizza Margherita', description: '450 g', price: 4000, imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400'),
    _MenuItem(name: 'Salade César', description: '280 g', price: 1800, imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Drag handle ─────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // ── Header fixe ──────────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildRestaurantInfo()),
                  SliverToBoxAdapter(child: _buildTabs()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppDimens.screenPadding, AppDimens.lg,
                          AppDimens.screenPadding, 0),
                      child: Text(
                        _tabs[_activeTab].label,
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // ── Grille produits ──────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, AppDimens.md,
                        AppDimens.screenPadding, 100),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _MenuItemCard(item: _menuItems[i]),
                        childCount: _menuItems.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppDimens.md,
                        mainAxisSpacing: AppDimens.md,
                        childAspectRatio: 0.82,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Barre livraison fixe ─────────────────────────
            _buildDeliveryBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 8, AppDimens.screenPadding, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: AppColors.dark),
          ),
          const Spacer(),
          Icon(LucideIcons.search, size: 22, color: AppColors.dark),
          const SizedBox(width: AppDimens.lg),
          Icon(LucideIcons.heart, size: 22, color: AppColors.dark),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, AppDimens.lg,
          AppDimens.screenPadding, AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.restaurant.name.toUpperCase(),
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Row(
            children: [
              // Rating
              Icon(Icons.star, size: 16, color: AppColors.dark),
              const SizedBox(width: 4),
              Text(
                '${widget.restaurant.rating.toStringAsFixed(1)} (124)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                  fontSize: 13,
                ),
              ),
              Text(
                '  Afficher >',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
              ),

              // Séparateur
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(width: 1, height: 20, color: AppColors.grey300),
              ),

              // Livraison
              const Icon(Icons.directions_bike_outlined,
                  size: 16, color: AppColors.dark),
              const SizedBox(width: 4),
              Text(
                widget.restaurant.deliveryTime,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'Livraison',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
              ),

              // Séparateur
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(width: 1, height: 20, color: AppColors.grey300),
              ),

              const Icon(Icons.more_vert, size: 18, color: AppColors.dark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDimens.xl),
            itemBuilder: (_, i) {
              final isActive = i == _activeTab;
              return GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _tabs[i].label.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isActive ? AppColors.dark : AppColors.grey500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2.5,
                      width: isActive ? 24 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.dark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.grey200),
      ],
    );
  }

  Widget _buildDeliveryBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: AppDimens.md,
        bottom: MediaQuery.of(context).padding.bottom + AppDimens.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, size: 22, color: AppColors.dark),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Livraison F 1 000 · ${widget.restaurant.deliveryTime}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Frais de service 0 F',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.dark),
        ],
      ),
    );
  }
}

// ── Carte produit ─────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: Image.network(
                  item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.grey200,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.grey400),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add,
                      size: 20, color: AppColors.dark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${item.price} F',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.dark,
          ),
        ),
        Text(
          item.name,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 13,
            color: AppColors.dark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item.description,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }
}
