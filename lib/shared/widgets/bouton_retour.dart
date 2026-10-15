import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

/// Flèche de retour des en-têtes d'écran.
///
/// Sans fond : la pastille grise qui entourait ces flèches était
/// recopiée dans sept écrans, et alourdissait des en-têtes déjà
/// blancs. La flèche seule suffit à se faire comprendre.
///
/// La zone touchable reste entière — 40 points de côté, la taille
/// recommandée par Apple comme par Google. C'est elle qui compte pour
/// le pouce, pas le fond qu'on voyait.
class BoutonRetour extends StatelessWidget {
  const BoutonRetour({
    super.key,
    this.onTap,
    this.icon = Icons.chevron_left_rounded,
    this.taille = 22,
    this.couleur = AppColors.dark,
  });

  /// Par défaut, revient à l'écran précédent.
  final VoidCallback? onTap;

  final IconData icon;

  /// Taille de la flèche, pas de la zone touchable.
  final double taille;

  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap    : onTap ?? () => Navigator.of(context).maybePop(),
      behavior : HitTestBehavior.opaque,
      child: SizedBox(
        width  : 40.r,
        height : 40.r,
        child: Align(
          // Alignée à gauche : la flèche se pose sur la marge de
          // l'écran, sans décalage visible, alors que le carré
          // touchable déborde vers la droite.
          alignment : Alignment.centerLeft,
          child     : Icon(icon, size: taille.r, color: couleur),
        ),
      ),
    );
  }
}
