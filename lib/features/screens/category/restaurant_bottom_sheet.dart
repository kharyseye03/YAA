import '../../../shared/widgets/image_reseau.dart';
import '../../../core/errors/messages_erreur.dart';
import '../../../core/utils/devise.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/category/structure_detail.dart';
import '../../../features/cart/providers/cart_notifier.dart';
import '../home/providers/category_provider.dart' show
    produitsByStructureProvider,
    ProduitQueryParams;
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
    builder: (_) => _RestaurantSheet(
      restaurant: restaurant,
      structureId: structureId,
      categoryType: categoryType.toLowerCase(),
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

  // ── Recherche dans le catalogue ───────────────────────────
  bool _enRecherche = false;
  final _rechercheCtrl = TextEditingController();
  Timer? _debounce;
  String _terme = '';
  bool _enPromotion = false;
  bool _disponible = false;
  bool _ordonnance = false;
  num? _prixMin;
  num? _prixMax;

  /// Le filtre ordonnance n'a de sens que pour une pharmacie
  bool get _estPharmacie => widget.categoryType.contains('pharmac');

  bool get _aDesCriteres =>
      _terme.isNotEmpty ||
      _enPromotion ||
      _disponible ||
      _ordonnance ||
      _prixMin != null ||
      _prixMax != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cartProvider.notifier).loadCart());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rechercheCtrl.dispose();
    super.dispose();
  }

  void _ouvrirRecherche() {
    setState(() => _enRecherche = true);
  }

  void _fermerRecherche() {
    _debounce?.cancel();
    _rechercheCtrl.clear();
    setState(() {
      _enRecherche = false;
      _terme       = '';
      _enPromotion = false;
      _disponible  = false;
      _ordonnance  = false;
      _prixMin     = null;
      _prixMax     = null;
    });
  }

  // On attend que l'utilisateur cesse de taper avant d'interroger l'API
  void _onTermeChange(String valeur) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _terme = valeur.trim());
    });
  }

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
    // Un seul appel : le catalogue complet. Les onglets sont déduits
    // des produits reçus, pas d'un référentiel de catégories séparé.
    final catalogueAsync = ref.watch(produitsByStructureProvider(
      ProduitQueryParams(structureId: widget.structureId),
    ));

    return DraggableScrollableSheet(
      initialChildSize: 0.96,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Expanded(
              child: _enRecherche
                  ? _buildRecherche()
                  : catalogueAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(
                          MessagesErreur.depuisException(e),
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                      data: (produits) {
                        final sections = _grouperParCategorie(produits);
                        _initKeys(sections.length);
                        return CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverToBoxAdapter(child: _buildHeader()),
                            SliverToBoxAdapter(child: _buildRestaurantInfo()),
                            if (sections.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildCatalogueVide(),
                              )
                            else ...[
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _TabsDelegate(
                                  height: 43.h,
                                  child: _buildTabs(sections),
                                ),
                              ),
                              ..._buildAllSections(sections),
                              SliverToBoxAdapter(
                                  child: SizedBox(height: 100.h)),
                            ],
                          ],
                        );
                      },
                    ),
            ),
            _buildCartPill(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPill() {
    final cartState = ref.watch(cartProvider);
    final count     = cartState.cart?.totalArticles ?? 0;
    final total     = cartState.cart?.montantTotal   ?? 0.0;
    final bottom    = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration  : const Duration(milliseconds: 300),
      curve     : Curves.easeOut,
      color     : Colors.white,
      padding   : EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        count > 0 ? 10 : 0,
        AppDimens.screenPadding,
        count > 0 ? bottom + 12 : 0,
      ),
      height: count > 0 ? bottom + 74 : 0,
      child: count > 0
          ? GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                context.goNamed(RouteNames.cart);
              },
              child: Container(
                height : 52.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color        : AppColors.primary,
                  borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                  boxShadow    : [
                    BoxShadow(
                      color     : AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 12.r,
                      offset    : const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Badge articles ─────────────────
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 9.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color        : Colors.white.withValues(alpha: 0.20),
                        borderRadius : BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.labelSmall.copyWith(
                          color      : Colors.white,
                          fontWeight : FontWeight.w800,
                          fontSize   : 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    // ── Label ──────────────────────────
                    Expanded(
                      child: Text(
                        'Voir mon panier',
                        style: AppTextStyles.labelMedium.copyWith(
                          color      : Colors.white,
                          fontWeight : FontWeight.w700,
                          fontSize   : 14.sp,
                        ),
                      ),
                    ),
                    // ── Prix ───────────────────────────
                    Text(
                      montantLabel(total),
                      style: AppTextStyles.labelMedium.copyWith(
                        color      : Colors.white,
                        fontWeight : FontWeight.w800,
                        fontSize   : 14.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14.r, color: Colors.white),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Découpe le catalogue en sections à partir des produits reçus.
  ///
  /// On ne demande plus au serveur quelles catégories existent : on
  /// regarde celles que les produits portent réellement. Un produit
  /// rangé dans une catégorie absente du référentiel reste donc
  /// visible, et aucune section vide n'est créée.
  List<_SectionCatalogue> _grouperParCategorie(List<Produit> produits) {
    if (produits.isEmpty) return const [];

    // LinkedHashMap : l'ordre d'apparition du serveur est conservé
    final parCategorie = <int, List<Produit>>{};
    final noms         = <int, String>{};
    for (final p in produits) {
      parCategorie.putIfAbsent(p.categorieProduitId, () => []).add(p);
      if (p.nomCategorieProduit.isNotEmpty) {
        noms[p.categorieProduitId] ??= p.nomCategorieProduit;
      }
    }

    return [
      // « Populaire » garde son rôle de vitrine : tout le catalogue
      _SectionCatalogue(titre: 'Populaire', produits: produits),
      for (final entree in parCategorie.entries)
        _SectionCatalogue(
          titre    : noms[entree.key] ?? 'Autres',
          produits : entree.value,
        ),
    ];
  }

  List<Widget> _buildAllSections(List<_SectionCatalogue> sections) {
    return sections.asMap().entries.expand((entry) {
      final i       = entry.key;
      final section = entry.value;

      return <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            key: _sectionKeys![i],
            padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding, AppDimens.lg,
                AppDimens.screenPadding, 0),
            child: Text(
              section.titre,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              AppDimens.screenPadding, AppDimens.md,
              AppDimens.screenPadding, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, j) => _ApiMenuItemCard(produit: section.produits[j]),
              childCount: section.produits.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount   : 2,
              crossAxisSpacing : AppDimens.md,
              mainAxisSpacing  : AppDimens.md,
              childAspectRatio : 0.82,
            ),
          ),
        ),
      ];
    }).toList();
  }

  Widget _buildCatalogueVide() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 44.r, color: AppColors.grey300),
            SizedBox(height: AppDimens.md),
            Text(
              'Aucun produit disponible pour le moment',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Recherche dans le catalogue de l'établissement
  // ════════════════════════════════════════════════════════

  Widget _buildRecherche() {
    return Column(
      children: [
        _buildBarreRecherche(),
        _buildFiltresRapides(),
        SizedBox(height: AppDimens.md),
        const Divider(height: 1, color: AppColors.grey200),
        Expanded(child: _buildResultats()),
      ],
    );
  }

  Widget _buildBarreRecherche() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 8, AppDimens.screenPadding, AppDimens.sm),
      child: Row(
        children: [
          // Champ nu : pas d'icône ni de croix, le bouton « Annuler »
          // suffit à sortir de la recherche
          Expanded(
            child: TextField(
              controller: _rechercheCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onTermeChange,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize   : 15.sp,
                fontWeight : FontWeight.w500,
                color      : AppColors.dark,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                hintText: 'Rechercher dans ce catalogue',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15.sp,
                  color: AppColors.grey400,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _fermerRecherche,
            child: Text(
              'Annuler',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltresRapides() {
    // Hauteur calée sur celle des puces (texte + 8 px de padding
    // haut et bas + la bordure) : en dessous, elles sont rognées
    return SizedBox(
      height: 38.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: AppDimens.screenPadding),
        children: [
          _chipFiltre(
            'En promotion',
            actif : _enPromotion,
            icone : Icons.local_offer_outlined,
            onTap : () => setState(() => _enPromotion = !_enPromotion),
          ),
          SizedBox(width: 8.w),
          _chipFiltre(
            'Disponible',
            actif : _disponible,
            onTap : () => setState(() => _disponible = !_disponible),
          ),
          if (_estPharmacie) ...[
            SizedBox(width: 8.w),
            _chipFiltre(
              'Sur ordonnance',
              actif : _ordonnance,
              onTap : () => setState(() => _ordonnance = !_ordonnance),
            ),
          ],
          SizedBox(width: 8.w),
          _chipFiltre(
            _libellePrix,
            actif : _prixMin != null || _prixMax != null,
            icone : Icons.payments_outlined,
            onTap : _choisirPrix,
          ),
        ],
      ),
    );
  }

  Widget _chipFiltre(
    String libelle, {
    required bool actif,
    required VoidCallback onTap,
    IconData? icone,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: actif ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(color: actif ? AppColors.primary : AppColors.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone,
                  size: 14.r, color: actif ? Colors.white : AppColors.dark),
              SizedBox(width: 5.w),
            ],
            Text(
              libelle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize   : 12.sp,
                fontWeight : FontWeight.w600,
                color      : actif ? Colors.white : AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _libellePrix {
    if (_prixMin == null && _prixMax == null) return 'Prix';
    if (_prixMax == null) return 'Dès ${_prixMin!.toInt()} F';
    if (_prixMin == null) return 'Jusqu\'à ${_prixMax!.toInt()} F';
    return '${_prixMin!.toInt()} – ${_prixMax!.toInt()} F';
  }

  Future<void> _choisirPrix() async {
    final minCtrl =
        TextEditingController(text: _prixMin?.toInt().toString() ?? '');
    final maxCtrl =
        TextEditingController(text: _prixMax?.toInt().toString() ?? '');

    final valide = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        title: Text(
          'Fourchette de prix',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
        content: Row(
          children: [
            Expanded(child: _champPrix(minCtrl, 'Min')),
            SizedBox(width: AppDimens.md),
            Expanded(child: _champPrix(maxCtrl, 'Max')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Appliquer',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );

    if (valide == true && mounted) {
      setState(() {
        // Champ vidé → critère retiré
        _prixMin = num.tryParse(minCtrl.text.trim());
        _prixMax = num.tryParse(maxCtrl.text.trim());
      });
    }
    minCtrl.dispose();
    maxCtrl.dispose();
  }

  Widget _champPrix(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodyMedium
          .copyWith(fontSize: 14.sp, color: AppColors.dark),
      decoration: InputDecoration(
        labelText: label,
        suffixText: kDevise,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
      ),
    );
  }

  Widget _buildResultats() {
    if (!_aDesCriteres) {
      return _buildInvite();
    }

    // Un booléen à false filtrerait « les produits qui ne sont pas en
    // promotion » — quand la puce est éteinte, on n'envoie rien
    final params = ProduitQueryParams(
      structureId         : widget.structureId,
      nom                 : _terme.isEmpty ? null : _terme,
      enPromotion         : _enPromotion ? true : null,
      disponible          : _disponible ? true : null,
      necessiteOrdonnance : _ordonnance ? true : null,
      prixMin             : _prixMin,
      prixMax             : _prixMax,
    );

    return ref.watch(produitsByStructureProvider(params)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.xl),
          child: Text(
            MessagesErreur.depuisException(e),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (produits) {
        if (produits.isEmpty) {
          return _buildAucunResultat();
        }
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            AppDimens.screenPadding,
            AppDimens.md,
            AppDimens.screenPadding,
            100,
          ),
          itemCount: produits.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount   : 2,
            crossAxisSpacing : AppDimens.md,
            mainAxisSpacing  : AppDimens.md,
            childAspectRatio : 0.82,
          ),
          itemBuilder: (_, i) => _ApiMenuItemCard(produit: produits[i]),
        );
      },
    );
  }

  Widget _buildInvite() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.search, size: 40.r, color: AppColors.grey300),
            SizedBox(height: AppDimens.md),
            Text(
              'Cherchez un produit chez ${widget.restaurant.name}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAucunResultat() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 44.r, color: AppColors.grey400),
            SizedBox(height: AppDimens.md),
            Text(
              _terme.isEmpty
                  ? 'Aucun produit ne correspond à ces filtres'
                  : 'Aucun résultat pour « $_terme »',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 8, AppDimens.screenPadding, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20.r, color: AppColors.dark),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _ouvrirRecherche,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Icon(LucideIcons.search, size: 22.r, color: AppColors.dark),
            ),
          ),
          SizedBox(width: AppDimens.md),
          Icon(LucideIcons.heart, size: 22.r, color: AppColors.dark),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppDimens.screenPadding, AppDimens.lg,
          AppDimens.screenPadding, AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.restaurant.name.toUpperCase(),
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22.sp,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: AppDimens.md),
          Row(
            children: [
              Icon(Icons.star, size: 16.r, color: AppColors.dark),
              SizedBox(width: 4.w),
              Text(
                '${widget.restaurant.rating.toStringAsFixed(1)} (124)',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                  fontSize: 13.sp,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Container(width: 1, height: 20.h, color: AppColors.grey300),
              ),
              Icon(Icons.directions_bike_outlined,
                  size: 16.r, color: AppColors.dark),
              SizedBox(width: 4.w),
              Text(
                widget.restaurant.deliveryTime,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                  fontSize: 13.sp,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'Livraison',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: 12.sp,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Container(width: 1, height: 20.h, color: AppColors.grey300),
              ),
              Icon(Icons.more_vert, size: 18.r, color: AppColors.dark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(List<_SectionCatalogue> tabs) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 42.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding),
              itemCount: tabs.length,
              separatorBuilder: (_, __) => SizedBox(width: AppDimens.xl),
              itemBuilder: (_, i) {
                final isActive = i == _activeTab;
                return GestureDetector(
                  onTap: () => _scrollToSection(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        tabs[i].titre.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12.sp,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w500,
                          color: isActive ? AppColors.dark : AppColors.grey500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2.5,
                        width: isActive ? 24 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2.r),
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

}

/// Une section du catalogue : un onglet et les produits qu'il montre.
class _SectionCatalogue {
  const _SectionCatalogue({required this.titre, required this.produits});

  final String titre;
  final List<Produit> produits;
}

// ── Delegate pour onglets sticky ──────────────────────────
class _TabsDelegate extends SliverPersistentHeaderDelegate {
  /// La hauteur est arrondie au pixel entier.
  ///
  /// Un sliver épinglé annonce son encombrement, et Flutter vérifie
  /// ensuite que ce qui est peint correspond. Une valeur ScreenUtil
  /// tombe presque toujours sur une fraction — 43.h vaut 52.8 sur un
  /// grand écran — et l'enfant se peint sur 52.6. L'écart de deux
  /// dixièmes suffit à violer l'invariant `layoutExtent <=
  /// paintExtent` : l'assertion coupe le rendu, et toute la feuille
  /// reste blanche.
  _TabsDelegate({required this.child, required double height})
      : height = height.roundToDouble();

  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  /// L'enfant est enfermé dans exactement la hauteur annoncée, pour
  /// qu'il ne puisse pas diverger de la déclaration ci-dessus.
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: height, child: child);

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      old.child != child || old.height != height;
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageReseau(
                    url: produit.imageUrl,
                    fit: BoxFit.cover,
                    fallback: Container(
                      color: AppColors.grey200,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.grey400),
                    ),
                  ),
                  Positioned(
                    bottom: 8.h,
                    right : 8.w,
                    child : Container(
                      width      : 32.r,
                      height     : 32.r,
                      decoration : const BoxDecoration(
                        color : AppColors.secondary,
                        shape : BoxShape.circle,
                      ),
                      child: Icon(Icons.add,
                          size: 18.r, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${produit.prix.toInt()} F',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize  : 15.sp,
              color     : AppColors.dark,
            ),
          ),
          Text(
            produit.nom,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13.sp,
              color   : AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
