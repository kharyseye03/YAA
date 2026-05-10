import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/widgets/yaa_button.dart';
import '../../../shared/widgets/yaa_text_field.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.onAddMore});

  final VoidCallback? onAddMore;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── Header blanc ────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            top: top + 12,
            left: AppDimens.screenPadding,
            right: AppDimens.screenPadding,
            bottom: 16,
          ),
          child: Row(
            children: [
              Text(
                'Mon panier',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Text(
                  '3 articles',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.grey200),

        // ── Contenu scrollable ──────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadding,
              20,
              AppDimens.screenPadding,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Résumé total ───────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total à payer',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '8 000 F',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _Chip(Icons.access_time_outlined, '20-30 min'),
                        const SizedBox(width: 8),
                        _Chip(Icons.directions_bike_outlined, '2 000 F'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.grey200),
                const SizedBox(height: 20),

                // ── Adresse ────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adresse de livraison',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey500,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '15 Rue de la Paix, Dakar',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.grey400),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.grey200),
                const SizedBox(height: 20),

                // ── Articles ───────────────────────────
                Text(
                  'Articles',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.grey500,
                    letterSpacing: 0.4,
                  ),
                ),

                const SizedBox(height: 16),

                _CartItem(
                  name: 'Truffle Beef Burger',
                  description: 'Bœuf Wagyu, truffe noire',
                  price: 2500,
                  quantity: 1,
                  imageUrl:
                      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
                ),
                const Divider(height: 24, color: AppColors.grey200),
                _CartItem(
                  name: 'Frites à la Truffe',
                  description: 'Parmesan 24 mois, persil frais',
                  price: 2000,
                  quantity: 2,
                  imageUrl:
                      'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=200',
                ),
                const Divider(height: 24, color: AppColors.grey200),
                _CartItem(
                  name: 'Limonade Maison',
                  description: 'Citron jaune, menthe fraîche',
                  price: 1500,
                  quantity: 1,
                  imageUrl:
                      'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200',
                ),

                const SizedBox(height: 24),

                // ── Ajouter des articles ───────────────
                GestureDetector(
                  onTap: onAddMore,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primary, width: 1.5),
                        ),
                        child: const Icon(Icons.add,
                            size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ajouter d\'autres articles',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.grey200),
                const SizedBox(height: 20),

                // ── Note ──────────────────────────────
                Text(
                  'Note pour le livreur',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.grey500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                YaaTextField(
                  hint: 'Instructions supplémentaires…',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),

        // ── Bouton Commander fixe ───────────────────────
        Container(
          padding: EdgeInsets.only(
            left: AppDimens.screenPadding,
            right: AppDimens.screenPadding,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.grey200)),
          ),
          child: YaaButton(
            label: 'Commander · 8 000 F',
            onPressed: () => context.pushNamed(RouteNames.checkout),
            icon: Icons.arrow_forward,
          ),
        ),
      ],
    );
  }
}

// ── Chip info ─────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.grey600),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Article panier ────────────────────────────────────────
class _CartItem extends StatefulWidget {
  const _CartItem({
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  final String name;
  final String description;
  final int price;
  final int quantity;
  final String imageUrl;

  @override
  State<_CartItem> createState() => _CartItemState();
}

class _CartItemState extends State<_CartItem> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            widget.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: AppColors.grey100,
              child: const Icon(Icons.image_outlined,
                  color: AppColors.grey400, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.dark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.price} F',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Sélecteur quantité
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_qty > 1) setState(() => _qty--);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove,
                    size: 14, color: AppColors.dark),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$_qty',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _qty++),
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add,
                    size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
