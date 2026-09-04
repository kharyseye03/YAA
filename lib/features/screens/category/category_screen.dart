import '../../../shared/widgets/image_reseau.dart';
import '../../../core/errors/messages_erreur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/favoris/providers/favori_notifier.dart';
import '../../../model/category/categorie_produit.dart';
import '../home/providers/category_provider.dart';
import '../home/restaurant_card.dart';
import 'category_filters.dart';
import 'category_filters_sheet.dart';
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
  CategoryFilters _filtres = const CategoryFilters();

  final _chipsCtrl = ScrollController();

  static const _espaceChips    = 8.0;
  static const _dureeDefilement = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _chipsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          SizedBox(height: AppDimens.md),
          Expanded(
            child: ref.watch(structuresFiltreesProvider(StructuresQuery(
              categorieId : widget.args.categoryId,
              specialite  : _filtres.categorie?.nom,
            ))).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  MessagesErreur.depuisException(e),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (structures) {
                // Note, temps et tri s'appliquent ici : le backend ne
                // les gère pas, mais la liste est courte
                final liste = _filtres.appliquer(structures);

                if (liste.isEmpty) {
                  return _buildVide(sourceVide: structures.isEmpty);
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.screenPadding,
                    0,
                    AppDimens.screenPadding,
                    AppDimens.xxl,
                  ),
                  itemCount: liste.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: AppDimens.lg),
                  itemBuilder: (_, i) {
                    final s = liste[i];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de filtres ────────────────────────────────────────────
  // Un bouton « Filtres » épinglé à gauche, qui ouvre le panneau
  // complet, puis les catégories de produits qui défilent.

  TextStyle get _styleChip => AppTextStyles.bodySmall.copyWith(
        fontSize   : 12.sp,
        fontWeight : FontWeight.w600,
      );

  Widget _buildFilters() {
    return ref.watch(filtresCategorieProvider(widget.args.categoryId)).when(
      // Hauteur réservée pendant le chargement, plutôt qu'un espace
      // vide qui saute quand les puces arrivent
      loading : () => SizedBox(height: 40.h),
      // Le bouton reste utile même sans catégories : il porte aussi
      // la note, le temps de livraison et le tri
      error   : (_, __) => _buildBarre(const []),
      data    : _buildBarre,
    );
  }

  Widget _buildBarre(List<CategorieProduit> categories) {
    return SizedBox(
      height: 40.h,
      child: Row(
        children: [
          SizedBox(width: AppDimens.screenPadding),
          _buildBoutonFiltres(categories),
          if (categories.isEmpty)
            const Spacer()
          else ...[
            SizedBox(width: AppDimens.md),
            Container(width: 1, height: 22.h, color: AppColors.grey300),
            SizedBox(width: AppDimens.md),
            Expanded(child: _buildChipsCategories(categories)),
          ],
        ],
      ),
    );
  }

  Widget _buildBoutonFiltres(List<CategorieProduit> categories) {
    final nb    = _filtres.nbCriteres;
    final actif = nb > 0;

    return GestureDetector(
      onTap: () => _ouvrirPanneau(categories),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: actif ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(color: actif ? AppColors.primary : AppColors.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size  : 15.r,
              color : actif ? Colors.white : AppColors.dark,
            ),
            SizedBox(width: 6.w),
            Text(
              'Filtres',
              style: _styleChip.copyWith(
                color: actif ? Colors.white : AppColors.dark,
              ),
            ),
            // Pastille : combien de critères sont posés dans le panneau
            if (actif) ...[
              SizedBox(width: 6.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Text(
                  '$nb',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize   : 11.sp,
                    fontWeight : FontWeight.w700,
                    color      : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChipsCategories(List<CategorieProduit> categories) {
    return ListView.separated(
      controller      : _chipsCtrl,
      scrollDirection : Axis.horizontal,
      padding         : EdgeInsets.only(right: AppDimens.screenPadding),
      // +1 pour la puce « Tous » en tête
      itemCount        : categories.length + 1,
      separatorBuilder : (_, __) => const SizedBox(width: _espaceChips),
      itemBuilder: (_, i) {
        final estTous  = i == 0;
        final filtre   = estTous ? null : categories[i - 1];
        final isActive = estTous
            ? _filtres.categorie == null
            : _filtres.categorie?.id == filtre!.id;

        return GestureDetector(
          onTap: () => setState(
            () => _filtres = estTous
                ? _filtres.copyWith(effacerCategorie: true)
                : _filtres.copyWith(categorie: filtre),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.grey300,
              ),
            ),
            child: Center(
              child: Text(
                estTous ? 'Tous' : filtre!.nom,
                style: _styleChip.copyWith(
                  color: isActive ? Colors.white : AppColors.dark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _ouvrirPanneau(List<CategorieProduit> categories) async {
    final resultat = await showCategoryFiltersSheet(
      context,
      filtres    : _filtres,
      categories : categories,
    );
    // null = fermeture sans valider, on garde les critères en cours
    if (resultat == null || !mounted) return;

    setState(() => _filtres = resultat);
    _revelerCategorie(categories);
  }

  /// Amène la puce de la catégorie choisie dans le champ de vision.
  ///
  /// Sans ça, choisir « Sandwichs » dans le panneau ne montrerait
  /// aucune puce active à l'écran, la barre restant en début de liste.
  void _revelerCategorie(List<CategorieProduit> categories) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipsCtrl.hasClients) return;

      final choisie = _filtres.categorie;
      if (choisie == null) {
        _chipsCtrl.animateTo(0,
            duration: _dureeDefilement, curve: Curves.easeOut);
        return;
      }

      // La puce visée est peut-être hors écran, donc non construite :
      // on calcule sa position en mesurant les libellés qui la
      // précèdent plutôt qu'en cherchant son contexte.
      var offset = _largeurChip('Tous') + _espaceChips;
      for (final c in categories) {
        if (c.id == choisie.id) break;
        offset += _largeurChip(c.nom) + _espaceChips;
      }

      _chipsCtrl.animateTo(
        offset.clamp(0.0, _chipsCtrl.position.maxScrollExtent),
        duration : _dureeDefilement,
        curve    : Curves.easeOut,
      );
    });
  }

  double _largeurChip(String libelle) {
    final peintre = TextPainter(
      text          : TextSpan(text: libelle, style: _styleChip),
      textDirection : TextDirection.ltr,
      maxLines      : 1,
    )..layout();
    // + les 14 px de padding de chaque côté
    return peintre.width + 28;
  }

  // ── État vide ───────────────────────────────────────────────────
  Widget _buildVide({required bool sourceVide}) {
    // Deux causes distinctes : le serveur n'a rien renvoyé, ou nos
    // critères locaux ont tout écarté
    final message = sourceVide
        ? (_filtres.categorie == null
            ? 'Aucun établissement pour cette catégorie'
            : 'Aucun établissement pour « ${_filtres.categorie!.nom} »')
        : 'Aucun établissement ne correspond à vos critères';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppDimens.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 44.r, color: AppColors.grey400),
            SizedBox(height: AppDimens.md),
            Text(
              message,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            if (!_filtres.estVierge) ...[
              SizedBox(height: AppDimens.sm),
              TextButton(
                onPressed: () =>
                    setState(() => _filtres = const CategoryFilters()),
                child: Text(
                  'Réinitialiser les filtres',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight : FontWeight.w600,
                    color      : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
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
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.r,
                color: AppColors.dark,
              ),
            ),
          ),
          SizedBox(width: AppDimens.md),
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

class _FullWidthRestaurantCard extends ConsumerWidget {
  const _FullWidthRestaurantCard({
    required this.restaurant,
    required this.structureId,
    required this.categoryName,
  });

  final RestaurantData restaurant;
  final int structureId;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriState = ref.watch(favoriProvider);
    final isFavori    = favoriState.isFavori(structureId);
    final isToggling  = favoriState.isToggling(structureId);

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
                child: ImageReseau(
                  url: restaurant.imageUrl,
                  height: 160.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallback: Container(
                    height: 160.h,
                    width: double.infinity,
                    color: AppColors.grey200,
                    child: Icon(Icons.storefront_outlined,
                        color: AppColors.grey400, size: 48.r),
                  ),
                ),
              ),
              // ── Bouton cœur ─────────────────────────────────
              Positioned(
                top  : 10.h,
                right: 10.w,
                child: GestureDetector(
                  onTap: isToggling
                      ? null
                      : () => ref
                            .read(favoriProvider.notifier)
                            .toggleFavori(structureId),
                  child: isToggling
                      ? SizedBox(
                          width : 22.r,
                          height: 22.r,
                          child : CircularProgressIndicator(
                            strokeWidth : 2.r,
                            color       : Colors.white,
                          ),
                        )
                      : isFavori
                          ? Icon(Icons.favorite_rounded,
                              color: Colors.red, size: 26.r,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 6.r)])
                          : SvgPicture.asset(
                              'assets/icones/heart.svg',
                              width : 24.r,
                              height: 24.r,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          // ── Nom + Rating ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: AppColors.dark,
                  ),
                ),
              ),
              Icon(Icons.star, size: 15.r, color: Colors.amber.shade600),
              SizedBox(width: 4.w),
              Text(
                restaurant.rating.toStringAsFixed(1),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),

          SizedBox(height: 5.h),

          // ── Temps + Cuisine ─────────────────────────────────
          Row(
            children: [
              SvgPicture.asset(
                'assets/icones/motorcycle-fill.svg',
                width: 15.r,
                height: 15.r,
                colorFilter: const ColorFilter.mode(
                  AppColors.grey500,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                restaurant.deliveryTime,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(width: 16.w),
              // L'adresse est de longueur imprévisible : elle doit
              // céder la place plutôt que déborder
              Expanded(
                child: Text(
                  restaurant.cuisine,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
