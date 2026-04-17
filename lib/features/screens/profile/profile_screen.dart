import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';

/// Profile screen — "Mon compte"
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppDimens.xxl),

          // Avatar + Name
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.grey200,
                        border: Border.all(color: AppColors.grey300, width: 2),
                      ),
                      child: const Icon(Icons.person, color: AppColors.grey500, size: 48),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: AppColors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.lg),
                Text('Bernadette Faye', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('bernadettekeita@gmail.com', style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.xxxl),

          _buildSectionTitle('INFORMATIONS PERSONNELLES'),
          const SizedBox(height: AppDimens.sm),
          _buildInfoTile(icon: Icons.mail_outlined, title: 'Adresse e-mail', value: 'bernadette.faye@email.com', onTap: () => context.pushNamed(RouteNames.personalInfo)),
          _buildInfoTile(icon: Icons.phone_outlined, title: 'Téléphone', value: '+221 78 123 45 67', onTap: () => context.pushNamed(RouteNames.personalInfo)),

          const SizedBox(height: AppDimens.xxl),

          _buildSectionTitle('PRÉFÉRENCES'),
          const SizedBox(height: AppDimens.sm),
          _buildInfoTile(icon: Icons.language, title: 'Langue', value: 'Français (France)', trailing: const Icon(Icons.translate, color: AppColors.grey500, size: 22)),
          _buildToggleTile(icon: Icons.notifications_none_outlined, title: 'Notifications', value: _notificationsEnabled, onChanged: (val) => setState(() => _notificationsEnabled = val)),
          _buildInfoTile(icon: Icons.description_outlined, title: 'Conditions d\'utilisations', onTap: () => context.pushNamed(RouteNames.terms)),

          const SizedBox(height: AppDimens.xxl),

          _buildSectionTitle('ZONE DE DANGER'),
          const SizedBox(height: AppDimens.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
            child: Column(
              children: [
                _buildDangerTile(icon: Icons.logout, label: 'Se déconnecter', onTap: () => context.goNamed(RouteNames.login)),
                const SizedBox(height: AppDimens.md),
                _buildDangerTile(icon: Icons.delete_outline, label: 'Supprimer mon compte', onTap: () {}),
              ],
            ),
          ),

          const SizedBox(height: AppDimens.huge),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.overline.copyWith(color: AppColors.grey500, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, String? value, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding, vertical: AppDimens.md),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                  if (value != null) ...[const SizedBox(height: 2), Text(value, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600))],
                ],
              ),
            ),
            trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.grey400, size: 22) : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.screenPadding, vertical: AppDimens.md),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(child: Text(title, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildDangerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.error, size: 22),
            const SizedBox(width: AppDimens.md),
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}