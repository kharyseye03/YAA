import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../model/category/categorie_produit.dart';
import '../../../model/category/structure_detail.dart';
import '../home/providers/category_provider.dart';
import '../home/restaurant_card.dart';
import 'product_bottom_sheet.dart';

// ── Entry point ───────────────────────────────────────────
void showRestaurantBottomSheet(
  BuildContext context,
  RestaurantData restaurant, {
  required int structureId,
  String categoryType = 'restaurant',
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProviderScope(
      child: _RestaurantSheet(
        restaurant: restaurant,
        structureId: structureId,
        categoryType: categoryType.toLowerCase(),
      ),
    ),
  );
}

class _RestaurantSheet extends ConsumerStatefulWidget {
  const _RestaurantSheet({
    required this.restaurant,
    required this.structureId,
    required this.categoryType,
  });
  final RestaurantData restaurant;
  final int structureId;
  final String categoryType;

  @override
  ConsumerState<_RestaurantSheet> createState() => _RestaurantSheetState();
}

class _RestaurantSheetState extends ConsumerState<_RestaurantSheet> {
  int _activeTab = 0;
  List<GlobalKey>? _sectionKeys;

  void _initKeys(int count) {
    if (_sectionKeys == null || _sectionKeys!.length != count) {
      _sectionKeys = List.generate(count, (_) => GlobalKey());
    }
  }

  void _scrollToSection(int index) {
    setState(() => _activeTab = index);
    final ctx = _sectionKeys?[index].currentContext;
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
    final tabsAsync = ref.watch(categorieProduitProvider(widget.structureId));

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
              child: tabsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error),
                  ),
                ),
                data: (tabs) {
                  _initKeys(tabs.length);
                  return CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverToBoxAdapter(child: _buildRestaurantInfo()),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabsDelegate(
                          height: 43,
                          child: _buildTabs(tabs),
                        ),
                      ),
                      ..._buildAllSections(tabs),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
            ),
            _buildDeliveryBar(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllSections(List<CategorieProduit> tabs) {
    return tabs.asMap().entries.expand((entry) {
      final i = entry.key;
      final tab = entry.value;

      final sectionTitle = SliverToBoxAdapter(
        child: Padding(
          key: _sectionKeys![i],
          padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadding, AppDimens.lg,
              AppDimens.screenPadding, 0),
          child: Text(
            tab.nom,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );

      // Onglet "Populaire" (categorie == null) → produits depuis l'API structure
      if (tab.categorie == null) {
        final detail = ref.watch(structureDetailProvider(widget.structureId));
        return <Widget>[
          sectionTitle,
          detail.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppDimens.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.xl),
                child: Center(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            data: (detail) => detail.produits.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(
                        child: Text(
                          'Aucun produit disponible',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.grey500),
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding, AppDimens.md,
                        AppDimens.screenPadding, 0),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, j) =>
                            _ApiMenuItemCard(produit: detail.produits[j]),
                        childCount: detail.produits.length,
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
          ),
        ];
      }

      // Autres onglets → masqués tant qu'il n'y a pas de produits
      return <Widget>[];
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(width: 1, height: 20, color: AppColors.grey300),
              ),
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

  Widget _buildTabs(List<CategorieProduit> tabs) {
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
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppDimens.xl),
              itemBuilder: (_, i) {
                final isActive = i == _activeTab;
                return GestureDetector(
                  onTap: () => _scrollToSection(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        tabs[i].nom.toUpperCase(),
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

// ── Carte produit (données API) ───────────────────────────
class _ApiMenuItemCard extends StatelessWidget {
  const _ApiMenuItemCard({required this.produit});
  final Produit produit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showProductBottomSheet(context, produit.id),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: Image.network(
                  produit.imageUrl,
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
          '${produit.prix.toInt()} F',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.dark,
          ),
        ),
        Text(
          produit.nom,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 13,
            color: AppColors.dark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      ),
    );
  }
}
