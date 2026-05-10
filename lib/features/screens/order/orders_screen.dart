import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _tab = 0;

  static const _ongoing = [
    _Order(
      shopName: 'Burger King – Plateau',
      items: '2× Truffle Beef Burger, 1× Frites',
      date: "Aujourd'hui, 14:30",
      price: 5000,
      status: 'En préparation',
      statusColor: Color(0xFFF39C12),
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
    ),
    _Order(
      shopName: 'Green Life',
      items: '1× Crudité salade, 1× Jus nature',
      date: "Aujourd'hui, 13:15",
      price: 12000,
      status: 'En route',
      statusColor: Color(0xFF1652F0),
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
    ),
  ];

  static const _completed = [
    _Order(
      shopName: 'Pasta Box',
      items: '1× Spaghetti bolognaise',
      date: 'Hier, 19:45',
      price: 1000,
      status: 'Livrée',
      statusColor: Color(0xFF27AE60),
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200',
    ),
    _Order(
      shopName: 'Chez Fatou',
      items: '1× Thiéboudienne, 2× Eau minérale',
      date: '08 mai, 12:00',
      price: 4500,
      status: 'Livrée',
      statusColor: Color(0xFF27AE60),
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final list = _tab == 0 ? _ongoing : _completed;

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        _Tabs(current: _tab, onTap: (i) => setState(() => _tab = i)),
        Expanded(
          child: list.isEmpty
              ? _Empty()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding,
                    vertical: AppDimens.lg,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 32, color: AppColors.grey200),
                  itemBuilder: (_, i) => _OrderRow(
                    order: list[i],
                    onTap: () => _tab == 0
                        ? context.pushNamed(RouteNames.orderTracking)
                        : context.pushNamed(RouteNames.orderDetail),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────
class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const labels = ['En cours', 'Terminées'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(2, (i) {
            final active = i == current;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 14,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppColors.dark : AppColors.grey400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Stack(
          children: [
            Container(height: 1, color: AppColors.grey200),
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment:
                  current == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 2,
                  color: AppColors.dark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Ligne commande ────────────────────────────────────────
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onTap});
  final _Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              order.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_outlined,
                    color: AppColors.grey400, size: 24),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.shopName,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.items,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  order.date,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Prix + statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${order.price} F',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: order.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.status,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: order.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── État vide ─────────────────────────────────────────────
class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: AppColors.grey300),
          const SizedBox(height: AppDimens.lg),
          Text(
            'Aucune commande',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            'Vos commandes apparaîtront ici.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modèle ────────────────────────────────────────────────
class _Order {
  final String shopName;
  final String items;
  final String date;
  final int price;
  final String status;
  final Color statusColor;
  final String imageUrl;

  const _Order({
    required this.shopName,
    required this.items,
    required this.date,
    required this.price,
    required this.status,
    required this.statusColor,
    required this.imageUrl,
  });
}
