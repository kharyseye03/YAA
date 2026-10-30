import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

/// Exécute [action] en couvrant l'écran, puis rend son résultat.
///
/// Réservé aux gestes dont on attend une réponse avant de pouvoir
/// continuer — une annulation, typiquement. Pour le reste, bloquer
/// l'écran coûte plus qu'il ne rassure : un panier qui se recalcule
/// mérite un indicateur discret, pas un voile.
///
/// Le voile ne se ferme pas au toucher ni au bouton retour : pendant
/// qu'une annulation part au serveur, il n'y a rien à faire d'autre
/// qu'attendre, et un écran qu'on peut quitter à mi-chemin laisse
/// croire que le geste n'a pas été pris en compte.
///
/// Relève ce que lève [action], après avoir retiré le voile.
Future<T> pendantAttente<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final navigateur = Navigator.of(context, rootNavigator: true);

  // Non attendu : la boîte ne se ferme qu'à notre demande, plus bas.
  unawaitedDialogue(showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(AppDimens.xl),
          decoration: BoxDecoration(
            color        : Colors.white,
            borderRadius : BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: SizedBox(
            width  : 30.r,
            height : 30.r,
            child  : const CircularProgressIndicator(
                strokeWidth: 2.4, color: AppColors.primary),
          ),
        ),
      ),
    ),
  ));

  try {
    return await action();
  } finally {
    // `finally` et non après le `return` : si l'action échoue, le
    // voile doit disparaître quand même, sinon l'écran reste pris.
    if (navigateur.canPop()) navigateur.pop();
  }
}

/// Ignore volontairement le futur d'une boîte de dialogue.
///
/// Nommé plutôt qu'un `// ignore:` pour que l'intention se lise :
/// cette boîte-là est fermée par [pendantAttente], pas attendue.
void unawaitedDialogue(Future<void> _) {}

/// Confirme qu'un geste a abouti, et attend d'être lue.
///
/// Après une annulation, une notification passagère ne suffit pas :
/// elle peut être manquée, et il reste un doute sur un geste qu'on ne
/// peut pas refaire. Une boîte qu'on ferme soi-même tranche.
Future<void> confirmationAction(
  BuildContext context, {
  required String titre,
  String? message,
}) {
  return showDialog<void>(
    context: context,
    builder: (boite) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width  : 52.r,
            height : 52.r,
            decoration: const BoxDecoration(
              color : AppColors.successLight,
              shape : BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                color: AppColors.success, size: 28.r),
          ),
          SizedBox(height: AppDimens.lg),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight : FontWeight.w800,
              color      : AppColors.dark,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: AppDimens.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color  : AppColors.grey600,
                height : 1.5,
              ),
            ),
          ],
        ],
      ),
      actions: [
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(boite).pop(),
            child: Text(
              'Fermer',
              style: AppTextStyles.bodyMedium.copyWith(
                color      : AppColors.primary,
                fontWeight : FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
