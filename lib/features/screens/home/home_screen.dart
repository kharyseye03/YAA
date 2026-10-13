import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yaa/features/screens/home/restaurant_card.dart';
import 'package:yaa/features/screens/home/promo_banner_carousel.dart';
import 'package:yaa/features/screens/home/search_bar_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../favoris/providers/favori_notifier.dart';
import '../../../shared/widgets/map_prewarm.dart';
import '../cart/cart_screen.dart';
import '../favoris/favoris_screen.dart';
import '../order/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../category/restaurant_bottom_sheet.dart';
import '../../course/models/course_models.dart';
import 'category_list.dart';
import 'service_cards.dart';
import 'home_bottom_nav.dart';
import 'home_header.dart';
// import 'promo_sheet.dart'; // page promo plein écran, voir
// _ouvrirBanniere : plus appelée depuis le passage des bannières à
// l'API, le fichier est conservé pour un retour éventuel.
import 'banniere_stories.dart';
import 'providers/banniere_provider.dart';
import 'providers/category_provider.dart';
import '../../../model/banniere/banniere_model.dart';
import '../../../service/api/api_service.dart';
import '../../../config/api/api_config.dart';
import '../category/category_screen.dart';

/// Main home dashboard screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.ongletInitial = 0});

  /// Onglet ouvert à l'arrivée : 0 accueil, 1 commandes, 2 favoris,
  /// 3 profil, 4 panier.
  ///
  /// Sert aux entrées qui ne passent pas par la barre de navigation —
  /// aujourd'hui le clic sur une notification de commande. Ces écrans
  /// n'ont pas de route à eux : ils vivent dans l'accueil, qui porte
  /// le Scaffold et la barre du bas. Les afficher par une route
  /// séparée les rendrait nus — fond noir et textes soulignés de
  /// jaune, faute de Material au-dessus d'eux.
  final int ongletInitial;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentNavIndex = widget.ongletInitial;

  /// Barre de navigation visible. Masquée pendant qu'on descend dans
  /// une liste, ramenée au premier geste vers le haut.
  bool _navVisible = true;

  /// L'accueil n'est pas reconstruit quand on y revient : Flutter
  /// réutilise l'état existant et se contente de remplacer le widget.
  /// Sans ceci, arriver sur `/home?onglet=1` depuis l'accueil ne
  /// changeait rien à l'écran — le clic sur une notification semblait
  /// sans effet.
  @override
  void didUpdateWidget(HomeScreen ancien) {
    super.didUpdateWidget(ancien);
    if (widget.ongletInitial != ancien.ongletInitial) {
      setState(() => _currentNavIndex = widget.ongletInitial);
    }
  }
  /// -1 tant que rien n'a été touché : à l'ouverture de l'accueil,
  /// aucune catégorie n'est mise en avant.
  int _activeCategoryIndex = -1;

  // ── Bannières du carrousel ───────────────────────────────
  // Servies par /bannieres/mobile/groupes. Les trois slides étaient
  // écrites en dur ici — promotion, sponsor, mise en avant du service
  // Course — avec leurs images dans les assets. Elles annonçaient donc
  // des offres que personne ne pouvait retirer sans republier l'app.

  /// Badge affiché selon le type renvoyé par le serveur.
  ///
  /// Un type inconnu s'affiche tel quel plutôt que d'être masqué : le
  /// jour où le backend en ajoute un, la bannière apparaît quand même,
  /// avec un badge imparfait mais visible.
  static String _badgePourType(String type) => switch (type) {
        'FLASH_DEAL' => 'Flash Deal',
        'SPONSOR'    => 'Sponsorisé',
        'NOUVEAUTE'  => 'Nouveau',
        _            => type,
      };

  /// Couleurs d'origine conservées, type par type : l'orange de la
  /// promotion, le bleu du sponsor, le vert de la nouveauté.
  static Color _couleurPourType(String type) => switch (type) {
        'FLASH_DEAL' => AppColors.secondary,
        'SPONSOR'    => AppColors.primary,
        'NOUVEAUTE'  => AppColors.success,
        _            => AppColors.primary,
      };

  @override
  void initState() {
    super.initState();
    // Les favoris étaient chargés seulement à l'ouverture de l'onglet
    // Favoris : sur l'accueil, tous les cœurs paraissaient donc vides
    // même pour une structure déjà enregistrée. On les demande ici,
    // après la première frame pour ne pas modifier un provider
    // pendant la construction.
    Future.microtask(() {
      if (mounted) ref.read(favoriProvider.notifier).loadFavoris();
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  /// Touche sur une carte du carrousel.
  ///
  /// Deux destinations, décidées par le serveur :
  ///
  /// - `cliquable: true` → la fiche de l'établissement `structureId` ;
  /// - sinon → les bannières du groupe en plein écran, façon stories.
  ///
  /// L'accueil n'affiche qu'une carte par type. Les autres bannières
  /// du groupe n'existent que derrière ce toucher : c'est ce qui
  /// permet au backend d'en publier dix sans allonger l'accueil.
  Future<void> _ouvrirGroupe(GroupeBannieres groupe) async {
    final banniere = groupe.principale;
    if (!banniere.cliquable || banniere.structureId == null) {
      await showBanniereStories(context, groupe);
      return;
    }
    await _ouvrirBanniere(banniere);
  }

  /// Ouvre l'établissement d'une bannière sponsorisée.
  ///
  /// La fiche a besoin du nom, de la note et du temps de livraison,
  /// que la bannière ne porte pas : on va les chercher par
  /// l'identifiant. Afficher le titre de la bannière en guise de nom
  /// donnerait un en-tête faux, « ATYFOOD vous régale » au lieu de
  /// « ATYFOOD ».
  ///
  /// L'ancienne page promo plein écran, `showPromoSheet`, n'est plus
  /// appelée : elle attendait un code promo, une mention de validité
  /// et un libellé d'action que l'API ne porte pas. Son rôle est repris
  /// par [showBanniereStories], alimenté par le serveur. Le fichier
  /// reste au dépôt.
  Future<void> _ouvrirBanniere(BanniereModel banniere) async {
    if (!banniere.cliquable || banniere.structureId == null) return;
    try {
      final structure = await ApiService().getStructureById(
        banniere.structureId!,
      );
      if (!mounted) return;
      showRestaurantBottomSheet(
        context,
        RestaurantData(
          name         : structure.name,
          cuisine      : structure.categorie,
          rating       : structure.nombreEtoile.toDouble(),
          deliveryTime : structure.tempsLivraison,
          imageUrl     : structure.logoUrl,
        ),
        structureId  : structure.id,
        categoryType : structure.categorie,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Établissement indisponible pour le moment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NotificationListener<UserScrollNotification>(
        // Masque la barre quand on descend dans une liste, la ramène
        // dès qu'on remonte — le geste de LinkedIn. On n'écoute que
        // le défilement vertical : un carrousel horizontal, comme les
        // bannières de l'accueil, ne doit pas la faire disparaître.
        onNotification: (notification) {
          if (notification.metrics.axis != Axis.vertical) return false;
          // Pas sur l'accueil : c'est le point de départ, celui d'où
          // l'on navigue le plus, et son contenu est court. Masquer la
          // barre y retirerait l'outil principal pour un gain de place
          // minime. Le geste n'a de sens que dans les listes longues —
          // commandes, favoris — où chaque ligne gagnée compte.
          if (_currentNavIndex == 0) return false;

          // Rien à gagner sur une liste qui tient déjà dans l'écran :
          // deux favoris, et pourtant le simple rebond du doigt faisait
          // fuir la barre. `maxScrollExtent` vaut alors zéro — le
          // contenu ne défile pas vraiment, il rebondit. On exige en
          // plus une demi-hauteur de barre à gagner, sinon le jeu n'en
          // vaut pas la chandelle.
          if (notification.metrics.maxScrollExtent < 40) return false;
          final direction = notification.direction;
          if (direction == ScrollDirection.reverse && _navVisible) {
            setState(() => _navVisible = false);
          } else if (direction == ScrollDirection.forward && !_navVisible) {
            setState(() => _navVisible = true);
          }
          return false;
        },
        child: Stack(
        children: [
          Column(
            children: [
              // ── Header ───────────────────────────────────────
              if (_currentNavIndex == 0)
                HomeHeader(
                  onNotificationTap: () =>
                      context.goNamed(RouteNames.notifications),
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
                    ? CartScreen(
                        onAddMore: () => setState(() => _currentNavIndex = 0))
                    : _buildHomeContent(),
              ),
            ],
          ),

          // Hors écran : initialise le SDK Maps pendant que
          // l'utilisateur est ici, pour que Course et Livraison
          // s'ouvrent sur une carte déjà prête. Voir MapPrewarm.
          const MapPrewarm(),
        ],
        ),
      ),

      extendBody: true,

      // ── Bottom navigation ───────────────────────────────
      // Glisse hors de l'écran plutôt que de disparaître d'un coup :
      // `extendBody` étant actif, le contenu occupe déjà toute la
      // hauteur et rien ne saute pendant l'animation.
      bottomNavigationBar: AnimatedSlide(
        offset   : _navVisible ? Offset.zero : const Offset(0, 1.4),
        duration : const Duration(milliseconds: 220),
        curve    : Curves.easeOut,
        child: HomeBottomNav(
          currentIndex: _currentNavIndex,
          // Changer d'onglet la fait toujours réapparaître : sans ça,
          // on arrive sur un écran dont la navigation est cachée.
          onTap: (index) => setState(() {
            _currentNavIndex = index;
            _navVisible = true;
          }),
          onCartTap: () => setState(() {
            _currentNavIndex = 4;
            _navVisible = true;
          }),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      // Réserve exactement la place de la barre de navigation, qui
      // flotte au-dessus du contenu (`extendBody`). La valeur était
      // figée à 90 quand la barre en mesurait 68 ; elle en fait 56
      // depuis, et l'écart se voyait en bas de l'accueil sous forme
      // d'une bande blanche. Calculée plutôt que devinée : hauteur de
      // la barre, sa marge basse, l'encoche du téléphone, et une
      // respiration.
      padding: EdgeInsets.only(
        bottom: 56.h + 12.h + MediaQuery.of(context).padding.bottom + 16.h,
      ),
      // Note : le même calcul sert à la barre elle-même, dans
      // home_bottom_nav.dart. Si l'un bouge, l'autre doit suivre.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppDimens.lg),

// Promo banner — hidden in search mode
          if (_currentNavIndex == 0)
            ref.watch(bannieresProvider).when(
                  // Pas de réserve d'espace pendant le chargement : la
                  // hauteur du carrousel est connue, on l'occupe pour
                  // que le reste de l'accueil ne saute pas à l'arrivée
                  // des bannières.
                  loading: () => SizedBox(height: 150.h + AppDimens.xxl),
                  // Serveur muet ou aucune bannière : on n'affiche
                  // rien. Les trois slides en dur annonçaient des
                  // promotions qui n'existaient peut-être plus ; mieux
                  // vaut un accueil sans bandeau qu'une offre fausse.
                  error: (_, __) => const SizedBox.shrink(),
                  data: (groupes) {
                    if (groupes.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.screenPadding),
                          // Une carte par groupe, jamais plus : c'est la
                          // bannière principale de chaque type. Les
                          // autres s'ouvrent en plein écran.
                          child: PromoBannerCarousel(
                            banners: groupes.map((g) {
                              final b = g.principale;
                              return PromoBannerData(
                                badge      : _badgePourType(g.type),
                                badgeColor : _couleurPourType(g.type),
                                title      : b.titre,
                                subtitle   : b.description,
                                imageUrl   : b.imageUrl,
                              );
                            }).toList(),
                            onBannerTap: (i) => _ouvrirGroupe(groupes[i]),
                          ),
                        ),
                        SizedBox(height: AppDimens.xxl),
                      ],
                    );
                  },
                ),

// Search bar
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: SearchBarWidget(
              onTap: () => context.pushNamed(RouteNames.search),
            ),
          ),

          SizedBox(height: AppDimens.xxl),

// Categories section
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding),
            child: Text(
              'Explorer par catégorie',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: AppDimens.md),

          ref.watch(categoriesProvider).when(
            loading: () => Padding(
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
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding),
                child: CategoryList(
                  categories: categories,
                  activeIndex: _activeCategoryIndex,
                ),
              );
            },
          ),

          SizedBox(height: AppDimens.xxl),

// ── Cartes de service : Livraison / Course ─────────────
          _buildSectionHeader('Livraison & Course'),
          SizedBox(height: AppDimens.md),
          ServiceCards(
            onLivraison: () => context.pushNamed(
              RouteNames.course,
              extra: TypeService.livraison,
            ),
            onCourse: () => context.pushNamed(
              RouteNames.course,
              extra: TypeService.course,
            ),
          ),

          SizedBox(height: AppDimens.xxl),

// ── Section : Restaurants proches ──────────────────────
          // « Tous » ouvrait l'écran Catégorie sur cats.first, donc
          // les restaurants — par le seul hasard de l'ordre renvoyé
          // par le serveur. Une section qui promet la proximité doit
          // montrer ce qui est proche, toutes catégories confondues.
          _buildSectionHeader(
            'Autour de vous',
            onSeeAll: () => context.pushNamed(RouteNames.autourDeVous),
          ),
          SizedBox(height: AppDimens.md),
          SizedBox(
            height: 200.h,
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
                  padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.screenPadding),
                  itemCount: structures.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: AppDimens.md),
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
                      // Le provider bascule l'état sur-le-champ puis
                      // appelle /structures-favoris/toggle. En cas
                      // d'échec il revient en arrière tout seul, donc
                      // rien à gérer ici.
                      isFavori      : ref.watch(favoriProvider).isFavori(s.id),
                      isToggling    : ref.watch(favoriProvider).isToggling(s.id),
                      onFavoriteTap : () => ref
                          .read(favoriProvider.notifier)
                          .toggleFavori(s.id),
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
          // Plus de marge finale ici : elle s'ajoutait à celle du
          // SingleChildScrollView ci-dessus et doublait le blanc.
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
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
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
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
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(Icons.chevron_right, size: 15.r, color: AppColors.dark),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
