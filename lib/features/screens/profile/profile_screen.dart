import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../user/providers/user_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final user = ref.watch(userProvider);
    final profile = user.profile;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: top + 24),

          // ── Photo + nom ───────────────────────────────
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    user.isLoading
                        ? Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.grey100,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            ),
                          )
                        : UserAvatar(imageUrl: profile?.imageUrl),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => context.pushNamed(
                            RouteNames.editPersonalInfo),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.dark,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  profile?.fullName ?? '—',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  profile?.email ?? '—',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
          const Divider(height: 1, color: AppColors.grey200),

          // ── Infos personnelles ────────────────────────
          _Row(
            icon: Icons.person_outline_rounded,
            label: 'Informations personnelles',
            onTap: () => context.pushNamed(RouteNames.personalInfo),
          ),
          const _Divider(),
          _Row(
            icon: Icons.location_on_outlined,
            label: 'Adresse de livraison',
            onTap: () {},
          ),
          const _Divider(),
          _Row(
            icon: Icons.phone_outlined,
            label: profile?.telephone ?? 'Téléphone',
            subtitle: profile?.telephone != null ? null : 'Non renseigné',
            onTap: () => context.pushNamed(RouteNames.personalInfo),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 8),

          // ── Historique ────────────────────────────────
          _Row(
            icon: Icons.history_rounded,
            label: 'Historique des commandes',
            subtitle: 'Vos commandes terminées',
            onTap: () => context.pushNamed(RouteNames.orderHistory),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 8),

          // ── Préférences ───────────────────────────────
          _ToggleRow(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          const _Divider(),
          _Row(
            icon: Icons.language_rounded,
            label: 'Langue',
            subtitle: 'Français',
            onTap: () {},
          ),
          const _Divider(),
          _Row(
            icon: Icons.description_outlined,
            label: 'Conditions d\'utilisation',
            onTap: () => context.pushNamed(RouteNames.terms),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 8),

          // ── Déconnexion ───────────────────────────────
          _Row(
            icon: Icons.logout_rounded,
            label: 'Se déconnecter',
            labelColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  content: const Text(
                    'Êtes-vous sûr de vouloir vous déconnecter ?',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Color(0xFF666666)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.goNamed(RouteNames.login);
            },
          ),
          const _Divider(),
          _Row(
            icon: Icons.delete_outline_rounded,
            label: 'Supprimer mon compte',
            labelColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {},
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Ligne simple ──────────────────────────────────────────
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: iconColor ?? AppColors.grey600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.dark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null && labelColor == null)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }
}

// ── Ligne avec toggle ─────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.screenPadding,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey600),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.dark,
              trackOutlineColor:
                  WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider interne ───────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 52),
      child: Divider(height: 1, color: AppColors.grey200),
    );
  }
}
