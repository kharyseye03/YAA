import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../model/course/type_vehicule.dart';

/// Deux cartes de service côte à côte sur le home : Livraison / Course.
/// Fond dégradé + grande icône (les images de fond pourront être
/// ajoutées plus tard sans changer la structure).
class ServiceCards extends StatelessWidget {
  const ServiceCards({
    super.key,
    required this.onLivraison,
    required this.onCourse,
  });

  final VoidCallback onLivraison;
  final VoidCallback onCourse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: Row(
        children: [
          Expanded(
            // Dégradés croisés par rapport à avant : la moto est navy
            // foncé et disparaîtrait sur un fond navy, la voiture est
            // blanche et ressort mal sur l'orange clair.
            child: _ServiceCard(
              titre     : 'Livraison',
              sousTitre : 'Faites-vous livrer',
              icon      : Icons.sports_motorsports,
              gradient  : const [AppColors.secondary, Color(0xFFCC4400)],
              image     : TypeVehicule.moto.asset,
              onTap     : onLivraison,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ServiceCard(
              titre     : 'Course',
              sousTitre : 'Voiture ou moto',
              icon      : Icons.local_taxi_rounded,
              gradient  : const [AppColors.primary, AppColors.primaryLight],
              image     : TypeVehicule.vehicule.asset,
              onTap     : onCourse,
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
    required this.sousTitre,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.image,
  });

  final String        titre;
  final String        sousTitre;
  final IconData      icon;
  final List<Color>   gradient;
  final VoidCallback  onTap;
  final String?       image; // image de fond optionnelle

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap    : onTap,
      behavior : HitTestBehavior.opaque,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius : BorderRadius.circular(AppDimens.radiusLg),
          gradient: LinearGradient(
            begin  : Alignment.topLeft,
            end    : Alignment.bottomRight,
            colors : gradient,
          ),
          boxShadow: [
            BoxShadow(
              color      : gradient.first.withValues(alpha: 0.3),
              blurRadius : 14,
              offset     : const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Véhicule à droite (PNG transparent) ───────────
            // Aucune hauteur plafonnée : l'image occupe toute la
            // hauteur de la carte, sa largeur suit le ratio. C'est
            // ce qui lui donne sa présence, quitte à mordre le texte.
            // Le Stack rogne ce qui dépasse du cadre arrondi.
            if (image != null)
              Positioned(
                right  : -6,
                top    : 0,
                bottom : 0,
                child: Image.asset(
                  image!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    icon,
                    size  : 40,
                    color : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),

            // ── Texte en bas à gauche ─────────────────────────
            Positioned(
              left   : 14,
              right  : 14,
              bottom : 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight : FontWeight.w800,
                      fontSize   : 18,
                      color      : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sousTitre,
                    style: AppTextStyles.bodySmall.copyWith(
                      color    : Colors.white.withValues(alpha: 0.85),
                      fontSize : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
