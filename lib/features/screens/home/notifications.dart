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
  // TODO: remplacer par un vrai provider
  final List<NotifItem> _notifications = [
    NotifItem(
      icon      : Icons.shopping_bag_outlined,
      iconBg    : AppColors.primarySurface,
      iconColor : AppColors.primary,
      title     : 'Commande confirmée',
      subtitle  : 'Votre commande #1042 chez Chez Fatou a bien été confirmée.',
      time      : 'Il y a 2 min',
      isUnread  : true,
    ),
    NotifItem(
      icon      : Icons.local_shipping_outlined,
      iconBg    : AppColors.infoLight,
      iconColor : AppColors.info,
      title     : 'En cours de livraison',
      subtitle  : 'Votre livreur est en route. Arrivée estimée dans 10 min.',
      time      : 'Il y a 20 min',
      isUnread  : true,
    ),
    NotifItem(
      icon      : Icons.check_circle_outline_rounded,
      iconBg    : AppColors.successLight,
      iconColor : AppColors.success,
      title     : 'Commande livrée',
      subtitle  : 'Votre commande #1038 a bien été livrée. Bon appétit !',
      time      : 'Hier, 19h30',
      isUnread  : false,
    ),
    NotifItem(
      icon      : Icons.local_offer_outlined,
      iconBg    : Color(0xFFFFF0E6),
      iconColor : AppColors.secondary,
      title     : 'Offre spéciale ce week-end',
      subtitle  : '-20% sur toutes vos commandes avec le code WEEKEND20.',
      time      : 'Hier, 10h00',
      isUnread  : false,
    ),
    NotifItem(
      icon      : Icons.account_balance_wallet_outlined,
      iconBg    : AppColors.successLight,
      iconColor : AppColors.success,
      title     : 'Remboursement effectué',
      subtitle  : 'Un remboursement de 3 500 F a été crédité sur votre compte.',
      time      : 'Il y a 3 jours',
      isUnread  : false,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  @override
  Widget build(BuildContext context) {
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
                  onTap: () => context.goNamed(RouteNames.home),
                  behavior: HitTestBehavior.opaque,
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
                  'Notifications',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight : FontWeight.w800,
                    color      : AppColors.dark,
                  ),
                ),
                const Spacer(),
                if (_unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color        : AppColors.grey100,
                      borderRadius : BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Text(
                      '$_unreadCount nouvelle${_unreadCount > 1 ? 's' : ''}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color      : AppColors.grey600,
                        fontWeight : FontWeight.w600,
                        fontSize   : 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.grey200),

          // ── Liste ───────────────────────────────────────────
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.grey200),
                    itemBuilder: (_, i) => _NotifTile(item: _notifications[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width  : 72,
            height : 72,
            decoration: const BoxDecoration(
              color : AppColors.grey100,
              shape : BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size  : 32,
              color : AppColors.grey400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune notification',
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight : FontWeight.w700,
              color      : AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vous serez informé de vos commandes ici.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item});
  final NotifItem item;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: item.isUnread
          ? AppColors.grey100.withValues(alpha: 0.6)
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal : AppDimens.screenPadding,
          vertical   : 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width  : 44,
              height : 44,
              decoration: BoxDecoration(
                color        : item.iconBg ?? AppColors.primarySurface,
                borderRadius : BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon ?? Icons.notifications_outlined,
                color : item.iconColor ?? AppColors.primary,
                size  : 20,
              ),
            ),

            const SizedBox(width: 14),

            // Textes
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
                            fontWeight : FontWeight.w700,
                            color      : AppColors.dark,
                            fontSize   : 13,
                          ),
                        ),
                      ),
                      if (item.isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width  : 8,
                          height : 8,
                          decoration: const BoxDecoration(
                            shape : BoxShape.circle,
                            color : AppColors.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color  : AppColors.grey600,
                      height : 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.time,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey400,
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
