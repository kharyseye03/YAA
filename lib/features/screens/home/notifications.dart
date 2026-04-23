import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../model/notification_item.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // TODO: Replace with real data from provider
  final List<NotifItem> _notifications = const [
    NotifItem(
      icon: Icons.inventory_2_outlined,
      iconBg: Color(0xFF1652F0),
      iconColor: Colors.white,
      title: 'Nouvelle livraison à proximité',
      subtitle: 'Une commande prioritaire est disponible à 0.5 km.',
      time: 'Il y a 2 min',
      isUnread: true,
      actionLabel: 'Voir les détails et accepter',
    ),
    NotifItem(
      avatarPath: 'assets/images/profile.jpg',
      title: 'Message de Sarah J.',
      subtitle: '"Je suis à l\'entrée. Veuillez laisser le colis et sonner."',
      time: 'Il y a 15 min',
      isUnread: false,
    ),
    NotifItem(
      icon: Icons.account_balance_wallet_outlined,
      iconBg: Color(0xFFFFF0E6),
      iconColor: Color(0xFFE07B39),
      title: 'Paiement traité',
      subtitle: 'Vos gains hebdomadaires de 452,80 € ont été versés.',
      time: 'Il y a 2h',
      isUnread: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _NotifHeader(onBack: () => context.goNamed(RouteNames.home)),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadding,
              AppDimens.md,
              AppDimens.screenPadding,
              AppDimens.sm,
            ),
            child: _SearchBar(controller: _searchController),
          ),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: AppDimens.screenPadding,
                endIndent: AppDimens.screenPadding,
              ),
              itemBuilder: (context, index) =>
                  _NotifTile(item: _notifications[index]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────

class _NotifHeader extends StatelessWidget {
  const _NotifHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1652F0), Color(0xFF08399A)],
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: MediaQuery.of(context).padding.top + AppDimens.sm,
        bottom: AppDimens.lg,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: AppDimens.md),

          Text(
            'Notifications',
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Rechercher',
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
        prefixIcon: const Icon(Icons.search, color: AppColors.grey400, size: 20),
        filled: true,
        fillColor: AppColors.grey100,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification tile
// ─────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item});

  final NotifItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // TODO: handle tap
      child: Container(
        color: item.isUnread
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding,
          vertical: AppDimens.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or icon
            _NotifAvatar(item: item),

            const SizedBox(width: AppDimens.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (item.isUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (item.actionLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.actionLabel!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),

                  Text(
                    item.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item.time,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifAvatar extends StatelessWidget {
  const _NotifAvatar({required this.item});

  final NotifItem item;

  @override
  Widget build(BuildContext context) {
    if (item.avatarPath != null) {
      return Stack(
        children: [
          ClipOval(
            child: Image.asset(
              item.avatarPath!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.grey200,
                child: const Icon(Icons.person, color: AppColors.grey400),
              ),
            ),
          ),
          // Online dot
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: item.iconBg ?? AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.icon ?? Icons.notifications,
        color: item.iconColor ?? AppColors.primary,
        size: 22,
      ),
    );
  }
}

