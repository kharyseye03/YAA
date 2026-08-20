import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../location/providers/position_provider.dart';

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
      error   : (_, __) => 'Dakar, Sénégal',
    );

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Votre position',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500,
                          fontSize: 11,
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
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            LucideIcons.chevronDown,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Notification (droite) ────────────────────────────
          GestureDetector(
            onTap: onNotificationTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                LucideIcons.bell,
                color: AppColors.dark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
