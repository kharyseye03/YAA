import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';

/// Orders list screen — "Commandes"
/// Two tabs: "En cours" and "Terminer".
/// Each tab shows a list of order cards.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isOngoing = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tabs ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.screenPadding,
            vertical: AppDimens.lg,
          ),
          child: _buildTabs(),
        ),

        // ── Orders list ─────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding,
            ),
            child: _isOngoing
                ? _buildOngoingOrders()
                : _buildCompletedOrders(),
          ),
        ),
      ],
    );
  }



  Widget _buildTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTab(
            label: 'En cours',
            isActive: _isOngoing,
            onTap: () => setState(() => _isOngoing = true),
          ),
          _buildTab(
            label: 'Terminer',
            isActive: !_isOngoing,
            onTap: () => setState(() => _isOngoing = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primarySurface : AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isActive ? AppColors.primary : AppColors.grey600,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── En cours ─────────────────────────────────────────────
  Widget _buildOngoingOrders() {
    return Column(
      children: [
        _OrderCard(
          orderId: '#CMD-8492',
          date: 'Aujourd\'hui, 14:30',
          status: 'Préparation',
          statusColor: AppColors.warning,
          shopName: 'Burger King - Plateau',
          items: '2x Truffle Beef Burger, 1x Frites',
          price: '5000F cfa',
          imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
          showTrackButton: true,
          onTrackTap: () => context.pushNamed(RouteNames.orderTracking),
        ),
        const SizedBox(height: AppDimens.lg),
        _OrderCard(
          orderId: '#CMD-8491',
          date: 'Aujourd\'hui, 13:15',
          status: 'En route',
          statusColor: AppColors.primary,
          shopName: 'Green Life',
          items: '1x Crudité salade, 1x Jus nature',
          price: '12000F cfa',
          imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
          showTrackButton: true,
          onTrackTap: () => context.pushNamed(RouteNames.orderTracking),
        ),
        const SizedBox(height: AppDimens.xxl),
      ],
    );
  }

  // ── Terminées ────────────────────────────────────────────
  Widget _buildCompletedOrders() {
    return Column(
      children: [
        _OrderCard(
          orderId: '#CMD-8320',
          date: 'Hier, 19:45',
          status: 'Livrée',
          statusColor: AppColors.success,
          shopName: 'Pasta Box',
          items: '1x Spaguetti bolognaise',
          price: '1000F cfa',
          imageUrl:
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200',
          showTrackButton: false,
          onTap: () => context.pushNamed(RouteNames.orderDetail),
        ),
        const SizedBox(height: AppDimens.xxl),
      ],
    );
  }
}

/// Single order card widget.
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.shopName,
    required this.items,
    required this.price,
    required this.imageUrl,
    required this.showTrackButton,
    this.onTrackTap,
    this.onTap,
  });

  final String orderId;
  final String date;
  final String status;
  final Color statusColor;
  final String shopName;
  final String items;
  final String price;
  final String imageUrl;
  final bool showTrackButton;
  final VoidCallback? onTrackTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande $orderId',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius:
                    BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.lg),

            // Product row
            Row(
              children: [
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusSm),
                  child: Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.grey200,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.md),

            // Price + Track button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showTrackButton)
                  GestureDetector(
                    onTap: onTrackTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        'Suivre',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}