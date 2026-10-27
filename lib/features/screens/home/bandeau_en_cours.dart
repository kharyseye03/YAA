import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/order/commande_model.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../orders/providers/commande_notifier.dart';
import '../order/commande_detail_sheet.dart';

/// Rappel permanent d'une course, livraison ou commande en cours.
///
/// Posé au-dessus de la barre de navigation, donc visible depuis les
/// cinq onglets. L'écran de suivi est une page empilée : en revenant
/// à l'accueil elle est détruite, et plus rien ne disait qu'une course
/// était en route. Il fallait rouvrir l'onglet Commandes, toucher la
/// mission, et on tombait sur une feuille sans carte.
///
/// Le bandeau rétablit le chemin : il dit qu'il se passe quelque
/// chose, et ramène là où on peut le suivre.
class BandeauEnCours extends ConsumerWidget {
  const BandeauEnCours({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat     = ref.watch(commandeProvider);
    final missions = etat.coursesEnCours;
    final achats   = etat.achatsEnCours;

    if (missions.isEmpty && achats.isEmpty) return const SizedBox.shrink();

    // Les deux listes sont déjà triées du plus récent au plus ancien.
    // La mission prime sur la commande : elle a une carte à montrer,
    // donc quelque chose à suivre en direct.
    final mission = missions.isNotEmpty ? missions.first : null;
    final achat   = achats.isNotEmpty   ? achats.first   : null;
    final autres  = missions.length + achats.length - 1;

    final libelle = mission != null
        ? _libelleMission(mission)
        : _libelleCommande(achat!);

    return GestureDetector(
      onTap: () {
        if (mission != null) {
          // Vers le suivi en direct, pas vers la feuille de détail.
          context.pushNamed(RouteNames.coursierSearch, extra: mission);
        } else {
          // Une commande sans coursier assigné n'a pas de carte : son
          // détail est tout ce qu'on peut montrer, et c'est honnête.
          showCommandeDetailSheet(context, achat!.id);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color        : AppColors.primary,
          borderRadius : BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color      : Colors.black.withValues(alpha: 0.18),
              blurRadius : 12.r,
              offset     : const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(libelle.icone, size: 18.r, color: Colors.white),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    libelle.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color      : Colors.white,
                      fontWeight : FontWeight.w700,
                    ),
                  ),
                  Text(
                    autres > 0
                        ? '${libelle.detail} · +$autres en cours'
                        : libelle.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20.r, color: Colors.white.withValues(alpha: 0.9)),
          ],
        ),
      ),
    );
  }

  ({String titre, String detail, IconData icone}) _libelleMission(
      LivraisonCourseModel m) {
    final course = m.typeService == TypeServiceMission.course;

    if (!m.hasLivreur) {
      return (
        titre  : course ? 'Recherche d\'un chauffeur' : 'Recherche d\'un coursier',
        detail : 'Touchez pour suivre',
        icone  : Icons.radar_rounded,
      );
    }
    return (
      titre  : m.versDestination
          ? (course ? 'Course en cours' : 'Livraison en cours')
          : (course ? 'Chauffeur en route' : 'Coursier en route'),
      detail : 'Touchez pour suivre en direct',
      icone  : course
          ? Icons.directions_car_rounded
          : Icons.two_wheeler_rounded,
    );
  }

  ({String titre, String detail, IconData icone}) _libelleCommande(
      CommandeModel c) {
    return (
      titre  : c.structureName.isEmpty ? 'Commande en cours' : c.structureName,
      detail : switch (c.statut) {
        'EN_ATTENTE'      => 'En attente de confirmation',
        'CONFIRME'        => 'Confirmée par l\'établissement',
        'EN_PREPARATION'  => 'En préparation',
        'PRET'            => 'Prête, en attente d\'un livreur',
        _                 => 'Touchez pour voir le détail',
      },
      icone  : Icons.shopping_bag_outlined,
    );
  }
}
