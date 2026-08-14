import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/category/categorie_produit.dart';
import '../../../model/category/structure_detail.dart';
import '../../../features/cart/providers/cart_notifier.dart';
import '../../../service/api/api_logger.dart';
import '../home/providers/category_provider.dart' show
    categorieProduitProvider,
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
              child: _enRecherche
                  ? _buildRecherche()
                  : tabsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 100)),
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
                height : 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color        : AppColors.primary,
                  borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                  boxShadow    : [
                    BoxShadow(
                      color     : AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset    : const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Badge articles ─────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color        : Colors.white.withValues(alpha: 0.20),
                        borderRadius : BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.labelSmall.copyWith(
                          color      : Colors.white,
                          fontWeight : FontWeight.w800,
                          fontSize   : 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ── Label ──────────────────────────
                    Expanded(
                      child: Text(
                        'Voir mon panier',
                        style: AppTextStyles.labelMedium.copyWith(
                          color      : Colors.white,
                          fontWeight : FontWeight.w700,
                          fontSize   : 14,
                        ),
                      ),
                    ),
                    // ── Prix ───────────────────────────
                    Text(
                      '${total.toStringAsFixed(0)} F',
                      style: AppTextStyles.labelMedium.copyWith(
                        color      : Colors.white,
                        fontWeight : FontWeight.w800,
                        fontSize   : 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.white),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  List<Widget> _buildAllSections(List<CategorieProduit> tabs) {
    return tabs.asMap().entries.expand((entry) {
      final i   = entry.key;
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

      // "Populaire" → tous les produits de la structure (sans filtre catégorie)
      // Autres onglets → filtrés par categorieProduitId
      final isPopulaire = tab.nom.toLowerCase() == 'populaire';
      final params = ProduitQueryParams(
        structureId        : widget.structureId,
        categorieProduitId : isPopulaire ? null : tab.id,
      );

      final produitsAsync = ref.watch(produitsByStructureProvider(params));

      // L'onglet « Populaire » ramène tout le catalogue : c'est le
      // seul endroit où l'on peut confronter les produits aux onglets
      if (isPopulaire) {
        produitsAsync.whenData((tous) => _verifierCoherence(tabs, tous));
      }

      return <Widget>[
        sectionTitle,
        produitsAsync.when(
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
          data: (produits) => produits.isEmpty
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
                      (_, j) => _ApiMenuItemCard(produit: produits[j]),
                      childCount: produits.length,
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
    }).toList();
  }

  /// Signale les produits qu'aucun onglet ne peut afficher.
  ///
  /// Les onglets viennent de la catégorie d'établissement (tous les
  /// supermarchés partagent la même liste), pas de ce que la
  /// structure vend réellement. Un produit rangé dans une catégorie
  /// absente de cette liste n'apparaît alors sous aucune section —
  /// seul « Populaire », qui ne filtre pas, le montre.
  bool _coherenceVerifiee = false;

  void _verifierCoherence(List<CategorieProduit> tabs, List<Produit> tous) {
    if (_coherenceVerifiee) return;
    _coherenceVerifiee = true;

    if (tous.isEmpty) {
      ApiLogger.vide(
        'Fiche structure ${widget.structureId}',
        'aucun produit renvoyé par /produits/structure — '
        'comparer avec /structures/${widget.structureId}',
      );
      return;
    }

    final idsOnglets = tabs.map((t) => t.id).toSet();
    final orphelins  = tous
        .where((p) => !idsOnglets.contains(p.categorieProduitId))
        .toList();

    if (orphelins.isNotEmpty) {
      final detail = orphelins
          .map((p) => '${p.nom} (categorieProduitId ${p.categorieProduitId})')
          .join(', ');
      ApiLogger.vide(
        'Fiche structure ${widget.structureId}',
        '${orphelins.length} produit(s) sans onglet correspondant, '
        'visibles uniquement sous « Populaire » → $detail',
      );
    }

    // Sections qui déclencheront un appel réseau pour rien
    final categoriesUtilisees = tous.map((p) => p.categorieProduitId).toSet();
    final ongletsVides = tabs
        .where((t) =>
            t.nom.toLowerCase() != 'populaire' &&
            !categoriesUtilisees.contains(t.id))
        .length;
    if (ongletsVides > 0) {
      ApiLogger.vide(
        'Fiche structure ${widget.structureId}',
        '$ongletsVides onglet(s) sur ${tabs.length} sans produit — '
        'autant de requêtes /produits/structure inutiles',
      );
    }
  }

  // ════════════════════════════════════════════════════════
  // Recherche dans le catalogue de l'établissement
  // ════════════════════════════════════════════════════════

  Widget _buildRecherche() {
    return Column(
      children: [
        _buildBarreRecherche(),
        _buildFiltresRapides(),
        const SizedBox(height: AppDimens.md),
        const Divider(height: 1, color: AppColors.grey200),
        Expanded(child: _buildResultats()),
      ],
    );
  }

  Widget _buildBarreRecherche() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
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
                fontSize   : 15,
                fontWeight : FontWeight.w500,
                color      : AppColors.dark,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: 'Rechercher dans ce catalogue',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.screenPadding),
        children: [
          _chipFiltre(
            'En promotion',
            actif : _enPromotion,
            icone : Icons.local_offer_outlined,
            onTap : () => setState(() => _enPromotion = !_enPromotion),
          ),
          const SizedBox(width: 8),
          _chipFiltre(
            'Disponible',
            actif : _disponible,
            onTap : () => setState(() => _disponible = !_disponible),
          ),
          if (_estPharmacie) ...[
            const SizedBox(width: 8),
            _chipFiltre(
              'Sur ordonnance',
              actif : _ordonnance,
              onTap : () => setState(() => _ordonnance = !_ordonnance),
            ),
          ],
          const SizedBox(width: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? AppColors.dark : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(color: actif ? AppColors.dark : AppColors.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone,
                  size: 14, color: actif ? Colors.white : AppColors.dark),
              const SizedBox(width: 5),
            ],
            Text(
              libelle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize   : 12,
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
            const SizedBox(width: AppDimens.md),
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
          .copyWith(fontSize: 14, color: AppColors.dark),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'F',
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
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Text(
            e.toString().replaceAll('Exception: ', ''),
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
          padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding,
            AppDimens.md,
            AppDimens.screenPadding,
            100,
          ),
          itemCount: produits.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.search, size: 40, color: AppColors.grey300),
            const SizedBox(height: AppDimens.md),
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
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 44, color: AppColors.grey400),
            const SizedBox(height: AppDimens.md),
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
          GestureDetector(
            onTap: _ouvrirRecherche,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(LucideIcons.search, size: 22, color: AppColors.dark),
            ),
          ),
          const SizedBox(width: AppDimens.md),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    produit.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.grey200,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.grey400),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right : 8,
                    child : Container(
                      width      : 32,
                      height     : 32,
                      decoration : const BoxDecoration(
                        color : AppColors.secondary,
                        shape : BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${produit.prix.toInt()} F',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize  : 15,
              color     : AppColors.dark,
            ),
          ),
          Text(
            produit.nom,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
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
