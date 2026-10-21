import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/yaa_button.dart';

/// Confirmation avant une annulation — commande, course ou livraison.
///
/// Une feuille plutôt qu'une boîte de dialogue : la boîte comprime le
/// texte et aligne ses deux réponses en bas à droite, là où le pouce
/// les confond.
///
/// Trois partis pris, tirés de ce qui se fait de mieux sur les actions
/// destructrices :
///
/// - **la sortie sûre est la plus visible.** Le bouton plein garde ;
///   annuler est un lien en dessous. Face à un geste irréversible,
///   c'est le retour en arrière qui mérite le pouce.
/// - **les deux réponses sont éloignées**, l'une sous l'autre et de
///   formes différentes, pour qu'un doigt pressé ne se trompe pas.
/// - **chaque libellé nomme son action.** Ni « OK » ni « Oui », qui
///   obligent à relire la question pour savoir ce qu'on valide.
///
/// Renvoie true si l'utilisateur confirme l'annulation.
Future<bool?> confirmerAnnulation(
  BuildContext context, {
  required String titre,
  required String message,
  required String libelleGarder,
  required String libelleAnnuler,
}) {
  return showModalBottomSheet<bool>(
    context            : context,
    backgroundColor    : Colors.transparent,
    isScrollControlled : true,
    builder: (feuille) => Container(
      decoration: BoxDecoration(
        color        : Colors.white,
        borderRadius : BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimens.screenPadding,
        AppDimens.xl,
        AppDimens.screenPadding,
        MediaQuery.of(feuille).padding.bottom + AppDimens.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width  : 40.w,
              height : 4.h,
              decoration: BoxDecoration(
                color        : AppColors.grey300,
                borderRadius : BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: AppDimens.xl),

          Text(
            titre,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
            ),
          ),
          SizedBox(height: AppDimens.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color  : AppColors.grey600,
              height : 1.55,
            ),
          ),

          SizedBox(height: AppDimens.xxl),

          YaaButton(
            label     : libelleGarder,
            onPressed : () => Navigator.of(feuille).pop(false),
          ),
          SizedBox(height: AppDimens.xs),
          TextButton(
            onPressed : () => Navigator.of(feuille).pop(true),
            style: TextButton.styleFrom(
              foregroundColor : AppColors.error,
              padding         : EdgeInsets.symmetric(vertical: 14.h),
            ),
            child: Text(
              libelleAnnuler,
              style: AppTextStyles.bodyMedium.copyWith(
                color      : AppColors.error,
                fontWeight : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Le lien discret qui ouvre cette confirmation.
///
/// Un lien, pas un bouton pleine largeur : annuler n'est pas ce que
/// l'on vient faire sur un écran de suivi. Une action destructrice
/// reste trouvable sans inviter au geste.
class LienAnnuler extends StatelessWidget {
  const LienAnnuler({
    super.key,
    required this.libelle,
    required this.onTap,
    this.enCours = false,
  });

  final String libelle;
  final VoidCallback onTap;

  /// Verrouille le lien pendant l'appel : un double toucher enverrait
  /// deux requêtes.
  final bool enCours;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap    : enCours ? null : onTap,
        behavior : HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (enCours)
                SizedBox(
                  width  : 13.r,
                  height : 13.r,
                  child  : CircularProgressIndicator(
                      strokeWidth: 1.6, color: AppColors.grey500),
                )
              else
                Icon(Icons.cancel_outlined,
                    size: 15.r, color: AppColors.error),
              SizedBox(width: 7.w),
              Text(
                enCours ? 'Annulation…' : libelle,
                style: AppTextStyles.bodySmall.copyWith(
                  color      : enCours ? AppColors.grey500 : AppColors.error,
                  fontWeight : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
