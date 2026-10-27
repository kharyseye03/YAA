import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../location/providers/position_provider.dart';
import '../../notifications/providers/notification_notifier.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({
    super.key,
    this.onNotificationTap,
  });

  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Position actuelle : adresse GPS, "Localisation…" pendant le
    // chargement, fallback si permission refusée / GPS désactivé
    final position = ref.watch(currentPositionProvider);
    final location = position.when(
      data    : (p) => p.adresse,
      loading : ()  => 'Localisation…',
      // Ni l'adresse réelle ni un mensonge : la ville par défaut
      // suivie d'une invitation à réessayer. Sans ce mot, quelqu'un
      // qui a refusé la permission ou qui ne capte pas voit une
      // position fausse sans savoir qu'elle l'est.
      error   : (_, __) => 'Conakry · toucher pour réessayer',
    );

    // Refaire le point GPS à la demande. Utile quand le premier essai
    // a échoué, mais aussi quand on change de quartier : la position
    // est mise en cache une fois pour toute la session.
    void rafraichir() {
      if (position.isLoading) return;
      ref.invalidate(currentPositionProvider);
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: MediaQuery.of(context).padding.top + AppDimens.sm,
        bottom: AppDimens.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Localisation (gauche) ────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap    : rafraichir,
              // Toute la zone réagit, pas seulement les lettres :
              // viser un texte de 14 points avec le pouce est ingrat.
              behavior : HitTestBehavior.opaque,
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20.r,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Votre position',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500,
                          fontSize: 11.sp,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              location,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.dark,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          // Pendant la recherche, le chevron cède la
                          // place à un indicateur : le geste a été
                          // pris en compte, quelque chose travaille.
                          if (position.isLoading)
                            SizedBox(
                              width  : 11.r,
                              height : 11.r,
                              child: CircularProgressIndicator(
                                strokeWidth : 1.6,
                                color       : AppColors.primary,
                              ),
                            )
                          else
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.primary,
                              size: 14.r,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),

          // ── Notification (droite) ────────────────────────────
          GestureDetector(
            onTap: onNotificationTap,
            behavior: HitTestBehavior.opaque,
            child: _ClocheAvecPastille(
              nonLues: ref.watch(notificationProvider).nonLues,
              child: SizedBox(
              width: 42.r,
                height: 42.r,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.dark,
                  size: 20.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La cloche, avec le nombre de notifications non lues.
///
/// Au-delà de neuf, « 9+ » : le chiffre exact n'apprend plus rien, et
/// une pastille trop large déborde de la cloche.
class _ClocheAvecPastille extends StatelessWidget {
  const _ClocheAvecPastille({required this.nonLues, required this.child});

  final int nonLues;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (nonLues <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top   : 6.h,
          right : 4.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            constraints: BoxConstraints(minWidth: 16.r),
            decoration: BoxDecoration(
              color        : AppColors.error,
              shape        : BoxShape.rectangle,
              borderRadius : BorderRadius.circular(AppDimens.radiusFull),
              border       : Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              nonLues > 9 ? '9+' : '$nonLues',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color      : Colors.white,
                fontWeight : FontWeight.w800,
                fontSize   : 9.sp,
                height     : 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
