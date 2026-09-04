import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/devise.dart';
import '../../../model/course/type_vehicule.dart';

/// Deux cartes de service côte à côte sur l'accueil : Livraison / Course.
///
/// Chacune annonce un prix d'appel. Sans lui, les cartes décrivaient un
/// service sans donner de raison d'y toucher — « Faites-vous livrer »
/// n'apprend rien à qui est déjà sur une app de livraison.
class ServiceCards extends StatelessWidget {
  const ServiceCards({
    super.key,
    required this.onLivraison,
    required this.onCourse,
  });

  final VoidCallback onLivraison;
  final VoidCallback onCourse;

  // ⚠️ VALEURS COMMERCIALES À CONFIRMER ⚠️
  // Ce sont des montants d'attente, choisis pour construire la mise en
  // page — ils ne viennent d'aucune API ni d'aucun tarif validé. Un
  // prix affiché engage YAA vis-à-vis du client : à remplacer par les
  // vrais tarifs de départ avant toute mise en production.
  static const int _prixDepartLivraison = 15000;
  static const int _prixDepartCourse    = 20000;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: Row(
        children: [
          Expanded(
            // Dégradés croisés : la moto est sombre et disparaîtrait
            // sur un fond navy, la voiture est claire et ressort mal
            // sur de l'orange.
            child: _ServiceCard(
              titre    : 'Livraison',
              accroche : 'dès ${montantLabel(_prixDepartLivraison)}',
              icon     : Icons.sports_motorsports,
              gradient : const [AppColors.secondary, AppColors.secondaryDeep],
              image    : TypeVehicule.moto.asset,
              onTap    : onLivraison,
            ),
          ),
          SizedBox(width: AppDimens.md),
          Expanded(
            child: _ServiceCard(
              titre    : 'Course',
              accroche : 'dès ${montantLabel(_prixDepartCourse)}',
              icon     : Icons.local_taxi_rounded,
              gradient : const [AppColors.primary, AppColors.primaryLight],
              image    : TypeVehicule.vehicule.asset,
              onTap    : onCourse,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.titre,
    required this.accroche,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.image,
  });

  final String       titre;
  final String       accroche;
  final IconData     icon;
  final List<Color>  gradient;
  final VoidCallback onTap;
  final String?      image;

  @override
  Widget build(BuildContext context) {
    final rayon = BorderRadius.circular(AppDimens.radiusLg);

    return Container(
      height: 132.h,
      decoration: BoxDecoration(
        borderRadius : rayon,
        gradient: LinearGradient(
          begin  : Alignment.topLeft,
          end    : Alignment.bottomRight,
          colors : gradient,
        ),
        boxShadow: [
          BoxShadow(
            color      : gradient.first.withValues(alpha: 0.3),
            blurRadius : 14.r,
            offset     : Offset(0, 6.h),
          ),
        ],
      ),
      // Material + InkWell par-dessus le dégradé : le Container peint
      // le fond, l'InkWell peint l'onde au toucher. Un GestureDetector
      // seul ne donnait aucun retour, la carte semblait inerte.
      child: Material(
        color: Colors.transparent,
        borderRadius: rayon,
        child: InkWell(
          onTap        : onTap,
          borderRadius : rayon,
          child: ClipRRect(
            borderRadius: rayon,
            child: Stack(
              children: [
                // ── Véhicule, en haut à droite ──────────────────
                // Plafonné à 58 % de la hauteur et repoussé vers le
                // haut : auparavant il occupait toute la carte et le
                // texte se dessinait par-dessus. Chacun son espace.
                if (image != null)
                  Positioned(
                    right : -4.w,
                    top   : AppDimens.xs,
                    height: 132.h * 0.58,
                    child: Image.asset(
                      image!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        size  : 34.r,
                        color : Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),

                // ── Titre + prix d'appel, en bas à gauche ───────
                Positioned(
                  left   : 14.w,
                  right  : 10.w,
                  bottom : 13.h,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titre,
                        maxLines : 1,
                        overflow : TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight : FontWeight.w800,
                          fontSize   : 18.sp,
                          color      : Colors.white,
                        ),
                      ),
                      SizedBox(height: AppDimens.xs),
                      // Pastille plutôt que texte nu : sur un dégradé,
                      // un chiffre posé à plat se lit mal et se perd.
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                        ),
                        child: Text(
                          accroche,
                          maxLines : 1,
                          overflow : TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color      : Colors.white,
                            fontWeight : FontWeight.w700,
                            fontSize   : 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
