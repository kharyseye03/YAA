import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_router.dart';
import '../../shared/widgets/yaa_button.dart';
import '../../shared/widgets/yaa_text_field.dart';

/// Cart screen showing a summary of items, description field,
/// add more button, and order button.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Header gradient ──────────────────────────────
          _buildHeader(context),

          // ── Content ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.lg),

                  // Total card
                  _buildTotalCard(),

                  const SizedBox(height: AppDimens.lg),

                  // Delivery address
                  _buildDeliveryAddress(),

                  const SizedBox(height: AppDimens.xxl),

                  // Vos articles
                  Text(
                    'Vos articles',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppDimens.md),

                  // Cart items
                  _buildCartItem(
                    name: 'Truffle Beef Burger',
                    description: 'Bœuf Wagyu, truffe noire, f...',
                    price: '2500F cfa',
                    quantity: 1,
                    imageUrl:
                    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
                  ),

                  const SizedBox(height: AppDimens.md),

                  _buildCartItem(
                    name: 'Frites à la Truffe',
                    description: 'Parmesan 24 mois, persil f...',
                    price: '2000F cfa',
                    quantity: 2,
                    imageUrl:
                    'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=200',
                  ),

                  const SizedBox(height: AppDimens.md),

                  _buildCartItem(
                    name: 'Limonade Maison',
                    description: 'Citron jaune, menthe fraîche',
                    price: '1500F cfa',
                    quantity: 1,
                    imageUrl:
                    'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200',
                  ),

                  const SizedBox(height: AppDimens.xxl),

                  // Description
                  Text(
                    'Description',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppDimens.sm),

                  YaaTextField(
                    hint: 'Description suplémentaire',
                    maxLines: 3,
                  ),

                  const SizedBox(height: AppDimens.xxl),

                  // Add more items
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.add,
                                size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Text(
                            'Ajouter d\'autres articles',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimens.xxl),
                ],
              ),
            ),
          ),

          // ── Bottom button ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding,
              vertical: AppDimens.lg,
            ),
            color: AppColors.white,
            child: SafeArea(
              top: false,
              child: YaaButton(
                label: 'Commander',
                onPressed: () {
                  context.pushNamed(RouteNames.checkout);
                },
                icon: Icons.arrow_forward,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: MediaQuery.of(context).padding.top + AppDimens.md,
        bottom: AppDimens.xl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1652F0),
            Color(0xFF08399A)
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Text(
            'Panier',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
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
          // Total label + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à payer',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '4',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimens.xs),

          // Total price
          Text(
            '8000F cfa',
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),

          const SizedBox(height: AppDimens.md),

          // Info chips
          Row(
            children: [
              _buildChip('3 articles'),
              const SizedBox(width: AppDimens.sm),
              _buildChip('Livraison 2000F'),
              const SizedBox(width: AppDimens.sm),
              _buildChip('20-30 min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              color: AppColors.primary, size: 22),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adresse de livraison',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '15 Rue de la Paix, Conakry',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.grey400, size: 22),
        ],
      ),
    );
  }

  Widget _buildCartItem({
    required String name,
    required String description,
    required String price,
    required int quantity,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: AppColors.grey200,
                child: const Icon(Icons.image_outlined,
                    color: AppColors.grey400),
              ),
            ),
          ),

          const SizedBox(width: AppDimens.md),

          // Name, description, price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDimens.md),

          // Quantity selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove, size: 14, color: AppColors.grey700),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    quantity.toString(),
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.add, size: 14, color: AppColors.grey700),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
