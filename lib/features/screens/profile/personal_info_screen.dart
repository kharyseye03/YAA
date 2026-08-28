import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../user/providers/user_notifier.dart';

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
              bottom : 16,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap     : () => Navigator.of(context).pop(),
                  behavior  : HitTestBehavior.opaque,
                  child: Container(
                    width  : 38,
                    height : 38,
                    decoration: BoxDecoration(
                      color        : AppColors.grey100,
                      borderRadius : BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color : AppColors.dark,
                      size  : 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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

          const Divider(height: 1, color: AppColors.grey200),

          // ── Contenu ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal : AppDimens.screenPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 28),

                  // Avatar
                  UserAvatar(imageUrl: profile?.imageUrl),

                  const SizedBox(height: 8),

                  // Nom complet sous l'avatar
                  if (profile != null)
                    Text(
                      '${profile.firstName} ${profile.lastName}',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight : FontWeight.w700,
                        fontSize   : 16,
                        color      : AppColors.dark,
                      ),
                    ),

                  const SizedBox(height: 28),
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
                ],
              ),
            ),
          ),

          // ── Bouton Modifier ──────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left   : AppDimens.screenPadding,
              right  : AppDimens.screenPadding,
              top    : 12,
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width  : 36,
            height : 36,
            decoration: BoxDecoration(
              color        : AppColors.grey100,
              borderRadius : BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.grey600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color    : AppColors.grey500,
                    fontSize : 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight : FontWeight.w600,
                    color      : AppColors.dark,
                    fontSize   : 14,
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
