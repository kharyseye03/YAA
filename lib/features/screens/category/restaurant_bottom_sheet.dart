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
void showRestaurantBottomSheet(
  BuildContext context,
  RestaurantData restaurant, {
  String categoryType = 'restaurant',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RestaurantSheet(
      restaurant: restaurant,
      categoryType: categoryType.toLowerCase(),
    ),
  );
}

class _RestaurantSheet extends StatefulWidget {
  const _RestaurantSheet({
    required this.restaurant,
    required this.categoryType,
  });
  final RestaurantData restaurant;
  final String categoryType;

  @override
  State<_RestaurantSheet> createState() => _RestaurantSheetState();
}

// ── Données mock par catégorie ────────────────────────────
const _restaurantTabs = [
  _MenuTab('Populaire'), _MenuTab('Entrées'), _MenuTab('Plats'),
  _MenuTab('Desserts'), _MenuTab('Boissons'),
];
const _restaurantItems = [
  _MenuItem(name: 'Hamburger', description: '300 g', price: 1600, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400'),
  _MenuItem(name: 'Tacos', description: '350 g', price: 2500, imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400'),
  _MenuItem(name: 'Chawarma', description: '250 g', price: 1500, imageUrl: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=400'),
  _MenuItem(name: 'Burger Royal', description: '400 g', price: 2500, imageUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400'),
  _MenuItem(name: 'Pizza Margherita', description: '450 g', price: 4000, imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400'),
  _MenuItem(name: 'Salade César', description: '280 g', price: 1800, imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400'),
];

const _pharmacieTabs = [
  _MenuTab('Populaire'), _MenuTab('Médicaments'), _MenuTab('Parapharmacie'),
  _MenuTab('Vitamines'), _MenuTab('Bébé'),
];
const _pharmacieItems = [
  _MenuItem(name: 'Doliprane 1000mg', description: 'Boîte de 8 cp', price: 1500, imageUrl: 'https://images.unsplash.com/photo-1584308666544-ada528ea88e4?w=400'),
  _MenuItem(name: 'Ibuprofène 400mg', description: 'Boîte de 12 cp', price: 1800, imageUrl: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400'),
  _MenuItem(name: 'Vitamine C 1000mg', description: 'Tube de 10 cp', price: 2200, imageUrl: 'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=400'),
  _MenuItem(name: 'Amoxicilline 500mg', description: 'Boîte de 16 gél', price: 3500, imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400'),
  _MenuItem(name: 'Masque chirurgical', description: 'Sachet de 50', price: 2500, imageUrl: 'https://images.unsplash.com/photo-1584017911766-d821172e0e07?w=400'),
  _MenuItem(name: 'Gel hydroalcoolique', description: '500 ml', price: 2000, imageUrl: 'https://images.unsplash.com/photo-1584308666544-ada528ea88e4?w=400'),
];

const _superMarcheTabs = [
  _MenuTab('Populaire'), _MenuTab('Épicerie'), _MenuTab('Fruits & Légumes'),
  _MenuTab('Boissons'), _MenuTab('Hygiène'),
];
const _superMarcheItems = [
  _MenuItem(name: 'Riz Parfumé 5kg', description: 'Sac de 5 kg', price: 4500, imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400'),
  _MenuItem(name: 'Huile Végétale 1L', description: 'Bouteille 1 L', price: 1800, imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400'),
  _MenuItem(name: 'Tomates fraîches', description: 'Filet de 1 kg', price: 800, imageUrl: 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?w=400'),
  _MenuItem(name: 'Eau minérale 1,5L', description: 'Pack de 6', price: 2400, imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400'),
  _MenuItem(name: 'Pain de mie', description: '500 g', price: 900, imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400'),
  _MenuItem(name: 'Savon de Marseille', description: 'Lot de 3', price: 1500, imageUrl: 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400'),
];

const _boutiqueTabs = [
  _MenuTab('Populaire'), _MenuTab('Vêtements'), _MenuTab('Chaussures'),
  _MenuTab('Accessoires'), _MenuTab('Électronique'),
];
const _boutiqueItems = [
  _MenuItem(name: 'T-shirt Coton', description: 'S / M / L / XL', price: 8500, imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400'),
  _MenuItem(name: 'Sneakers Blanc', description: 'Tailles 39-45', price: 28000, imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400'),
  _MenuItem(name: 'Robe Wax', description: 'Taille unique', price: 15000, imageUrl: 'https://images.unsplash.com/photo-1502716119720-b23a93e5fe1b?w=400'),
  _MenuItem(name: 'Sac à main', description: 'Cuir synthétique', price: 22000, imageUrl: 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400'),
  _MenuItem(name: 'Montre Casio', description: 'Résistante eau', price: 18000, imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400'),
  _MenuItem(name: 'Écouteurs Bluetooth', description: 'Autonomie 20h', price: 35000, imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400'),
];

class _RestaurantSheetState extends State<_RestaurantSheet> {
  int _activeTab = 0;

  List<_MenuTab> get _tabs {
    switch (widget.categoryType) {
      case 'pharmacie': return _pharmacieTabs;
      case 'supermarché':
      case 'supermarche': return _superMarcheTabs;
      case 'boutique': return _boutiqueTabs;
      default: return _restaurantTabs;
    }
  }

  List<_MenuItem> get _menuItems {
    switch (widget.categoryType) {
      case 'pharmacie': return _pharmacieItems;
      case 'supermarché':
      case 'supermarche': return _superMarcheItems;
      case 'boutique': return _boutiqueItems;
      default: return _restaurantItems;
    }
  }

  late final List<GlobalKey> _sectionKeys;

  @override
  void initState() {
    super.initState();
    _sectionKeys = List.generate(_tabs.length, (_) => GlobalKey());
  }

  void _scrollToSection(int index) {
    setState(() => _activeTab = index);
    final ctx = _sectionKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.96,
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
                  // ── Header + infos ───────────────────────
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildRestaurantInfo()),

                  // ── Onglets sticky ───────────────────────
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabsDelegate(
                      height: 43,
                      child: _buildTabs(),
                    ),
                  ),

                  // ── Toutes les sections en scroll ────────
                  ..._buildAllSections(),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // ── Barre livraison fixe ─────────────────────
            _buildDeliveryBar(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllSections() {
    return _tabs.asMap().entries.expand((entry) {
      final i = entry.key;
      final tab = entry.value;
      return <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            key: _sectionKeys[i],
            padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding, AppDimens.lg,
                AppDimens.screenPadding, 0),
            child: Text(
              tab.label,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadding, AppDimens.md,
              AppDimens.screenPadding, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, j) => _MenuItemCard(item: _menuItems[j % _menuItems.length]),
              childCount: _menuItems.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimens.md,
              mainAxisSpacing: AppDimens.md,
              childAspectRatio: 0.82,
            ),
          ),
        ),
      ];
    }).toList();
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
              const Icon(Icons.star, size: 16, color: AppColors.dark),
              const SizedBox(width: 4),
              Text(
                '${widget.restaurant.rating.toStringAsFixed(1)} (124)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                  fontSize: 13,
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
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  onTap: () => _scrollToSection(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _tabs[i].label.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w500,
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
      ),
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
      decoration: const BoxDecoration(
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

// ── Delegate pour onglets sticky ──────────────────────────
class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _TabsDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_TabsDelegate old) => old.child != child;
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
                  child: const Icon(Icons.add, size: 20, color: AppColors.dark),
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
