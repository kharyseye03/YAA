import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../user/providers/user_notifier.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../../shared/widgets/bouton_retour.dart';
import 'suppression_compte_sheet.dart';

class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProvider).profile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top    : MediaQuery.of(context).padding.top + 12,
              left   : AppDimens.screenPadding,
              right  : AppDimens.screenPadding,
              bottom : 16.h,
            ),
            child: Row(
              children: [
                const BoutonRetour(),
                SizedBox(width: 12.w),
                Text(
                  'Informations personnelles',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
              ],
            ),
          ),

          // ── Contenu ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal : AppDimens.screenPadding,
              ),
              child: Column(
                children: [
                  SizedBox(height: 28.h),

                  // Avatar
                  UserAvatar(imageUrl: profile?.imageUrl),

                  SizedBox(height: 8.h),

                  // Nom complet sous l'avatar
                  if (profile != null)
                    Text(
                      '${profile.firstName} ${profile.lastName}',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight : FontWeight.w700,
                        fontSize   : 16.sp,
                        color      : AppColors.dark,
                      ),
                    ),

                  SizedBox(height: 28.h),
                  const Divider(height: 1, color: AppColors.grey200),

                  // Lignes infos
                  _InfoRow(
                    icon  : Icons.person_outline_rounded,
                    label : 'Prénom',
                    value : profile?.firstName ?? '—',
                  ),
                  const Divider(height: 1, color: AppColors.grey200),
                  _InfoRow(
                    icon  : Icons.person_outline_rounded,
                    label : 'Nom',
                    value : profile?.lastName ?? '—',
                  ),
                  const Divider(height: 1, color: AppColors.grey200),
                  _InfoRow(
                    icon  : Icons.phone_outlined,
                    label : 'Téléphone',
                    value : profile?.telephone ?? '—',
                  ),
                  const Divider(height: 1, color: AppColors.grey200),
                  _InfoRow(
                    icon  : Icons.mail_outline_rounded,
                    label : 'Email',
                    value : profile?.email ?? '—',
                  ),
                  const Divider(height: 1, color: AppColors.grey200),

                  SizedBox(height: 28.h),

                  // ── Suppression du compte ─────────────────────
                  // Sa place est ici, sur la page du compte : Google
                  // Play exige depuis avril 2024 un chemin de
                  // suppression **facilement trouvable** dans l'app.
                  // Rangée sous « Contacter le support », elle aurait
                  // été accessible mais introuvable pour qui la
                  // cherche — et un examinateur la cherche.
                  //
                  // En bas de page et discrète, loin du bouton
                  // « Modifier » : l'une est quotidienne, l'autre
                  // irréversible.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap    : () => _supprimerCompte(context, ref),
                      behavior : HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18.r, color: AppColors.error),
                            SizedBox(width: 8.w),
                            Text(
                              'Supprimer mon compte',
                              style: AppTextStyles.bodySmall.copyWith(
                                color      : AppColors.error,
                                fontWeight : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),

          // ── Bouton Modifier ──────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left   : AppDimens.screenPadding,
              right  : AppDimens.screenPadding,
              top    : 12.h,
              bottom : MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color  : Colors.white,
              border : Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: YaaButton(
              label     : 'Modifier',
              onPressed : () => context.pushNamed(RouteNames.editPersonalInfo),
            ),
          ),
        ],
      ),
    );
  }

  /// Ouvre la feuille de suppression, puis nettoie la session si le
  /// compte a réellement été supprimé.
  ///
  /// Le `logout` est indispensable : sans lui, les jetons resteraient
  /// dans le coffre et l'application tenterait de restaurer une
  /// session dont le compte n'existe plus.
  Future<void> _supprimerCompte(BuildContext context, WidgetRef ref) async {
    final supprime = await showSuppressionCompteSheet(context);
    if (!supprime || !context.mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Votre compte a été supprimé.')),
    );
    context.goNamed(RouteNames.login);
  }
}

// ── Ligne d'information ───────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Container(
            width  : 36.r,
            height : 36.r,
            decoration: BoxDecoration(
              color        : AppColors.grey100,
              borderRadius : BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.r, color: AppColors.grey600),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color    : AppColors.grey500,
                    fontSize : 11.sp,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight : FontWeight.w600,
                    color      : AppColors.dark,
                    fontSize   : 14.sp,
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
