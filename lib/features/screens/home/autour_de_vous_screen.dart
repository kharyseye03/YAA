import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../favoris/providers/favori_notifier.dart';
import '../../location/providers/position_provider.dart';
import '../category/restaurant_bottom_sheet.dart';
import 'providers/category_provider.dart';
import 'restaurant_card.dart';

/// Toutes les structures proches, tous types confondus.
///
/// Le bouton « Tous » de l'accueil ouvrait l'écran Catégorie sur
/// `cats.first` — c'est-à-dire les restaurants, par le hasard de
/// l'ordre du serveur. Une section qui promet la proximité doit
/// montrer ce qui est proche, pas une catégorie.
///
/// Aucun nouvel appel : la liste vient du même `nearbyStructuresProvider`
/// que le défilé de l'accueil, déjà chargé. Le passage est donc
/// immédiat, et les deux vues ne peuvent pas diverger.
class AutourDeVousScreen extends ConsumerWidget {
  const AutourDeVousScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structures = ref.watch(nearbyStructuresProvider);
    final favoris    = ref.watch(favoriProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor : Colors.white,
        surfaceTintColor: Colors.white,
        elevation       : 0,
        title: Text(
          'Autour de vous',
          style: AppTextStyles.h4.copyWith(
            fontWeight : FontWeight.w700,
            color      : AppColors.dark,
          ),
        ),
      ),
      body: structures.when(
        loading : () => const Center(child: CircularProgressIndicator()),
        error   : (_, __) => _message(
          'Impossible de charger les structures',
        ),
        data: (liste) {
          if (liste.isEmpty) {
            return _message('Aucune structure autour de vous');
          }
          return RefreshIndicator(
            // Le rayon est fixe : ce qui change entre deux passages,
            // c'est la position de l'utilisateur. Réinvalider les deux
            // providers refait le point GPS puis la requête.
            onRefresh: () async {
              ref.invalidate(currentPositionProvider);
              ref.invalidate(nearbyStructuresProvider);
              await ref.read(nearbyStructuresProvider.future);
            },
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                AppDimens.lg,
                AppDimens.screenPadding,
                AppDimens.xxl,
              ),
              itemCount: liste.length,
              separatorBuilder: (_, __) => SizedBox(height: AppDimens.xl),
              itemBuilder: (_, i) {
                final s = liste[i];
                final data = RestaurantData(
                  name         : s.name,
                  cuisine      : s.categorie,
                  rating       : s.nombreEtoile.toDouble(),
                  deliveryTime : s.tempsLivraison,
                  imageUrl     : s.logoUrl,
                  distance     : s.distance > 0 ? s.distanceLabel : null,
                );
                return RestaurantCard(
                  restaurant : data,
                  // Pleine largeur : la carte de l'accueil est calibrée
                  // pour un défilé horizontal, pas pour une liste.
                  width       : double.infinity,
                  isFavori    : favoris.isFavori(s.id),
                  isToggling  : favoris.isToggling(s.id),
                  onFavoriteTap: () =>
                      ref.read(favoriProvider.notifier).toggleFavori(s.id),
                  onTap: () => showRestaurantBottomSheet(
                    context,
                    data,
                    structureId  : s.id,
                    categoryType : s.categorie,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _message(String texte) => Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.xl),
          child: Text(
            texte,
            textAlign : TextAlign.center,
            style     : AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMuted),
          ),
        ),
      );
}
