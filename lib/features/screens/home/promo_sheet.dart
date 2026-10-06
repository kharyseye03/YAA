import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';

/// Page promotionnelle plein écran, ouverte depuis une bannière.
///
/// Une bannière de carrousel ne peut porter qu'une accroche : le
/// détail de l'offre — ce qu'elle couvre, jusqu'à quand, avec quel
/// code — n'y tient pas. D'où cette page, qui prend tout l'écran et
/// laisse le message respirer.
///
/// [codePromo] est l'élément central quand il existe : c'est la seule
/// chose que le client doit emporter. Il est donc surligné et copiable
/// d'un appui — recopier un code à la main depuis une image est le
/// meilleur moyen de le saisir de travers.
Future<void> showPromoSheet(
  BuildContext context, {
  required String image,
  required String titre,
  required String sousTitre,
  String? codePromo,
  String? mention,
  required String libelleAction,
  VoidCallback? onAction,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => _PromoSheet(
      image         : image,
      titre         : titre,
      sousTitre     : sousTitre,
      codePromo     : codePromo,
      mention       : mention,
      libelleAction : libelleAction,
      onAction      : onAction,
    ),
    transitionBuilder: (_, animation, __, child) {
      // Monte depuis le bas : la page vient de la bannière touchée,
      // elle ne surgit pas de nulle part.
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

class _PromoSheet extends StatelessWidget {
  const _PromoSheet({
    required this.image,
    required this.titre,
    required this.sousTitre,
    required this.codePromo,
    required this.mention,
    required this.libelleAction,
    required this.onAction,
  });

  final String  image;
  final String  titre;
  final String  sousTitre;
  final String? codePromo;
  final String? mention;
  final String  libelleAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image de fond ───────────────────────────────
          Image.asset(
            image,
            fit: BoxFit.cover,
            // Le fond navy reste visible si l'asset manque : mieux
            // vaut une page unie qu'une croix d'erreur.
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          // Voile dégradé : le texte blanc doit rester lisible quelle
          // que soit l'image, et l'image doit rester reconnaissable.
          // Un aplat uniforme la tuerait.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin : Alignment.topCenter,
                end   : Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark.withValues(alpha: 0.88),
                  AppColors.primaryDark.withValues(alpha: 0.55),
                  AppColors.primaryDark.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Fermer ──────────────────────────────
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap    : () => Navigator.of(context).pop(),
                    behavior : HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(AppDimens.lg),
                      child: Icon(Icons.close_rounded,
                          color: Colors.white, size: 26.r),
                    ),
                  ),
                ),

                SizedBox(height: AppDimens.xl),

                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.screenPadding),
                  child: Column(
                    children: [
                      Text(
                        titre.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h1.copyWith(
                          color      : Colors.white,
                          fontWeight : FontWeight.w900,
                          height     : 1.05,
                          fontSize   : 34.sp,
                        ),
                      ),
                      SizedBox(height: AppDimens.md),
                      Text(
                        sousTitre,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color  : Colors.white.withValues(alpha: 0.92),
                          height : 1.45,
                        ),
                      ),
                      if (codePromo != null) ...[
                        SizedBox(height: AppDimens.xl),
                        _Code(code: codePromo!),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                if (mention != null)
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.screenPadding),
                    child: Text(
                      mention!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                SizedBox(height: AppDimens.md),

                // ── Action ──────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.screenPadding,
                    0,
                    AppDimens.screenPadding,
                    AppDimens.xl,
                  ),
                  child: SizedBox(
                    width  : double.infinity,
                    height : 54.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onAction?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor : AppColors.secondary,
                        foregroundColor : Colors.white,
                        elevation       : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                        ),
                      ),
                      child: Text(
                        libelleAction,
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Code promo surligné, copiable d'un appui.
class _Code extends StatefulWidget {
  const _Code({required this.code});
  final String code;

  @override
  State<_Code> createState() => _CodeState();
}

class _CodeState extends State<_Code> {
  bool _copie = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.code));
        if (!mounted) return;
        HapticFeedback.selectionClick();
        setState(() => _copie = true);
        // Le retour revient à son état initial : la page peut rester
        // ouverte, et « Copié » n'a de sens qu'un instant.
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copie = false);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppDimens.lg, vertical: AppDimens.md),
        decoration: BoxDecoration(
          // Jaune vif, comme le numéro surligné des campagnes Yango :
          // sur un fond sombre, c'est ce qui accroche l'œil en premier.
          color        : const Color(0xFFFFE94A),
          borderRadius : BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copie ? Icons.check_rounded : Icons.local_offer_rounded,
              color: AppColors.dark,
              size : 20.r,
            ),
            SizedBox(width: AppDimens.sm),
            Text(
              _copie ? 'Copié' : widget.code,
              style: AppTextStyles.h3.copyWith(
                color        : AppColors.dark,
                fontWeight   : FontWeight.w900,
                letterSpacing: 1.5,
                fontSize     : 22.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
